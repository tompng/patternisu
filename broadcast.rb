require 'oj'
require 'redis'

class Connection
  attr_reader :worker_id, :redis
  def initialize(&block)
    @worker_id = random_id
    @workers = {}
    @redis = Redis.new
    @inbox = {}
    Thread.new { run_ping }
    Thread.new { run_ping_receive }
    Thread.new { run_broadcast_receive(&block) }
    Thread.new { run_inbox_receive }
  end

  def random_id
    rand(0xffffff).to_s(16)
  end

  def run_ping_receive
    subscribe 'ping' do |worker_id|
      time = Time.now
      @workers[worker_id] = time
      @workers = @workers.select { |_, t| t > time - 3 }
    end
  end

  def live_workers
    time = Time.now - 3
    @workers.map { |id, t| id if time < t }.compact
  end

  def run_ping
    loop do
      @redis.publish 'ping', @worker_id
      sleep 1
    end
  end

  def run_broadcast_receive
    subscribe 'data' do |data|
      message, from, msg_id = Oj.load data
      response = yield message, from, !!msg_id
      @redis.publish from, Oj.dump([msg_id, response]) if msg_id
    end
  end

  def run_inbox_receive
    subscribe @worker_id do |message|
      msg_id, response = Oj.load message
      box = @inbox[msg_id]
      box << response if box
    end
  end

  def broadcast message
    @redis.publish 'data', Oj.dump([message, @worker_id])
  end

  def subscribe key, &block
    Thread.new do
      Redis.new.subscribe key do |on|
        on.message do |_, message|
          block.call message
        end
      end
    end
  end

  def broadcast_with_ack message, timeout: 1
    msg_id = random_id
    queue = Queue.new
    @inbox[msg_id] = queue
    @redis.publish 'data', Oj.dump([message, @worker_id, msg_id])
    output = []
    Timeout.timeout timeout do
      live_workers.map do
        output << queue.deq
      end
    end rescue nil
    output
  ensure
    @inbox[msg_id] = nil
  end
end

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
    Thread.new { run_receive(&block) }
  end

  def random_id
    rand(0xffffffff).to_s(16)
  end

  def run_ping_receive
    subscribe 'ping' do |_, worker_id|
      time = Time.now
      @workers[worker_id] = time
      @workers = @workers.select { |_, t| t > time - 3 }
    end
  rescue StandardError => e
    puts e
    sleep 1
    retry
  end

  def live_workers
    time = Time.now - 3
    @workers.map { |id, t| id if time < t }.compact
  end

  def run_ping
    loop do
      @redis.publish 'ping', @worker_id rescue nil
      sleep 1
    end
  end

  def run_receive
    subscribe 'data', @worker_id do |type, data|
      if type == 'data'
        message, from, msg_id, include_self = Oj.load data
        response = yield message, from, !!msg_id
        next if msg_id.nil? || (!include_self && from == @worker_id)
        @redis.publish from, Oj.dump([response, @worker_id, msg_id, true]) if msg_id
      else
        message, from, msg_id, is_reply = Oj.load data
        if is_reply
          box = @inbox[msg_id]
          box << [from, message] if box
        else
          response = yield message, from, !!msg_id
          @redis.publish from, Oj.dump([response, @worker_id, msg_id, true]) if msg_id
        end
      end
    end
  rescue StandardError => e
    puts e
    sleep 1
    retry
  end

  def subscribe *keys
    Redis.new.subscribe(*keys) do |on|
      on.message do |key, message|
        yield key, message
      end
    end
  end

  def send message, to:
    @redis.publish to, Oj.dump([message, @worker_id, nil, false])
  end

  def send_with_ack message, to:, timeout: 1
    msg_id = random_id
    queue = Queue.new
    @inbox[msg_id] = queue
    @redis.publish to, Oj.dump([message, @worker_id, msg_id, false])
    Timeout.timeout timeout do
      queue.deq.last
    end rescue nil
  ensure
    @inbox.delete msg_id
  end

  def broadcast message
    @redis.publish 'data', Oj.dump([message, @worker_id])
  end

  def broadcast_with_ack message, timeout: 1, include_self: false
    msg_id = random_id
    queue = Queue.new
    @inbox[msg_id] = queue
    @redis.publish 'data', Oj.dump([message, @worker_id, msg_id, include_self])
    output = []
    Timeout.timeout timeout do
      count = include_self ? live_workers.size : live_workers.size - 1
      count.times { output << queue.deq }
    end rescue nil
    output.to_h
  ensure
    @inbox.delete msg_id
  end
end

require 'pry';binding.pry

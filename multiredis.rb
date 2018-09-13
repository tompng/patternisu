require 'oj'
require 'redis'

class Connection
  attr_reader :worker_id, :client, :clients
  def initialize(worker_id: nil, local_server:, servers: [], &block)
    @block = block
    @workers = {}
    @worker_id = worker_id || random_id
    servers = servers.zip(servers).to_h if servers.is_a? Array
    @client = Redis.new host: servers[local_server] || local_server
    @clients = servers.map do |name, host|
      # host = 'localhost' if local_server == name || local_server == host
      [name, Redis.new(host: host)]
    end.to_h
    @publish_queue = Queue.new
    @inbox = {}
    @receive_queue = Queue.new
    servers.each_value { |host| Thread.new { run_receive host } }
    Thread.new { run_async_publish }
    Thread.new { run_process_receive }
    Thread.new { send_ping }
  end

  def run_receive host
    subscribe host: host, keys: ['ping', 'data', @worker_id] do |type, data|
      @receive_queue << [type, data]
    end
  rescue StandardError => e
    puts e
    sleep 1
    retry
  end

  def run_process_receive
    loop do
      type, data = @receive_queue.deq
      case type
      when 'data'
        process_data data
      when 'ping'
        process_ping data
      else
        process_msg data
      end
    end
  end

  def process_data(data)
    message, from, msg_id, include_self = Oj.load data
    return if !include_self && from == @worker_id
    response = @block.call message, from, !!msg_id
    return if msg_id.nil?
    async_publish from, Oj.dump([response, @worker_id, msg_id, true]) if msg_id
  end

  def process_msg(data)
    message, from, msg_id, is_reply = Oj.load data
    if is_reply
      box = @inbox[msg_id]
      box << [from, message] if box
    else
      response = @block.call message, from, !!msg_id
      async_publish from, Oj.dump([response, @worker_id, msg_id, true]) if msg_id
    end
  end

  def process_ping(worker_id)
    time = Time.now
    @workers[worker_id] = time
    @workers = @workers.select { |_, t| t > time - 3 }
  end

  def random_id
    rand(0xffffffff).to_s(16)
  end

  def async_publish channel, data
    @publish_queue << [channel, data]
    nil
  end

  def send_ping
    loop do
      @client.publish 'ping', @worker_id rescue nil
      sleep 1
    end
  end

  def run_async_publish
    loop do
      channel, data = @publish_queue.deq
      @client.publish channel, data rescue nil
    end
  end

  def live_workers
    time = Time.now - 3
    @workers.map { |id, t| id if time < t }.compact
  end

  def subscribe(keys:, host: nil)
    Redis.new(host: host).subscribe(*keys) do |on|
      on.message do |key, message|
        yield key, message
      end
    end
  end

  def send message, to:
    async_publish to, Oj.dump([message, @worker_id, nil, false])
  end

  def send_with_ack message, to:, timeout: 1
    msg_id = random_id
    queue = Queue.new
    @inbox[msg_id] = queue
    @client.publish to, Oj.dump([message, @worker_id, msg_id, false])
    Timeout.timeout timeout do
      queue.deq.last
    end rescue nil
  ensure
    @inbox.delete msg_id
  end

  def broadcast message, include_self: false
    async_publish 'data', Oj.dump([message, @worker_id, nil, include_self])
  end

  def broadcast_with_ack message, timeout: 1, include_self: false
    msg_id = random_id
    queue = Queue.new
    @inbox[msg_id] = queue
    @client.publish 'data', Oj.dump([message, @worker_id, msg_id, include_self])
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
c1 = Connection.new worker_id: :c1, local_server: :a, servers: {a: '0.0.0.0', b: '::0'} do |aaa|
  p c1: aaa
  aaa.to_s.swapcase
end
c2 = Connection.new worker_id: :c2, local_server: :b, servers: {a: '0.0.0.0', b: '::0'} do |aaa|
  p c2: aaa
  aaa.to_s.swapcase.reverse
end

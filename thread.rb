@task_queue = Queue.new
@pools = 4.times.map do
  Thread.new do
    loop do
      task, cb = @task_queue.deq
      response = task.call
      cb << response if cb
    end
  end
end

def async_insert
  @task_queue << -> { db.xquery('insert') }
end

def parallel_insert
  queue = Queue.new
  @task_queue << [-> { db.xquery 'insert1' }, queue]
  @task_queue << [-> { db.xquery 'insert2' }, queue]
  2.times { queue.deq }
end

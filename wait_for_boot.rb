def wait_for_db
  new_db_connection.close
rescue => e
  puts "waiting for db launch: #{e}"
  sleep 1
  retry
end

def wait_for_redis(host_option = {})
  redis = Redis.new host_option
  begin
    redis.get 'test'
  rescue => e
    puts "waiting for redis launch: #{e}"
    sleep 1
    retry
  end
  redis.close
end

require 'redis'
redis = Redis.new
redis.flushall

redis.lpush 'list', 'a'
redis.lpush 'list', 'b'
redis.rpush 'list', 'c'
redis.llen 'list' #=> 3
Array.new(3) { redis.lpop 'list' } #=> ["b", "a", "c"]
10.times { |i| redis.lpush 'list', i }
redis.lrange 'list', 3, 5 #=> ["6", "5", "4"]
redis.ltrim 'list', 7, -1
redis.brpop 'list', 1 # blocking rpop with integer timeout

redis.sadd 'set', 'aaa' #=> true
redis.sismember 'set', 'aaa' #=> true
redis.scard 'set' #=> 1
redis.smembers 'set' #=> ['aaa']
redis.srem 'set', 'aaa' #=> true
redis.spop 'set' #=> 'aaa'
redis.sadd 'set', 'aaa' #=> true
redis.smove 'set', 'set2', 'aaa' #=> true

redis.hset 'hash', 'key1', 'value'
redis.hmset 'hash', 'key2', 2, 'key3', 0.3
redis.hlen 'hash' #=> 3
redis.hexists 'hash', 'key1' #=> true
redis.hget 'hash', 'key3' #=> 0.3
redis.hmget 'hash', 'key1', 'key2' #=> ["value", "2"]
redis.hincrby 'hash', 'key2', 10 #=> 12 (integer only)
redis.hdel 'hash', 'key3' #=> 1
redis.hkeys 'hash' # hvals, hgetall

# O(log(N)) + O(response_size)
100.times do |i|
  redis.zadd 'sortedset', 1.0.fdiv(i), "1/#{i}"
end

redis.zincrby 'sortedset', 1, 'aaa'
# => 1.0
redis.zincrby 'sortedset', 0.1, 'aaa'
# => 1.1
redis.zrem 'sortedset', 'aaa'
# => true

redis.zcard 'sortedset'
#=> 100

redis.zscore 'sortedset', '1/3'
#=> 0.3333333333333333
redis.zrank 'sortedset', '1/3'
# => 96
redis.zrevrank 'sortedset', '1/3'
# => 3

redis.zrange 'sortedset', 0, 2, withscores: true
# => [["1/99", 0.010101010101010102], ["1/98", 0.01020408163265306], ["1/97", 0.010309278350515464]]
redis.zrevrange 'sortedset', 0, 2, withscores: true
# => [["1/0", Infinity], ["1/1", 1.0], ["1/2", 0.5]]

redis.zrangebyscore 'sortedset', 0.1, 0.5, withscores: true, limit: [0, 3]
# => [["1/10", 0.1], ["1/9", 0.1111111111111111], ["1/8", 0.125]]
redis.zrevrangebyscore 'sortedset', 0.5, 0.1, withscores: true, limit: [0, 3]
# => [["1/2", 0.5], ["1/3", 0.33333333333333326], ["1/4", 0.25]]
redis.zcount 'sortedset', 0.1, 0.5
# => 9

redis.zremrangebyrank 'sortedset', 80, 100
# => 20
redis.zremrangebyscore 'sortedset', 0, 0.04
# => 75
redis.zcard 'sortedset'
# => 5

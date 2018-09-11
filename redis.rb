require 'redis'
redis = Redis.new
redis.flushall

100.times do |i|
  redis.zadd 'list', 1.0.fdiv(i), "1/#{i}"
end

redis.zincrby 'list', 1, 'aaa'
# => 1.0
redis.zincrby 'list', 0.1, 'aaa'
# => 1.1
redis.zrem 'list', 'aaa'
# => true

redis.zcard 'list'
#=> 100

redis.zscore 'list', '1/3'
#=> 0.3333333333333333
redis.zrank 'list', '1/3'
# => 96
redis.zrevrank 'list', '1/3'
# => 3

redis.zrange 'list', 0, 2, withscores: true
# => [["1/99", 0.010101010101010102], ["1/98", 0.01020408163265306], ["1/97", 0.010309278350515464]]
redis.zrevrange 'list', 0, 2, withscores: true
# => [["1/0", Infinity], ["1/1", 1.0], ["1/2", 0.5]]

redis.zrangebyscore 'list', 0.1, 0.5, withscores: true, limit: [0, 3]
# => [["1/10", 0.1], ["1/9", 0.1111111111111111], ["1/8", 0.125]]
redis.zrevrangebyscore 'list', 0.5, 0.1, withscores: true, limit: [0, 3]
# => [["1/2", 0.5], ["1/3", 0.33333333333333326], ["1/4", 0.25]]
redis.zcount 'list', 0.1, 0.5
# => 9

redis.zremrangebyrank 'list', 80, 100
# => 20
redis.zremrangebyscore 'list', 0, 0.04
# => 75
redis.zcard 'list'
# => 5

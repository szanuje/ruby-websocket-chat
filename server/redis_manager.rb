REDIS_HOST = ENV["REDIS_HOST"] != nil ? ENV["REDIS_HOST"] : 'localhost'
REDIS_PORT = ENV["REDIS_PORT"] != nil ? ENV["REDIS_PORT"] : 6379
require 'redis'

class RedisManager

  def initialize
    @redis = Redis.new(host: REDIS_HOST, port: REDIS_PORT)
  end

  def store_message(message)
    @redis.rpush('ruby_chat_messages', "#{message}")
  end

  def get_messages
    @redis.lrange('ruby_chat_messages', 0, -1)
  end
end

require 'socket'
require 'digest/sha1'
require_relative 'log/my_logger'
require_relative 'server/web_socket_client'
require_relative 'server/web_socket_server'

class Runner

  include Logging

  def initialize
    @server = WebSocketServer.new
    $sockets = []
  end

  def run
    loop do
      client = WebSocketClient.new(@server, $sockets)
      logger.info('listening...')
      client.listen
    end
  end
end

# Start server
runner = Runner.new
runner.run

# redis = Redis.new(host: 'localhost')
# redis.del('ruby_chat_messages')

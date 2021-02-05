require 'time'
require_relative '../log/my_logger'
require_relative 'redis_manager'

class WebSocketClient

  include Logging

  def initialize(server, list_of_sockets)
    @server = server
    @list_of_sockets = list_of_sockets
    @redis = RedisManager.new
    @first_message = false
  end

  def compose_redis_message(message)
    message[0] = ''
    message[-1] = ''
    "#{Time.now.to_i}:#{message}"
  end

  def listen
    Thread.new(@server.connect) do |socket|

      @list_of_sockets << socket

      loop do

        first_byte = socket.getbyte
        fin = first_byte & 0b10000000
        opcode = first_byte & 0b00001111

        unless fin
          @list_of_sockets.delete(socket)
          raise "We don't support continuations. Disconnecting #{socket.inspect}"
        end
        unless opcode == 1
          @list_of_sockets.delete(socket)
          raise "We only support opcode 1. Disconnecting #{socket.inspect}"
        end

        second_byte = socket.getbyte
        is_masked = second_byte & 0b10000000
        payload_size = second_byte & 0b01111111

        unless is_masked
          @list_of_sockets.delete(socket)
          raise "All incoming frames should be masked according to the websocket spec. Disconnecting #{socket.inspect}"
        end

        unless payload_size < 126
          @list_of_sockets.delete(socket)
          raise "We only support payloads < 126 bytes in length. Disconnecting #{socket.inspect}"
        end

        logger.info("Server got a message. Payload size: #{payload_size} bytes")

        mask = 4.times.map { socket.getbyte }
        # logger.info("Got mask: #{mask.inspect}")

        data = payload_size.times.map { socket.getbyte }
        # logger.info("Got masked data: #{data.inspect}")

        unmasked_data = data.each_with_index.map { |byte, i| byte ^ mask[i % 4] }
        # logger.info("Unmasked the data: #{unmasked_data.inspect}")

        received_message = unmasked_data.pack('C*').force_encoding('utf-8').inspect

        response = compose_redis_message(received_message)

        output = [0b10000001, response.size, response]


        if !@first_message
          messages = @redis.get_messages
          messages.each do |msg|
            socket.write [0b10000001, msg.size, msg].pack("CCA#{msg.size}")
          end
          @first_message = true
        else
          @redis.store_message(response)
          logger.info("Sending response to all clients. response: [#{response}] clients: #{@list_of_sockets.inspect}")
          @list_of_sockets.each do |soc|
            soc.write output.pack("CCA#{response.size}")
          end
        end
      end
      logger.info("Closing socket #{socket.inspect}")
      socket.close
    end
  end
end

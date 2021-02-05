require 'socket' # Provides TCPServer and TCPSocket classes
require 'digest/sha1'
require_relative '../log/my_logger'

class WebSocketServer

  include Logging

  def initialize(options = { path: '/', port: 2345, host: '0.0.0.0' })
    _path = options[:path]
    port = options[:port]
    host = options[:host]
    @tcp_server = TCPServer.new(host, port)
  end

  def connect
    # waits for connection (blocking)
    socket = @tcp_server.accept
    logger.info('Incoming Request.')

    # Read the HTTP request. We know it's finished when we see a line with nothing but \r\n
    http_request = ''
    while (line = socket.gets) && (line != "\r\n")
      http_request += line
    end

    # Grab the security key from the headers. If one isn't present, close the connection.
    if (matches = http_request.match(/^Sec-WebSocket-Key: (\S+)/))
      websocket_key = matches[1]
      logger.info("Websocket handshake detected with key: #{websocket_key}")
    else
      logger.info('Aborting non-websocket connection')
      socket.close
      return
    end

    response_key = Digest::SHA1.base64digest([websocket_key, '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'].join)
    logger.info("Responding to handshake with key: #{response_key}")

    socket.write <<-eos
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: #{response_key}

    eos

    logger.info('Handshake completed. Starting to parse the websocket frame.')
    socket
  end
end

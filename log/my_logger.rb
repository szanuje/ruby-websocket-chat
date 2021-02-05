LOGGING_OUT = ENV["LOGGING_OUT"] != nil ? ENV["LOGGING_OUT"] : STDOUT

require 'logger'

module Logging
  def logger
    Logging.logger
  end

  # Global, memoized, lazy initialized instance of a logger
  def self.logger
    @logger ||= Logger.new(LOGGING_OUT)
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "#{severity} [#{datetime.strftime('%Y-%m-%d %H:%M:%S.%L')}]: #{msg}\n"
    end
    @logger
  end
end

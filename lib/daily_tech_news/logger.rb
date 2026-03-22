# frozen_string_literal: true

require 'logger'

module DailyTechNews
  def self.logger
    @logger ||= Logger.new($stdout).tap do |l|
      l.level = Logger::INFO
      l.formatter = proc do |severity, datetime, _progname, msg|
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
      end
    end
  end
end

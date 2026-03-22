# frozen_string_literal: true

module DailyTechNews
  class ConfigError < StandardError; end

  class Config
    REQUIRED_KEYS = %w[ANTHROPIC_API_KEY LINE_CHANNEL_ACCESS_TOKEN LINE_USER_ID].freeze
    OPTIONAL_KEYS = %w[QIITA_ACCESS_TOKEN].freeze

    def self.validate!
      missing = REQUIRED_KEYS.select { |k| ENV.fetch(k, '').empty? }
      raise ConfigError, "Missing required env vars: #{missing.join(', ')}" unless missing.empty?
    end

    def self.anthropic_api_key = ENV.fetch('ANTHROPIC_API_KEY')
    def self.line_channel_access_token = ENV.fetch('LINE_CHANNEL_ACCESS_TOKEN')
    def self.line_user_id = ENV.fetch('LINE_USER_ID')
    def self.qiita_access_token = ENV.fetch('QIITA_ACCESS_TOKEN', nil)
  end
end

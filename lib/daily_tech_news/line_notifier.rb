# frozen_string_literal: true

require 'httparty'

module DailyTechNews
  class LineNotifier
    API_URL = 'https://api.line.me/v2/bot/message/push'
    MAX_LENGTH = 4990

    def notify(message)
      truncated = message.slice(0, MAX_LENGTH)
      response = HTTParty.post(
        API_URL,
        headers: {
          'Authorization' => "Bearer #{Config.line_channel_access_token}",
          'Content-Type' => 'application/json'
        },
        body: {
          to: Config.line_user_id,
          messages: [{ type: 'text', text: truncated }]
        }.to_json
      )
      DailyTechNews.logger.warn("LINE notify failed: #{response.code}") unless response.success?
    end
  end
end

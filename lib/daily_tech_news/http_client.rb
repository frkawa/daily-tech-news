# frozen_string_literal: true

require 'httparty'

module DailyTechNews
  class HttpClient
    include HTTParty

    MAX_RETRIES = 3
    RETRY_BASE_WAIT = 2

    def get(url, headers: {}, query: {})
      attempt = 0
      begin
        response = self.class.get(url, headers: headers, query: query)
        raise "HTTP #{response.code}" unless response.success?

        response
      rescue StandardError => e
        attempt += 1
        if attempt < MAX_RETRIES
          sleep(RETRY_BASE_WAIT**attempt)
          retry
        end
        raise e
      end
    end
  end
end

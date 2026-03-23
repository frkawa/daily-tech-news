# frozen_string_literal: true

module DailyTechNews
  module Sources
    class Base
      MAX_RETRIES = 3
      RETRY_BASE_WAIT = 2

      def initialize(deduplicator:)
        @deduplicator = deduplicator
        @http = HttpClient.new
      end

      def fetch
        attempt = 0
        begin
          raw = fetch_articles
          raw.select { |a| @deduplicator.new?(a.url) }
        rescue StandardError => e
          attempt += 1
          if attempt < MAX_RETRIES
            sleep(RETRY_BASE_WAIT**attempt)
            retry
          end
          DailyTechNews.logger.warn("#{self.class.name} fetch failed: #{e.message}")
          []
        end
      end

      private

      def fetch_articles
        raise NotImplementedError, "#{self.class}#fetch_articles not implemented"
      end
    end
  end
end

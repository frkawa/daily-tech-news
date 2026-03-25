# frozen_string_literal: true

require 'nokogiri'

module DailyTechNews
  module Sources
    class Zenn < Base
      TOPICS = %w[ruby rails ai claude].freeze
      FEED_URL = 'https://zenn.dev/topics/%<topic>s/feed'
      BODY_LIMIT = 1500

      private

      def fetch_articles
        articles = TOPICS.flat_map { |topic| fetch_topic(topic) }
        articles.uniq(&:url)
      end

      def fetch_topic(topic)
        url = format(FEED_URL, topic: topic)
        response = @http.get(url)
        parse_feed(response.body)
      rescue StandardError => e
        DailyTechNews.logger.warn("Zenn topic #{topic} failed: #{e.message}")
        []
      end

      def parse_feed(xml)
        doc = Nokogiri::XML(xml)
        doc.css('item').map { |item| build_article(item) }
      end

      def build_article(item)
        desc = item.at_css('description')&.text.to_s
        body = Nokogiri::HTML.fragment(desc).text.slice(0, BODY_LIMIT)

        Article.new(
          url: item.at_css('link')&.text.to_s.strip,
          title: item.at_css('title')&.text.to_s.strip,
          body: body,
          published_at: parse_time(item.at_css('pubDate')&.text),
          source: 'zenn',
          tags: []
        )
      end

      def parse_time(text)
        text ? Time.parse(text) : Time.now
      rescue ArgumentError
        Time.now
      end
    end
  end
end

# frozen_string_literal: true

require 'nokogiri'
require 'time'

module DailyTechNews
  module Sources
    class Zenn < Base
      TOPICS = %w[ruby rails ai claude].freeze
      LIST_URL = 'https://zenn.dev/api/articles?topic=%<topic>s&order=liked_count&count=20'
      ARTICLE_URL = 'https://zenn.dev/api/articles/%<slug>s'
      BASE_URL = 'https://zenn.dev'
      BODY_LIMIT = 1500
      MIN_LIKES = 5
      TOP_N = 5

      private

      def fetch_articles
        articles = TOPICS.flat_map { |topic| fetch_topic(topic) }
        articles.uniq(&:url)
      end

      def fetch_topic(topic)
        url = format(LIST_URL, topic: topic)
        response = @http.get(url)
        items = JSON.parse(response.body)['articles'] || []
        items
          .select { |item| item['liked_count'].to_i >= MIN_LIKES }
          .first(TOP_N)
          .filter_map { |item| fetch_article(item) }
      rescue StandardError => e
        DailyTechNews.logger.warn("Zenn topic #{topic} failed: #{e.message}")
        []
      end

      def fetch_article(item)
        url = format(ARTICLE_URL, slug: item['slug'])
        response = @http.get(url)
        data = JSON.parse(response.body)['article']
        build_article(data)
      rescue StandardError => e
        DailyTechNews.logger.warn("Zenn article #{item['slug']} failed: #{e.message}")
        nil
      end

      def build_article(item)
        body = Nokogiri::HTML.fragment(item['body_html'].to_s).text.slice(0, BODY_LIMIT)

        Article.new(
          url: "#{BASE_URL}#{item['path']}",
          title: item['title'].to_s.strip,
          body: body,
          published_at: Time.parse(item['published_at']),
          source: 'zenn',
          tags: item.dig('topics')&.map { |t| t['name'] } || []
        )
      end
    end
  end
end

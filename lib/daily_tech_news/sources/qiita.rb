# frozen_string_literal: true

module DailyTechNews
  module Sources
    class Qiita < Base
      TAGS = %w[Ruby Rails].freeze
      API_URL = 'https://qiita.com/api/v2/items'
      PER_PAGE = 20
      BODY_LIMIT = 1500

      private

      def fetch_articles
        articles = TAGS.flat_map { |tag| fetch_by_tag(tag) }
        articles.uniq(&:url)
      end

      def fetch_by_tag(tag)
        headers = build_headers
        response = @http.get(API_URL, headers: headers, query: { tag: tag, per_page: PER_PAGE })
        JSON.parse(response.body).map { |item| build_article(item) }
      end

      def build_headers
        token = Config.qiita_access_token
        token ? { 'Authorization' => "Bearer #{token}" } : {}
      end

      def build_article(item)
        Article.new(
          url: item['url'],
          title: item['title'],
          body: item['body'].to_s.slice(0, BODY_LIMIT),
          published_at: Time.parse(item['created_at']),
          source: 'qiita',
          tags: item['tags'].map { |t| t['name'] }
        )
      end
    end
  end
end

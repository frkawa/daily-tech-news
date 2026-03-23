# frozen_string_literal: true

module DailyTechNews
  module Sources
    class HackerNews < Base
      TOP_STORIES_URL = 'https://hacker-news.firebaseio.com/v0/topstories.json'
      ITEM_URL = 'https://hacker-news.firebaseio.com/v0/item/%<id>s.json'
      FETCH_COUNT = 10
      BODY_LIMIT = 1500

      private

      def fetch_articles
        response = @http.get(TOP_STORIES_URL)
        ids = JSON.parse(response.body).first(FETCH_COUNT)
        ids.filter_map { |id| fetch_item(id) }
      end

      def fetch_item(id)
        response = @http.get(format(ITEM_URL, id: id))
        item = JSON.parse(response.body)
        return nil unless item['url'] && item['title']

        build_article(item)
      end

      def build_article(item)
        Article.new(
          url: item['url'],
          title: item['title'],
          body: item['text'].to_s.then { |t| Nokogiri::HTML.fragment(t).text }.slice(0, BODY_LIMIT),
          published_at: Time.at(item['time'].to_i),
          source: 'hacker_news',
          tags: []
        )
      end
    end
  end
end

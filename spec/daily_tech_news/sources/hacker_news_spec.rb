# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DailyTechNews::Sources::HackerNews do
  subject(:source) { described_class.new(deduplicator: deduplicator) }

  let(:deduplicator) { instance_double(DailyTechNews::Deduplicator) }
  let(:top_stories_fixture) { File.read('spec/support/fixtures/hacker_news_top_stories.json') }
  let(:item_fixture) { File.read('spec/support/fixtures/hacker_news_item.json') }

  before do
    allow(deduplicator).to receive(:new?).and_return(true)
    stub_request(:get, 'https://hacker-news.firebaseio.com/v0/topstories.json')
      .to_return(status: 200, body: top_stories_fixture, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, %r{https://hacker-news\.firebaseio\.com/v0/item/\d+\.json})
      .to_return(status: 200, body: item_fixture, headers: { 'Content-Type' => 'application/json' })
  end

  it_behaves_like 'a source'

  describe '#fetch' do
    it 'returns articles with correct attributes' do
      articles = source.fetch
      expect(articles.first.url).to eq('https://example.com/ruby-framework')
      expect(articles.first.title).to eq('Show HN: A new Ruby framework')
      expect(articles.first.source).to eq('hacker_news')
    end

    it 'skips items without url' do
      item_without_url = JSON.parse(item_fixture).merge('url' => nil).to_json
      stub_request(:get, %r{https://hacker-news\.firebaseio\.com/v0/item/\d+\.json})
        .to_return(status: 200, body: item_without_url, headers: { 'Content-Type' => 'application/json' })

      articles = source.fetch
      expect(articles).to be_empty
    end
  end
end

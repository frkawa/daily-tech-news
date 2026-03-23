# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DailyTechNews::Sources::Qiita do
  subject(:source) { described_class.new(deduplicator: deduplicator) }

  let(:deduplicator) { instance_double(DailyTechNews::Deduplicator) }
  let(:fixture) { File.read('spec/support/fixtures/qiita_items.json') }

  before do
    allow(deduplicator).to receive(:new?).and_return(true)
    stub_request(:get, 'https://qiita.com/api/v2/items')
      .with(query: hash_including({ 'per_page' => '20' }))
      .to_return(status: 200, body: fixture, headers: { 'Content-Type' => 'application/json' })
  end

  it_behaves_like 'a source'

  describe '#fetch' do
    it 'returns articles with correct attributes' do
      articles = source.fetch
      expect(articles.first.url).to eq('https://qiita.com/example/items/abc123')
      expect(articles.first.title).to eq('Ruby 3.4 の新機能まとめ')
      expect(articles.first.source).to eq('qiita')
      expect(articles.first.tags).to include('Ruby', 'Rails')
    end

    it 'deduplicates articles across tags' do
      allow(deduplicator).to receive(:new?).and_return(true)
      articles = source.fetch
      urls = articles.map(&:url)
      expect(urls).to eq(urls.uniq)
    end

    it 'truncates body to 1500 chars' do
      long_body = 'a' * 2000
      fixture_with_long_body = JSON.parse(fixture).tap { |f| f[0]['body'] = long_body }.to_json
      stub_request(:get, 'https://qiita.com/api/v2/items')
        .with(query: hash_including({ 'per_page' => '20' }))
        .to_return(status: 200, body: fixture_with_long_body, headers: { 'Content-Type' => 'application/json' })

      articles = source.fetch
      expect(articles.first.body.length).to eq(1500)
    end
  end
end

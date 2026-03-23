# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DailyTechNews::Sources::Zenn do
  subject(:source) { described_class.new(deduplicator: deduplicator) }

  let(:deduplicator) { instance_double(DailyTechNews::Deduplicator) }
  let(:fixture) { File.read('spec/support/fixtures/zenn_feed.xml') }

  before do
    allow(deduplicator).to receive(:new?).and_return(true)
    stub_request(:get, 'https://zenn.dev/topics/ruby/feed')
      .to_return(status: 200, body: fixture, headers: { 'Content-Type' => 'application/xml' })
  end

  it_behaves_like 'a source'

  describe '#fetch' do
    it 'returns articles with correct attributes' do
      articles = source.fetch
      expect(articles.first.url).to eq('https://zenn.dev/example/articles/ruby-intro')
      expect(articles.first.title).to eq('Zenn記事: Ruby入門')
      expect(articles.first.source).to eq('zenn')
      expect(articles.first.tags).to eq([])
    end

    it 'strips HTML tags from body' do
      articles = source.fetch
      expect(articles.first.body).not_to include('<p>')
      expect(articles.first.body).to include('Ruby の基礎を学ぶ記事です')
    end
  end
end

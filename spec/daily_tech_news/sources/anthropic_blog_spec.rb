# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DailyTechNews::Sources::AnthropicBlog do
  subject(:source) { described_class.new(deduplicator: deduplicator) }

  let(:deduplicator) { instance_double(DailyTechNews::Deduplicator) }
  let(:fixture) { File.read('spec/support/fixtures/anthropic_blog_feed.xml') }

  before do
    allow(deduplicator).to receive(:new?).and_return(true)
    stub_request(:get, 'https://www.anthropic.com/news.rss')
      .to_return(status: 200, body: fixture, headers: { 'Content-Type' => 'application/xml' })
  end

  it_behaves_like 'a source'

  describe '#fetch' do
    it 'returns articles with correct attributes' do
      articles = source.fetch
      expect(articles.first.url).to eq('https://www.anthropic.com/news/claude-4')
      expect(articles.first.title).to eq('Claude 4 released')
      expect(articles.first.source).to eq('anthropic_blog')
      expect(articles.first.tags).to eq([])
    end

    it 'strips HTML tags from body' do
      articles = source.fetch
      expect(articles.first.body).not_to include('<p>')
      expect(articles.first.body).to include('We are excited to announce Claude 4')
    end
  end
end

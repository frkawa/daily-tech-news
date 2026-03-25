# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DailyTechNews::ClaudeClient do
  subject(:client) { described_class.new }

  let(:api_url) { 'https://api.anthropic.com/v1/messages' }
  let(:select_fixture) { File.read('spec/support/fixtures/claude_select_response.json') }
  let(:select_fenced_fixture) { File.read('spec/support/fixtures/claude_select_response_fenced.json') }
  let(:summarize_fixture) { File.read('spec/support/fixtures/claude_summarize_response.json') }

  let(:articles) do
    [
      DailyTechNews::Article.new(
        url: 'https://example.com/1',
        title: 'Ruby 3.4 の新機能',
        body: 'Ruby 3.4 がリリースされました',
        published_at: Time.now,
        source: 'qiita',
        tags: ['Ruby']
      ),
      DailyTechNews::Article.new(
        url: 'https://example.com/2',
        title: 'Claude 4 released',
        body: 'Anthropic has released Claude 4',
        published_at: Time.now,
        source: 'anthropic_blog',
        tags: []
      )
    ]
  end

  before do
    allow(DailyTechNews::Config).to receive(:anthropic_api_key).and_return('test-api-key')
  end

  describe '#select_top_article' do
    before do
      stub_request(:post, api_url)
        .to_return(status: 200, body: select_fixture, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns the article at selected_index' do
      result = client.select_top_article(articles)
      expect(result).to eq(articles[1])
    end

    it 'sends a POST request to the Claude API' do
      client.select_top_article(articles)
      expect(WebMock).to have_requested(:post, api_url)
        .with(headers: { 'x-api-key' => 'test-api-key' })
    end

    context 'when response contains JSON fences' do
      before do
        stub_request(:post, api_url)
          .to_return(status: 200, body: select_fenced_fixture, headers: { 'Content-Type' => 'application/json' })
      end

      it 'strips fences and parses correctly' do
        result = client.select_top_article(articles)
        expect(result).to eq(articles[0])
      end
    end

    context 'when API returns an error' do
      before do
        stub_request(:post, api_url).to_return(status: 500, body: '{}')
      end

      it 'raises ClaudeApiError' do
        expect { client.select_top_article(articles) }
          .to raise_error(DailyTechNews::ClaudeApiError, /500/)
      end
    end
  end

  describe '#summarize' do
    before do
      stub_request(:post, api_url)
        .to_return(status: 200, body: summarize_fixture, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns a SummarizedArticle' do
      result = client.summarize(articles.first)
      expect(result).to be_a(DailyTechNews::SummarizedArticle)
    end

    it 'maps bullets, importance, and ruby_impact correctly' do
      result = client.summarize(articles.first)
      expect(result.bullets.length).to eq(3)
      expect(result.importance).to eq(4)
      expect(result.ruby_impact).to eq('既存コードへの影響は少なく、新機能を段階的に導入できる')
    end

    it 'sets the original article on the result' do
      result = client.summarize(articles.first)
      expect(result.article).to eq(articles.first)
    end

    context 'when japanese: true' do
      it 'includes Japanese instruction in the prompt body' do
        client.summarize(articles.first, japanese: true)
        expect(WebMock).to(have_requested(:post, api_url).with do |req|
          JSON.parse(req.body)['messages'].first['content'].include?('日本語')
        end)
      end
    end

    context 'when japanese: false (default)' do
      it 'does not include Japanese instruction' do
        client.summarize(articles.first)
        expect(WebMock).to(have_requested(:post, api_url).with do |req|
          !JSON.parse(req.body)['messages'].first['content'].include?('日本語')
        end)
      end
    end
  end
end

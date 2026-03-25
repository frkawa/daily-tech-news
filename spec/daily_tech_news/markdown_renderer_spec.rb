# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DailyTechNews::MarkdownRenderer do
  subject(:renderer) { described_class.new }

  let(:date) { Date.new(2026, 3, 26) }

  let(:article) do
    DailyTechNews::Article.new(
      url: 'https://example.com/ruby34',
      title: 'Ruby 3.4 の新機能まとめ',
      body: 'Ruby 3.4 がリリースされました',
      published_at: Time.now,
      source: 'qiita',
      tags: %w[Ruby Rails]
    )
  end

  let(:summarized) do
    DailyTechNews::SummarizedArticle.new(
      article: article,
      bullets: %w[ポイント1 ポイント2 ポイント3],
      importance: 4,
      ruby_impact: 'Rubyistに大きな影響があります'
    )
  end

  let(:sections) { { 'qiita' => [summarized] } }

  describe '#render' do
    subject(:output) { renderer.render(date: date, highlight: summarized, sections: sections) }

    it 'includes YAML frontmatter with date' do
      expect(output).to include('date: 2026-03-26')
    end

    it 'includes article_count in frontmatter' do
      expect(output).to include('article_count: 1')
    end

    it 'includes today\'s highlight section' do
      expect(output).to include('## 今日のハイライト')
      expect(output).to include('Ruby 3.4 の新機能まとめ')
    end

    it 'includes source section heading' do
      expect(output).to include('## Qiita')
    end

    it 'includes article bullets' do
      expect(output).to include('- ポイント1')
      expect(output).to include('- ポイント2')
      expect(output).to include('- ポイント3')
    end

    it 'includes ruby_impact' do
      expect(output).to include('Rubyistに大きな影響があります')
    end

    it 'includes footer with previous day link' do
      expect(output).to include('2026/03/2026-03-25.md')
    end

    it 'includes archive link' do
      expect(output).to include('archive.md')
    end
  end

  describe 'importance badge' do
    it 'renders ★★★★☆ for importance 4' do
      output = renderer.render(date: date, highlight: summarized, sections: sections)
      expect(output).to include('★★★★☆')
    end

    it 'renders ★★★★★ for importance 5' do
      max_summarized = DailyTechNews::SummarizedArticle.new(
        article: article,
        bullets: %w[a b c],
        importance: 5,
        ruby_impact: 'test'
      )
      output = renderer.render(date: date, highlight: max_summarized, sections: { 'qiita' => [max_summarized] })
      expect(output).to include('★★★★★')
    end

    it 'renders ☆☆☆☆☆ for importance 0' do
      zero_summarized = DailyTechNews::SummarizedArticle.new(
        article: article,
        bullets: %w[a b c],
        importance: 0,
        ruby_impact: 'test'
      )
      output = renderer.render(date: date, highlight: zero_summarized, sections: { 'qiita' => [zero_summarized] })
      expect(output).to include('☆☆☆☆☆')
    end
  end

  describe 'source heading mapping' do
    it 'maps hacker_news to Hacker News' do
      hn_article = DailyTechNews::Article.new(
        url: 'https://hn.example.com',
        title: 'HN Post',
        body: 'body',
        published_at: Time.now,
        source: 'hacker_news',
        tags: []
      )
      hn_summarized = DailyTechNews::SummarizedArticle.new(
        article: hn_article, bullets: %w[a b c], importance: 3, ruby_impact: 'test'
      )
      output = renderer.render(date: date, highlight: hn_summarized, sections: { 'hacker_news' => [hn_summarized] })
      expect(output).to include('## Hacker News')
    end
  end
end

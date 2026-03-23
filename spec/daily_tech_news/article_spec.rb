# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DailyTechNews::Article do
  subject(:article) { described_class.new(**attributes) }

  let(:attributes) do
    {
      url: 'https://example.com/article',
      title: 'Test Article',
      body: 'Article body content',
      published_at: Time.now,
      source: 'qiita',
      tags: %w[Ruby Rails]
    }
  end

  it 'holds all attributes' do
    expect(article.url).to eq('https://example.com/article')
    expect(article.title).to eq('Test Article')
    expect(article.body).to eq('Article body content')
    expect(article.source).to eq('qiita')
    expect(article.tags).to eq(%w[Ruby Rails])
  end

  it 'is immutable' do
    expect { article.instance_variable_set(:@url, 'other') }.to raise_error(FrozenError)
  end

  it 'supports equality by value' do
    other = described_class.new(**attributes)
    expect(article).to eq(other)
  end

  it 'accepts empty tags' do
    article_no_tags = described_class.new(**attributes, tags: [])
    expect(article_no_tags.tags).to eq([])
  end
end

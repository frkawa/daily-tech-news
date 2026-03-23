# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DailyTechNews::SummarizedArticle do
  subject(:summarized) { described_class.new(**attributes) }

  let(:article) do
    DailyTechNews::Article.new(
      url: 'https://example.com/article',
      title: 'Test Article',
      body: 'Article body content',
      published_at: Time.now,
      source: 'qiita',
      tags: ['Ruby']
    )
  end

  let(:attributes) do
    {
      article: article,
      bullets: %w[ポイント1 ポイント2 ポイント3],
      importance: 4,
      ruby_impact: 'Rails 8 に直接影響する'
    }
  end

  it 'holds all attributes' do
    expect(summarized.article).to eq(article)
    expect(summarized.bullets).to eq(%w[ポイント1 ポイント2 ポイント3])
    expect(summarized.importance).to eq(4)
    expect(summarized.ruby_impact).to eq('Rails 8 に直接影響する')
  end

  it 'is immutable' do
    expect { summarized.instance_variable_set(:@importance, 1) }.to raise_error(FrozenError)
  end

  it 'supports equality by value' do
    other = described_class.new(**attributes)
    expect(summarized).to eq(other)
  end
end

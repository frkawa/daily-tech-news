# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DailyTechNews::Sources::Base do
  subject(:source) { concrete_class.new(deduplicator: deduplicator) }

  let(:deduplicator) { instance_double(DailyTechNews::Deduplicator) }

  let(:concrete_class) do
    Class.new(described_class) do
      def fetch_articles
        [
          DailyTechNews::Article.new(
            url: 'https://example.com/1',
            title: 'Test',
            body: 'body',
            published_at: Time.now,
            source: 'test',
            tags: []
          )
        ]
      end
    end
  end

  let(:failing_class) do
    Class.new(described_class) do
      def fetch_articles
        raise StandardError, 'error'
      end
    end
  end

  before { allow(deduplicator).to receive(:new?).and_return(true) }

  describe '#fetch' do
    it 'returns articles from fetch_articles' do
      expect(source.fetch.length).to eq(1)
    end

    it 'filters out already-seen articles' do
      allow(deduplicator).to receive(:new?).and_return(false)
      expect(source.fetch).to be_empty
    end

    context 'when fetch_articles raises' do
      subject(:failing_source) { failing_class.new(deduplicator: deduplicator) }

      before { stub_const('DailyTechNews::Sources::Base::RETRY_BASE_WAIT', 0) }

      it 'returns empty array after exhausting retries' do
        expect(failing_source.fetch).to eq([])
      end
    end
  end

  describe '#fetch_articles' do
    it 'raises NotImplementedError on the base class directly' do
      base = described_class.new(deduplicator: deduplicator)
      expect { base.send(:fetch_articles) }.to raise_error(NotImplementedError)
    end
  end
end

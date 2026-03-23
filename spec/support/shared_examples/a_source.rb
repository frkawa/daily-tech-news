# frozen_string_literal: true

RSpec.shared_examples 'a source' do
  let(:deduplicator) { instance_double(DailyTechNews::Deduplicator) }

  before do
    allow(deduplicator).to receive(:new?).and_return(true)
  end

  describe '#fetch' do
    context 'when the request succeeds' do
      it 'returns an array of Article objects' do
        articles = subject.fetch
        expect(articles).to all(be_a(DailyTechNews::Article))
      end

      it 'returns only new articles (dedup filtered)' do
        allow(deduplicator).to receive(:new?).and_return(false)
        expect(subject.fetch).to be_empty
      end
    end

    context 'when the request fails every time' do
      before do
        stub_request(:any, /.*/).to_raise(StandardError.new('connection refused'))
        stub_const('DailyTechNews::Sources::Base::RETRY_BASE_WAIT', 0)
        stub_const('DailyTechNews::HttpClient::RETRY_BASE_WAIT', 0)
      end

      it 'returns an empty array without raising' do
        expect(subject.fetch).to eq([])
      end
    end
  end
end

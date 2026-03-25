# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DailyTechNews::LineNotifier do
  subject(:notifier) { described_class.new }

  let(:api_url) { 'https://api.line.me/v2/bot/message/push' }

  before do
    allow(DailyTechNews::Config).to receive_messages(line_channel_access_token: 'test-token',
                                                     line_user_id: 'U1234567890')
    stub_request(:post, api_url).to_return(status: 200, body: '{}')
  end

  describe '#notify' do
    it 'sends a POST to the LINE API' do
      notifier.notify('https://github.com/example/daily-tech-news/blob/main/news/2026/03/2026-03-26.md')
      expect(WebMock).to have_requested(:post, api_url)
    end

    it 'includes the correct Authorization header' do
      notifier.notify('test message')
      expect(WebMock).to have_requested(:post, api_url).with(
        headers: { 'Authorization' => 'Bearer test-token' }
      )
    end

    it 'sends the message to the configured user' do
      notifier.notify('test message')
      expect(WebMock).to(have_requested(:post, api_url).with do |req|
        JSON.parse(req.body)['to'] == 'U1234567890'
      end)
    end

    it 'truncates messages longer than 4990 characters' do
      long_message = 'a' * 5000
      notifier.notify(long_message)
      expect(WebMock).to(have_requested(:post, api_url).with do |req|
        body = JSON.parse(req.body)
        body['messages'].first['text'].length == 4990
      end)
    end

    it 'does not truncate messages within the limit' do
      message = 'a' * 100
      notifier.notify(message)
      expect(WebMock).to(have_requested(:post, api_url).with do |req|
        body = JSON.parse(req.body)
        body['messages'].first['text'].length == 100
      end)
    end

    context 'when LINE API returns an error' do
      before { stub_request(:post, api_url).to_return(status: 400, body: '{"message":"Invalid token"}') }

      it 'logs a warning and does not raise' do
        expect { notifier.notify('test') }.not_to raise_error
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DailyTechNews::GitPublisher do
  subject(:publisher) { described_class.new }

  let(:success_status) { instance_double(Process::Status, success?: true) }
  let(:failure_status) { instance_double(Process::Status, success?: false) }
  let(:file_path) { 'news/2026/03/2026-03-26.md' }

  before do
    # All git commands succeed by default
    allow(Open3).to receive(:capture3).and_return(['', '', success_status])
    # Simulate staged changes (exit 1 = changes exist)
    allow(Open3).to receive(:capture3).with('git', 'diff', '--cached', '--quiet')
                                      .and_return(['', '', failure_status])
  end

  describe '#publish' do
    it 'configures git user name and email' do
      publisher.publish(file_path)
      expect(Open3).to have_received(:capture3).with('git', 'config', 'user.name', 'github-actions[bot]')
      expect(Open3).to have_received(:capture3).with('git', 'config', 'user.email',
                                                     'github-actions[bot]@users.noreply.github.com')
    end

    it 'stages the file and .seen_urls' do
      publisher.publish(file_path)
      expect(Open3).to have_received(:capture3).with('git', 'add', file_path, '.seen_urls')
    end

    it 'commits with the date in the message' do
      publisher.publish(file_path)
      expect(Open3).to have_received(:capture3).with('git', 'commit', '-m', "news: #{Date.today}")
    end

    it 'pushes after commit' do
      publisher.publish(file_path)
      expect(Open3).to have_received(:capture3).with('git', 'push')
    end

    context 'when nothing is staged' do
      before do
        allow(Open3).to receive(:capture3).with('git', 'diff', '--cached', '--quiet')
                                          .and_return(['', '', success_status])
      end

      it 'skips commit and push' do
        publisher.publish(file_path)
        expect(Open3).not_to have_received(:capture3).with('git', 'commit', any_args)
        expect(Open3).not_to have_received(:capture3).with('git', 'push')
      end
    end

    context 'when git push fails' do
      before do
        allow(Open3).to receive(:capture3).with('git', 'push')
                                          .and_return(['', 'remote: error', failure_status])
      end

      it 'raises GitPublishError' do
        expect { publisher.publish(file_path) }.to raise_error(DailyTechNews::GitPublishError, /push failed/)
      end
    end

    context 'when a git command other than push fails' do
      before do
        allow(Open3).to receive(:capture3).with('git', 'config', 'user.name', any_args)
                                          .and_return(['', 'fatal: error', failure_status])
      end

      it 'raises GitPublishError' do
        expect { publisher.publish(file_path) }.to raise_error(DailyTechNews::GitPublishError)
      end
    end
  end
end

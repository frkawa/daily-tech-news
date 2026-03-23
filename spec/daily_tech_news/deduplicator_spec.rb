# frozen_string_literal: true

require 'spec_helper'
require 'digest'

RSpec.describe DailyTechNews::Deduplicator do
  subject(:deduplicator) { described_class.new(path) }

  let(:tmpdir) { Dir.mktmpdir }
  let(:path) { File.join(tmpdir, '.seen_urls') }

  after { FileUtils.remove_entry(tmpdir) }

  describe '#new?' do
    it 'returns true for an unseen url' do
      expect(deduplicator.new?('https://example.com')).to be true
    end

    it 'returns false after mark_seen' do
      deduplicator.mark_seen('https://example.com')
      expect(deduplicator.new?('https://example.com')).to be false
    end

    it 'treats different urls independently' do
      deduplicator.mark_seen('https://example.com/a')
      expect(deduplicator.new?('https://example.com/b')).to be true
    end
  end

  describe '#load' do
    it 'loads previously persisted hashes' do
      url = 'https://example.com/persisted'
      hash = Digest::SHA256.hexdigest(url)
      File.write(path, "#{hash}\n")

      deduplicator.load
      expect(deduplicator.new?(url)).to be false
    end

    it 'does nothing when file does not exist' do
      expect { deduplicator.load }.not_to raise_error
    end

    it 'ignores blank lines' do
      File.write(path, "\n\n")
      expect { deduplicator.load }.not_to raise_error
    end
  end

  describe '#persist!' do
    it 'writes seen hashes to file' do
      deduplicator.mark_seen('https://example.com/a')
      deduplicator.mark_seen('https://example.com/b')
      deduplicator.persist!

      lines = File.readlines(path, chomp: true).reject(&:empty?)
      expect(lines).to contain_exactly(
        Digest::SHA256.hexdigest('https://example.com/a'),
        Digest::SHA256.hexdigest('https://example.com/b')
      )
    end

    it 'persists and reloads correctly' do
      deduplicator.mark_seen('https://example.com/reload')
      deduplicator.persist!

      reloaded = described_class.new(path)
      reloaded.load
      expect(reloaded.new?('https://example.com/reload')).to be false
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DailyTechNews::FileWriter do
  subject(:writer) { described_class.new(base_dir: tmpdir) }

  let(:tmpdir) { Dir.mktmpdir }
  let(:date) { Date.new(2026, 3, 26) }
  let(:content) { "# Test\n\nHello world\n" }

  after { FileUtils.remove_entry(tmpdir) }

  describe '#write' do
    it 'creates the correct directory structure' do
      writer.write(date: date, content: content)
      expect(File.directory?(File.join(tmpdir, '2026/03'))).to be true
    end

    it 'writes the content to the correct file' do
      path = writer.write(date: date, content: content)
      expect(File.read(path)).to eq(content)
    end

    it 'returns the file path' do
      path = writer.write(date: date, content: content)
      expect(path).to eq(File.join(tmpdir, '2026/03/2026-03-26.md'))
    end

    it 'creates intermediate directories' do
      writer.write(date: date, content: content)
      expect(File.exist?(File.join(tmpdir, '2026/03/2026-03-26.md'))).to be true
    end
  end
end

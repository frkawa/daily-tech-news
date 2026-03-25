# frozen_string_literal: true

require 'digest'

module DailyTechNews
  class Deduplicator
    def initialize(path = '.seen_urls')
      @path = path
      @seen = Set.new
    end

    def load
      return unless File.exist?(@path)

      File.foreach(@path) do |line|
        hash = line.strip
        @seen.add(hash) unless hash.empty?
      end
    end

    def new?(url)
      !@seen.include?(digest(url))
    end

    def mark_seen(url)
      @seen.add(digest(url))
    end

    def persist!
      File.write(@path, "#{@seen.to_a.join("\n")}\n")
    end

    private

    def digest(url)
      Digest::SHA256.hexdigest(url)
    end
  end
end

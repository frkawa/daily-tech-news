# frozen_string_literal: true

require 'fileutils'

module DailyTechNews
  class FileWriter
    def initialize(base_dir: 'news')
      @base_dir = base_dir
    end

    def write(date:, content:)
      dir = File.join(@base_dir, date.strftime('%Y/%m'))
      FileUtils.mkdir_p(dir)

      path = File.join(dir, "#{date}.md")
      File.write(path, content)
      path
    end
  end
end

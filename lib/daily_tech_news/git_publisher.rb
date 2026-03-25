# frozen_string_literal: true

require 'open3'

module DailyTechNews
  class GitPublishError < StandardError; end

  class GitPublisher
    GIT_AUTHOR_NAME = 'github-actions[bot]'
    GIT_AUTHOR_EMAIL = 'github-actions[bot]@users.noreply.github.com'

    def publish(file_path)
      run!('git', 'config', 'user.name', GIT_AUTHOR_NAME)
      run!('git', 'config', 'user.email', GIT_AUTHOR_EMAIL)
      run!('git', 'add', file_path, '.seen_urls')

      return DailyTechNews.logger.info('No changes to commit, skipping.') if nothing_staged?

      date = Date.today.to_s
      run!('git', 'commit', '-m', "news: #{date}")
      push!
    end

    private

    def nothing_staged?
      _, _, status = Open3.capture3('git', 'diff', '--cached', '--quiet')
      status.success?
    end

    def push!
      out, err, status = Open3.capture3('git', 'push')
      return if status.success?

      raise GitPublishError, "git push failed: #{err.strip.empty? ? out.strip : err.strip}"
    end

    def run!(*cmd)
      out, err, status = Open3.capture3(*cmd)
      return if status.success?

      raise GitPublishError, "Command failed: #{cmd.join(' ')}\n#{err.strip.empty? ? out.strip : err.strip}"
    end
  end
end

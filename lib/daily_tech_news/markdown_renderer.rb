# frozen_string_literal: true

module DailyTechNews
  class MarkdownRenderer
    SOURCE_HEADINGS = {
      'qiita' => 'Qiita',
      'zenn' => 'Zenn',
      'hacker_news' => 'Hacker News',
      'anthropic_blog' => 'Anthropic Blog'
    }.freeze

    def render(date:, highlight:, sections:)
      article_count = sections.values.sum(&:length)
      source_names = sections.keys

      parts = []
      parts << frontmatter(date, source_names, article_count)
      parts << header(date)
      parts << highlight_section(highlight)
      sections.each { |source, items| parts << source_section(source, items) }
      parts << footer(date)

      parts.join("\n")
    end

    private

    def frontmatter(date, sources, article_count)
      <<~YAML
        ---
        date: #{date}
        sources: [#{sources.join(', ')}]
        article_count: #{article_count}
        ---
      YAML
    end

    def header(date)
      "# 技術ニュース日報 #{date}\n\n生成日時: #{Time.now.strftime('%Y-%m-%d %H:%M:%S JST')}\n"
    end

    def highlight_section(summarized)
      article = summarized.article
      badge = importance_badge(summarized.importance)
      bullets = summarized.bullets.map { |b| "- #{b}" }.join("\n")

      <<~MD
        ## 今日のハイライト

        ### #{badge} [#{article.title}](#{article.url})

        **ソース:** #{article.source}
        **Rubyistへの影響:** #{summarized.ruby_impact}

        #{bullets}
      MD
    end

    def source_section(source, items)
      return '' if items.empty?

      heading = SOURCE_HEADINGS.fetch(source, source)
      lines = ["## #{heading}\n"]

      items.each { |s| lines << article_entry(s) }
      lines.join("\n")
    end

    def article_entry(summarized)
      article = summarized.article
      badge = importance_badge(summarized.importance)
      tags = article.tags.empty? ? '' : " `#{article.tags.join('` `')}`"
      bullets = summarized.bullets.map { |b| "- #{b}" }.join("\n")

      <<~MD
        ### #{badge} [#{article.title}](#{article.url})#{tags}

        #{bullets}

        **Rubyistへの影響:** #{summarized.ruby_impact}
      MD
    end

    def importance_badge(importance)
      filled = '★' * importance
      empty = '☆' * (5 - importance)
      "#{filled}#{empty}"
    end

    def footer(date)
      prev_date = Date.parse(date.to_s) - 1
      prev_path = "../../#{prev_date.strftime('%Y/%m/%Y-%m-%d')}.md"

      <<~MD
        ---

        [前日のニュース](#{prev_path}) | [アーカイブ](../../archive.md)
      MD
    end
  end
end

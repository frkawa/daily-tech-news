# frozen_string_literal: true

require 'httparty'
require 'json'

module DailyTechNews
  class ClaudeApiError < StandardError; end

  class ClaudeClient
    API_URL = 'https://api.anthropic.com/v1/messages'
    MODEL = 'claude-haiku-4-5-20251001'
    MAX_TOKENS = 1024
    ANTHROPIC_VERSION = '2023-06-01'
    HIGHLIGHT_BODY_LIMIT = 200

    def select_top_article(articles)
      list = articles.each_with_index.map do |a, i|
        "#{i}. [#{a.source}] #{a.title}\n#{a.body.slice(0, HIGHLIGHT_BODY_LIMIT)}"
      end.join("\n\n")

      prompt = <<~PROMPT
        あなたは技術ニュースキュレーターです。
        以下の記事リストから、Rubyistにとって最も重要・インパクトのある1本を選んでください。

        #{list}

        以下のJSON形式のみで返答してください（他のテキスト不要）:
        {"selected_index": 0, "reason": "選んだ理由を1文で"}
      PROMPT

      data = parse_json_response(call_api(prompt))
      articles[data['selected_index']]
    end

    def summarize(article, japanese: false)
      lang = japanese ? "要約は必ず日本語で出力してください。\n" : ''

      prompt = <<~PROMPT
        #{lang}以下の技術記事を要約してください。
        必ずJSON形式のみで出力し、説明文・マークダウン・前置きは一切含めないでください。

        タイトル: #{article.title}
        本文（先頭1500字）:
        #{article.body}

        出力形式（このJSONのみ返答すること）:
        {"bullets":["要点1","要点2","要点3"],"importance":3,"ruby_impact":"Rubyistへの影響を1文で"}

        ルール:
        - importance は 1〜5 の整数（5が最重要）
        - bullets は各30〜60字程度の箇条書き3行
        - JSON以外の文字を出力してはいけない
      PROMPT

      data = parse_json_response(call_api(prompt))
      SummarizedArticle.new(
        article: article,
        bullets: Array(data['bullets']),
        importance: data['importance'].to_i.clamp(1, 5),
        ruby_impact: data['ruby_impact'].to_s
      )
    end

    private

    def call_api(prompt)
      response = HTTParty.post(
        API_URL,
        headers: {
          'x-api-key' => Config.anthropic_api_key,
          'anthropic-version' => ANTHROPIC_VERSION,
          'content-type' => 'application/json'
        },
        body: {
          model: MODEL,
          max_tokens: MAX_TOKENS,
          messages: [{ role: 'user', content: prompt }]
        }.to_json
      )
      raise ClaudeApiError, "API error: #{response.code} - #{response.body}" unless response.success?

      response.dig('content', 0, 'text')
    end

    def parse_json_response(text)
      stripped = text
                 .gsub(/\A\s*```(?:json)?\s*\n?/, '')
                 .gsub(/\n?```\s*\z/, '')
                 .strip
      JSON.parse(stripped)
    rescue JSON::ParserError => e
      raise ClaudeApiError, "JSON parse error: #{e.message} (response: #{text.slice(0, 200)})"
    end
  end
end

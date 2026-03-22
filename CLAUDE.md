# CLAUDE.md — daily-tech-news 作業ガイド

## プロジェクト概要

毎日 AM 9:00 JST に技術記事を自動収集・要約・配信する Ruby スクリプト群。
GitHub Actions cron で `bin/run` を実行し、Markdown を生成して git push、LINE 通知を送る。

---

## ディレクトリ構成

```
lib/daily_tech_news/
  config.rb           # 環境変数バリデーション（起動時に必ず validate! を呼ぶ）
  logger.rb           # DailyTechNews.logger で共有ロガー取得
  article.rb          # Data.define 値オブジェクト（イミュータブル）
  summarized_article.rb
  deduplicator.rb     # .seen_urls 管理（SHA256）
  http_client.rb      # HTTParty ラッパー（リトライ付き）
  claude_client.rb    # Phase1 選出 + Phase2 要約
  markdown_renderer.rb
  file_writer.rb
  git_publisher.rb
  line_notifier.rb
  sources/
    base.rb           # 抽象基底：リトライ・デデュップ・テンプレートメソッド
    qiita.rb
    zenn.rb
    hacker_news.rb
    anthropic_blog.rb
bin/run               # オーケストレータ（ロジックを持たない）
spec/                 # lib/ と同じ構成でミラーリング
```

---

## bin/run の実行順序（変更禁止）

```
1. Config.validate!
2. deduplicator.load
3. 各ソース fetch（deduplicator.new? でフィルタ）
4. articles.empty? → warn して exit 0
5. deduplicator.mark_seen（使用記事のみ）
6. Claude Phase1: select_top_article
7. Claude Phase2: 各記事 summarize
8. markdown_renderer.render
9. file_writer.write
10. git_publisher.publish   ← GitPublishError を raise しうる
11. deduplicator.persist!  ← ★ 必ず git push 成功後
12. line_notifier.notify
```

**重要:** `deduplicator.persist!` は `git_publisher.publish` の後でなければならない。
push 失敗後に persist! すると、次回実行で未配信記事がスキップされる致命的バグになる。

---

## よく使うコマンド

```bash
# テスト実行
bundle exec rspec

# 特定ファイルのみ
bundle exec rspec spec/daily_tech_news/deduplicator_spec.rb

# Lint
bundle exec rubocop

# 自動修正
bundle exec rubocop -a

# スクリプト実行（環境変数が必要）
bundle exec ruby bin/run
```

---

## テスト方針

- 全テストで `WebMock.disable_net_connect!`（実ネットワーク禁止）
- HTTP スタブ: WebMock
- ファイル I/O: `Dir.mktmpdir` を `after` で削除
- `Open3.capture3`: RSpec の allow/stub
- フィクスチャ: `spec/support/fixtures/` に JSON / XML を配置

---

## 実装上の注意点

- `body` の 1500 字切り詰めは各 Source クラスで行う（ClaudeClient 側ではない）
- Qiita はタグ別に取得するため、ソース内で `uniq_by(&:url)` してから Deduplicator に渡す
- RSS 解析は `Nokogiri::HTML.fragment(desc).text` を使う（`.parse` は `<html>` ラッパーが入る）
- Claude API レスポンスは必ず JSON フェンス除去してからパース
- LINE は push エンドポイント `/v2/bot/message/push`（reply は cron では使えない）
- `bin/run` は `rescue` で最外周をラップして `exit 1` を明示

---

## 環境変数

| 変数名 | 必須 | 用途 |
|--------|------|------|
| `ANTHROPIC_API_KEY` | ✅ | Claude API |
| `LINE_CHANNEL_ACCESS_TOKEN` | ✅ | LINE 送信 |
| `LINE_USER_ID` | ✅ | LINE 送信先 |
| `QIITA_ACCESS_TOKEN` | 任意 | レート制限緩和（なくても動く） |
| `GITHUB_TOKEN` | Actions 自動提供 | git push |

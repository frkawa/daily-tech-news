# daily-tech-news 実装計画

## システム概要

毎日 AM 9:00 JST に技術記事を自動収集・要約・配信する Ruby スクリプト群。
GitHub Actions cron で `bin/run` を実行し、Markdown を生成して git push、LINE 通知を送る。

---

## ディレクトリ構成

```
daily-tech-news/
├── .github/
│   └── workflows/
│       ├── daily_news.yml          # cron 配信 + workflow_dispatch
│       └── ci.yml                  # PR/push 時の lint + test
├── bin/
│   └── run                         # 実行エントリポイント（薄いオーケストレータ）
├── lib/
│   └── daily_tech_news/
│       ├── version.rb
│       ├── config.rb               # 環境変数バリデーション・定数
│       ├── logger.rb               # 共有ロガー
│       ├── http_client.rb          # HTTParty ラッパー
│       ├── article.rb              # Data.define 値オブジェクト
│       ├── summarized_article.rb   # Claude 出力の値オブジェクト
│       ├── deduplicator.rb         # .seen_urls 管理 (SHA256)
│       ├── claude_client.rb        # Phase1 選出 + Phase2 要約
│       ├── markdown_renderer.rb    # Markdown 文字列生成
│       ├── file_writer.rb          # news/YYYY/MM/ 書き出し
│       ├── git_publisher.rb        # git add/commit/push (Open3)
│       ├── line_notifier.rb        # LINE push メッセージ
│       └── sources/
│           ├── base.rb             # 抽象基底クラス（リトライ・デデュップ）
│           ├── qiita.rb
│           ├── zenn.rb
│           ├── hacker_news.rb
│           └── anthropic_blog.rb
├── spec/
│   ├── spec_helper.rb
│   ├── support/
│   │   ├── fixtures/               # HTTP レスポンス等のフィクスチャ
│   │   └── shared_examples/
│   │       └── a_source.rb
│   └── daily_tech_news/
│       ├── sources/
│       │   ├── base_spec.rb
│       │   ├── qiita_spec.rb
│       │   ├── zenn_spec.rb
│       │   ├── hacker_news_spec.rb
│       │   └── anthropic_blog_spec.rb
│       ├── article_spec.rb
│       ├── deduplicator_spec.rb
│       ├── claude_client_spec.rb
│       ├── markdown_renderer_spec.rb
│       ├── file_writer_spec.rb
│       ├── git_publisher_spec.rb
│       └── line_notifier_spec.rb
├── news/
│   └── .gitkeep
├── .claude/
│   └── settings.json               # PostToolUse フック（RuboCop 自動実行）
├── CLAUDE.md                        # Claude Code 向け作業ガイド
├── .seen_urls                       # 空ファイル、git 管理
├── .rubocop.yml
├── .ruby-version                    # 3.4（最新安定版）
├── .gitignore
├── Gemfile
├── Gemfile.lock                     # コミット対象（Actions との一致のため）
└── README.md
```

### scripts/ でなく lib/ を採用した理由

- `lib/daily_tech_news/` で各クラスを独立 require・テスト可能にする
- `bin/run` はオーケストレーションのみ（ロジックを持たない）
- sources / 値オブジェクト / I/O を分離することで WebMock でのモックが容易

---

## Ruby バージョン

**3.4**（2024年12月リリース、最新安定版）を使用。

- `Data.define` の安定化（値オブジェクトで多用）
- エラーメッセージ大幅改善（デバッグしやすい）
- `it` ブロックパラメータ（RSpec で簡潔に書ける）

---

## 必要な環境変数と権限

### Anthropic API

| 項目 | 内容 |
|------|------|
| 変数名 | `ANTHROPIC_API_KEY` |
| 取得元 | https://console.anthropic.com → API Keys |
| 権限 | 課金設定のみ（特別スコープなし） |

### Qiita API

| 項目 | 内容 |
|------|------|
| 変数名 | `QIITA_ACCESS_TOKEN` |
| 取得元 | https://qiita.com/settings/tokens/new |
| 必要スコープ | `read_qiita`（読み取りのみ） |
| 備考 | なし → 60req/時、あり → 1000req/時 |

### LINE Messaging API

| 項目 | 内容 |
|------|------|
| 変数名1 | `LINE_CHANNEL_ACCESS_TOKEN`（長期チャネルアクセストークン） |
| 変数名2 | `LINE_USER_ID`（送信先のユーザーID） |
| 取得手順 | ① https://developers.line.biz でチャネル作成 → ② 長期トークン発行 → ③ ボットを友だち追加 → ④ ユーザーIDはコンソールで確認 |
| エンドポイント | `/v2/bot/message/push`（push 型、cron での使用に必須） |

### GitHub Actions（git push）

| 項目 | 内容 |
|------|------|
| 変数名 | `GITHUB_TOKEN`（Actions が自動注入、Secrets 登録不要） |
| 必要な設定 | ワークフローに `permissions: contents: write` を明示 |
| リポジトリ設定 | Settings → Actions → General → **"Read and write permissions"** を選択 |

---

## 段階的実装フェーズ

| Phase | 内容 | コミットメッセージ例 | 状態 |
|-------|------|---------------------|------|
| 1 | Gemfile / .ruby-version / RuboCop / spec_helper / CLAUDE.md / bin/run スタブ | `chore: initial project structure` | ✅ 完了 |
| 2 | Article / SummarizedArticle / Deduplicator + spec | `feat: article model and deduplication` | |
| 3 | HttpClient / Sources::Base / 4 ソース + spec | `feat: data sources with retry and dedup` | |
| 4 | ClaudeClient + spec（フィクスチャあり） | `feat: claude api client with json parsing` | |
| 5 | MarkdownRenderer / FileWriter / GitPublisher / LineNotifier + spec | `feat: output pipeline` | |
| 6 | bin/run 完成 / GitHub Actions 2 ワークフロー | `feat: orchestrator and github actions` | |
| 7 | RuboCop 全 0 / CI グリーン / README 完成 | `chore: rubocop fixes and ci hardening` | |

---

## bin/run 実行順序（最重要・変更禁止）

```
1.  Config.validate!
2.  deduplicator.load
3.  各ソース fetch（deduplicator.new? でフィルタ）
4.  articles.empty? → warn して exit 0
5.  deduplicator.mark_seen（使用記事のみ）
6.  Claude Phase1: select_top_article
7.  Claude Phase2: 各記事 summarize
8.  markdown_renderer.render
9.  file_writer.write
10. git_publisher.publish   ← GitPublishError を raise しうる
11. deduplicator.persist!  ← ★ 必ず git push 成功後
12. line_notifier.notify
```

> **重要:** `deduplicator.persist!` は `git_publisher.publish` の後でなければならない。
> push 失敗後に persist! すると、次回実行で未配信記事がスキップされる致命的バグになる。

---

## 主要クラス設計

### `Article` / `SummarizedArticle`（値オブジェクト）

```ruby
Article = Data.define(:url, :title, :body, :published_at, :source, :tags)
SummarizedArticle = Data.define(:article, :bullets, :importance, :ruby_impact)
```

- `body` は各ソースで 1500 字に切り詰め済み（ClaudeClient 側ではなく Source 側で）
- `tags` は空配列でよいソースもあり

### `Sources::Base`（テンプレートメソッドパターン）

```ruby
def fetch
  attempt = 0
  begin
    raw = fetch_articles          # サブクラスが実装
    raw.select { |a| @deduplicator.new?(a.url) }
  rescue StandardError => e
    attempt += 1
    attempt < MAX_RETRIES ? (sleep(2 ** attempt); retry) : (warn ...; [])
  end
end
```

- 指数バックオフ（2^n 秒）、最大 3 回
- 失敗時は `[]` を返し例外を外に出さない
- Qiita は同タグ間でも `uniq_by(&:url)` が必要（タグ重複記事対策）

### `Deduplicator`

```ruby
def new?(url)      = !@seen.include?(Digest::SHA256.hexdigest(url))
def mark_seen(url) = @seen.add(Digest::SHA256.hexdigest(url))
def persist!       # ← git push 成功後にのみ呼ぶ
```

### `ClaudeClient`

**Phase 1：最重要記事の選出**

プロンプト構造：全記事のタイトル＋本文先頭200字を番号付きで渡し、
`{"selected_index": 0, "reason": "..."}` の JSON を返させる。

**Phase 2：各記事の個別要約**

プロンプト構造：タイトル＋本文先頭1500字を渡し、
`{"bullets": [...3行...], "importance": 1-5, "ruby_impact": "..."}` の JSON を返させる。
HN / Anthropic Blog は `japanese: true` で日本語出力を明示。

**JSON フェンス除去（必須）**

```ruby
def parse_json_response(text)
  text.gsub(/\A\s*```(?:json)?\s*\n?/, '').gsub(/\n?```\s*\z/, '').strip
  JSON.parse(stripped)
end
```

Claude Haiku は ` ```json ` フェンス付きで返すことがある。

### `GitPublisher`

- `Open3.capture3` でコマンド実行（backtick は使わない）
- `git diff --cached --quiet` → exit 0 なら commit/push をスキップ
- push 失敗は `GitPublishError` を raise

---

## テスト戦略

- `spec_helper.rb` で `WebMock.disable_net_connect!` → 全テストで実ネットワーク禁止
- HTTP スタブ: WebMock
- ファイル I/O: `Dir.mktmpdir` を `after` で削除
- `Open3.capture3`: RSpec の allow/stub
- フィクスチャ: `spec/support/fixtures/` に JSON / XML を配置
- 共有 example `a_source.rb`: 正常系・リトライ・全失敗・dedup フィルタを全ソースに適用
- ClaudeClient: JSON フェンスあり・なし両パターンでテスト

---

## GitHub Actions

### ci.yml（PR + main push）

```yaml
on:
  pull_request:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.4"
          bundler-cache: true
      - run: bundle exec rspec --format progress
      - run: bundle exec rubocop --parallel --format github
```

### daily_news.yml（cron 配信）

```yaml
on:
  schedule:
    - cron: "0 0 * * *"   # JST 09:00
  workflow_dispatch:

permissions:
  contents: write

jobs:
  deliver:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0    # .seen_urls の git 管理に必要
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.4"
          bundler-cache: true
      - run: bundle exec ruby bin/run
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          LINE_CHANNEL_ACCESS_TOKEN: ${{ secrets.LINE_CHANNEL_ACCESS_TOKEN }}
          LINE_USER_ID: ${{ secrets.LINE_USER_ID }}
          QIITA_ACCESS_TOKEN: ${{ secrets.QIITA_ACCESS_TOKEN }}
```

---

## 実装上の注意事項

| 項目 | 内容 |
|------|------|
| `Gemfile.lock` | 必ずコミット（Actions との gem バージョン一致） |
| `bin/run` | `rescue` で最外周をラップして `exit 1` を明示 |
| RSS 解析 | `Nokogiri::HTML.fragment(desc).text` を使う（`.parse` は `<html>` ラッパーが入る） |
| Qiita 重複 | Source 内で `uniq_by(&:url)` してから Deduplicator に渡す |
| LINE | push エンドポイント `/v2/bot/message/push`（reply トークンは cron では使えない） |
| Config | 起動時に必須変数をチェック、不足時は即 raise（`QIITA_ACCESS_TOKEN` は任意） |

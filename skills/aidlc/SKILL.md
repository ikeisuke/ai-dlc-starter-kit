---
name: aidlc
description: >
  AI-DLC（AI-Driven Development Lifecycle）の統合オーケストレーター。
  フェーズ（inception/construction/operations）の開始・継続、セットアップ、エクスプレスモード、フィードバック送信を統一的に実行する。
  Use when the user says "インセプション進めて", "start inception",
  "コンストラクション進めて", "start construction",
  "オペレーション進めて", "start operations",
  "start express", "start setup", "AIDLCフィードバック", "aidlc feedback",
  "start migrate", "aidlc migrate".
argument-hint: "<action> [追加コンテキスト]"
---

# AI-DLC オーケストレーター

AI-DLCは、AIを開発の中心に据えた開発手法。Inception（要件定義）→ Construction（実装）→ Operations（運用）の3フェーズで開発を推進する。

## 不変ルール【絶対遵守】

以下はautomation_modeや過去の経験に関わらず、常に遵守する:

1. **ステップファイルの読み込みは省略不可**: 「ステップ4: フェーズステップ読み込み」に列挙された全ファイルを必ずReadツールで読み込む。「内容を覚えている」「前回と同じ」は省略理由にならない
2. **semi_autoの範囲**: ゲート承認の自動化のみ。ステップファイル読み込み・AIレビュー・progress.md管理の省略権限は含まない
3. **review_mode=requiredの厳守**: この設定時、AIレビューのスキップはバグである。成果物の承認前に必ずreview-flow.mdに従ってレビューを実施する
4. **コンパクション復帰時**: 前セッションの記憶に依存せず、ステップファイルを必ず再読み込みする

## ARGUMENTSパーシング

ARGUMENTS文字列を以下のルールでパースする:

1. ARGUMENTSが空または未指定の場合:
   - action = ブランチ名で判定（`cycle/*` なら `construction`、それ以外は `inception`）
   - additional_context = （空）

2. ARGUMENTSが指定されている場合:
   - 先頭の空白区切りトークンを action として取得
   - action が短縮形（`i` / `c` / `o` / `e`）の場合、フル名に展開する: `i`→`inception`, `c`→`construction`, `o`→`operations`, `e`→`express`
   - action が有効値（`inception` / `construction` / `operations` / `setup` / `express` / `feedback` / `migrate`）でない場合:
     エラーメッセージ「`/aidlc [action]` の action には inception/construction/operations/setup/express/feedback/migrate（短縮形: i/c/o/e）のいずれかを指定してください」を表示して処理を中断
   - action 以降の残りテキストから先頭の区切り空白（1つ）のみ除去し、残りを additional_context として設定（内部の空白は保持）

パース完了後、`additional_context` をコンテキスト変数として保持する（空の場合は従来と同じ動作）。

## 引数ルーティング

| 引数 | 対応処理 |
|------|----------|
| `inception` (`i`) / なし（cycleブランチ外） | Inception Phase |
| `construction` (`c`) / なし（cycleブランチ上） | Construction Phase |
| `operations` (`o`) | Operations Phase |
| `setup` | Setup Phase（独立フロー） |
| `express` (`e`) | Inception Phase（エクスプレスモード有効） |
| `feedback` | フィードバック送信 → 「フィードバック送信」セクション参照 |
| `migrate` | v1→v2移行（独立フロー） |

引数なしの場合: ブランチ名が `cycle/*` なら construction、そうでなければ inception。

**追加コンテキスト**: ARGUMENTSのパーシング結果として `additional_context` が設定されている場合、フェーズ実行中にコンテキスト変数として参照可能。空の場合は従来と同じ動作。

## 共通初期化フロー

全フェーズ共通で以下を実行する。**フィードバック送信の場合はスキップ**。**Setup Phaseの場合はステップ1〜3をスキップし、直接ステップ4へ進む**（セットアップは `.aidlc/config.toml` が未存在の状態で実行されるため）。**migrate の場合もステップ1〜3をスキップし、直接ステップ4へ進む**（移行スクリプトが自律的に環境検出を行うため）。

### ステップ1: 共通ステップ読み込み

以下のファイルを順に読み込む:

1. `steps/common/agents-rules.md` — エージェントルール
2. `steps/common/rules.md` — 共通開発ルール
3. `steps/common/preflight.md` — プリフライトチェック（実行）

### ステップ2: プロジェクト情報確認

- `.aidlc/config.toml` の存在を確認
- `.aidlc/rules.md` が存在すれば読み込む
- セッションタイトルを設定（`tools:session-title` スキル使用）

### ステップ3: セッション継続判定

`steps/common/session-continuity.md` を読み込み、前回セッションの継続かを判定。
コンパクション復帰の場合は `steps/common/compaction.md` を読み込む。

### ステップ4: フェーズステップ読み込み

引数に応じたフェーズステップを読み込む:

| フェーズ | 読み込み対象 |
|---------|-------------|
| inception | `steps/inception/01-setup.md` → `02-preparation.md` → `03-intent.md` → `04-stories-units.md` → `05-completion.md`（`06-backtrack.md` は必要時） |
| construction | `steps/construction/01-setup.md` → `02-design.md` → `03-implementation.md` → `04-completion.md` |
| operations | `steps/operations/01-setup.md` → `02-deploy.md` → `03-release.md` → `04-completion.md` |
| setup | `steps/setup/01-detect.md` → `02-generate-config.md` → `03-migrate.md` |
| migrate | `steps/migrate/01-preflight.md` → `02-execute.md` → `03-verify.md` |

## ワークフロー共通ステップ

フェーズ実行中に必要に応じて読み込む:

| ステップ | ファイル | タイミング |
|---------|---------|-----------|
| コミットフロー | `steps/common/commit-flow.md` | コミット時 |
| レビューフロー | `steps/common/review-flow.md` | AIレビュー時 |
| コンテキストリセット | `steps/common/context-reset.md` | セッション切り替え時 |

## Expressモード

引数 `express` でInception Phase開始後、`.aidlc/config.toml` の `[rules.automation]` を確認:

- `automation_mode = "semi_auto"`: ゲート自動承認、Unit自動選択
- `automation_mode = "full_auto"`: 全自動（ユーザー確認なし）

Inception完了後 → Construction Phase → Operations Phase と自動遷移。
各フェーズ完了時に次のフェーズステップを読み込んで継続する。

## フィードバック送信

引数 `feedback` の場合、共通初期化をスキップして以下を実行:

1. `.aidlc/config.toml` の `rules.feedback.enabled` を確認
2. `false` なら無効メッセージを表示して終了
3. フィードバック内容をヒアリング
4. GitHub CLI利用可能なら `gh issue create --web` でブラウザを開く
5. 利用不可なら `https://github.com/ikeisuke/ai-dlc-starter-kit/issues/new?template=feedback.yml` を案内

## 制約事項

- **ドキュメント読み込み制限**: `.aidlc/cycles/{{CYCLE}}/` 配下のファイルのみ読み込む。他サイクルのドキュメントは読まない
- **テンプレート参照**: ドキュメント作成時は `templates/` を参照（スキルベースディレクトリからの相対パス）
- **パス解決**: `steps/` および `scripts/` で始まるパスはスキルのベースディレクトリ（SKILL.mdと同じディレクトリ）からの相対パスとして解決する。ステップファイル内の相互参照（例: `steps/common/rules.md` を読み込んで）も同じルールに従う。Bashコマンドで `scripts/` 配下のスクリプトを実行する場合は、解決した絶対パスを使用すること
- **SKILL.md本文制限**: 本文500行以内。詳細はステップファイルに分離

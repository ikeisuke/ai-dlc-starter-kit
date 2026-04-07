---
name: aidlc
description: >
  AI-DLC（AI-Driven Development Lifecycle）の統合オーケストレーター。
  フェーズ（inception/construction/operations）の開始・継続、セットアップ、エクスプレスモード、フィードバック送信を統一的に実行する。
  Use when the user says "インセプション進めて", "start inception",
  "コンストラクション進めて", "start construction",
  "オペレーション進めて", "start operations",
  "start express", "start setup", "AIDLCフィードバック", "aidlc feedback",
  "start migrate", "aidlc migrate", "aidlc version".
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
   - action が短縮形の場合、フル名に展開する: `inc`→`inception`, `con`→`construction`, `ops`→`operations`, `exp`→`express`, `i`→`inception`, `c`→`construction`, `o`→`operations`, `e`→`express`, `h`→`help`, `v`→`version`
   - action が有効値（`inception` / `construction` / `operations` / `setup` / `express` / `feedback` / `migrate` / `help` / `version`）でない場合:
     エラーメッセージ「`/aidlc [action]` の action には inception/construction/operations/setup/express/feedback/migrate/help/version（短縮形: inc/con/ops/exp または i/c/o/e/h/v）のいずれかを指定してください」を表示して処理を中断
   - action 以降の残りテキストから先頭の区切り空白（1つ）のみ除去し、残りを additional_context として設定（内部の空白は保持）

パース完了後、`additional_context` をコンテキスト変数として保持する（空の場合は従来と同じ動作）。

## 引数ルーティング

| 引数 | 対応処理 |
|------|----------|
| `inception` (`inc` / `i`) / なし（cycleブランチ外） | Inception Phase |
| `construction` (`con` / `c`) / なし（cycleブランチ上） | Construction Phase |
| `operations` (`ops` / `o`) | Operations Phase |
| `setup` | `/aidlc-setup` スキルに委譲 |
| `express` (`exp` / `e`) | Inception Phase（エクスプレスモード有効） |
| `feedback` | `/aidlc-feedback` スキルに委譲 |
| `migrate` | `/aidlc-migrate` スキルに委譲 |
| `help` (`h`) | ヘルプ表示（アクション一覧） |
| `version` (`v`) | バージョン表示 |

引数なしの場合: ブランチ名が `cycle/*` なら construction、そうでなければ inception。

**追加コンテキスト**: ARGUMENTSのパーシング結果として `additional_context` が設定されている場合、フェーズ実行中にコンテキスト変数として参照可能。空の場合は従来と同じ動作。

## 共通初期化フロー

`inception` / `construction` / `operations` / `express` で実行する。

### ステップ1: 共通ステップ読み込み

以下のファイルを順に読み込む:

1. `steps/common/rules-core.md` — 共通開発ルール
2. `steps/common/preflight.md` — プリフライトチェック（実行）

### ステップ2: プロジェクト情報確認

- `.aidlc/config.toml` の存在を確認
- `.aidlc/rules.md` が存在すれば読み込む
- セッションタイトルを設定（`tools:session-title` スキル使用）

### ステップ3: セッション継続判定

`steps/common/session-continuity.md` を読み込み、前回セッションの継続かを判定。

### ステップ4: フェーズステップ読み込み

引数に応じたフェーズステップを読み込む:

| フェーズ | 読み込み対象 |
|---------|-------------|
| inception | `steps/inception/01-setup.md` → `02-preparation.md` → `03-intent.md` → `04-stories-units.md` → `05-completion.md`（`06-backtrack.md` は必要時） |
| construction | `steps/construction/01-setup.md` → `02-design.md` → `03-implementation.md` → `04-completion.md` |
| operations | `steps/operations/01-setup.md` → `02-deploy.md` → `03-release.md` → `04-completion.md` |

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

## 独立フロー委譲

`setup` / `migrate` / `feedback` は独立スキルに委譲する。親スキルは委譲指示の出力のみを行い、成功/失敗の検出はAIエージェント層の責務。

委譲手順:
1. `additional_context` がある場合は引数として付加（単一の生文字列をそのまま透過）
2. 「`/aidlc-{action} {additional_context}` を実行してください。」と出力して処理を終了

| action | 委譲先スキル |
|--------|------------|
| `setup` | `/aidlc-setup` |
| `migrate` | `/aidlc-migrate` |
| `feedback` | `/aidlc-feedback` |

## ヘルプ表示

`help` アクション時に以下を表示して処理を終了する。共通初期化フローは実行しない。

```text
AI-DLC オーケストレーター - 利用可能なアクション:

| アクション | 短縮形 | 説明 |
|-----------|--------|------|
| inception | inc, i | 要件定義（Intent・ストーリー・Unit定義） |
| construction | con, c | 実装（設計・コーディング・テスト） |
| operations | ops, o | 運用（デプロイ・リリース・PR管理） |
| setup | - | AI-DLC環境の初期セットアップ |
| express | exp, e | エクスプレスモード（Inception→Construction自動遷移） |
| feedback | - | AI-DLCへのフィードバック送信 |
| migrate | - | v1→v2マイグレーション |
| help | h | このヘルプを表示 |
| version | v | スキルバージョンを表示 |

使い方: /aidlc <action> [追加コンテキスト]
例: /aidlc ops   （Operations Phase開始）
例: /aidlc con 前回のセッションで設計レビューまで完了
```

## バージョン表示

`version` アクション時に以下を表示して処理を終了する。共通初期化フローは実行しない。

1. スキルベースディレクトリの `version.txt` を読み込む
2. 値を正規化する: 前後の空白をトリムし、先頭の `v` プレフィックスがあれば除去する。空文字・不正値・読取不能の場合は不存在と同じ扱いとする
3. 以下のフォーマットで表示:

```text
AI-DLC Starter Kit v{version}
```

4. `version.txt` が存在しない、または正規化後の値が空の場合:

```text
AI-DLC Starter Kit (version unknown)
```

## 制約事項

- **ドキュメント読み込み制限**: `.aidlc/cycles/{{CYCLE}}/` 配下のファイルのみ読み込む。他サイクルのドキュメントは読まない
- **テンプレート参照**: ドキュメント作成時は `templates/` を参照（スキルベースディレクトリからの相対パス）
- **パス解決**: `steps/` および `scripts/` で始まるパスはスキルのベースディレクトリ（SKILL.mdと同じディレクトリ）からの相対パスとして解決する。ステップファイル内の相互参照（例: `steps/common/rules-core.md` を読み込んで）も同じルールに従う。Bashコマンドで `scripts/` 配下のスクリプトを実行する場合は、解決した絶対パスを使用すること
- **SKILL.md本文制限**: 本文500行以内。詳細はステップファイルに分離

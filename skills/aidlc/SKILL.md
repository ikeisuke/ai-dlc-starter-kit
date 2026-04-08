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

## 前提ガード

### 非AIDLCプロジェクトガード

`.aidlc/config.toml` が存在しない場合、通常フェーズ（inception/construction/operations）の実行は行わない。
`/aidlc setup` のみ許可し、ユーザーにセットアップを案内する:

```text
AI-DLC環境が未セットアップです。
「start setup」または `/aidlc setup` でセットアップを開始してください。
```

## 不変ルール【絶対遵守】

以下はautomation_modeや過去の経験に関わらず、常に遵守する:

1. **ステップファイルの読み込みは省略不可**: 「ステップ4: フェーズステップ読み込み」に列挙された全ファイルを必ずReadツールで読み込む。「内容を覚えている」「前回と同じ」は省略理由にならない
   - **フェーズインデックス併用時**: 「フェーズステップ読み込み」の対象がフェーズインデックスファイル（`steps/{phase}/index.md`）である場合、インデックス読み込み＋インデックスの「ステップ読み込み契約」テーブル経由で必要な詳細ファイルを読み込む流れ全体が「ステップファイル読み込み」の一形態である。インデックスのみロードして詳細ファイル読み込みを省略することは禁止
2. **semi_autoの範囲**: ゲート承認の自動化のみ。ステップファイル読み込み・AIレビュー・progress.md管理の省略権限は含まない
3. **review_mode=requiredの厳守**: この設定時、AIレビューのスキップはバグである。成果物の承認前に必ずreview-flow.mdに従ってレビューを実施する
4. **コンパクション復帰時**: 前セッションの記憶に依存せず、ステップファイルを必ず再読み込みする

## 実行判断・対話規約

### 質問と実行の判断基準【重要】

実行前に以下の2条件を確認する:

1. **要件を1文で言い換えられるか**
2. **実装アプローチが1つに絞れるか**

両方Yesなら直接実行。どちらかNoなら質問する。

#### 質問フロー

1. 質問の数と概要を先に提示
2. 1問ずつ詳細を質問し、回答を待つ
3. 回答に基づく追加質問が発生した場合は明示して質問

#### 確認が必要な場面

- 破壊的操作（データ削除、force push等）
- 機密情報の取り扱い

これらの確認は「AskUserQuestion使用ルール」セクションでは主に「ユーザー選択」として扱う。

#### 不明点の記録

独自の判断をせず、不明点はドキュメントに `[Question]` / `[Answer]` タグで記録する。

#### 情報提示ルール

ユーザーに判断を求める際は、判断に必要な情報を**質問の前に**提示すること:

- Issue選択時: タイトルだけでなく本文の概要・受け入れ基準を提示
- スコープ判断時: Intent「含まれるもの」の該当項目を引用
- 技術選択時: 各選択肢のメリット・デメリットを提示
- 差分確認時: `git diff` の要約を提示

### 承認プロセス【重要】

計画・設計等の成果物はユーザーの承認を得てから次ステップへ進む。

- `automation_mode=semi_auto`: フォールバック条件に該当しなければ自動承認（`rules-automation.md` のセミオートゲート仕様を参照）
- `automation_mode=manual`: ユーザーの明示的な肯定返答が必要

### AskUserQuestion使用ルール【重要】

ユーザーとの対話場面を3種類に分類し、種別に応じた適切なツール使用を定義する。

#### インタラクション種別と対応方法

| 種別 | 説明 | 対応方法 | `semi_auto` での扱い | 具体例 |
|------|------|---------|---------------------|--------|
| ゲート承認 | フェーズ/ステップの進行承認。ステップファイルで「セミオートゲート判定」と定義された選択（Unit自動選択、ステップスキップ等）を含む | セミオートゲート仕様に従う | `auto_approved` / `fallback` で判定 | 「この設計で進めてよろしいですか？」「計画を承認しますか？」「どのUnitから着手しますか？」（semi_auto時は自動選択） |
| ユーザー選択 | ゲート承認に該当しない選択場面（ステップファイルで「セミオートゲート判定」と定義されていないもの） | `AskUserQuestion` 必須 | 自動化対象外（常に `AskUserQuestion`） | 「マージ方法を選んでください」「force pushしてよろしいですか？」 |
| 情報収集 | ユーザーからの自由入力やコンテキスト提供が必要な場面 | `AskUserQuestion` 必須 | 自動化対象外（常に `AskUserQuestion`） | 「今回取り組みたい内容は何ですか？」「追加コンテキストを教えてください」 |

#### セミオートゲート仕様との関係

- **ゲート承認のみ**がセミオートゲート仕様の対象。`automation_mode=semi_auto` 時にフォールバック条件に該当しなければ `auto_approved` となる
- **ユーザー選択**と**情報収集**は `automation_mode` に関わらず常に `AskUserQuestion` ツールを使用する。テキスト出力のみで代替してはならない

## 引数処理

### ARGUMENTSパーシング

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

### 引数ルーティング

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

### 独立フロー委譲

`setup` / `migrate` / `feedback` は独立スキルに委譲する。親スキルは委譲指示の出力のみを行い、成功/失敗の検出はAIエージェント層の責務。

委譲手順:
1. `additional_context` がある場合は引数として付加（単一の生文字列をそのまま透過）
2. 「`/aidlc-{action} {additional_context}` を実行してください。」と出力して処理を終了

| action | 委譲先スキル |
|--------|------------|
| `setup` | `/aidlc-setup` |
| `migrate` | `/aidlc-migrate` |
| `feedback` | `/aidlc-feedback` |

## 実行フロー

### 共通初期化フロー

`inception` / `construction` / `operations` / `express` で実行する。

1. **共通ステップ読み込み**: 以下のファイルを順に読み込む — `steps/common/rules-core.md`（共通開発ルール）→ `steps/common/preflight.md`（プリフライトチェック・実行）
2. **プロジェクト情報確認**: `.aidlc/config.toml` の存在を確認。`.aidlc/rules.md` が存在すれば読み込む。セッションタイトルを設定（`tools:session-title` スキル使用）
3. **セッション継続判定**: `steps/common/session-continuity.md` を読み込み、前回セッションの継続かを判定
4. **フェーズステップ読み込み**: 引数に応じたフェーズステップを読み込む

| フェーズ | 読み込み対象 |
|---------|-------------|
| inception | `steps/inception/index.md`（フェーズインデックス。詳細ステップはインデックス内「ステップ読み込み契約」テーブル経由で必要時ロード。`06-backtrack.md` はバックトラック発動時のみ） |
| construction | `steps/construction/01-setup.md` → `02-design.md` → `03-implementation.md` → `04-completion.md`（Unit 003 でインデックス化予定） |
| operations | `steps/operations/01-setup.md` → `02-deploy.md` → `03-release.md` → `04-completion.md`（Unit 004 でインデックス化予定） |

### Expressモード

引数 `express` でInception Phase開始後、`.aidlc/config.toml` の `[rules.automation]` を確認:

- `automation_mode = "semi_auto"`: ゲート自動承認、Unit自動選択
- `automation_mode = "full_auto"`: 全自動（ユーザー確認なし）

Inception完了後 → Construction Phase → Operations Phase と自動遷移。各フェーズ完了時に次のフェーズステップを読み込んで継続する。

## 補助フロー

### ワークフロー共通ステップ

フェーズ実行中に必要に応じて読み込む:

| ステップ | ファイル | タイミング |
|---------|---------|-----------|
| コミットフロー | `steps/common/commit-flow.md` | コミット時 |
| レビューフロー | `steps/common/review-flow.md` | AIレビュー時 |
| コンテキストリセット | `steps/common/context-reset.md` | セッション切り替え時 |

## ユーティリティ

### ヘルプ表示

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

### バージョン表示

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

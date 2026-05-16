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
| ユーザー選択 | ゲート承認に該当しない選択場面（ステップファイルで「セミオートゲート判定」と定義されていないもの） | `AskUserQuestion` 必須 | 自動化対象外（常に `AskUserQuestion`） | 「マージ方法を選んでください」「force pushしてよろしいですか？」「設定保存確認（`branch_mode` / `draft_pr` / `merge_method`）」 |
| ユーザー選択（振り返り内容の決定） | Operations Phase §1 振り返りでの KPT / 主因切り分け / 格納先選択 / mirror 送信判断 / 起票実行確認。AI エージェントの `auto mode`（Claude Code 等）動作に関わらず適用される（auto mode 適用外） | `AskUserQuestion` 必須 | 自動化対象外（常に `AskUserQuestion`）。実行時ガード（対話確認トークン検証）と併用 | 「この Keep を振り返り Issue に含めますか？」「この主因切り分けで進めてよいですか？」「この内容で Issue を起票しますか？」 |
| 情報収集 | ユーザーからの自由入力やコンテキスト提供が必要な場面 | `AskUserQuestion` 必須 | 自動化対象外（常に `AskUserQuestion`） | 「今回取り組みたい内容は何ですか？」「追加コンテキストを教えてください」 |

#### セミオートゲート仕様との関係

- **ゲート承認のみ**がセミオートゲート仕様の対象。`automation_mode=semi_auto` 時にフォールバック条件に該当しなければ `auto_approved` となる
- **ユーザー選択**と**情報収集**は `automation_mode` に関わらず常に `AskUserQuestion` ツールを使用する。テキスト出力のみで代替してはならない
- 「ユーザー選択（振り返り内容の決定）」は AI エージェントの auto mode（Claude Code 等）動作に**関わらず**適用される。auto mode を理由とした AskUserQuestion 省略は禁止。Operations Phase §1 における具体的手順は `steps/operations/04-completion.md` §1.0.5 を参照

#### 推奨・提案応答確保ルール

推奨・提案を含むメッセージ表示時の応答確保基準。既存3種別の分類に変更を加えず、推奨・提案場面での適切な種別マッピングを規定する横断ルールである。

| 条件 | 対応方法 | マッピング先種別 |
|------|---------|----------------|
| ユーザーアクションが後続処理の品質・正確性に影響する推奨 | `AskUserQuestion` で応答を待つ | ユーザー選択 |
| 情報提供のみで後続処理に影響しない推奨 | テキスト出力で進行 | （対話不要） |

- `automation_mode` に関わらず、「ユーザー選択」にマッピングされた推奨は常に `AskUserQuestion` を使用する
- テキスト出力のみで推奨を表示し応答を待たない「投げっぱなし」は禁止

#### 区切り判断での AskUserQuestion 禁止【重要】

以下のような「次に何をするか」「ここで一度区切るか」を問う場面では `AskUserQuestion` を使用しない。
ユーザーが `/clear` 等で即座にセッションを切り替えたい場合に、選択肢を 1 つ選ばないと進められず
ブロッカーになるため。

該当する場面:

- Phase / Unit / ステップ完了後の「次に進む / 一旦休止 / コンテキストリセット」を問う場面
- 進捗報告のみで作業継続を伴わない確認（「進めてよいですか？」を投げ続けない）
- バックログ追加のみの指示への対応（「Issue 起票しました」の続行確認を求めない）
- コンテキストリセット推奨のタイミングで「リセットして続ける / そのまま続ける」を問う場面
- Unit 完了サマリ後の「次の Unit に進みますか？」を問う場面（semi_auto では自動継続 / manual では平文の案内のみ）

代わりに以下のいずれかで対応する:

- 推奨アクション（例: コンテキストリセット）を平文で提示し、続行可否はユーザー側に委ねる（メッセージはここで完結させる）
- `automation_mode=semi_auto` で進むのが安全な場面なら、進行状況とロールバック手段を提示してそのまま続行する
- 区切り情報（コンテキスト保持必須情報 / 再開コマンド / 現状サマリ）を提示してメッセージを終える

**例外**:

- 「ユーザー選択（振り返り内容の決定）」など、本セクション上位の表で `AskUserQuestion` 必須と明示されている対話（スキル仕様を優先する）
- 破壊的操作（force push / リモートブランチ削除 / 機密情報の取り扱い等）の最終確認は引き続き `AskUserQuestion` を使用する

## 引数処理

### ARGUMENTSパーシング

ARGUMENTS文字列を以下のルールでパースする:

1. ARGUMENTSが空または未指定の場合:
   - action = ブランチ名で判定（`cycle/*` なら `construction`、それ以外は `inception`）
   - additional_context = （空）

2. ARGUMENTSが指定されている場合:
   - 先頭の空白区切りトークンを action として取得
   - action が短縮形の場合、フル名に展開する: `inc`→`inception`, `con`→`construction`, `ops`→`operations`, `exp`→`express`, `i`→`inception`, `c`→`construction`, `o`→`operations`, `e`→`express`, `h`→`help`, `v`→`version`, `r`→`retrospective`
   - action が有効値（`inception` / `construction` / `operations` / `setup` / `express` / `feedback` / `migrate` / `retrospective` / `help` / `version`）でない場合:
     エラーメッセージ「`/aidlc [action]` の action には inception/construction/operations/setup/express/feedback/migrate/retrospective/help/version（短縮形: inc/con/ops/exp/r または i/c/o/e/h/v）のいずれかを指定してください」を表示して処理を中断
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
| `retrospective` (`r`) | `/aidlc-retrospective` スキルに委譲（v2.6.0+ / Operations §1 から分離） |
| `help` (`h`) | ヘルプ表示（アクション一覧） |
| `version` (`v`) | バージョン表示 |

引数なしの場合: ブランチ名が `cycle/*` なら construction、そうでなければ inception。

**追加コンテキスト**: ARGUMENTSのパーシング結果として `additional_context` が設定されている場合、フェーズ実行中にコンテキスト変数として参照可能。空の場合は従来と同じ動作。

### 独立フロー委譲

`setup` / `migrate` / `feedback` / `retrospective` は独立スキルに委譲する。親スキルは委譲指示の出力のみを行い、成功/失敗の検出はAIエージェント層の責務。

委譲手順:
1. `additional_context` がある場合は引数として付加（単一の生文字列をそのまま透過）
2. 「`/aidlc-{action} {additional_context}` を実行してください。」と出力して処理を終了

| action | 委譲先スキル |
|--------|------------|
| `setup` | `/aidlc-setup` |
| `migrate` | `/aidlc-migrate` |
| `feedback` | `/aidlc-feedback` |
| `retrospective` | `/aidlc-retrospective` |

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
| construction | `steps/construction/index.md`（フェーズインデックス。詳細ステップはインデックス内「ステップ読み込み契約」テーブル経由で必要時ロード） |
| operations | `steps/operations/index.md`（フェーズインデックス。詳細ステップはインデックス内「ステップ読み込み契約」テーブル経由で必要時ロード） |

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
| retrospective | r | サイクル振り返り（KPT / Issue 起票 / Operations §1 から分離 / v2.6.0+） |
| help | h | このヘルプを表示 |
| version | v | スキルバージョンを表示 |

使い方: /aidlc <action> [追加コンテキスト]
例: /aidlc ops   （Operations Phase開始）
例: /aidlc con 前回のセッションで設計レビューまで完了
例: /aidlc r v2.6.0   （v2.6.0 サイクルの振り返りを起動）
```

### バージョン表示

`version` アクション時に以下を実行する。共通初期化フローは実行しない。

#### 実行手順

1. **base dir 解決**: SKILL.md 冒頭の `Base directory for this skill:` 行から `{base}` の絶対パスを取得する
2. **CLI 実行**: `bash {base}/scripts/lib/version.sh` を引数省略で実行（v2.6.3 以降、引数省略時はスクリプト位置から marketplace.json を自己解決する）
3. **正規化と表示**: stdout を取得し、前後空白トリム + 先頭 `v` プレフィックス除去後に以下を表示

   ```text
   AI-DLC Starter Kit v{version}
   ```

4. **フォールバック**: 上記コマンドが exit 非 0 を返した場合、または stdout が空文字の場合は以下を表示

   ```text
   AI-DLC Starter Kit (version unknown)
   ```

#### 禁則【絶対遵守】

- **内部知識からの推測禁止**: AI エージェントは Bash ツール呼び出しを行わずに学習データ等から version 文字列を推測出力してはならない。CLI 実行が失敗した場合は必ず `(version unknown)` フォールバックを使用する
- **base dir の組み立てミス防止**: `{base}` は SKILL.md 冒頭行から直接取得する。プラグインキャッシュパス（`~/.claude/plugins/...`）の構造を推測で再構築してはならない

#### 注意: Bash ツール経由の zsh OOM 回避ルール

AI エージェントが Bash ツール引数文字列にコマンド置換構文（`$(...)` / backtick）を含めると、zsh `command_not_found_handler` の無限再帰により OOM クラッシュを誘発する既知のクラスバグがある（Issue #697 / 関連 #688）。本ルールは Bash ツール経由のあらゆる外部スクリプト呼び出しに適用される。

- **規約本文 SoT**: [`CLAUDE.md` § AI エージェント Bash ツール経由の安全パターン](../../CLAUDE.md#ai-エージェント-bash-ツール経由の安全パターン)
- **運用例 SoT**: [`steps/common/bash-tool-safety.md`](./steps/common/bash-tool-safety.md)
- `/aidlc v` 経路固有の経緯（zsh 手動 source 等）は `scripts/lib/version.sh` 冒頭コメント + Issue #688 を参照

## 制約事項

- **ドキュメント読み込み制限**: `.aidlc/cycles/{{CYCLE}}/` 配下のファイルのみ読み込む。他サイクルのドキュメントは読まない
- **テンプレート参照**: ドキュメント作成時は `templates/` を参照（スキルベースディレクトリからの相対パス）
- **パス解決**: `steps/`、`scripts/`、`config/`、`templates/`、`guides/`、`references/` で始まるパスはスキルのベースディレクトリ（SKILL.mdと同じディレクトリ）からの相対パスとして解決する。`..` によるベースディレクトリ外への参照は **以下の例外を除き** 無効とする。ステップファイル内の相互参照（例: `steps/common/rules-core.md` を読み込んで）も同じルールに従う。Bashコマンドで `scripts/` 配下のスクリプトを実行する場合は、解決した絶対パスを使用すること
  - **例外**（v2.6.1 Unit 001 / Issue #688）: `marketplace.json`（プラグインルート `.claude-plugin/marketplace.json`）への参照は `{SKILLベースディレクトリ}/../../.claude-plugin/marketplace.json` として解決する。これは `marketplace.json` が version SoT であり、スキルベースディレクトリ外に配置されているための限定的な例外である。「バージョン表示」アクション（`/aidlc v`）でのみ使用する
- **SKILL.md本文制限**: 本文500行以内。詳細はステップファイルに分離

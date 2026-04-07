# AI-DLC（AI-Driven Development Lifecycle）

このプロジェクトはAI-DLCを使用しています。

## 非AIDLCプロジェクトガード

`.aidlc/config.toml` が存在しない場合、通常フェーズ（inception/construction/operations）の実行は行わない。
`/aidlc setup` のみ許可し、ユーザーにセットアップを案内する:

```text
AI-DLC環境が未セットアップです。
「start setup」または `/aidlc setup` でセットアップを開始してください。
```

## 開発サイクルの開始

### 初期セットアップ / アップグレード

`/aidlc setup` を実行してください。

スターターキットの初期セットアップ、バージョンアップ、または移行時に使用します。

### 新規サイクル開始

`/aidlc inception` を実行してください。

Setup PhaseとInception Phaseが統合され、1回の実行で
サイクル開始からUnit定義まで完了できます。

### 既存サイクルの継続

以下のコマンドを実行してください：

- Inception Phase: `/aidlc inception`
- Construction Phase: `/aidlc construction`
- Operations Phase: `/aidlc operations`

## 推奨ワークフロー

1. 初回は `/aidlc setup` でセットアップ
2. `/aidlc inception` でサイクル作成からUnit定義まで完了
3. `/aidlc construction` で設計と実装
4. `/aidlc operations` でデプロイと運用

## ドキュメント

- 設定: `.aidlc/config.toml`
- 追加ルール: `.aidlc/rules.md`

---

## フェーズ簡略指示

以下の簡略指示でフェーズを開始できます：

| 指示 | 対応処理 |
|------|----------|
| 「インセプション進めて」「start inception」 | `/aidlc inception`（短縮形: `/aidlc i`） |
| 「コンストラクション進めて」「start construction」 | `/aidlc construction`（短縮形: `/aidlc c`） |
| 「オペレーション進めて」「start operations」 | `/aidlc operations`（短縮形: `/aidlc o`） |
| 「セットアップ」「start setup」 | `/aidlc setup`（Setup Phase） |
| 「start express」 | `/aidlc express`（短縮形: `/aidlc e`、エクスプレスモード） |
| 「AIDLCフィードバック」「aidlc feedback」 | `/aidlc feedback`（フィードバック送信） |
| 「start migrate」「aidlc migrate」 | `/aidlc migrate`（v1→v2移行） |

**追加コンテキスト**: `/aidlc <action> <テキスト>` の形式で、actionの後に任意のテキストを追加できます。追加テキストはフェーズ実行中にコンテキスト変数 `additional_context` として参照されます。ARGUMENTSパーシングの詳細仕様（有効action一覧、エラー条件、引数なし時の既定動作）は `SKILL.md` の「ARGUMENTSパーシング」セクションが正本です。

例: `/aidlc construction 前回のセッションで設計レビューまで完了`

**後方互換性**: 従来の詳細な指示（`docs/aidlc/prompts/xxx.md を読み込んで`）は `/aidlc` コマンドにリダイレクトされます。

### サイクル判定

- ブランチ名が `cycle/*` の場合: サイクルブランチと判定し、引数なしで `construction` をデフォルト実行
- ブランチ名が `cycle/*` でない場合（main、feature/* 等）: 引数なしで `inception` をデフォルト実行
- mainブランチの場合:
  - 初期セットアップ: `/aidlc setup`
  - 新規サイクル開始: `/aidlc inception`
- コンテキストなしで「続けて」: ユーザーに確認

---

## 質問と実行の判断基準【重要】

実行前に以下の2条件を確認する:

1. **要件を1文で言い換えられるか**
2. **実装アプローチが1つに絞れるか**

両方Yesなら直接実行。どちらかNoなら質問する。

### 質問フロー

1. 質問の数と概要を先に提示
2. 1問ずつ詳細を質問し、回答を待つ
3. 回答に基づく追加質問が発生した場合は明示して質問

### 質問不要でも確認が必要な場面

- 破壊的操作（データ削除、force push等）
- 機密情報の取り扱い

これらの確認は「AskUserQuestion使用ルール」セクションでは主に「ユーザー選択」として扱う。

### 不明点の記録

独自の判断をせず、不明点はドキュメントに `[Question]` / `[Answer]` タグで記録する。

### 質問の目的

- 曖昧な要件を明確化する
- 前提条件や制約を確認する
- 複数の解釈がある場合に意図を特定する

### 深掘りのテクニック

- 「具体的には？」で詳細を引き出す
- 「例えば？」で具体例を求める
- 「なぜ？」で背景・理由を確認する
- ユースケースやシナリオを聞いて理解を深める

### 情報提示ルール

ユーザーに判断を求める際は、判断に必要な情報を**質問の前に**提示すること:

- Issue選択時: タイトルだけでなく本文の概要・受け入れ基準を提示
- スコープ判断時: Intent「含まれるもの」の該当項目を引用
- 技術選択時: 各選択肢のメリット・デメリットを提示
- 差分確認時: `git diff` の要約を提示

## 承認プロセス【重要】

計画・設計等の成果物はユーザーの承認を得てから次ステップへ進む。

- `automation_mode=semi_auto`: フォールバック条件に該当しなければ自動承認（`rules-automation.md` のセミオートゲート仕様を参照）
- `automation_mode=manual`: ユーザーの明示的な肯定返答が必要

## AskUserQuestion使用ルール【重要】

ユーザーとの対話場面を3種類に分類し、種別に応じた適切なツール使用を定義する。

### インタラクション種別と対応方法

| 種別 | 説明 | 対応方法 | `semi_auto` での扱い | 具体例 |
|------|------|---------|---------------------|--------|
| ゲート承認 | フェーズ/ステップの進行承認。ステップファイルで「セミオートゲート判定」と定義された選択（Unit自動選択、ステップスキップ等）を含む | セミオートゲート仕様に従う | `auto_approved` / `fallback` で判定 | 「この設計で進めてよろしいですか？」「計画を承認しますか？」「どのUnitから着手しますか？」（semi_auto時は自動選択） |
| ユーザー選択 | ゲート承認に該当しない選択場面（ステップファイルで「セミオートゲート判定」と定義されていないもの） | `AskUserQuestion` 必須 | 自動化対象外（常に `AskUserQuestion`） | 「マージ方法を選んでください」「force pushしてよろしいですか？」 |
| 情報収集 | ユーザーからの自由入力やコンテキスト提供が必要な場面 | `AskUserQuestion` 必須 | 自動化対象外（常に `AskUserQuestion`） | 「今回取り組みたい内容は何ですか？」「追加コンテキストを教えてください」 |

### セミオートゲート仕様との関係

本セクションはセミオートゲートの**対象範囲**（どの種類のインタラクションが自動化対象か）を定義する。判定ロジック自体（`automation_mode`, `reason_code`, `auto_approved`, `fallback` の処理フロー）は `rules-automation.md` のセミオートゲート仕様に委譲する。

- **ゲート承認のみ**がセミオートゲート仕様の対象。`automation_mode=semi_auto` 時にフォールバック条件に該当しなければ `auto_approved` となる
- **ユーザー選択**と**情報収集**は `automation_mode` に関わらず常に `AskUserQuestion` ツールを使用する。テキスト出力のみで代替してはならない

### 各種別の入出力契約

| 種別 | 入力 | 出力 | ツール |
|------|------|------|--------|
| ゲート承認 | 承認ポイントID、成果物 | `manual`: ユーザー承認結果 / `semi_auto`: `auto_approved` / `fallback` | セミオートゲート仕様に委譲 |
| ユーザー選択 | 選択肢リスト、コンテキスト | ユーザーの選択結果 | `AskUserQuestion`（選択肢提示） |
| 情報収集 | 質問文、コンテキスト | ユーザーの自由入力 | `AskUserQuestion`（自由入力） |

---

@`steps/common/rules-core.md` を参照してください。

---

@`steps/common/feedback.md` を参照してください。

---

@`steps/common/ai-tools.md` を参照してください。

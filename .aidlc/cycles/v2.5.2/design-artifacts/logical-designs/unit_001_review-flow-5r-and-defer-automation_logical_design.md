# 論理設計: Unit 001 review-flow 5R 化と defer 自動化

## 概要

`skills/aidlc/steps/common/review-flow.md`（正本）を中心に、5R / 完了条件 / defer 自動 Issue 起票 / Round 4+ 新領域 backlog 化の手順を構造化する。本 Unit はドキュメント改修であり、新規スクリプトを生成しない。論理設計はドキュメントを「規定された状態機械」と捉え、その状態遷移と入出力契約を形式化する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体的なコード（SQL、JSON、実装コード等）は Phase 2（コード生成ステップ）で作成する。

## アーキテクチャパターン

**Documentation-as-Specification + Layered Reference**

- ドキュメントを「規定された手順」「契約」として扱い、実装（AI agent + CLI）はドキュメントを忠実に解釈する
- 正本（`review-flow.md`）→ 共通基盤（`reviewing-common-base.md`）→ 各 reviewing-* スキル の片方向参照階層を維持
- `bin/sync-reviewing-common.sh` が共通基盤の伝播を担保（明示的な伝播スクリプトによる依存方向の固定）

選定理由: 既存の AI-DLC スターターキットがドキュメントベースで AI agent の挙動を規定しており、正本 → 共通 → 派生スキルの階層がすでに確立されているため。新規アーキテクチャを導入するコストよりも既存階層への統合が効率的。

## コンポーネント構成

### レイヤー / モジュール構成

```text
review-flow ドキュメント階層
├── skills/aidlc/steps/common/         (共通ステップ層)
│   ├── review-flow.md                 (正本)
│   └── review-flow-reference.md       (外部 CLI 制約参照、正本に従属)
├── skills/aidlc/templates/             (テンプレート層)
│   └── review_summary_template.md     (記録テンプレート、正本の用語に従属)
├── skills/reviewing-common/            (共通レビュー基盤層)
│   └── reviewing-common-base.md       (共通基盤、正本の用語に従属)
├── skills/reviewing-{stage}-{kind}/    (個別レビュースキル層、9 種)
│   ├── SKILL.md                       (スキル本体、共通基盤を参照)
│   └── references/
│       ├── reviewing-common-base.md   (sync-reviewing-common.sh で伝播)
│       └── session-management.md      (CLI セッション継続のサンプル例、独立)
└── bin/                                 (運用ツール層)
    ├── sync-reviewing-common.sh       (伝播ツール)
    └── check-skill-references.sh      (整合性検証ツール)
```

### コンポーネント詳細

#### `review-flow.md`（正本）

- **責務**: review round 上限・完了条件・defer 自動 Issue 起票・Round 4+ 新領域 backlog 化・指摘対応判断・スコープ保護・履歴記録の全規範を保持する単一情報源
- **依存**: `review-routing.md`（ReviewRoutingDecision 入力）、`rules-core.md`（スコープ保護ルール）、`rules-automation.md`（セミオートゲート仕様）
- **公開インターフェース**:
  - 反復レビュー実行手順（パス 1/2/3、最大 5 round）
  - 指摘対応判断フロー（5 round 終了後）
  - defer 自動 Issue 起票フロー（必須ラベル仕様、起票後検証、`PENDING_MANUAL` 異常系）
  - Round 4+ 新領域判定フロー（領域キー正規化、判定手順 0〜7）
  - 完了時シグナル（`review_detected` / `deferred_count` / `resolved_count` / `unresolved_count`）

#### `review-flow-reference.md`（外部 CLI 制約参照）

- **責務**: 外部 CLI の既知制約（sandbox、認証、interactive）と対処法を保持
- **依存**: `review-flow.md`（参照される側）
- **公開インターフェース**: 制約カタログ（sandbox / output_format / auth_lifecycle / interactive_mode テーブル）

#### `review_summary_template.md`（記録テンプレート）

- **責務**: AI レビュー Set のフォーマット定義、新たに `## Round 4 新領域判定` セクションを保持
- **依存**: `review-flow.md`（用語定義）
- **公開インターフェース**:
  - Set フォーマット（反復回数 1〜5、結論欄）
  - 指摘テーブル（`#` / 重要度 / 内容 / 対応 / バックログ）
  - `## Round 4 新領域判定` セクション（K_old / K_new / K_diff の JSON 配列記録）
  - 履歴文言補注（5 回上限・新完了条件への注記）

#### `reviewing-common-base.md`（共通基盤）

- **責務**: 全 reviewing-* スキルが共有する外部ツール実行コマンド・セッション継続手順・セルフレビューモード規定
- **依存（種別を分離）**:
  - **規範依存**: `review-flow.md` の用語（round / 完了条件 / defer 等）に従属（概念整合性は正本側で担保される）
  - **物理参照依存**: なし（ファイル間の `参照` リンクは持たない独立基盤）
- **公開インターフェース**: codex / claude / gemini の実行コマンド / セッション継続コマンド / セルフレビュー指示テンプレート

#### `bin/sync-reviewing-common.sh`（伝播ツール）

- **責務**: `skills/reviewing-common/reviewing-common-base.md` を全 reviewing-* スキル配下の `references/reviewing-common-base.md` に同期コピー
- **依存**: ファイルシステム
- **公開インターフェース**: 引数なし（リポジトリルートから実行）

#### `bin/check-skill-references.sh`（整合性検証ツール）

- **責務**: スキル間参照の整合性検証（既存）
- **依存**: ファイルシステム
- **公開インターフェース**: 既存の検証ロジック（本 Unit では改修しない、pass の確認のみ）

## インターフェース設計

### コマンド（該当する場合）

#### `ReviewSession.next_round()`（review-flow.md 内手順として実装）

- **パラメータ**: `session: ReviewSession`、`router_decision: ReviewRoutingDecision`
- **戻り値**: `Result<ReviewRound, FallbackPolicy>` - 次の ReviewRound または fallback ポリシー
- **副作用**:
  - パス 1: codex / claude / gemini の `exec resume <session-id>` 呼び出し
  - パス 2: サブエージェント or インラインのセルフレビュー実行
  - パス 3: ユーザーへのレビュー要求

#### `DeferIssueRegistrar.register(finding)`（review-flow.md 内手順として実装）

- **パラメータ**: `finding: ReviewFinding`（disposition が `out_of_scope` または `technical_blocker`）
- **戻り値**: `BacklogReference` - 起票成功時 `issue_ref + #N`、失敗時 `pending_manual`、focus=security の OUT_OF_SCOPE は `security_private`
- **副作用**:
  - `gh issue create --label backlog --label type:defer-from-review --title "..." --body-file ...`
  - 起票後 `gh issue view <N> --json labels --jq '[.labels[].name]'` で必須ラベル両方の付与確認
  - 検証失敗時 review-summary 「バックログ」列に `PENDING_MANUAL` 記録

#### `NewAreaDetector.detect(rounds)`（review-flow.md 内手順として実装）

- **パラメータ**: `rounds: List<ReviewRound>`（4 round 以上必要）
- **戻り値**: `NewAreaJudgment` - K_old / K_new / K_diff / source_findings
- **副作用**: なし（純粋導出。記録は `NewAreaIssueRegistrar` が担う）

#### `NewAreaIssueRegistrar.register(judgment)`（review-flow.md 内手順として実装）

- **パラメータ**: `judgment: NewAreaJudgment`
- **戻り値**: `List<BacklogReference>`
- **副作用**:
  - 各新領域指摘について `gh issue create --label backlog --label type:new-area-from-round4plus`
  - 起票後ラベル検証（DeferIssueRegistrar と同等）
  - `## Round 4 新領域判定` セクションへの K_old / K_new / K_diff 記録（review-summary 内）

### クエリ（該当する場合）

#### `ReviewCompletionEvaluator.evaluate(session)`

- **パラメータ**: `session: ReviewSession`
- **戻り値**: `{completed, in_progress, decision_required}` - 単一仕様（`CompletionCondition` ドメインモデル参照）:
  - `rounds.size == 1 && rounds[0].is_clean()` → `completed`（1R clean 特例）
  - `rounds.size >= 2 && last_two_rounds_clean` → `completed`
  - `rounds.size >= 5 && unresolved_count > 0` → `decision_required`
  - 上記いずれにも該当しない → `in_progress`

## スクリプトインターフェース設計（該当する場合）

本 Unit ではドキュメント改修中心のため、新規スクリプトの生成は行わない。既存の `bin/sync-reviewing-common.sh` および `bin/check-skill-references.sh` の引数・出力フォーマットは現状維持。

### `bin/sync-reviewing-common.sh`（既存、改修なし）

#### 概要

`skills/reviewing-common/reviewing-common-base.md` を全 reviewing-* スキル配下の `references/reviewing-common-base.md` に同期する。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| なし | - | リポジトリルートから引数なしで実行 |

#### 成功時出力

既存の出力形式に従う（本 Unit では未改修）。

- 終了コード: `0`
- 出力先: stdout

#### エラー時出力

既存の出力形式に従う。

- 終了コード: 非 `0`

#### 使用コマンド

```bash
bash bin/sync-reviewing-common.sh
```

### `bin/check-skill-references.sh`（既存、改修なし）

#### 概要

スキル間参照の整合性を検証する（既存）。

#### 引数

既存仕様。

#### 成功時出力

`PASS` / `FAIL` 等の既存出力。

- 終了コード: `0`（pass）/ 非 `0`（fail）

## データモデル概要

### ファイル形式

- **形式**: Markdown
- **主要フィールド**:
  - `review-flow.md`: 規範手順テキスト + ASCII テーブル
  - `review_summary_template.md`: Set ブロック + `## Round 4 新領域判定` セクション
  - `reviewing-common-base.md`: 外部 CLI 実行コマンドテーブル + セルフレビュー指示テンプレート

## 処理フロー概要

### ユースケース 1: 5R 反復レビュー → 完了

**ステップ**:

1. `review-routing.md` で ReviewRoutingDecision 導出（パス 1/2/3、tool_name）
2. レビュー前コミット（パス 1 のみ、パス 2/3 は手順内で代替）
3. 機密情報除外スキャン（パス 1）
4. Round 1 実行 → `ReviewCompletionEvaluator.evaluate(session)` で判定（Round 1 が clean なら `completed`、それ以外で指摘ありなら修正コミット → Round 2）
5. Round N （2≦N≦5）実行 → `ReviewCompletionEvaluator.evaluate(session)` で判定（最後 2 round 連続クリーン → `completed`、`rounds.size >= 5 && unresolved_count > 0` → `decision_required`、その他 → `in_progress`）
6. `decision_required` 遷移 → 指摘対応判断フロー → ユーザー判断（千日手検出 / 修正・TECHNICAL_BLOCKER・OUT_OF_SCOPE 選択）
7. 全件解決 / defer 化されたら完了処理（シグナル生成 / レビュー後コミット 3 段階 / レビューサマリ更新 / セミオートゲート判定）

**関与するコンポーネント**: `review-flow.md`、`reviewing-common-base.md`、各 reviewing-* スキル

### ユースケース 2: defer 判定時の自動 Issue 起票

**ステップ**:

1. ReviewFinding が `disposition = out_of_scope | technical_blocker` に遷移
2. `DeferIssueRegistrar.register(finding)` 起動
3. `gh issue create --label backlog --label type:defer-from-review --title "..." --body-file ...` 実行
4. 起票成功 → `gh issue view <N> --json labels --jq '[.labels[].name]'` でラベル検証
5. 必須ラベル `backlog` と `type:defer-from-review` 両方の付与を確認
6. 全条件成功 → review-summary バックログ列に `#NNN` 記録
7. いずれか失敗 → review-summary バックログ列に `PENDING_MANUAL` 記録、warn 表示、review 自体は中断しない

**関与するコンポーネント**: `review-flow.md`（手順）、`gh` CLI（外部）、`review_summary_template.md`（記録）

### ユースケース 3: Round 4+ 新領域指摘の自動 backlog 化

**ステップ**:

1. ReviewSession が Round 4 に到達
2. `NewAreaDetector.extract_paths(rounds[1..3])` → Round 1〜3 のパス抽出
3. `NewAreaDetector.normalize(paths)` → 領域キーに正規化（境界条件テーブル + フォールバック規則）
4. `K_old = unique_sorted(area_keys_round_1_3)` を確定
5. Round 4 以降の各 round について同様に `K_new` を逐次更新
6. `K_diff = K_new - K_old` を計算
7. `K_diff` に該当する Round 4+ 指摘を「新領域指摘」と判定
8. 各新領域指摘について `NewAreaIssueRegistrar.register(judgment)` 起動 → `gh issue create --label backlog --label type:new-area-from-round4plus` → 起票後ラベル検証
9. 同 round 内で対応せず（次サイクルへ defer）
10. review-summary 末尾 `## Round 4 新領域判定` セクションに `K_old` / `K_new` / `K_diff` を JSON 配列で記録

**関与するコンポーネント**: `review-flow.md`、`review_summary_template.md`、`gh` CLI

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: review 1 round の所要時間に追加負荷なし（ドキュメント改修中心）
- **対応策**: ドキュメント改修のみで実行時オーバーヘッドなし。`gh issue view --json labels` 1 回追加のみ（API 呼び出し 1 回 + ラベル比較）

### セキュリティ

- **要件**: 起票時に機密情報（秘密鍵・トークン・内部機密パス）を Issue 本文に含めない
- **対応策**:
  - `review-flow.md` に起票前の機密情報マスク注意書きを追記
  - focus=security の OUT_OF_SCOPE は `SECURITY_PRIVATE` 扱い（公開 Issue 詳細記載禁止）またはマスク済み Issue 限定（脆弱性種類のみ、再現手順・影響範囲は禁止）

### スケーラビリティ

- **要件**: 単一ファイル群の改修のため考慮不要
- **対応策**: 該当なし

### 可用性

- **要件**: `gh` 不可時は warn 継続（review 自体は中断しない）
- **対応策**:
  - `gh issue create` 失敗 → warn 表示 + `PENDING_MANUAL` 記録 + review 継続
  - 起票後ラベル検証失敗 → 同上
  - `gh_status != available` → review 開始時から Issue 起票は warn + `PENDING_MANUAL`

## 技術選定

- **言語**: Markdown（ドキュメント本体）+ Bash（既存 sync / check スクリプト、本 Unit では改修なし）
- **フレームワーク**: AI-DLC スターターキット既存階層
- **ライブラリ**: `gh` CLI（v2 系、`gh issue view --json labels` の `[.labels[].name]` jq クエリ前提）
- **データベース**: 該当なし（GitHub Issues が外部ストア）

## 実装上の注意事項

- **削除対象を厳密に限定**: 「ユーザー判断に委ねる」「Issue 化保留」等の文言は defer 起票の裁量文言のみ削除し、スコープ保護確認 / 千日手判断 / 指摘対応判断フローのユーザー確認フローは維持する（計画レビュー指摘 #2 由来）
- **`reviewing-common-base.md` の同期判定 + sync-reviewing-common.sh 実行**: 5R / 完了条件 / 自動 Issue 起票に関する記述があれば正本同期 + sync-reviewing-common.sh 実行で各 reviewing-* スキルへ伝播。なくとも伝播経路の健全性確認のため `bin/sync-reviewing-common.sh` を実行する（計画レビュー指摘 #3 由来）
- **既存 BATS テスト追従**: `bin/tests/` および `tests/` 配下を grep し review-flow 記述（round 上限・完了条件・defer 扱い）に依存する既存テストがあれば 5R / 新フローに追従。検出されない場合は明示的に履歴記録（計画レビュー指摘 #1 由来）
- **`session-management.md` の `[3 回目]` 表記**: CLI セッション継続のサンプル例（独立コンテキスト）であり、5R 化に伴う直接書き換えは行わない（仕様変更ではない）
- **テンプレート履歴文言の補注**: `review_summary_template.md` の良い例 / 悪い例に含まれる「最大 3 回の反復制限を追記」等の履歴文言は本文の文脈として保持しつつ、テーブル直前または直後に「（注: 当時の上限値。本サイクル v2.5.2 以降は 5 回 / 完了条件は最後 2 round 連続で指摘ゼロまたは defer 化）」相当の補注 1 行を追記（外部検証指摘由来）

## 不明点と質問（設計中に記録）

[Question] `bin/sync-reviewing-common.sh` の現在の挙動は確認済みか（同期対象ファイル名 / 出力フォーマット）？  
[Answer] Phase 2 開始時に `cat bin/sync-reviewing-common.sh` で挙動を確認する。本論理設計では「同期コピー」「引数なし」のみ依存しており、既存挙動を変更しない。

[Question] 完了条件「最後 2 round 連続で指摘ゼロまたは defer 化」のうち、Round 1 で指摘 0 となった場合（1 round で完了）の扱いは？  
[Answer] 単一仕様として「1R clean 特例」を採用し、ドメインモデル / 論理設計 / `review-flow.md` の 3 箇所で完了規則を統一する。具体仕様:

- `rounds.size == 1 && rounds[0].is_clean()` → `completed`（1R clean 特例）
- `rounds.size >= 2 && last_two_rounds_clean` → `completed`（通常完了）
- `rounds.size >= 5 && unresolved_count > 0` → `decision_required`（指摘対応判断フロー起動）
- 上記いずれにも該当しない → `in_progress`

`ReviewCompletionEvaluator.evaluate` / `ReviewSession.is_completed()` / `CompletionCondition` 値オブジェクトはすべて本仕様で記述を揃える。

[Question] パス 2（セルフレビュー）でも 5R / 完了条件 / 新領域判定を適用するか？  
[Answer] 適用する。`review-flow.md` のパス 2 セクションに「反復・完了はパス 1 と同一」と既に明記されており、本 Unit でもこの整合性を維持する。`reviewing-common-base.md` のセルフレビュー指示テンプレートには round 上限の数値直書きはないため、改修不要。

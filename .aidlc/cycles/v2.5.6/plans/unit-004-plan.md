# Unit 004 計画: Inception Issue 選択フローで複数選択を前提化（D）

## 概要

`steps/inception/02-preparation.md` §16「GitHub Issue確認」の文言を改善し、AI エージェントが複数 Issue を 1 サイクルに含める提案を自然に行えるようにする。現状の「対応するIssueを選択させ」という単数形ニュアンスを残したまま、

1. 「複数選択可」を明示する文言の追加
2. `AskUserQuestion` で `multiSelect: true` を使う推奨呼び出し例の追加

の 2 点を §16 周辺に局所的に施す。Markdown 文言修正のみで実装範囲は最小。

## 関連 Issue

- #674（Inception 02-preparation §16 で複数 Issue 選択前提を明示化）

## スコープ境界

| 範囲 | 含む / 含まない |
|------|----------------|
| `steps/inception/02-preparation.md` §16「対応確認」サブセクションへの「複数選択可」明示文言追加 | 含む |
| `steps/inception/02-preparation.md` §16 への `AskUserQuestion(multiSelect: true)` 呼び出し例ブロック追加 | 含む |
| `story-artifacts/units/004-inception-issue-multiselect-clarification.md` の「関連Issue」反映確認 | 含む（既に #674 反映済みのため整合性チェックのみ） |
| `steps/inception/02-preparation.md` §16 以外（§15 / §17 等）への変更 | 含まない |
| Inception 03-intent / Operations / Construction 等の AskUserQuestion 呼び出し全般への文言改善 | 含まない（Intent §「明示的に除外するもの」で除外済み） |
| `AskUserQuestion` API 自体の設計見直し | 含まない |
| `scripts/check-open-issues.sh` の出力フォーマット変更 | 含まない |
| Milestone 紐付けロジック自体の変更 | 含まない（既に `SELECTED_ISSUES` の改行区切り保持で複数対応済み） |

## 完了条件チェックリスト（Definition of Done）

Unit 定義「責務」セクションおよび Issue #674 受け入れ基準より抽出。

### A. Unit 責務由来（必須）

- [ ] **A-1**: `steps/inception/02-preparation.md` §16「GitHub Issue確認」内に「複数選択可」を明示する文言が追加されている（例: 「対応する Issue を**複数選択可で**選択させ」）
- [ ] **A-2**: §16 内に `AskUserQuestion` 呼び出し例または推奨パターンが 1 ブロック以上追加されている。例には `multiSelect: true` の使用が含まれる
- [ ] **A-3**: 文言修正は §16 周辺の局所修正にとどまる（§15 / §17 等への波及なし、他の AskUserQuestion 呼び出し全般への言及なし）
- [ ] **A-4**: `story-artifacts/units/004-inception-issue-multiselect-clarification.md` の「関連Issue」セクションに採番済み Issue 番号 `#674` が反映されている（Inception 05-completion で既に反映済みであることを確認）

### B. Issue #674 受け入れ基準由来（必須）

- [ ] **B-1**: §16 内に「複数選択可」を明示する文言と AskUserQuestion 呼び出し例の両方が存在する
- [ ] **B-2**: 文言修正の局所性が保たれている（§16 周辺のみ、他 AskUserQuestion 呼び出し全般には言及しない）

### C. 品質基準（必須）

- [ ] **C-1**: `markdownlint` が 0 errors（**本 Unit で変更したファイルのみ**: `skills/aidlc/steps/inception/02-preparation.md` および `.aidlc/cycles/v2.5.6/plans/unit-004-plan.md` / `.aidlc/cycles/v2.5.6/design-artifacts/domain-models/unit_004_*.md` / `.aidlc/cycles/v2.5.6/design-artifacts/logical-designs/unit_004_*.md` / `.aidlc/cycles/v2.5.6/story-artifacts/units/004-*.md` / `.aidlc/cycles/v2.5.6/history/construction_unit04.md` / `.aidlc/cycles/v2.5.6/construction/units/004-review-summary.md`）。サイクル全体の lint は Cycle 完了時の別ゲートに委譲し、本 Unit ではブロックしない
- [ ] **C-2**: AI レビュー全ラウンド完了（設計レビュー / コードレビュー / 統合レビュー）。一次証跡は `.aidlc/cycles/v2.5.6/construction/units/004-review-summary.md`（**必須**、Phase 2 完了時点で生成）

### D. 補助基準（参考、本サイクル DoD 外）

- 後続サイクル運用で AI が `multiSelect: true` を自然に提案する確率が向上することを観測（観測タイミングは v2.5.6 以降の Inception フェーズ実行時、本サイクル DoD 外）

## 設計方針（Phase 1 で詳細化）

### ドメインモデル要素

- **対象ステップ**: Inception Phase の Preparation ステップ §16
- **修正カテゴリ**: 文言（自然言語ガイダンス）+ コード例（推奨パターン）
- **観測対象**: AI エージェントが §16 を読み込んで `AskUserQuestion` を構築する際の `multiSelect` パラメータ選択挙動

### 修正対象箇所（事前調査済み、Phase 1 で確定）

`steps/inception/02-preparation.md` の以下行が単数選択バイアスの主因:

- L46（対応確認テキスト内）: `1. はい - 選択したIssueをユーザーストーリーとUnit定義に追加する`
- L50（判定後のアクション説明）: `1を選択: 対応するIssueを選択させ、ユーザーストーリーとUnit定義に追加することを案内`

修正案（Phase 1 で確定）:

- L46: 「選択したIssue（複数可）」のように複数前提を明示
- L50: 「対応する Issue を**複数選択可で**選択させ、ユーザーストーリーとUnit定義に追加することを案内」と修正
- L50 直後または周辺に `AskUserQuestion` 呼び出し例ブロック（`multiSelect: true` を含む）を追加

### AskUserQuestion 呼び出し例（Phase 1 で文面確定）

```text
AskUserQuestion 推奨パターン:
- multiSelect: true（複数 Issue を 1 サイクルにまとめるユースケースが標準的なため）
- options に最大 4 件まで掲載（`AskUserQuestion` の制約）。5 件以上は Other で受け付け
- 質問文: 「これらの Issue のうち本サイクルに含めるものをすべて選択してください（複数可）」
```

## Phase 1（設計）成果物

| ファイル | 内容 |
|---------|------|
| `.aidlc/cycles/v2.5.6/design-artifacts/domain-models/unit_004_inception_issue_multiselect_clarification_domain_model.md` | 対象ステップのドメイン記述 / 修正カテゴリ / 影響範囲のモデル |
| `.aidlc/cycles/v2.5.6/design-artifacts/logical-designs/unit_004_inception_issue_multiselect_clarification_logical_design.md` | §16 への具体的な文言差分 / AskUserQuestion 呼び出し例ブロック / 完了条件マッピング |

## Phase 2（実装）成果物

| ファイル | 内容 |
|---------|------|
| `skills/aidlc/steps/inception/02-preparation.md` | §16 の文言修正 + AskUserQuestion 呼び出し例追加 |

> **注**: プラグインキャッシュ（`/Users/keisuke/.claude/plugins/cache/ai-dlc-starter-kit/aidlc/<commit>/skills/aidlc/steps/inception/02-preparation.md`）はリポジトリソースから生成される派生物。本 Unit ではリポジトリソース側のみ編集する。

## 完了処理成果物

| ファイル | 内容 |
|---------|------|
| `.aidlc/cycles/v2.5.6/story-artifacts/units/004-inception-issue-multiselect-clarification.md` | 状態を「完了」に更新、完了日記録 |
| `.aidlc/cycles/v2.5.6/history/construction_unit04.md` | Unit 004 履歴記録（プロンプト・実行内容・成果物総覧） |
| `.aidlc/cycles/v2.5.6/construction/units/004-review-summary.md` | AI レビューサマリ（**必須**、設計レビュー / コードレビュー / 統合レビューの一次証跡。計画レビューは `review-flow.md` の規定によりサマリ非生成） |

## 見積もり

- Phase 1（設計）: 0.05 日（修正対象が局所、ドメインモデル / 論理設計とも軽量）
- Phase 2（実装）: 0.05 日（Markdown 文言修正のみ）
- 完了処理: 0.05 日
- **合計: 約 0.15 日**（Unit 定義の見積もり「0.1 日」と概ね一致）

## リスク・留意点

- **LLM 解釈バイアスの完全排除は不可能**: 文言の明示化と推奨例の掲載でバイアスを軽減することが目的。残留バイアスは補助基準（後続サイクル観測）でモニタする
- **Markdown 構造の崩壊リスク**: 既存の §16 構造（対応確認テキストブロック / Milestone 紐付け処理 / コードフェンス）を壊さないよう、追加位置を慎重に決める
- **プラグインキャッシュとリポジトリソースの差分**: 編集はリポジトリソース側のみ。キャッシュは次回プラグイン更新で同期される（本 Unit 範囲外）

## 完了条件マッピング（`A-*` / `B-*` / `C-*` → 成果物）

| 完了条件 | 検証成果物 / 方法 |
|----------|------------------|
| A-1 | `steps/inception/02-preparation.md` §16 の修正後 grep 確認 |
| A-2 | `steps/inception/02-preparation.md` §16 の `AskUserQuestion` ブロック存在確認 |
| A-3 | `git diff` で §15 / §17 / 他ステップへの波及がないことを確認 |
| A-4 | `story-artifacts/units/004-*.md` の「関連Issue」grep 確認 |
| B-1 | A-1 + A-2 の合算 |
| B-2 | A-3 と同等 |
| C-1 | 本 Unit 変更ファイルに対する `markdownlint` 実行ログ |
| C-2 | `construction/units/004-review-summary.md` のレビューサマリ（必須成果物） |

## ブランチ戦略

- `unit_branch_enabled = false` のため、Unit 専用ブランチは作成しない
- `cycle/v2.5.6` ブランチ上で直接作業し、Unit 完了処理時に通常のコミット（必要に応じ squash）で記録

## 承認後の進行

1. 本計画承認
2. Phase 1: ドメインモデル → 論理設計 → 設計レビュー → 設計承認
3. Phase 2: コード生成 → コードレビュー → ビルド・テスト → 統合レビュー → 実装承認
4. 完了処理: 完了条件チェック → 履歴記録 → markdownlint → squash → コミット

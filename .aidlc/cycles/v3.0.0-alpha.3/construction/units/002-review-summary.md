# レビューサマリ: Unit 002 work-item-next.sh（依存解決による次 work item 選定）

## 基本情報

- **サイクル**: v3.0.0-alpha.3
- **フェーズ**: Construction
- **対象**: Unit 002 work-item-next.sh（依存解決による次 work item 選定）

<!-- 以下、AIレビュー完了時に Set が追記される -->

---

## Set 1: 2026-06-14 設計レビュー

- **レビュー種別**: 設計レビュー（reviewing-construction-design / focus: architecture）
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘対応判断完了（全 2 件 修正済み / Round 3 で指摘0件 clean）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 低 | `.aidlc/cycles/v3.0.0-alpha.3/design-artifacts/logical-designs/unit_002_work_item_next_logical_design.md` - 出力 `<relpath>` のパス基準が曖昧（引数 dir 相対 or 含むパスの揺れ）で Unit 003 入力契約として producer/consumer 解釈差が出る | 修正済み（`<path>` に統一し確定形式「`<work-items-dir 引数>/<filename>`（呼び出し時 cwd 基準 / 正規化・絶対化しない）」を明記。`relpath` 表記を `path` に統一） | - |
| 2 | 低 | `.aidlc/cycles/v3.0.0-alpha.3/design-artifacts/logical-designs/unit_002_work_item_next_logical_design.md` - 選定アルゴリズム手順 7 に「相対パスで」の旧表現が残り、引数絶対パス時の出力契約と矛盾（Round 2 検出） | 修正済み（手順 7 を「`<work-items-dir 引数>/<filename>` 形式の `<path>`（引数絶対なら出力も絶対）」へ統一） | - |

---

## Set 2: 2026-06-14 コードレビュー

- **レビュー種別**: コードレビュー（reviewing-construction-code / focus: code, security）
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘対応判断完了（全 1 件 修正済み / Round 2 で指摘0件 clean）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `skills/aidlc-v3/scripts/work-item-next.sh` - glob の辞書順を「id 昇順」とみなしており、非ゼロ埋め id（`2` vs `10`）で `10` が先に選定され論理設計の「id 昇順」と不一致（resume 複数時も同様） | 修正済み（`id_lt` ヘルパを追加し、両 id が数字のみなら `10#...` で base-10 数値昇順 / それ以外は文字列昇順。resume・pending 両方の選定を「最小 id 追跡」に変更。論理設計の id 昇順定義を数値優先に明確化。非ゼロ埋め id テスト 2 件追加） | - |

---

## Set 3: 2026-06-14 統合レビュー

- **レビュー種別**: 統合レビュー（focus: code / 設計-実装整合性・カバレッジ・完了条件）
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘対応判断完了（全 2 件 修正済み / Round 2 で指摘0件 clean）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `skills/aidlc-v3/scripts/tests/test-work-item-next.sh` - 終了コード規約テストが 0/1 までで exit 2 系（読み取り不可ディレクトリ / 読み取り不可 work item）が未網羅 | 修正済み（`chmod 000` の読み取り不可ディレクトリ・読み取り不可 work item ファイルで `assert_rc 2` を 2 件追加 / 通常ユーザー前提を明記） | - |
| 2 | 低 | `skills/aidlc-v3/scripts/tests/test-work-item-next.sh` - blocked 依存を持つ pending item が候補外になる専用 fixture がない（blocked 自身の候補外は別観点で確認済みだが「blocked 依存は非充足」が未検証） | 修正済み（`001 blocked` + `002 pending dependencies:["001"]` → `next:none` の fixture を追加） | - |

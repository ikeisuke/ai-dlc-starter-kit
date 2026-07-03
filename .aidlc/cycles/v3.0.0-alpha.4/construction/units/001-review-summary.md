# レビューサマリ: Unit 001 — 共有 frontmatter parser ライブラリ集約

## 基本情報

- **サイクル**: v3.0.0-alpha.4
- **フェーズ**: Construction
- **対象**: Unit 001（設計: ドメインモデル + 論理設計）

---

## Set 1: 設計レビュー（reviewing-construction-design / focus=architecture）

- **レビュー種別**: 設計レビュー（architecture）
- **使用ツール**: codex
- **反復回数**: 4
- **結論**: 指摘対応完了（Round 4 で指摘0件 / 全件修正済み・未解決0件）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `design-artifacts/logical-designs/unit_001_shared_frontmatter_parser_logical_design.md` - assigned の raw 値抽出が共有 API マッピングから漏れ、`fm_scalar`(loose) では `"a b"` と `a b` を区別できず既存境界を保存できない | 修正済み（logical_design.md: `fm_scalar_raw` を共有 API に追加 + マッピング表に assigned 行追加 / domain_model.md・ユビキタス言語も整合） | - |
| 2 | 高 | `design-artifacts/logical-designs/unit_001_shared_frontmatter_parser_logical_design.md` - conformance RC マトリクスが固定契約でない（#10/#12 が状況依存表記） | 修正済み（logical_design.md: #1〜#11 を「移行前実挙動==移行後」固定契約化 + #10 next=0 確定。#733 強化は別枠「意図的拒否強化セット」に分離。Intent 成功基準 intent.md:33 でスコープ内のため削除せず before/after 明記方式に整理） | - |
| 3 | 中 | `design-artifacts/domain-models/unit_001_shared_frontmatter_parser_domain_model.md` - RejectionReason（理由コード返却）が論理 API（stdout+return code のみ）と不整合 | 修正済み（domain_model.md: RejectionDecision に置換し「parser は return 1 のみ、理由コードは返さない、文言は consumer」で既存挙動保存） | - |
| 4 | 中 | `design-artifacts/logical-designs/unit_001_shared_frontmatter_parser_logical_design.md` - `fm_extract_block`/`fm_extract_body` の fail-closed 性が曖昧で未終端 partial parse のリスク | 修正済み（logical_design.md: extract API を fail-closed 内包に確定 + 呼び出し規約 `if ! fm="$(...)"` 明記） | - |
| 5 | 低 | `design-artifacts/logical-designs/unit_001_shared_frontmatter_parser_logical_design.md` - `fm_in_list` は構造解釈責務外で false DRY の入口 | 修正済み（logical_design.md: `fm_in_list` を frontmatter.sh から除外、in_list は consumer 維持） | - |
| 6 | 高 | `design-artifacts/logical-designs/unit_001_shared_frontmatter_parser_logical_design.md` - #733 拒否強化が全 consumer 一律 after=1 で過剰検証を誘発（R2） | 修正済み（logical_design.md: #733 セットを consumer 別 RC マトリクス化 + 対象 shared API 併記。読まない consumer は before=after 維持） | - |
| 7 | 中 | `design-artifacts/logical-designs/unit_001_shared_frontmatter_parser_logical_design.md` - API 一覧が古い（ツリーに fm_split_file/fm_in_list 残存、fm_scalar_raw 欠落、Q&A 矛盾）（R2） | 修正済み（logical_design.md: ツリーから fm_split_file/fm_in_list 削除・fm_scalar_raw 追加、Q&A を確定結論に統一） | - |
| 8 | 中 | `design-artifacts/domain-models/unit_001_shared_frontmatter_parser_domain_model.md` - domain 更新漏れ（Aggregate含有要素 RejectionReason 残存、スカラー 2 モード表記、ユビキタス言語に raw 欠落）（R2） | 修正済み（domain_model.md: RejectionDecision + Scalar(strict/loose/raw) に更新、3 モード明記、ユビキタス言語に raw 追加） | - |
| 9 | 中 | `design-artifacts/logical-designs/unit_001_shared_frontmatter_parser_logical_design.md` - source 例 `$dir/lib/...` が後段の SCRIPT_DIR 基準と SoT 割れ（R3） | 修正済み（logical_design.md: source 例を `$SCRIPT_DIR/lib/frontmatter.sh` に統一 + dir/SCRIPT_DIR 用語分離） | - |

> ラウンド別: R1=5件（高2/中2/低1 = #1-5）→ R2=3件（高1/中2 = #6-8）→ R3=1件（中 = #9）→ R4=0件。全件修正済み・未解決0件。

### Round 4 新領域判定

```json
{
  "K_old": ["cycle-artifacts"],
  "K_new": ["cycle-artifacts"],
  "K_diff": [],
  "rounds_executed": 4
}
```

全指摘が `.aidlc/cycles/v3.0.0-alpha.4/design-artifacts/**`（領域キー `cycle-artifacts`）に限局し、Round 4 で新領域差分なし（指摘0件のため新規指摘自体なし）。早期 defer ガイドの Round 別閾値（Round 3 で 5 件以上 / Round 4 で 3 件以上）はいずれも未到達（R3=1件 / R4=0件）。

---

## Set 2: コードレビュー（reviewing-construction-code / focus=code,security）

- **レビュー種別**: コードレビュー（code, security）
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘対応完了（Round 2 で指摘0件 / 全件修正済み・未解決0件）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `skills/aidlc-v3/scripts/tests/test-frontmatter-parser.sh` - conformance suite が未追加で、移行前後の受理/拒否境界保存を既存フロー系テストのみで担保している | 修正済み（`test-frontmatter-parser.sh` を追加: consumer 別 RC マトリクスを fixture 化、受理/拒否/#733 強化セットで全63 assertion パス） | - |
| 2 | 低 | `skills/aidlc-v3/scripts/lib/frontmatter.sh` - `fm_scalar`/`fm_scalar_raw`/`fm_key_count` が key を grep/sed の ERE に直接埋込（将来の外部入力 key で regex 注入リスク） | 修正済み（`lib/frontmatter.sh`: `_fm_valid_key`（`^[A-Za-z_][A-Za-z0-9_]*$`）を追加し 3 関数の key を検証、不正 key は return 1） | - |

> ラウンド別: R1=2件（中1/低1）→ R2=0件。全件修正済み・未解決0件。指摘1の解消として conformance suite（テスト生成ステップ）を前倒し実装。

### ビルド・テスト結果（v3 全スイート）

| テスト | 結果 |
|--------|------|
| test-frontmatter-parser.sh（新規 conformance） | All tests passed（63 assertion） |
| test-work-item-next.sh | All tests passed |
| test-develop-flow.sh | PASS=49 FAIL=0 |
| test-define-flow.sh | All tests passed |
| test-state-scripts.sh | All tests passed |
| test-activation.sh | All tests passed |

回帰なし（既存の受理/拒否境界を保存）。bash -n / shellcheck 全ファイルクリーン。Self-Healing: shellcheck SC1091（source 非追跡 info）を `disable=SC1091` で解消（attempt 1 / recoverable）。

---

## Set 3: 統合レビュー（reviewing-construction-integration / focus=code）

- **レビュー種別**: 統合レビュー（設計-実装整合性 / 完了条件 / テストカバレッジ / 規約）
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘対応完了（Round 2 で指摘0件 / 全件修正済み・未解決0件）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `skills/aidlc-v3/scripts/lib/frontmatter.sh` - `fm_scalar` loose の `grep \| head` 非一致が `set -euo pipefail` 下で公開 API として早期終了し得る（現 consumer は command substitution 経由で未顕在） | 修正済み（`lib/frontmatter.sh`: `fm_scalar`/`fm_deps` の `grep \| head` に `\|\| true` を付与。loose は空文字 return 0 / fail-closed は return 1 に正しく倒れる） | - |
| 2 | 低 | `skills/aidlc-v3/scripts/tests/test-frontmatter-parser.sh` - #733 強化セットが ad-hoc assert で `status_write` 列が欠落し設計の4列固定契約に対し薄い | 修正済み（`test-frontmatter-parser.sh`: #733-a/b/c を `matrix_case` 化し validate/next/status_read/status_write 全4列固定。#733-a=1/1/1/1、#733-b/c=1/1/0/0） | - |

> ラウンド別: R1=2件（中1/低1）→ R2=0件。全件修正済み・未解決0件。conformance は67 assertion に増加（全パス）。codex が `set -e` 下での fm_deps fail-closed も実証確認。

### 統合確認

- **設計-実装整合性**: 公開 API（fm_*）/ consumer 別 API マッピング / namespace（fm_/_fm_）/ fail-closed 内包 / enum=consumer 責務 が設計どおり実装に反映。乖離なし。
- **完了条件カバレッジ**: 計画 §5 チェックリスト全項目を実装・テストで充足（lib 新設 / 3 consumer 移行 / 規約文書化（lib header SoT）/ conformance / namespace / fail-closed / bash 3.2 互換 / 全テスト緑）。
- **規約**: 「個別 consumer での frontmatter 構造解釈禁止」を lib header に SoT 文書化。3 consumer に frontmatter 構造解釈の grep/sed/awk は残存せず（本文セクション検証 `^## ` と selection/transition の awk は frontmatter 構造解釈に非該当）。

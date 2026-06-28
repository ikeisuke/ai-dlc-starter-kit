# レビューサマリ: Unit 001 squash-unit.sh 複数 --message 段落結合修正

## 基本情報

- **サイクル**: v3.0.0-alpha.7
- **フェーズ**: Construction
- **対象**: Unit 001 squash-unit-multi-message

---

## Set 1: 設計レビュー

- **レビュー種別**: 設計レビュー（reviewing-construction-design / focus: architecture）
- **使用ツール**: codex
- **反復回数**: 4
- **結論**: 指摘0件（Round 4 で clean / 全指摘修正済み）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `.aidlc/cycles/v3.0.0-alpha.7/design-artifacts/domain-models/unit_001_squash_unit_multi_message_domain_model.md`, `.aidlc/cycles/v3.0.0-alpha.7/design-artifacts/logical-designs/unit_001_squash_unit_multi_message_logical_design.md` - compose_full_message の dedup が message 側のみで co_authors 内部の正規化キー重複を排除しない（既存 `sort -u` は raw 比較で case 差を残す） | 修正済み（両ファイル: 採用キーを `seen` に蓄積し co_authors 内部重複も一意化する契約に変更） | - |
| 2 | 中 | `.aidlc/cycles/v3.0.0-alpha.7/design-artifacts/logical-designs/unit_001_squash_unit_multi_message_logical_design.md` - 論理設計冒頭にステップ0（事前コード読込み (a)(b)(c)）が欠落 | 修正済み（論理設計 L9-: ステップ0 セクション追加） | - |
| 3 | 中 | `.aidlc/cycles/v3.0.0-alpha.7/design-artifacts/domain-models/unit_001_squash_unit_multi_message_domain_model.md`, `.aidlc/cycles/v3.0.0-alpha.7/design-artifacts/logical-designs/unit_001_squash_unit_multi_message_logical_design.md` - dedup 比較キーで「値部原文比較」と「case/空白差吸収」が矛盾（コロン後空白差が残る） | 修正済み（両ファイル: 正規化キーを 行trim/トレーラ名case-insensitive/コロン後空白畳み/値部trim に精緻化） | - |
| 4 | 低 | `.aidlc/cycles/v3.0.0-alpha.7/design-artifacts/logical-designs/unit_001_squash_unit_multi_message_logical_design.md` - `--message` 表が「必須」だが dry-run 時は空許容で内部矛盾 | 修正済み（論理設計: 「非 dry-run 時必須 / dry-run 時任意」に明記） | - |
| 5 | 低 | `.aidlc/cycles/v3.0.0-alpha.7/design-artifacts/domain-models/unit_001_squash_unit_multi_message_domain_model.md` - ユビキタス言語内の dedup キー記述が旧文言「値部は原文」のまま詳細定義と矛盾 | 修正済み（ドメインモデル: 詳細定義と統一） | - |

### Round 4 新領域判定

```json
{
  "K_old": [],
  "K_new": [],
  "K_diff": [],
  "rounds_executed": 4
}
```

Round 4 は指摘0件（clean）のため Round 4+ 新領域指摘なし。新領域判定の境界条件・判定手順は `skills/aidlc/steps/common/review-flow.md` の「Round 4 以降の新領域指摘の自動 backlog 化フロー」を参照。

---

## Set 2: コードレビュー

- **レビュー種別**: コードレビュー（reviewing-construction-code / focus: code, security）
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘対応判断完了（Round 1 修正 / Round 2 は OUT_OF_SCOPE defer）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 低 | `bin/tests/squash-unit/message_compose.bats` - retroactive の純関数テストのみで実 CLI 経路（`extract_co_authors_for_range` → `build_commit_message_file` → rebase editor）の接続が未検証 | 修正済み（message_compose.bats: `--retroactive --unit 001 --from/--to` の統合テストを 1 件追加。subject 保持 + Co-Authored-By 1 回のみを検証） | - |
| 2 | 低 | `skills/aidlc/scripts/squash-unit.sh` - `find_unit_commit_range_git` の `--from/--to` 経路（385 行）が `${FROM_COMMIT}^..` を直書きしており `--from` がルートコミットの場合に失敗（既存コードの不整合 / `safe_log_range` 不使用） | OUT_OF_SCOPE（理由: Unit 001 は `--message` 段落結合 + Co-Authored-By 重複排除が責務。retroactive 範囲特定のルート対応は対象外の既存コード不整合で、本変更の回帰ではない） | #740 |

> セキュリティ: focus=security 該当指摘なし。CLI ツール（ネットワーク通信なし）のため OWASP/HTTP/ネットワーク観点は N/A。codex は glob 文字入りトレーラでの dedup 誤爆なし・bash 3.2 互換・`set -e` 安全性を実機検証済み。

---

## Set 3: 統合レビュー

- **レビュー種別**: 統合レビュー（reviewing-construction-integration / focus: code）
- **使用ツール**: codex
- **反復回数**: 1
- **結論**: 指摘0件（1R clean 特例）

### 指摘一覧

指摘0件。

> 検証内容: (1)設計乖離なし — 論理設計の `compose_full_message` 契約（stdout / 末尾改行なし / 純関数 / dedup 正規化キー）と両経路収束（`squash_git` / `build_commit_message_file` が共に委譲）が実装と一致。(2)レビュー・テスト実施済み — bats 14 件全パス、コードレビュー完了（Set 2）。(3)完了条件 — 計画チェックリストと Unit 責務（段落結合 / Co-Authored-By 二重出力解消 / 回帰テスト / help 更新 / 単一 message 後方互換 / v3 非変更）を全て充足。

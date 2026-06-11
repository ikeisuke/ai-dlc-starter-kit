# Unit: v3 成果物テンプレート

## 概要

`skills/aidlc-v3/templates/` に v3 の成果物テンプレート 3 種（intent.md / work-item.md / journal.md）を作成する。`docs/v3/data-model.md` §4（work item frontmatter / 本文必須セクション）および journal 形式に準拠した確定テンプレートを置く。

## 含まれるユーザーストーリー
- ストーリー 2: v3 成果物テンプレートを確定する

## 責務
- `templates/intent.md`: v3 Intent 構成（目的 / スコープ（含む・含まない）/ 受け入れ基準等）
- `templates/work-item.md`: frontmatter（必須キー id/status/size/risk/assigned/dependencies + 各 enum）+ 本文必須 6 セクション（`Goal`, `Scope`, `Acceptance Criteria`, `Traceability`, `Size / Risk`（単一見出し）, `Dependencies`）
- `templates/journal.md`: 追記型 journal 形式（日付見出し + 箇条書き）

## 境界
- テンプレートを使ってファイルを実生成する define フロー実装は対象外（Phase 3）
- frontmatter / journal の正本は `docs/v3/data-model.md`（本 Unit は準拠する）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- 入力: `docs/v3/data-model.md` §4（work item template / frontmatter / 本文必須セクション）, journal 形式

## 非機能要件（NFR）
- **整合性**: frontmatter キー・enum 値（status: pending/in_progress/blocked/done/withdrawn、size: tiny/normal/risky、risk: low/medium/high）が SoT と一致
- **共存**: 成果物は `skills/aidlc-v3/templates/` に限定し、v2 に非影響
- **lint**: markdownlint 通過

## 技術的考慮事項
- enum 値の取りこぼし・表記揺れを避け、`docs/v3/data-model.md` §4 と完全一致させる
- placeholder 記法はテンプレートとして自然な形（例: `{{...}}` または説明コメント）に統一

## 関連Issue
- なし

## 実装優先度
High

## 見積もり
テンプレート 3 ファイル（小）。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -

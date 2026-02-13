# Unit: aidlc-upgradeスキル改善

## 概要
aidlc-upgradeスキルをagentskills.ioベストプラクティスに準拠させ、#181対応（setup-prompt.md検索効率化）を実装する。外部プロジェクトでの不要な再帰検索を排除する。

## 含まれるユーザーストーリー
- ストーリー 8: aidlc-upgradeスキルの改善

## 責務
- SKILL.md frontmatterのdescriptionを三人称に変更
- SKILL.md frontmatterのnameがagentskills.io仕様を満たすことを確認・修正（小文字英数字+ハイフン）
- プロジェクト内の命名パターン統一のためスキル名をリネーム（`aidlc-upgrade` → `upgrading-aidlc`）※ユーザー指示によるスコープ拡張
- 検索フローの更新: (1) `prompts/setup-prompt.md` の存在確認を1回実行 (2) 存在しない場合は `docs/aidlc.toml` から `ghq root` 経由のパスを解決 (3) Glob等の再帰検索は行わない

## 境界
- setup-prompt.md自体の変更は含まない
- aidlc-upgradeの新機能追加は含まない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- agentskills.io仕様（https://agentskills.io/specification）

## 非機能要件（NFR）
- 該当なし（43行の小規模スキル）

## 技術的考慮事項
- 現状の検索フロー: `prompts/setup-prompt.md` → Glob検索 → `docs/aidlc.toml` + ghq
- 改善後: `prompts/setup-prompt.md` 存在確認 → 不在なら即 `docs/aidlc.toml` 経由（再帰検索なし）

## 関連Issue
- #181

## 受け入れ基準
- [ ] SKILL.md frontmatterのnameが小文字英数字+ハイフンのみで構成されている
- [ ] SKILL.md frontmatterのdescriptionが三人称で記述されている
- [ ] SKILL.mdに検索フローが記載されている: (1) `prompts/setup-prompt.md` 存在確認を1回実行 (2) 不在時は `docs/aidlc.toml` 経由で解決 (3) Glob等の再帰検索は行わない

## 実装優先度
Medium

## 見積もり
0.25日（SKILL.md内のフロー記述修正 + frontmatter修正。43行の小規模スキルのため影響範囲は限定的）

---
## 実装状態

- **状態**: 進行中
- **開始日**: 2026-02-14
- **完了日**: -
- **担当**: @claude

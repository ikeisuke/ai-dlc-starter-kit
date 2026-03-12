# Unit: aidlc-setupリネーム

## 概要
`upgrading-aidlc` スキルを `aidlc-setup` にリネームし、関連する全参照箇所を更新する。他のUnitでリネーム後の名前を前提とするため、最初に実施する。

## 含まれるユーザーストーリー
- ストーリー 3: upgrading-aidlc → aidlc-setup リネーム

## 責務
- `prompts/package/skills/upgrading-aidlc/` → `prompts/package/skills/aidlc-setup/` のディレクトリリネーム
- `upgrade-aidlc.sh` → `aidlc-setup.sh` のスクリプトリネーム
- CLAUDE.md, AGENTS.md, ai-tools.md, operations.md 等のスキル参照更新
- シンボリックリンクの更新（`.claude/skills/`, `.kiro/skills/`）
- 旧名の完全削除（`prompts/package/skills/`, `docs/aidlc/skills/`, `.claude/skills/`）

## 境界
- スクリプト内部のロジック変更は行わない（パス参照のみ更新）
- 名前空間プレフィックスの導入はUnit 003で実施

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- `aidlc-setup.sh` 内の `resolve_script_dir()` がシンボリックリンクを追跡するため、リネーム後のパスでの動作確認が必要
- 旧名は本リリースで完全削除（v1.19.0で非推奨化済みのため互換期間不要）
- 編集は `prompts/package/` 側で行う（メタ開発ルール）
- `grep -r upgrading-aidlc` で旧名残留がないことを確認

## 実装優先度
High

## 見積もり
小規模（ファイルリネーム＋参照更新）

## 関連Issue
- #292

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -

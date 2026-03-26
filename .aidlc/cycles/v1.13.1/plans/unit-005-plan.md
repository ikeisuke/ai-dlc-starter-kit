# Unit 005 計画: アップグレードスキル化

## 概要

アップグレード処理（setup-prompt.md）をスキルとして定義し、`/aidlc-upgrade`コマンドで呼び出せるようにする。

**命名規則**: AI-DLC関連スキルは `aidlc-` プレフィックスで統一する（将来の拡張性を考慮）。

## 変更対象ファイル

| ファイル | 変更種別 | 説明 |
|----------|----------|------|
| `prompts/package/skills/aidlc-upgrade/SKILL.md` | 新規作成 | アップグレードスキル定義 |
| `prompts/package/prompts/AGENTS.md` | 修正 | スキル参照を追加 |

## 実装計画

### Phase 1: 設計

1. **スキルファイル構造の確認**
   - 既存スキル（codex-review等）の構造を参考にする
   - YAML frontmatter: name, description, argument-hint
   - 本文: 使用方法とリダイレクト先の説明

2. **AGENTS.md変更箇所の特定**
   - 「AIツール対応」セクションにスキル参照を追加

### Phase 2: 実装

1. **スキルファイル作成**
   - `prompts/package/skills/aidlc-upgrade/SKILL.md` を新規作成
   - setup-prompt.mdへのリダイレクト的な役割を定義

2. **AGENTS.md更新**
   - スキル参照テーブルにupgradeスキルを追加

3. **動作確認**
   - スキルの参照パスが正しいことを確認

## 完了条件チェックリスト

- [ ] `docs/aidlc/skills/aidlc-upgrade/SKILL.md`の新規作成（ソース: `prompts/package/skills/aidlc-upgrade/SKILL.md`）
- [ ] AGENTS.mdへのスキル参照追加

## 関連Issue

- #133（部分）

## 技術的考慮事項

- 既存のスキル（codex-review等）の構造を参考にする
- スキルはsetup-prompt.mdへのリダイレクト的な役割
- rsync同期のためprompts/package/skills/配下に作成
- `allowed-tools` は不要（読み取りとリダイレクトのみ）
- スキル名は `aidlc-upgrade`（将来の拡張性を考慮したプレフィックス統一）

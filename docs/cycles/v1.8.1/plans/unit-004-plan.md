# Unit 004 計画: AIレビュー設定改善

## 概要

AIレビュー設定をSkills優先（MCPフォールバック）方式に改善し、様々なツール環境で一貫して利用できるようにする。

## 背景

- **現状の問題**: `rules.md`では「Skill ツールの codex を使用する」と記載されているが、各プロンプト（inception/construction/operations.md）では`mcp__codex__codex`を参照している（矛盾）
- **関連Issue**: #70, #73

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/prompts/inception.md` | AIレビューセクションをSkills優先+MCPフォールバックに修正 |
| `prompts/package/prompts/construction.md` | AIレビューセクションをSkills優先+MCPフォールバックに修正、反復レビュー後の継続確認追加 |
| `prompts/package/prompts/operations.md` | AIレビューセクションをSkills優先+MCPフォールバックに修正 |

**確認済み**: setup.mdは対象外（AIレビュー設定セクションが存在しないため）

## 実装計画

### Phase 1: 設計

1. **Skills/MCP切り替えフローの設計**
   - Skills利用可否の判定方法を明確化
   - MCPフォールバック時のフローを定義
   - 反復レビュー改善: 3回後に継続確認フローを追加（Issue #73対応）

2. **ドメインモデル・論理設計**
   - 各プロンプトの修正箇所を特定
   - 統一されたAIレビューフローを設計

### Phase 2: 実装

1. **inception.md の修正**
   - AIレビュー優先ルールセクションの書き換え
   - Skills優先判定ロジックの追加

2. **construction.md の修正**
   - 同様にSkills優先に変更
   - 反復レビューフローの維持（または改善）

3. **operations.md の修正**
   - 同様にSkills優先に変更

4. **検証**
   - markdownlintの実行（設定がfalseのためスキップ）
   - フローの整合性確認

## 完了条件チェックリスト

- [ ] inception.mdのAIレビュー設定をSkills優先+MCPフォールバックに修正
- [ ] construction.mdのAIレビュー設定を同様に修正
- [ ] operations.mdのAIレビュー設定を同様に修正
- [ ] Skills/MCP切り替えフローの明確化
- [ ] 反復レビュー3回後の継続確認フローを追加
- [ ] 変更後の各mdファイルが一貫した記述になっていること

## 確認済み事項

1. **setup.md**: 対象外（AIレビュー設定セクションが存在しないため）
2. **反復レビュー回数**: 3回後にユーザーに継続確認を求めるフローを追加（Issue #73対応）

# Unit: AIレビュー設定改善

## 概要

AIレビュー設定をSkills優先（MCPフォールバック）方式に改善し、様々なツール環境で一貫して利用できるようにする。

## 含まれるユーザーストーリー

- ストーリー 4: AIレビュー設定の改善（Skills優先、MCPフォールバック）

## 関連Issue

- #70
- #73

## 責務

- setup.mdのAIレビュー設定をSkills優先+MCPフォールバックに修正
- inception.mdのAIレビュー設定を同様に修正
- construction.mdのAIレビュー設定を同様に修正
- operations.mdのAIレビュー設定を同様に修正
- Skills/MCP切り替えフローの明確化
- 変更後の各mdファイルがmarkdownlintをパスすることを確認

## 境界

- Skillsの実装やMCPの実装は行わない（既存機能を利用）
- aidlc.tomlの設定項目追加は行わない（バックログ #82 で対応）

## 依存関係

### 依存するUnit

- 001-env-info-integration（依存理由: setup.mdを先に編集してもらい、その後にAIレビュー設定を追加）
- 002-write-history-integration（依存理由: inception/construction/operations.mdを先に編集してもらい、競合を回避）
- 003-label-cycle-issues（依存理由: inception.mdを先に編集してもらい、競合を回避）

### 外部依存

- Claude Code（Skills対応ツール）
- Codex MCP（MCPフォールバック用）

## 非機能要件（NFR）

- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項

- Skills対応ツール: Claude Code
- Skillツール呼び出し: `Skill tool: skill="codex"`
- MCPフォールバック: `codex exec -s read-only -C <dir> "<prompt>"`
- 判定フロー: Skills利用可能 → Skills使用、不可 → MCP使用

## 実装優先度

High

## 見積もり

中規模（4ファイルのAIレビューセクション修正）

---

## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -

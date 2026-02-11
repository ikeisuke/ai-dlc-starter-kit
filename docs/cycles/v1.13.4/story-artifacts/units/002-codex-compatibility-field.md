# Unit: Codex skills compatibilityフィールド追加

## 概要
Codex skillsのSKILL.mdにcompatibilityフィールドを追加し、サンドボックス要件を明記する。

## 含まれるユーザーストーリー
- ストーリー 2: Codex skills compatibilityフィールド追加（#178）

## 関連Issue
- #178

## 責務
- `codex-review/SKILL.md` にcompatibilityフィールドを追加
- ネットワークアクセス等のサンドボックス要件を明記
- Agent Skills Specification v1.0準拠の形式で記載

## 境界
- ランタイムでのサンドボックス制御は含まない（ドキュメント用途のみ）
- 他のスキル（claude-review, gemini-review等）のcompatibilityフィールドは含まない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- [Agent Skills Specification v1.0](https://agentskills.io/specification)

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- メタ開発: `prompts/package/skills/codex-review/SKILL.md` を編集
- compatibilityフィールドは最大500文字（Codex仕様の上限）

## 実装優先度
Medium

## 見積もり
小（フィールド追加のみ）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -

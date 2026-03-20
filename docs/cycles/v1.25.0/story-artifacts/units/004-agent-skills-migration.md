# Unit: .kiro/skills → .agent/skills 移行

## 概要
スキルディレクトリを `.kiro/skills` から `.agent/skills` に移行し、関連する全参照を更新する。エージェント定義ディレクトリ（`.kiro/agents` → `.agent/agents`）も同時に移行する。

## 含まれるユーザーストーリー
- ストーリー 5: .kiro/skills → .agent/skills 移行

## 責務
- `setup-ai-tools.sh` の `setup_kiro_skills()` → `setup_agent_skills()` リネームとターゲットディレクトリ変更
- `setup-ai-tools.sh` の `setup_kiro_agent()` → `setup_agent_agents()` リネームとターゲットディレクトリ変更（`.kiro/agents/` → `.agent/agents/`）
- `setup-prompt.md` 内の全 `.kiro/skills`, `.kiro/agents` 参照を `.agent/skills`, `.agent/agents` に更新
- `.kiro/agents/aidlc-poc.json` を `.agent/agents/` にコピー
- 既存ディレクトリのバックアップ機能
- 破壊的変更のCHANGELOG記載とアップグレード手順提供
- リポジトリ内の参照残存0件検証

## 境界
- スキル定義形式の変更は含まない
- `.kiro/skills` 互換リンクの維持は含まない（完全移行）
- 過去サイクルの履歴ドキュメント内の参照は変更しない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: シンボリックリンクの相対パス形式を維持（パストラバーサル防止）
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- 変更対象: `prompts/package/bin/setup-ai-tools.sh`, `prompts/setup-prompt.md`, `.kiro/` → `.agent/` ディレクトリ
- 自己修復機能（壊れたシンボリックリンク検出・修復）はそのまま引き継ぐ
- 検証コマンド: `rg ".kiro/skills" --glob "!docs/cycles/v1.*/" --glob "!CHANGELOG.md"` および `rg ".kiro/agents" --glob "!docs/cycles/v1.*/" --glob "!CHANGELOG.md"`

## 関連Issue
- #347

## 実装優先度
Medium

## 見積もり
M（3ポイント）— 主要タスク: setup-ai-tools.sh 関数変更、setup-prompt.md 参照更新、ディレクトリ移行、CHANGELOG記載（計3ファイル変更 + ディレクトリ操作）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-20
- **完了日**: 2026-03-20
- **担当**: -

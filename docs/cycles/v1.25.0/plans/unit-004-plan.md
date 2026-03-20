# Unit 004 計画: .kiro/skills → .agents/skills 移行

## 概要

スキルディレクトリを `.kiro/skills` から `.agents/skills` に移行する。エージェント定義（`.kiro/agents`）は移行対象外で `.kiro/agents` のまま維持する。関連する skills 参照を全て更新する。

## 変更対象ファイル

| ファイル | 変更種別 | 概要 |
|---------|---------|------|
| `prompts/package/bin/setup-ai-tools.sh` | 修正 | `setup_kiro_skills()` → `setup_agent_skills()` リネーム、ターゲットディレクトリ `.kiro/skills` → `.agents/skills` |
| `prompts/setup-prompt.md` | 修正 | `.kiro/skills` 参照を `.agents/skills` に更新（`.kiro/agents` はそのまま） |
| `prompts/package/guides/skill-usage-guide.md` | 確認 | `.kiro/skills` 参照があれば更新 |
| `prompts/package/prompts/common/ai-tools.md` | 確認 | `.kiro/skills` 参照があれば更新 |

## 設計方針

### 移行対象

- **skills のみ移行**: `.kiro/skills` → `.agents/skills`
- **agents は移行しない**: `.kiro/agents` はそのまま維持

### 関数リネーム

| 旧名 | 新名 | 変更内容 |
|------|------|---------|
| `setup_kiro_skills()` | `setup_agent_skills()` | ターゲット: `.kiro/skills` → `.agents/skills` |
| `setup_kiro_agent()` | 変更なし | `.kiro/agents` のまま維持 |

## 実装計画

### Phase 2: 実装

#### ステップ4: コード生成

1. `setup-ai-tools.sh` の関数リネームとパス更新（skills のみ）
2. `setup-prompt.md` の `.kiro/skills` 参照を `.agents/skills` に更新
3. その他ファイルの `.kiro/skills` 参照を確認・更新
4. 破壊的変更のCHANGELOG記載

#### ステップ5: テスト

- `.kiro/skills` の参照残存0件を検証（過去サイクル履歴・CHANGELOG除く）

#### ステップ6: 統合とレビュー

- Markdownlint
- AIレビュー

## 完了条件チェックリスト

- [ ] `setup-ai-tools.sh` の `setup_kiro_skills()` → `setup_agent_skills()` リネームとターゲットディレクトリ変更が完了している
- [ ] `setup-prompt.md` 内の `.kiro/skills` 参照が `.agents/skills` に更新されている
- [ ] 破壊的変更のCHANGELOG記載とアップグレード手順が提供されている
- [ ] リポジトリ内の `.kiro/skills` 参照残存0件が検証されている（過去サイクル履歴・CHANGELOG除く）

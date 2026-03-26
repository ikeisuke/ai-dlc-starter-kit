# Unit 004: aidlcスキル - 共通基盤 - 計画

## 概要

統合オーケストレーターSKILL.md（~200行）を作成し、`steps/common/` に共通ステップを配置する。フェーズ固有ステップは後続Unit（005-008）で実装。

## 方針

- PoC結果: オンデマンドRead・スキル間呼び出し両方supported → ステップ分割アーキテクチャ採用
- SKILL.md本文は200行以内（500行ERRORルール対応）
- 各ステップは `steps/common/` にMarkdownファイルとして配置
- SKILL.md内でReadツールによるオンデマンド読み込み指示

## SKILL.md設計

### frontmatter

```yaml
---
name: aidlc
description: >
  AI-DLC（AI-Driven Development Lifecycle）の統合オーケストレーター。
  フェーズ（inception/construction/operations）の開始・継続、
  セットアップ、エクスプレスモード、フィードバック送信を統一的に実行する。
  Use when the user says "インセプション進めて", "start inception",
  "コンストラクション進めて", "start construction",
  "オペレーション進めて", "start operations",
  "start express", "start setup", "AIDLCフィードバック", "aidlc feedback",
  or any AI-DLC phase command.
argument-hint: "[inception|construction|operations|setup|express|feedback|lite inception|lite construction|lite operations]"
---
```

### 本文構成（~200行）

1. **概要・トリガー条件**: 引数→フェーズマッピング表
2. **共通初期化フロー**: プロジェクトルート検出、config.toml確認、preflight
3. **フェーズルーティング**: 引数解析 → 対応ステップファイル群の Read 指示
4. **Expressモード遷移**: フェーズ完了後の自動遷移ロジック
5. **コンパクション復帰**: コンテキスト圧縮後の復帰手順

### SKILL.md内のステップ読み込みパターン

```markdown
次のファイルを読み込んでください:
- `steps/common/preflight.md`
- `steps/common/rules.md`
```

## steps/common/ ファイルマッピング

| 移行元（docs/aidlc/prompts/common/） | 移行先（skills/aidlc/steps/common/） | 行数 | 備考 |
|---------------------------------------|--------------------------------------|------|------|
| preflight.md | preflight.md | 225 | スクリプトパスはUnit 003で更新済み |
| rules.md | rules.md | 652 | |
| compaction.md | compaction.md | 71 | |
| commit-flow.md | commit-flow.md | 438 | |
| review-flow.md | review-flow.md | 1,158 | 最大ファイル |
| session-continuity.md | session-continuity.md | 56 | |
| context-reset.md | context-reset.md | 50 | |
| agents-rules.md | agents-rules.md | 80 | |

### 本Unitで移行しないファイル

| ファイル | 理由 |
|---------|------|
| intro.md | 26行。SKILL.md本文に統合 |
| project-info.md | 19行。SKILL.md本文に統合 |
| phase-responsibilities.md | 5行。SKILL.md本文に統合 |
| progress-management.md | 5行。SKILL.md本文に統合 |
| ai-tools.md | 90行。AGENTS.mdに残す（ツール選択はフェーズ非依存） |
| feedback.md | 63行。SKILL.md本文のfeedbackルーティングに統合 |

## 設定ファイル

### config.toml.example

`.aidlc/config.toml` のサンプルファイルを `skills/aidlc/config/` に配置。

### defaults.toml

既に `skills/aidlc/config/defaults.toml` に移動済み（Unit 003）。変更不要。

## marketplace.json更新

スキル一覧に `./skills/aidlc` を追加。

## .claude/skills/ シンボリックリンク

`aidlc` → `../../skills/aidlc` のシンボリックリンクを追加。

## 変更対象ファイル

### 新規
- `skills/aidlc/SKILL.md`
- `skills/aidlc/steps/common/preflight.md`
- `skills/aidlc/steps/common/rules.md`
- `skills/aidlc/steps/common/compaction.md`
- `skills/aidlc/steps/common/commit-flow.md`
- `skills/aidlc/steps/common/review-flow.md`
- `skills/aidlc/steps/common/session-continuity.md`
- `skills/aidlc/steps/common/context-reset.md`
- `skills/aidlc/steps/common/agents-rules.md`
- `skills/aidlc/config/config.toml.example`

### 更新
- `.claude-plugin/marketplace.json`
- `.claude/skills/` （シンボリックリンク追加）

## 実装手順

1. `skills/aidlc/steps/common/` ディレクトリ作成
2. 共通ステップファイルをコピー（内容はUnit 003で更新済みのパスを使用）
3. SKILL.md作成（frontmatter + 本文~200行）
4. config.toml.example作成
5. marketplace.json にaidlcスキル追加
6. .claude/skills/aidlc シンボリックリンク作成
7. 動作確認

## 完了条件チェックリスト

- [ ] SKILL.md が200行以内で作成されている
- [ ] frontmatter の description にトリガー条件が含まれている
- [ ] steps/common/ に8つの共通ステップが配置されている
- [ ] SKILL.md 内で各ステップのRead指示が記述されている
- [ ] marketplace.json にaidlcスキルが登録されている
- [ ] .claude/skills/aidlc シンボリックリンクが正しく設定されている
- [ ] 引数なしまたは不正な引数でヘルプが表示される設計になっている

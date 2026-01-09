# AGENTS.md と CLAUDE.md への AI-DLC 統合

- **発見日**: 2025-12-28
- **発見フェーズ**: Inception
- **発見サイクル**: v1.5.3
- **優先度**: 中

## 概要

AGENTS.md に AI-DLC スターターキットのことを記載することで、AI エージェントからの呼び出しを簡易化する。また CLAUDE.md には @AGENTS.md を参照するように記載することで、他の AI コーディングエージェントからも認識させる。

## 詳細

**現状**:
- AI-DLC スターターキットの利用開始には、プロンプトファイルのパスを直接指定する必要がある
- AI コーディングエージェント（Claude Code 等）が AI-DLC の存在を自動認識できない

**期待する動作**:
1. AGENTS.md に AI-DLC スターターキットの情報を記載
   - 利用可能なプロンプトファイル
   - 各フェーズの開始方法
   - 推奨されるワークフロー
2. CLAUDE.md に @AGENTS.md への参照を記載
   - 他の AI エージェントも AGENTS.md を参照できるようになる

## 対応案

### AGENTS.md への追記
```markdown
## AI-DLC スターターキット

このプロジェクトは AI-DLC (AI-Driven Development Lifecycle) を使用しています。

### サイクル開始
- セットアップ: `prompts/setup-prompt.md` を読み込み
- Inception Phase: `docs/aidlc/prompts/inception.md` を読み込み
- Construction Phase: `docs/aidlc/prompts/construction.md` を読み込み
- Operations Phase: `docs/aidlc/prompts/operations.md` を読み込み
```

### CLAUDE.md への追記
```markdown
@AGENTS.md を参照してください。
```

## 影響範囲

- AGENTS.md（新規作成または追記）
- CLAUDE.md（新規作成または追記）

## 備考

このバックログは v1.5.3 の Inception Phase 中に追加されました。次回以降のサイクルで対応を検討してください。

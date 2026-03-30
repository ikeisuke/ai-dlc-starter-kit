# Unit 004 計画: Setup/Inception統合（Lite版）

## 概要

Lite版のInception PhaseプロンプトにSetup統合の説明を追加し、通常版との一貫性を保つ。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `docs/aidlc/prompts/lite/inception.md` | 統合に関する注意書きを追加 |

## 実装計画

### Phase 1: 設計

このUnitは小規模なプロンプト修正のため、設計フェーズは簡略化する。

- パッケージ版 (`prompts/package/prompts/lite/inception.md`) の変更点を確認
- 差分を `docs/aidlc/prompts/lite/inception.md` に反映

### Phase 2: 実装

1. `docs/aidlc/prompts/lite/inception.md` に以下を追加:
   - 「Full版はSetup PhaseとInception Phaseが統合されています」の注意書き
   - 「Lite版は既存サイクルでの使用が前提のため、Setup部分は自動スキップされます」の説明

## 完了条件チェックリスト

- [ ] Lite版統合プロンプトの更新（`docs/aidlc/prompts/lite/inception.md`）
- [ ] パッケージ版との内容一致確認

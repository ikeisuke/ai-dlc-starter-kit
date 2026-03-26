# Unit 003: Markdownlint対象範囲の最適化 - 実装計画

## 概要

Construction PhaseでのMarkdownlint実行時に、過去サイクルのファイルを除外し、効率的なlint実行を実現する。

## 現状分析

| ファイル | 現在の対象範囲 | 問題 |
|----------|---------------|------|
| `construction.md` | `docs/**/*.md` | 過去サイクル含む |
| `operations.md` | `docs/cycles/{{CYCLE}}/**/*.md` | 現在サイクルのみ（OK） |

## 修正方針

`construction.md`のMarkdownlint対象範囲を`operations.md`と同様に現在サイクルのみに限定する。

## Phase 1: 設計

### 論理設計

このUnitはドキュメント修正のみのため、ドメインモデル設計は省略し、論理設計のみ作成する。

- **変更対象**: `prompts/package/prompts/construction.md`
- **変更内容**: Markdownlint実行コマンドの対象範囲を変更

**変更前**:
```bash
npx markdownlint-cli2 "docs/**/*.md" "prompts/**/*.md" "*.md"
```

**変更後**:
```bash
npx markdownlint-cli2 "docs/cycles/{{CYCLE}}/**/*.md" "prompts/**/*.md" "*.md"
```

- **注意事項の追加**: operations.mdと同様の注意事項を追加

## Phase 2: 実装

### ステップ

1. `prompts/package/prompts/construction.md`の該当箇所を修正
2. 修正後のMarkdownlint実行で動作確認
3. Unit完了処理（状態更新・履歴・コミット）

## 完了条件

- [ ] construction.mdのMarkdownlint対象が現在サイクルのみになっている
- [ ] 注意事項コメントが追加されている
- [ ] Markdownlintが正常に実行できる

## リスク・考慮事項

- **メタ開発の考慮**: `prompts/package/`を編集（`docs/aidlc/`は直接編集禁止）
- **Operations Phaseでの同期**: rsyncで`docs/aidlc/`に反映される

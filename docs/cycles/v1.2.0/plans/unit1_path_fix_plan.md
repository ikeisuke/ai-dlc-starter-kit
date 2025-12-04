# Unit 1: パス参照不整合修正 - 実行計画

## 概要
construction.mdにUnit定義ファイルのパス（`story-artifacts/units/`）を明示し、AIが探索なしでUnit定義を読み込めるようにする

## 問題
- 現状: construction.mdにUnit定義ファイルのパスが記載されていない
- 影響: AIがUnit定義を見つけるためにGlobで探索が必要
- 期待: パスを明示することで即座にファイルを特定できる

## 修正内容

### 修正対象ファイル
1. `docs/aidlc/prompts/construction.md`（生成済みプロンプト）
2. `prompts/setup/construction.md`（テンプレート）

### 追加する記述
Unit選択後にUnit定義ファイルを読み込む手順を追加：
```
Unit定義ファイル: `docs/cycles/{{CYCLE}}/story-artifacts/units/[unit_name].md`
```

### 追加箇所の候補
- 「対象Unit決定」セクション付近
- または「フロー」セクションの冒頭

## Phase 1: 設計
このUnitは単純なドキュメント修正のため、設計フェーズはスキップ（ドメインモデル・論理設計は該当なし）

## Phase 2: 実装
1. construction.md の適切な箇所にUnit定義ファイルパスを追加
2. テンプレート（prompts/setup/construction.md）も同様に修正
3. 動作確認

## 受け入れ基準
- [ ] construction.md内にUnit定義ファイルパス `story-artifacts/units/` が記載されている
- [ ] AIがUnit定義を探索なしで読み込める

## 見積もり
0.5時間

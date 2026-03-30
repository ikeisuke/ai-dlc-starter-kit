# 既存コードベース分析

## ディレクトリ構造・ファイル構成

```
prompts/package/prompts/          ← 編集対象（正本）
├── inception.md                  ← Inception Phase定義
├── construction.md               ← Construction Phase定義
├── operations.md                 ← Operations Phase定義
├── operations-release.md         ← リリース特化バリアント
├── lite/                         ← Lite版バリアント
└── common/
    ├── rules.md                  ← 共通ルール（Depth Level仕様の定義源）
    ├── commit-flow.md            ← コミットワークフロー
    ├── review-flow.md            ← レビュー仕様
    └── [その他共通ファイル]

docs/aidlc/prompts/               ← rsyncコピー（直接編集禁止）
docs/cycles/rules.md              ← プロジェクト固有ルール（直接編集）
```

## アーキテクチャ・パターン

### Depth Level参照パターン
- **定義源（Single Source of Truth）**: `prompts/package/prompts/common/rules.md`
- **設定キー**: `rules.depth_level.level`（デフォルト: `standard`）
- **有効値**: `minimal` / `standard` / `comprehensive`
- **参照箇所**:
  - inception.md ステップ15: 設定読み込み → 各ステップで分岐
  - construction.md ステップ4: 設定読み込み → Phase 1/2で分岐
- 根拠: rules.md lines 167-252、inception.md Step 15、construction.md Step 4

### rules.md確認タイミングパターン
- inception.md: Part 2 ステップ13（遅い位置）
- construction.md: ステップ2（早い位置）
- 根拠: inception.md lines 731-733、construction.md early steps

### バージョン確認パターン
- **設定キー**: `rules.upgrade_check.enabled`（現在デフォルト: `true`）
- inception.md ステップ6で評価
- rules.md lines 134-165が定義源
- 根拠: inception.md line 245、rules.md line 141

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash (スクリプト), Markdown (プロンプト) | bin/*.sh, prompts/**/*.md |
| フレームワーク | AI-DLC (独自) | docs/aidlc.toml |
| 主要ツール | gh CLI, dasel, git, codex | docs/aidlc/bin/env-info.sh |

## 依存関係

### 内部モジュール間
- **inception.md → common/rules.md**: Depth Level仕様、セミオートゲート仕様を参照
- **construction.md → common/rules.md**: 同上
- **inception.md → construction.md**: Inception完了後にConstruction開始（エクスプレスモードでは統合）
- **prompts/package/ → docs/aidlc/**: rsyncによる一方向同期

### aidlc-setup同期タイミング
- 現在: Operations Phase ステップ6の前（docs/cycles/rules.md lines 35-41）
- 問題: 同期後にCHANGELOG更新等の追加変更あり
- 循環依存なし

## 特記事項

- エクスプレスモード追加時、rules.mdのDepth Level定義テーブルとinception.md/construction.mdの両方に分岐追加が必要
- rules.mdのバージョン確認デフォルト変更はinception.mdにも反映が必要（コードブロック内のデフォルト値）
- docs/cycles/rules.mdはrsync対象外のため直接編集可能

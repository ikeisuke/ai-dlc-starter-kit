# 論理設計: dasel v3対応

## 概要

aidlc-setupのプロンプトファイル2箇所のdaselコマンド例をv2/v3両対応に更新する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

プロンプトファイルの記述修正のみ。既存のスクリプトアーキテクチャ（toml-reader.sh によるv2/v3互換層）は変更しない。

## コンポーネント構成

### 変更対象

```text
skills/aidlc-setup/steps/
├── 01-detect.md      ← 変更箇所1: バージョン比較のdaselコマンド
└── 02-generate-config.md  ← 変更箇所2: キー追記のdaselコマンド例
```

### 変更不要（既にv2/v3対応済み）

```text
skills/aidlc/scripts/lib/toml-reader.sh    # v2/v3互換ロジック
skills/aidlc/scripts/read-config.sh        # toml-reader.sh経由
skills/aidlc-setup/scripts/detect-missing-keys.sh  # 独自v2/v3対応
```

## 変更箇所詳細

### 変更1: 01-detect.md 行101

**現状**:
> `dasel -f .aidlc/config.toml 'starter_kit_version'` を実行し、ローカルバージョンを取得する

**修正方針**: v2/v3両方のコマンド形式を併記し、AIエージェントが試行で判定する記述にする。外部スクリプト（`read-config.sh` 等）への新たな依存は追加しない。

- v2: `dasel -f .aidlc/config.toml 'starter_kit_version'`
- v3: `cat .aidlc/config.toml | dasel -i toml 'starter_kit_version'`（v3では `-f` フラグ廃止）
- いずれも失敗 → フェイルセーフ（既存ロジック）

### 変更2: 02-generate-config.md 行417

**現状**:
> `dasel put -f .aidlc/config.toml -t <type> '<key>' -v '<value>'`（dasel v2）またはパイプ入力形式（dasel v3）

**修正方針**: v2/v3それぞれの具体的なコマンド形式を明記する。

- v2: `dasel put -f .aidlc/config.toml -t <type> '<key>' -v '<value>'`
- v3: v3では `put` サブコマンド自体が廃止されているため、daselでの書き込みは不可。AIが直接TOMLファイルを編集する（Editツール等を使用）
- AIエージェントはv2形式を試行し、失敗時にAI直接編集にフォールバック

## 処理フロー概要

### バージョン取得（01-detect.md）

1. `dasel -f .aidlc/config.toml 'starter_kit_version'`（v2形式）を試行
2. 失敗 → `cat .aidlc/config.toml | dasel -i toml 'starter_kit_version'`（v3形式）を試行
3. 全失敗 → フェイルセーフ（警告表示して続行、既存ロジック）

### キー追記（02-generate-config.md）

1. `dasel put -f` をv2形式で試行
2. 失敗 → v3では `put` が廃止されているため、AIが直接TOMLファイルを編集して追記

## NFRへの対応

- **可用性**: dasel v2/v3の両環境で動作すること。dasel未インストール時のフォールバックは既存の仕組み（フェイルセーフ）で対応済み

## 実装上の注意事項

- プロンプトファイルの変更のみ。スクリプトファイルは一切変更しない
- 既存のフェイルセーフ判定ロジック（行103-107）は変更しない
- `detect-missing-keys.sh` は独自にv2/v3判定しているため、02-generate-config.mdの記述はAIが直接daselを呼ぶ場面（スクリプト外）のガイダンスとして機能する

## 不明点と質問（設計中に記録）

なし

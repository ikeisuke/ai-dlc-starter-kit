# 論理設計: アーキテクチャスタイル宣言と違反検出

## 概要
アーキテクチャスタイル宣言の設定スキーマを `defaults.toml` に追加し、reviewing-architecture スキルが設定を参照してスタイル固有のレビュー観点を適用する。

## コンポーネント構成

### 1. 設定層（Configuration Layer）

**変更対象**: `prompts/package/config/defaults.toml`

新規セクション `[rules.architecture]` を追加。既存の `read-config.sh` で読み取り可能。

```toml
[rules.architecture]
style = "none"
layers = []
dependency_direction = "none"
```

**読み取り方法**:
- 単一値: `read-config.sh rules.architecture.style`
- 配列値: `read-config.sh rules.architecture.layers`（dasel が配列として返す）
- バッチ: `read-config.sh --keys rules.architecture.style rules.architecture.layers rules.architecture.dependency_direction`

### 2. レビュースキル層（Review Skill Layer）

**変更対象**: `prompts/package/skills/reviewing-architecture/SKILL.md`（正本。`.claude/skills/` と `docs/aidlc/skills/` は aidlc-setup 同期でコピーされる）

既存のレビュー観点セクションに「スタイル準拠（Style Compliance）」観点を追加。

**追加内容**:
- 設定参照手順: レビュー開始時に `read-config.sh` でアーキテクチャ設定を取得
- スタイル別チェック項目: ドメインモデルで定義したスタイル別レビュー観点マッピングを反映
- グレースフルデグラデーション: `style = "none"` または未設定時は追加観点をスキップ

### 3. aidlc.toml（プロジェクト設定）

**変更**: 任意。プロジェクトがアーキテクチャスタイルを宣言する場合のみ設定。
本プロジェクト（AI-DLCスターターキット）自体は `style = "none"` のまま（設定定義ツールであり、特定のアーキテクチャスタイルを採用していないため）。

## インターフェース設計

### read-config.sh との連携

既存の `read-config.sh` をそのまま使用。新しいキーの追加のみ。

| キー | 返却値の型 | 例 |
|-----|----------|---|
| `rules.architecture.style` | string | `"layered"` |
| `rules.architecture.layers` | string（配列表現） | `['presentation', 'application', 'domain', 'infrastructure']` |
| `rules.architecture.dependency_direction` | string | `"top-down"` |

### SKILL.md 内のレビューフロー

```text
1. レビュー開始時に設定を確認:
   read-config.sh --keys rules.architecture.style rules.architecture.layers rules.architecture.dependency_direction

2. style が "none" または未設定 → 既存の汎用レビュー観点のみ適用

3. style が有効値 → 汎用レビュー観点 + スタイル固有の追加観点を適用
   - layered: レイヤースキップ検出、上→下依存チェック
   - hexagonal: ポート/アダプタ分離、ドメイン外部依存チェック
   - clean: ユースケース層責務、依存性逆転チェック
   - event-driven: イベント駆動一貫性、ハンドラ責務分離
   - modular: モジュール結合度、公開IF最小化

4. style が未知の値 → 警告出力 + 汎用レビュー観点のみ適用
```

## エラーハンドリング

| シナリオ | 対応 |
|---------|------|
| `[rules.architecture]` セクション未定義 | `defaults.toml` のデフォルト値が適用（style="none"） |
| `style` に未知の値 | 警告表示 + `"none"` フォールバック |
| `layers` が配列でない | 警告表示 + `[]` フォールバック |
| `dependency_direction` に未知の値 | 警告表示 + `"none"` フォールバック |
| `read-config.sh` がエラー（exit 2） | 警告表示 + デフォルト値使用 |

## 不明点と質問

なし

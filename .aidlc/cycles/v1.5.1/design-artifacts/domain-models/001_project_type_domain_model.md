# ドメインモデル: プロジェクトタイプ設定機能

## 概要

プロジェクトの種類を定義し、Operations Phaseでの配布ステップの要否判断に使用する設定値を管理する。

**重要**: 本Unitはプロンプトファイルの修正であり、アプリケーションコードの開発ではない。

## 値オブジェクト（Value Object）

### ProjectType

プロジェクトの種類を表す列挙型的な値。

- **取りうる値**:
  | 値 | 説明 | 配布ステップ |
  |----|------|-------------|
  | `web` | Webアプリケーション | スキップ |
  | `backend` | バックエンドAPI/サーバー | スキップ |
  | `general` | 汎用/未分類（デフォルト） | スキップ |
  | `cli` | コマンドラインツール | 実行 |
  | `desktop` | デスクトップアプリ | 実行 |
  | `ios` | iOSアプリ | 実行 |
  | `android` | Androidアプリ | 実行 |

- **不変性**: 一度設定されたら、同一サイクル内では変更しない想定
- **等価性**: 文字列値で等価性を判定
- **デフォルト値**: `general`（未設定時の後方互換性）

## ビジネスルール

### 配布ステップスキップ判定

```
requiresDistribution(type: ProjectType): boolean
  if type in [cli, desktop, ios, android]:
    return true
  else:
    return false
```

**理由**:
- `web/backend/general`: サーバーデプロイで完結するため、パッケージ配布は不要
- `cli/desktop/ios/android`: ユーザーへの配布（npm publish、App Store、Google Play等）が必要

## データフロー

```
[setup.md]
    ↓ ユーザーが選択
[aidlc.toml] project.type = "xxx"
    ↓ Operations Phase で参照
[operations.md]
    ↓ 判定
配布ステップ: 実行 or スキップ
```

## ユビキタス言語

- **プロジェクトタイプ**: プロジェクトの種類を示す分類値
- **配布ステップ**: Operations Phase のステップ4。パッケージ配布計画を作成するステップ
- **スキップ**: 該当ステップを実行せず完了扱いにすること

## 不明点と質問

なし（仕様は計画フェーズで確定済み）

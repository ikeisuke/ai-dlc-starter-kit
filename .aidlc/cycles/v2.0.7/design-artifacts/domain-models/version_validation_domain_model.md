# ドメインモデル: バージョン検証一元化

## 概要

`version.sh` ライブラリの `read_starter_kit_version()` 関数にmatch_count検証を統合し、`update-version.sh` の重複ロジックを排除する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（Entity）

（該当なし — シェルスクリプトライブラリのリファクタリングのため、DDDのエンティティは不要）

## 値オブジェクト（Value Object）

### SemVer
- **属性**: version: string - `X.Y.Z[-prerelease]` 形式のバージョン文字列
- **不変性**: 一度検証されたバージョン文字列は変更されない
- **等価性**: 文字列の完全一致

## ドメインサービス

### VersionLibrary（version.sh）

バージョン関連の共通操作を提供するライブラリ。関数定義のみを含み、トップレベルで実行されるコードはない。

- **責務**: バージョン文字列の検証・正規化・読み取り
- **操作**:
  - `validate_semver(version)` → 0:有効 / 1:無効 — SemVerフォーマット検証（既存・変更なし）
  - `strip_v_prefix(version)` → stdout:正規化文字列 — vプレフィックス除去（既存・変更なし）
  - `read_starter_kit_version(config_path)` → stdout:バージョン文字列, 終了コード 0/1/2 — config.tomlからstarter_kit_version読み取り（**拡張対象**）

### VersionUpdater（update-version.sh）

version.txtとconfig.tomlのバージョン番号を一括更新するスクリプト。

- **責務**: バージョン更新のオーケストレーション（検証→読み取り→書き込み→ロールバック）
- **依存**: VersionLibrary の `validate_semver()`, `strip_v_prefix()`, `read_starter_kit_version()` を使用
- **操作**:
  - バージョン引数のパース・検証
  - 現在値の取得（version.txt + config.toml）
  - アトミック更新（一時ファイル→mv方式）
  - エラー時ロールバック

## 依存関係

```text
VersionUpdater (bin/update-version.sh)
    └── source ── VersionLibrary (skills/aidlc/scripts/lib/version.sh)
                    ├── validate_semver()
                    ├── strip_v_prefix()
                    └── read_starter_kit_version()  ← 拡張対象
```

### スキル境界（変更対象外）

```text
aidlc-setup/scripts/read-version.sh  ← 独立・自己完結（version.txt読み取り）
    └── 親スキルへの依存なし（スキル分離の不変条件）
```

## `read_starter_kit_version()` 拡張の責務定義

### 現在の責務
1. ファイル存在確認
2. sedでstarter_kit_versionの値を抽出
3. 空値チェック

### 追加する責務
4. **match_count検証**: starter_kit_versionキーが正確に1件存在することを確認（0件=キー不在、2件以上=フォーマット不正）

### 追加しない責務（呼び出し側の責務）
- エラーメッセージの出力形式（`error:xxx` 等）は呼び出し側が終了コードに基づいて決定
- SemVerフォーマット検証は呼び出し側が必要に応じて `validate_semver()` を使用

## ユビキタス言語

- **starter_kit_version**: config.toml内のスターターキットバージョンフィールド
- **match_count検証**: 設定キーがファイル内に正確に1回出現することの確認
- **スキル境界**: 独立スキルが親スキルの内部実装に依存しないという不変条件

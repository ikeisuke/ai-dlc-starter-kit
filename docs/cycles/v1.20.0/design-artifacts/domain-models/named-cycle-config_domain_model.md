# ドメインモデル: 名前付きサイクル設定

## 概要

`rules.cycle.mode` 設定キーの仕様と、その読み取り・バリデーション・フォールバックの振る舞いを定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## 値オブジェクト（Value Object）

### CycleMode

- **属性**: mode: string - サイクルモードの設定値
- **不変性**: 設定読み取り後、バリデーション完了時点で確定し変更されない
- **等価性**: 文字列の完全一致で判定
- **有効値**: `"default"` / `"named"` / `"ask"`
- **デフォルト値**: `"default"`

## ドメインサービス

### CycleModeResolver

- **責務**: TOML設定から `rules.cycle.mode` を読み取り、バリデーションし、有効なCycleModeを返す
- **操作**:
  - resolve() → CycleMode: 設定を読み取り、バリデーション後の確定値を返す
- **バリデーションルール**:
  1. `read-config.sh rules.cycle.mode --default "default"` で読み取り
  2. 読み取り失敗（exit code 2）→ 警告 + `"default"` フォールバック
  3. 有効値チェック（`default` / `named` / `ask` の完全一致）
  4. 無効値 → 警告 + `"default"` フォールバック

## ユビキタス言語

- **サイクルモード（cycle_mode）**: 名前付きサイクルの動作モード。`default`/`named`/`ask` のいずれか
- **名前付きサイクル**: `docs/cycles/[name]/vX.X.X/` 形式の、機能ドメイン別ディレクトリ構造

## 不明点と質問（設計中に記録）

なし

# 論理設計: アップグレード判定修正

## 概要

check-version.shにsanitize_version()関数を追加し、check-setup-type.shのnot_foundフォールバックを改善する。

## コンポーネント構成

```text
check-setup-type.sh
  └─→ check-version.sh
        ├─ sanitize_version()  [新規]
        ├─ normalize_version() [既存・変更なし]
        └─ compare_versions()  [既存・変更なし]
```

## 変更詳細（設計=変更後の目標状態。Phase 2で実装予定）

### check-version.sh

#### sanitize_version() 関数追加（L46付近、既存のnormalize_versionの前に配置）

```text
入力: raw version string（空白トリム済み前提）
処理: vプレフィックス除去: "${version#v}"
出力: sanitized version string（例: "v1.22.0" → "1.22.0"）
注意: 空白トリムは呼び出し元のtr -d '[:space:]'で実施済み
```

#### 適用箇所

1. L43: KIT_VERSION取得直後に `KIT_VERSION=$(sanitize_version "$KIT_VERSION")` を追加
2. L61: PROJECT_VERSION取得直後に `PROJECT_VERSION=$(sanitize_version "$PROJECT_VERSION")` を追加

### check-setup-type.sh

#### not_found ケース（L67-69）

```text
変更前: echo "setup_type:initial"
変更後: echo "setup_type:upgrade"
```

理由: このブロックはaidlc.toml存在確認済みのif文内部。aidlc.tomlが存在する = 初回ではなくアップグレード。

#### ワイルドカード `*` ケース（L71-73）

```text
変更前: echo "setup_type:initial"
変更後: echo "setup_type:"
```

理由: 未知のステータスをinitialにマッピングするのはfail-open。unknownとしてAIに委ねる。

## インターフェース

### check-version.sh の出力（変更なし）

```text
version_status:{current|upgrade_available:P:K|project_newer:P:K|not_found|(空)}
```

### check-setup-type.sh の出力（not_foundマッピングのみ変更）

```text
setup_type:{initial|cycle_start|upgrade|upgrade:P:K|warning_newer:P:K|migration|(空)}
```

- `upgrade`（バージョン情報なし）: aidlc.toml存在だがバージョン比較不能（not_found時）
- `upgrade:P:K`（バージョン付き）: バージョン比較によるアップグレード検出

## テスト観点

1. version.txt に `v1.22.0` → version_status:current（kit=1.22.0の場合）
2. version.txt に `1.22.0` → version_status:current（既存動作維持）
3. aidlc.toml存在 + version_status:not_found → setup_type:upgrade
4. aidlc.toml存在 + 未知ステータス → setup_type:（unknown）
5. aidlc.toml非存在 → setup_type:initial（既存動作維持）

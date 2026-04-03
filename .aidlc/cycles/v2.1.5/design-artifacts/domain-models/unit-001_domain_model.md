# ドメインモデル: aidlc-setupバージョン比較修正

## 概要
aidlc-setupスキルの01-detect.mdにおけるバージョン取得方法を、存在しないスクリプト参照からdasel直接呼び出しに変更する。

## 対象コンポーネント

### 01-detect.md（プロンプトファイル）
- **責務**: aidlc-setup実行時の環境検出・バージョン比較
- **変更箇所**: ステップ1a（バージョン比較）のローカルバージョン取得指示
- **現状**: `scripts/read-config.sh starter_kit_version` を参照（存在しない）
- **変更後**: `.aidlc/config.toml`からdaselで`starter_kit_version`を直接取得する指示

## データフロー

```
.aidlc/config.toml --[dasel]--> starter_kit_version（ローカル）
skills/aidlc-setup/version.txt --[Read]--> skill_version（スキル）
↓
正規化（vプレフィックス除去・trim）→ 文字列比較
↓
一致 → Inception遷移 / 不一致 → アップグレードモード / 失敗 → フェイルセーフ
```

## フェイルセーフ
- dasel呼び出し失敗（config.toml不在、キー不在、dasel未インストール）→ 既存のフェイルセーフ判定に委譲（警告表示+スキップ）
- 空値・不正値 → 同上（正規化後に空文字列となるケース）

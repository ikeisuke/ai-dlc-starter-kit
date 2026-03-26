# 論理設計: dasel v3 予約語対応修正

## 概要

get_value() 関数のキー変換ロジックを、dasel v2/v3 の両環境で安全に動作するよう改善する。機能検出パターンを採用し、バージョン文字列分岐を回避する。

## アーキテクチャパターン

**機能検出パターン（Feature Detection）**: dasel のバージョン番号ではなく、ブラケット記法の動作可否を実際のテストクエリで判定する。これにより v3.x の将来バージョンや未知の実装にも対応できる。

## コンポーネント構成

### 既存構造（変更なし）

```text
read-config.sh
├── 引数パース
├── バリデーション
├── dasel存在確認
├── get_value()       ← 変更対象
├── strip_quotes()
├── resolve_key()
└── メイン処理
```

### 変更箇所: get_value() 関数内

**現在のコード（L145-151）**:
```bash
# dasel v3 予約語回避: ドット区切りキーをブラケット記法に変換
local escaped_key
escaped_key=$(printf '%s' "$key" | sed 's/\.\([^.]*\)/["\1"]/g')

result=$(cat "$file" 2>"$err_file" | dasel -i toml "$escaped_key" 2>>"$err_file") || dasel_exit_code=$?
```

**改善後の設計**:

1. スクリプトレベルのグローバル変数 `_DASEL_USE_BRACKET` を導入
2. dasel 存在確認直後に機能検出を1回実行
3. get_value() で検出結果に基づきキー変換の有無を分岐

## 機能検出の設計

### 検出ロジック（2段階検出）

```text
入力: なし（dasel コマンドの動作で判定）
出力: _DASEL_USE_BRACKET（"true" or "false"）

手順:
1. テスト用の最小 TOML データを用意: [t]\nv = 1
2. 前提確認: ドット記法 t.v で dasel クエリを実行
   → エラー終了の場合: _DASEL_USE_BRACKET="false"（dasel 自体に問題あり）
3. ブラケット検出: ブラケット記法 t["v"] で dasel クエリを実行
   → 正常終了（exit 0）→ _DASEL_USE_BRACKET="true"
   → エラー終了 → _DASEL_USE_BRACKET="false"
```

### テストクエリの選定理由

- **2段階検出の理由**: 単一プローブ（`t["v"]`のみ）だと、dasel 自体の問題（インストール不良等）とブラケット記法非対応の区別ができない。前提確認で dasel の基本動作を担保してからブラケット検出を行うことで誤判定リスクを低減する
- `t["v"]` は dasel v3 のブラケット記法
- dasel v2 では `["v"]` が配列インデックスとして解釈され、文字列 `"v"` は不正なインデックスとなりエラーになる → v2 を正しく判別可能
- テストデータは最小サイズ（2行）でオーバーヘッドを最小化

### 配置場所

dasel 存在確認（L114-117）の直後に配置:

```text
# daselの存在確認
if ! command -v dasel >/dev/null 2>&1; then ... fi

# [NEW] ブラケット記法の機能検出（2段階）
_DASEL_USE_BRACKET="false"
_DASEL_TEST_DATA=$(printf '[t]\nv = 1')
# 段階1: 前提確認（ドット記法が動作するか）
if printf '%s' "$_DASEL_TEST_DATA" | dasel -i toml 't.v' >/dev/null 2>&1; then
    # 段階2: ブラケット記法の検出
    if printf '%s' "$_DASEL_TEST_DATA" | dasel -i toml 't["v"]' >/dev/null 2>&1; then
        _DASEL_USE_BRACKET="true"
    fi
fi
```

## キー変換の設計

### 変換ロジック（get_value() 内）

```text
入力: key（ドット区切りの設定キー）
出力: escaped_key（dasel に渡すセレクター文字列）

分岐（安全デフォルト: ${_DASEL_USE_BRACKET:-false}）:
  "true" の場合:
    → 現在の sed 変換を適用: sed 's/\.\([^.]*\)/["\1"]/g'
    → 結果: rules.branch.mode → rules["branch"]["mode"]

  "false" の場合（デフォルト）:
    → 変換なし（キーをそのまま使用）
    → 結果: rules.branch.mode → rules.branch.mode
```

### 第1セグメントの制約事項

dasel v3 では先頭セグメントをブラケット化できない（`["rules"]` は配列アクセスと解釈される）。この制約は構造的なものであり、以下の対応方針とする:

- **現状**: AI-DLC 設定のトップレベルキー（`starter_kit_version`, `project`, `paths`, `rules`）に予約語は含まれない → 実害なし
- **防御策**: コードコメントに制約を明記し、将来トップレベルに予約語が追加された場合に気づけるようにする
- **過剰設計の回避**: ランタイムでの予約語チェックは実装しない（既知の予約語リストの管理コストが保守メリットを上回る）

## dasel v2 互換性設計

### v2 環境での動作

| 項目 | v2 の動作 |
|------|-----------|
| 機能検出 段階1 | `t.v` → 成功（v2 はドット記法が標準） |
| 機能検出 段階2 | `t["v"]` → エラー（v2 ではブラケット記法非対応） → `_DASEL_USE_BRACKET="false"` |
| キー変換 | なし（ドット区切りをそのまま使用） |
| `rules.branch.mode` | そのまま dasel に渡される → 正常動作（v2 では `branch` は予約語ではない） |

### v2 互換性の根拠

- dasel v2 ではセレクターは単純なプロパティ名として扱われ、`branch` 等の予約語は存在しない
- ドット区切りキーは v2 の標準アクセスパス
- 参考: [dasel v2 Selector Overview](https://daseldocs.tomwright.me/v2/functions)

## エラーハンドリング

既存の API 契約（戻り値: 0=存在, 1=不在, 2=エラー）を維持。変更なし。

機能検出の失敗ケース:
- dasel が存在しない → 機能検出の前に既存チェックで exit 2
- 機能検出自体のエラー → `_DASEL_USE_BRACKET="false"`（安全側にフォールバック: v2 互換の変換なしモード）

## 不明点と質問

（なし）

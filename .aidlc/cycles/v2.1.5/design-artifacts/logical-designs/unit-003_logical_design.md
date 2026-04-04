# 論理設計: config.toml欠落キー検出・追記候補提示

## 概要
欠落キー検出スクリプトのインターフェース設計とaidlc-setupフロー統合の設計。

## スクリプトインターフェース設計

### detect-missing-keys.sh

#### 概要
defaults.tomlとconfig.tomlを比較し、config.tomlに欠落しているリーフキーを検出する。

#### 引数
| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--defaults` | 必須 | defaults.tomlのパス |
| `--config` | 必須 | config.tomlのパス |
| `--dry-run` | 任意 | 検出のみ、追記しない |

#### 成功時出力
```text
missing:<key>:<default_value>
missing:<key>:<default_value>
summary:total:<N>
```
- 終了コード: `0`（欠落キーの有無に関わらず）

欠落キー0件時:
```text
summary:total:0
```

#### エラー時出力
```text
error:<error_type>:<message>
```
- 終了コード: `1`（defaults.toml不在）、`2`（dasel不在/実行エラー）

#### 処理ロジック

1. bootstrap.shで環境初期化（daselパス解決含む）
2. defaults.tomlの存在確認（不在→exit 1）
3. config.tomlの存在確認（不在→exit 1）
4. daselでdefaults.tomlの全キーをフラットに列挙
5. 各キーについてconfig.tomlに存在するかdaselで確認
6. 存在しないキー（欠落キー）をmissing:key:value形式で出力
7. summary行を出力

#### daselでの全キー列挙方式

daselの`-m`（multiple）オプションとキーのwalking:
```bash
dasel -f defaults.toml -m -s 'keys()' のようなネイティブ機能は限定的
```

代替案: dasel v2の`-w plain`出力を利用してセクションを再帰的に辿る。
具体的には、トップレベルセクション名をdaselで取得し、各セクション配下のキーを再帰的に列挙する。

## aidlc-setupフロー統合

### 統合ポイント
`02-generate-config.md`のステップ7.4（設定マイグレーション）の後に、新ステップ「7.4b. 欠落キー検出」を追加する。

### ステップ7.4b プロンプト設計

```markdown
### 7.4b. 欠落キー検出【アップグレードモードのみ】

defaults.tomlをスキーマとして、config.tomlに欠落しているキーを検出します。

**実行**:

scripts/detect-missing-keys.sh --defaults <defaults.tomlパス> --config .aidlc/config.toml

**defaults.tomlパスの解決**: SKILL.mdの親ディレクトリ配下の `config/defaults.toml` をReadツールで存在確認し、存在すればそのパスを使用。

**出力の解釈**:
- `missing:<key>:<value>` → 欠落キー（追記候補）
- `summary:total:0` → 欠落キーなし
- `error:*` → スクリプトエラー（警告表示してスキップ）

**欠落キーがある場合**: ユーザーに追記候補を提示し確認を求める。
**欠落キーがない場合**: 「欠落キーなし」と表示して次のステップへ。
```

## 実装上の注意事項
- dasel v2/v3互換: bootstrap.shのdaselパス解決を利用
- config.tomlの既存コメント・書式はdasel追記時に保持されない可能性がある（制約事項として明記済み）

# ドメインモデル: write-config.shレガシーエイリアス対応

## 概要
write-config.shにおける設定キーの書き込み先解決ドメイン。レガシーキーと正規キーの共存環境でTOMLファイルへの重複書き込みを防止する。

## エンティティ（Entity）

### ConfigKey
- **ID**: ドット区切りキー文字列（例: `rules.git.branch_mode`）
- **属性**:
  - canonicalKey: String - 正規化されたキー（`aidlc_normalize_key()` 結果）
  - legacyKey: String | Empty - 対応するレガシーキー（`aidlc_get_legacy_key()` 結果、マッピングなしは空）
  - sectionKey: String - TOMLセクション部分（例: `rules.git`）
  - leafKey: String - TOMLリーフ部分（例: `branch_mode`）
- **振る舞い**:
  - normalize(): 入力キーを正規キーに変換
  - decompose(): キーをsection + leafに分解

### TOMLFile
- **ID**: ファイルパス（`$AIDLC_CONFIG` or `$AIDLC_LOCAL_CONFIG`）
- **属性**:
  - scope: "project" | "local" - 書き込みスコープ
  - sections: セクションヘッダーとキー値ペアのマップ
- **振る舞い**:
  - hasKeyInSection(section, leaf): セクション内のleaf存在確認
  - updateKey(section, leaf, value): 既存キーの値を更新
  - appendToSection(section, leaf, value): セクション内にキーを追加
  - appendNewSection(section, leaf, value): 新セクション+キーを末尾追加

## 値オブジェクト（Value Object）

### WriteTarget
- **属性**:
  - targetSection: String - 書き込み先セクション
  - targetLeaf: String - 書き込み先リーフ
  - action: "update" | "update_legacy" | "create" - 書き込みアクション
- **不変性**: 一度決定した書き込み先は変更しない（dry-runと実書き込みで同一結果）
- **等価性**: targetSection + targetLeaf + action の組み合わせで判定

### KeyAlias
- **属性**:
  - canonicalKey: String - 正規キー
  - legacyKey: String - レガシーキー
- **不変性**: key-aliases.shのマッピングで定義される固定の双方向マッピング
- **等価性**: canonicalKey同士の一致

## 集約（Aggregate）

### WriteOperation
- **集約ルート**: ConfigKey
- **含まれる要素**: ConfigKey, WriteTarget, TOMLFile
- **境界**: 1回のwrite-config.sh呼び出しにおけるキー解決〜書き込みの一連の操作
- **不変条件**:
  - 同一ファイル内で正規キーとレガシーキーが同時に存在する状態を新たに作らない
  - 既存のキー（正規/レガシー）がある場合はそれを更新し、新規キーの追加による重複を防止

## ドメインサービス

### WriteTargetResolver
- **責務**: 入力キーとTOMLファイルの状態から、書き込み先を決定する
- **操作**: resolve(inputKey, file) → WriteTarget

## ユビキタス言語

- **正規キー（canonical key）**: key-aliases.shで定義される推奨キー形式（例: `rules.git.branch_mode`）
- **レガシーキー（legacy key）**: 旧設定構造のキー形式（例: `rules.branch.mode`）
- **正規化（normalize）**: レガシーキーを正規キーに変換する操作（冪等）
- **セクション**: TOMLの `[rules.git]` のようなテーブルヘッダー
- **リーフ**: セクション内の末端キー名（例: `branch_mode`）

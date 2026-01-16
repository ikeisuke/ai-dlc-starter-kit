# Construction Phase リセット記録

## 日時: 2026-01-17

## リセット理由

コンストラクションフェーズのアプローチを見直すためリセット。

## 反省点

### 1. 抽象化・分割しすぎた

Unit 001-002で作成したスクリプト基盤は、過度に抽象化・分割されていた。

**問題のあったアプローチ:**
- `_common.sh` - 共通関数ライブラリ
- `check-deps.sh` - コマンド存在確認スクリプト

これらは「作らなくてもできる」処理をスクリプト化してしまった。

### 2. 本来欲しかったもの

「処理のまとまりをそのままスクリプト化」すること。

**良いスクリプトの例:**
- 環境変数一覧を返却するスクリプト
- ラベルづけをまとめてやるスクリプト
- 具体的な処理フローをそのまま実行するスクリプト

### 3. 抽象化すべきケースの判断基準

**抽象化すべき:**
- 可変部分がある処理（例: サイクルバージョンのラベルは実行ごとに変わる）

**抽象化不要:**
- 固定の処理（例: 共通ラベルの存在確認＋作成）
- AIが直接実行できる単純なコマンド

## 削除した成果物

### 実装ファイル
- `prompts/package/bin/_common.sh`
- `prompts/package/bin/README.md`
- `prompts/package/bin/check-deps.sh`
- `docs/aidlc/bin/_common.sh`
- `docs/aidlc/bin/README.md`

### 設計ドキュメント
- `docs/cycles/v1.8.0/design-artifacts/` 配下全て
- `docs/cycles/v1.8.0/construction/` 配下全て
- `docs/cycles/v1.8.0/plans/` 配下全て

### 履歴
- `docs/cycles/v1.8.0/history/construction_unit1.md`
- `docs/cycles/v1.8.0/history/construction_unit2.md`

## 次のアクション

Inceptionからやり直し、Unit定義を「処理のまとまり」ベースで再設計する。

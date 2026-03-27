# Unit 004 計画: シェルスクリプトバグ修正・リファクタリング

## 概要

#411で報告されたシェルスクリプトの既知バグと技術的負債を修正する。

## 変更対象

### 1. detect_phase() 改善（#411-1）

`aidlc-cycle-info.sh:62-84` のフェーズ判定をディレクトリ存在からアーティファクトベースに変更:
- operations: `operations/progress.md` 存在
- construction: `story-artifacts/units/` ディレクトリに `.md` ファイル存在
- inception: デフォルト（上記以外）

### 2. get_backlog_mode() 重複解消（#411-2）

`init-cycle-dir.sh:156-158` と `env-info.sh:113-115` の重複ラッパーを削除。`resolve_backlog_mode` を直接呼び出し。

### 3. get_current_branch() 統一（#411-3）

3ファイルで重複定義（`aidlc-cycle-info.sh`, `aidlc-git-info.sh`, `env-info.sh`）。
`lib/bootstrap.sh` に最完全版を集約し、各スクリプトから定義を削除。

### 4. クォート除去統一（#411-4）

`env-info.sh` 内の複数パターンのクォート除去を統一:
- Bash展開 `${var//\'/}` を使用
- 不要なパイプチェーン削減

### 5. UUOC修正（#411-5）

`env-info.sh:106` の `echo "$result" | tr -d "'"` を `echo "${result//\'/}"` に修正。

### 6. 01-detect.md パス確認（#413-2）

スクリプトパス `skills/aidlc/scripts/check-setup-type.sh` は正しい。修正不要。

### 7. コンテキスト変数文書化（#412-3）

`lib/bootstrap.sh` のヘッダーコメントに全コンテキスト変数一覧を追記。

## 完了条件

- [x] detect_phase() がアーティファクトベースで判定（compgen -G使用）
- [x] get_backlog_mode() 重複が解消（resolve_backlog_mode直接呼び出し）
- [x] get_current_branch() が共通化（aidlc_get_current_branch in bootstrap.sh）
- [x] クォート除去が統一（aidlc_strip_quotes in bootstrap.sh）
- [x] UUOC パターンが解消
- [x] コンテキスト変数が文書化（bootstrap.shヘッダー + ユーティリティ関数追加）
- [x] 既存テストがパス + 新規テスト17件追加

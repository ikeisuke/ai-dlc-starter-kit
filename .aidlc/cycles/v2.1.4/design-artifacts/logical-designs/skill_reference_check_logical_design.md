# 論理設計: skills/直接参照チェック導入

## 概要

`bin/check-skill-references.sh`の実装構造と`skill-reference-check.yml`のCI統合を定義する。

## スクリプトインターフェース設計

### bin/check-skill-references.sh

#### 引数
| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `target_dir` | 任意 | 検査対象ディレクトリ（デフォルト: `skills/`） |
| `-v, --verbose` | 任意 | 詳細出力 |

#### スコープ判定
- `skills/`ディレクトリの存在で判定（config依存なし、自己完結）
- 不在時: `exit 0`（スキップ）

#### 検出ロジック
- `grep -rn "skills/aidlc/"` で `skills/` 配下の対象ファイル（.md, .sh, .toml）を検索
- 自身（check-skill-references.sh）は除外
- 違反行をファイルパス:行番号:内容の形式で出力

#### 終了コード
- 0: 違反なし
- 1: 違反あり
- 2: スクリプトエラー

### .github/workflows/skill-reference-check.yml

独立workflow。`skills/**`と`bin/check-skill-references.sh`の変更時にトリガー。

## 不明点と質問

（なし）

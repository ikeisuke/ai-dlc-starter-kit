# 論理設計: バリデーション共通化とサイクルID緩和

## 1. 正規表現パターン設計

### 現行パターン（SemVerのみ）
```regex
^([a-z0-9][a-z0-9-]*/)?v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$
```

### 新パターン（カスタム名追加）
```regex
^[a-z0-9v][a-z0-9._-]*(/[a-z0-9v][a-z0-9._-]*)?$
```

**パターン解説**:
- `^[a-z0-9v]` — 先頭: 英小文字、数字、`v`
- `[a-z0-9._-]*` — 以降: 英小文字、数字、ドット、アンダースコア、ハイフン
- `(/[a-z0-9v][a-z0-9._-]*)?$` — オプションで1段階のスラッシュ区切り

**設計方針**: このパターンは1セグメントまたは2セグメント（スラッシュ区切り）の汎用ラベル検証である。SemVer厳密検証は行わない（`v1` や `name/v1.2` も許可される）。これは意図的な設計であり、カスタム名を広く受け入れるための緩和である。

**既存パターンとの互換性**:
- `v1.21.2` → マッチ（SemVer）
- `waf/v1.0.0` → マッチ（名前付きSemVer）
- `v1.0.0-rc.1` → マッチ（prerelease付き）
- `feature-auth` → マッチ（カスタム名、新規）
- `2026-03` → マッチ（カスタム名、新規）

## 2. validate_cycle 関数のロジック

```
function validate_cycle(cycle):
  1. cycle が空文字列 → return 1
  2. cycle に ".." を含む → return 1
  3. cycle に空白を含む → return 1
  4. cycle に制御文字を含む → return 1
  5. cycle が "/" で始まる → return 1
  6. cycle が新パターンにマッチしない → return 1
  7. return 0
```

## 3. source パス解決

**前提**: 現行の `write-history.sh` / `setup-branch.sh` は `SCRIPT_DIR` を定義していない。実装時に各スクリプトの冒頭（`set -euo pipefail` の直後）に以下を追加する必要がある:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

lib への相対パス:
```bash
source "${SCRIPT_DIR}/../lib/validate.sh"
```

**ファイル不存在時の動作**: `set -e` 環境下で `source` が失敗した場合、スクリプトは即時終了する（意図通り）。

- `bin/write-history.sh` → `../lib/validate.sh` = `lib/validate.sh`
- `bin/setup-branch.sh` → `../lib/validate.sh` = `lib/validate.sh`
- `tests/test_validate_cycle.sh` → `../lib/validate.sh` = `lib/validate.sh`（SCRIPT_DIR は既に定義済み）

## 4. 変更箇所の詳細

### write-history.sh
- 削除: 92-107行の `validate_cycle` 関数定義
- 削除: 91行のコメント「# サイクル名を検証（vX.Y.Z または name/vX.Y.Z 形式のみ許可）」
- 追加: `source "${SCRIPT_DIR}/../lib/validate.sh"` （スクリプト冒頭、SCRIPT_DIR 定義後）

### setup-branch.sh
- 削除: 172-182行のインラインバリデーション（パストラバーサルチェック + 正規表現チェック）
- 追加: `source "${SCRIPT_DIR}/../lib/validate.sh"` （スクリプト冒頭）
- 変更: バリデーション呼び出しを `validate_cycle "$version"` に置換
- エラーメッセージ更新: 新しい許可形式を反映

### test_validate_cycle.sh
- 変更: `eval "$(sed ...)"` を `source "${SCRIPT_DIR}/../lib/validate.sh"` に置換
- 追加: カスタム名の正常系テストケース
- 変更: `not-a-version` が正常系に移動（カスタム名として許可）

## 5. エラーメッセージ更新

### write-history.sh
- 旧: （暗黙的にSemVer前提）
- 新: エラー時に許可形式を明示しない（validate_cycle は exit code のみ返す。呼び出し元が `"Invalid cycle name: ${CYCLE}"` のように出力）

### setup-branch.sh
- 旧: `"無効なバージョン形式: ${version}（vX.Y.Z, vX.Y.Z-prerelease, または [name]/vX.Y.Z 形式で指定してください）"`
- 新: `"無効なバージョン形式: ${version}（英小文字・数字・ハイフン・ドットで構成し、パストラバーサル（..）は許可されていません）"`

## 6. デプロイコピーとの同期

`docs/aidlc/` 配下のファイル（`docs/aidlc/bin/write-history.sh` 等）は `prompts/package/` の rsync コピーである。本Unitでは `prompts/package/` のみを編集する。`docs/aidlc/` への同期は Operations Phase の `/aidlc-setup`（rsync）で自動実行されるため、本Unitでは同期不要。

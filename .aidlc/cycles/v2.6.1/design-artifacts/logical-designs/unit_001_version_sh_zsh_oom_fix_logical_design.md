# Unit 001 論理設計: version.sh zsh OOM クラッシュ修正

## 全体構成

本 Unit は以下 3 種類の成果物に分かれる:

1. **`skills/aidlc/scripts/lib/version.sh`** - CLI モードガード追加
2. **`skills/aidlc/SKILL.md`** - バージョン表示セクション改訂
3. **`skills/aidlc/scripts/tests/test_read_marketplace_version.sh`**（既存追記）または **`test_version_cli.sh`**（新規）- CLI モードテストケース追加

## 1. `version.sh` の論理設計

### 1.1 ヘッダコメント更新

`version.sh` 冒頭コメントには現状「このファイルは関数定義のみを含む。トップレベルで実行されるコードはない。」と記載されているが、本 Unit で CLI モードガードを追加するため矛盾する。以下のように更新する:

```bash
# version.sh - バージョン検証共通ライブラリ + CLI エントリポイント
#
# 使用方法（必須サポート / v2.6.1 Unit 001 以降）:
#   - CLI モード: bash <path>/version.sh <marketplace.json のパス>
#   - subprocess source: bash -c "source <path>/version.sh; read_marketplace_version <args>"
#   - 他 bash スクリプトからの source: source "${SCRIPT_DIR}/../lib/version.sh"
#
# 非対象経路（zsh 対話シェルからの手動 source）:
#   zsh command_not_found_handler 競合により OOM クラッシュリスクがあるため避ける。
#   詳細は SKILL.md「バージョン表示」セクションを参照。
#
# 末尾の CLI モードガード（${BASH_SOURCE[0]} == $0）により bash 直接実行時のみ
# read_marketplace_version() を呼び出す。source 経由時は関数定義のみが取り込まれる。
```

### 1.2 CLI モードガードの追加箇所

`version.sh` の末尾（`read_starter_kit_version()` 関数定義の後）に以下のブロックを追加する:

```bash
# CLI モードガード（v2.6.1 Unit 001 / Issue #688）:
# `bash version.sh <json_path>` 形式での直接実行を有効化する。
# `source` 経由呼び出し時には実行されない（${BASH_SOURCE[0]} != $0 のため）。
# zsh 対話シェルから手動 source した場合は zsh command_not_found_handler 競合のリスクがあるため
# SKILL.md の注意書きで非対象経路として案内する。
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    read_marketplace_version "$@"
fi
```

### 1.3 動作モード

| 呼び出し方法 | `${BASH_SOURCE[0]} == $0` | 実行される処理 |
|------------|--------------------------|--------------|
| `bash skills/aidlc/scripts/lib/version.sh /path/to/marketplace.json` | true | `read_marketplace_version /path/to/marketplace.json` |
| `source skills/aidlc/scripts/lib/version.sh`（bash スクリプト内から） | false | 関数定義のみ（既存挙動） |
| `. skills/aidlc/scripts/lib/version.sh`（同上） | false | 関数定義のみ（既存挙動） |
| zsh 対話シェルからの手動 `source`（非対象経路） | false（同上） | 関数定義のみ。だが zsh 補完 hook 競合の既知リスクあり |

### 1.4 既存関数への影響

- `validate_semver()`: 変更なし
- `strip_v_prefix()`: 変更なし
- `read_marketplace_version()`: 変更なし（CLI ガードは関数を呼び出すだけ）
- `aidlc_strip_quotes_safe()`: 変更なし
- `read_starter_kit_version()`: 変更なし

### 1.5 終了コードの伝播

CLI モードでの呼び出し時、`read_marketplace_version "$@"` の終了コードがそのままシェルの終了コードとして返る:

- 0: 成功（stdout に version）
- 1: コンテンツエラー（stderr に `error:metadata-version-*`）
- 2: 実行環境エラー（stderr に `error:missing-json-path` / `error:marketplace-json-not-found` / `error:marketplace-json-read-failed` / `error:dasel-and-jq-unavailable`）

これは既存の関数仕様と一致しており、契約不変条件を維持する。

### 1.6 引数のバリデーション

CLI モードで `<json_path>` 引数なしで呼ばれた場合:

- `read_marketplace_version()` が `[[ -z "$json_path" ]]` をチェックし `error:missing-json-path` を stderr 出力 + return 2
- これも既存挙動と一致

### 1.7 引数個数契約（CLI モード）

CLI モードでの引数契約を以下のように固定する:

- **第 1 引数のみ使用**: `marketplace.json` のパス（必須）
- **第 2 引数以降**: 無視（`read_marketplace_version()` の関数仕様が `$1` のみ参照するため、過多引数は安全に無視される）
- **将来拡張**: もし将来追加引数（出力フォーマット指定等）を導入する場合は、`read_marketplace_version()` の関数シグネチャ拡張で対応する。CLI モードガード自体（`read_marketplace_version "$@"`）は引数透過のままで、関数側の責務として処理する

この契約は本 Unit のスコープでは「第 1 引数のみ使用」を前提とし、追加引数の能動的なバリデーション（過多引数で exit 1）は導入しない。理由:

1. 既存の `read_marketplace_version()` 関数仕様と一致（過多引数を無視する素直な挙動）
2. 将来拡張時に関数側で引数を受け取る可能性があり、CLI ガード側で拒否するとレイヤー責務が混入する
3. AI エージェント / ユーザー誤用時の影響は限定的（過多引数があっても結果は変わらない）

## 2. SKILL.md の論理設計

### 2.1 改訂対象セクション

- `skills/aidlc/SKILL.md` の「### バージョン表示」セクション（現行 234-250 行付近）
- `skills/aidlc/SKILL.md` の「## 制約事項」セクション（現行 252 行付近）— `..` 参照禁止条項に **marketplace.json アクセス専用の例外** を明示する

### 2.1.1 marketplace.json パス解決の `..` 制約衝突解消

現状の SKILL.md には以下 2 つの記述が共存しており、本 Unit より前から不整合がある:

- L238: 「スキルベースディレクトリ（SKILL.md と同じディレクトリ）から `../../.claude-plugin/marketplace.json` を解決し」（`..` を使う）
- L252: 「`..` によるベースディレクトリ外への参照は無効とする」（`..` を禁ずる）

**採用解消方針**: 「制約事項」セクションに **明示的な例外** を追記する。

理由:

- `marketplace.json` はスキルベースディレクトリ外（プラグインルート `.claude-plugin/` 配下）に配置されており、現実的に `..` 経由で解決せざるを得ない
- 呼び出し側（AI エージェント）が絶対パスを生成して渡す方式に変更すると、SKILL.md の指示が AI エージェント実装に強く依存し、移植性が下がる
- 例外を明示する方が現状の運用と整合し、他経路（`scripts/` / `templates/` 等）の `..` 禁止規約は維持できる

### 2.1.2 改訂後の制約事項セクション（差分）

```markdown
## 制約事項

- **ドキュメント読み込み制限**: ...（既存維持）
- **テンプレート参照**: ...（既存維持）
- **パス解決**: `steps/`、`scripts/`、`config/`、`templates/`、`guides/`、`references/` で始まるパスはスキルのベースディレクトリ（SKILL.mdと同じディレクトリ）からの相対パスとして解決する。`..` によるベースディレクトリ外への参照は **以下の例外を除き** 無効とする。
  - **例外**: `marketplace.json`（プラグインルート `.claude-plugin/marketplace.json`）への参照は `{SKILLベースディレクトリ}/../../.claude-plugin/marketplace.json` として解決する。これは `marketplace.json` が SoT であり、スキルベースディレクトリ外に配置されているための限定的な例外である。バージョン表示アクションのみで使用する。
- **SKILL.md本文制限**: ...（既存維持）
```

### 2.2 改訂後の構成

```markdown
### バージョン表示

`version` アクション時に以下を表示して処理を終了する。共通初期化フローは実行しない。

#### 必須: 安全な呼び出し経路

AI エージェント（Claude Code Bash ツール / 同等の subprocess 経由）は **以下の CLI モード経由で呼び出すこと**:

​```bash
bash {SKILLベースディレクトリ}/scripts/lib/version.sh {marketplace.json のパス}
​```

- `{SKILLベースディレクトリ}` は SKILL.md と同じディレクトリの絶対パス
- `{marketplace.json のパス}` は `{SKILLベースディレクトリ}/../../.claude-plugin/marketplace.json` で解決
- 終了コード 0（成功）/ 1（コンテンツエラー）/ 2（実行環境エラー）と stderr メッセージは既存の `read_marketplace_version()` 関数仕様に従う

#### 表示処理

1. 上記 CLI モード呼び出しで version 文字列を取得（stdout）
2. 値を正規化する: 前後の空白をトリムし、先頭の `v` プレフィックスがあれば除去する。空文字・不正値・読取不能の場合は不存在と同じ扱いとする
3. 以下のフォーマットで表示:

​```text
AI-DLC Starter Kit v{version}
​```

4. `marketplace.json` が存在しない、または正規化後の値が空の場合:

​```text
AI-DLC Starter Kit (version unknown)
​```

#### 注意: 使用すべきでない呼び出し経路（zsh 対話シェル）

ユーザーが zsh 対話シェルで以下を手動実行した場合、zsh `command_not_found_handler` の無限再帰により OOM クラッシュする既知の制約があります。AI エージェントはこの経路を使用しないこと:

​```text
（非対象 / 危険）
source {SKILLベースディレクトリ}/scripts/lib/version.sh
read_marketplace_version /path/to/marketplace.json
​```

`bash <path>` 経由 / `bash -c "source <path>; read_marketplace_version ..."` 経由 / 他の bash スクリプトからの `source` 経由は **すべて安全に動作します**。
```

### 2.3 改訂方針

- `scripts/lib/version.sh::read_marketplace_version` を呼び出す」という曖昧な指示を、CLI モード呼び出しコマンドの具体例に置き換える
- 「使用すべきでない経路」を明示し、AI エージェントが誤誘導されないようにする
- 既存の正規化フォーマット規約は維持

## 3. テストケースの論理設計

### 3.1 既存ファイルへの追記 vs 新規ファイル

採用方針: **`skills/aidlc/scripts/tests/test_read_marketplace_version.sh` の末尾にセクション「CLI モード経由テスト」を追加**する。新規ファイル作成より既存テストとの一体性が高く、レビュー・保守も容易。

### 3.2 追加するテストケース

#### 3.2.1 CLI モード正常系

| ケース | 入力 | 期待 |
|--------|------|------|
| C1: 正常な marketplace.json を渡す | `bash version.sh <fixture>/valid.json` | exit 0、stdout が `2.6.0` 等の SemVer |
| C2: 連続実行の安定性 | C1 を 3 回連続実行 | 全て exit 0、stdout 値が同一 |

#### 3.2.2 CLI モード異常系

| ケース | 入力 | 期待 |
|--------|------|------|
| C3: 引数なし | `bash version.sh` | exit 2、stderr に `error:missing-json-path` |
| C4: 存在しないパス | `bash version.sh /nonexistent.json` | exit 2、stderr に `error:marketplace-json-not-found` |
| C5: metadata.version キー不在 | `bash version.sh <fixture>/no_version.json` | exit 1、stderr に `error:metadata-version-missing-or-empty` |
| C6: 不正な SemVer | `bash version.sh <fixture>/invalid_semver.json` | exit 1、stderr に `error:metadata-version-invalid-semver:` |

#### 3.2.3 source 経路との両立確認

| ケース | 入力 | 期待 |
|--------|------|------|
| C7: source 経由でも関数が動作 | `source version.sh; read_marketplace_version <fixture>/valid.json` | 既存テストでカバー済み（変更なし） |
| C8: source 経由で末尾 if は実行されない | `source version.sh` のみ | 副作用ゼロ（既存テストで暗黙にカバー） |

### 3.3 テスト実行方法

```bash
bash skills/aidlc/scripts/tests/test_read_marketplace_version.sh
```

期待: exit 0、stdout に `=== 結果: PASS=N, FAIL=0 ===`

### 3.4 fixture の配置

既存の `mktemp -d` 経由で生成する一時ディレクトリ内に valid.json / no_version.json / invalid_semver.json を作成する（既存パターン踏襲）。fixture を別ファイル化しない。

## 4. 整合性チェック観点

### 4.1 ガイド照合（CLAUDE.md ルール）

| ルール | 本設計への適用 |
|--------|--------------|
| ドッグフーディング特殊処理を本体に埋めない | CLI モードガードは starter kit / consumer 共通の動作（自リポジトリ判定なし）、原則準拠 |
| `$(...)` 絶対禁止 | 本設計のすべてのサンプルで `$(...)` 不使用 |
| コマンド置換禁止 | 同上 |

### 4.2 v2.6.0 Unit 007 との整合性

`squash-unit.sh` の CLI モードガード:

```bash
# squash-unit.sh の末尾（参考）
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
```

本 Unit の `version.sh` ガード:

```bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    read_marketplace_version "$@"
fi
```

→ 同パターンで整合性確保。

### 4.3 v2.6.0 Unit 001 SoT 規約との整合性

`marketplace.json.metadata.version` を SoT とする方針は変更しない（DR-001/DR-002 維持）。本 Unit はあくまで「呼び出し経路の安全化」に閉じる。

## 5. 実装手順（Phase 2 着手時の指針）

1. `skills/aidlc/scripts/lib/version.sh` 末尾に CLI モードガードブロックを追加（コメント付き）
2. `skills/aidlc/SKILL.md` の「バージョン表示」セクションを改訂
3. `skills/aidlc/scripts/tests/test_read_marketplace_version.sh` に CLI モードテストケース C1〜C6 を追加
4. `bash skills/aidlc/scripts/tests/test_read_marketplace_version.sh` 実行 → green 確認
5. `shellcheck skills/aidlc/scripts/lib/version.sh` 実行 → green 確認
6. markdownlint（SKILL.md）実行 → green 確認

## 6. 設計レビュー観点（自己チェック）

- [x] レイヤー責務分離: 業務ロジック（read_marketplace_version）/ CLI ガード（薄い委譲）/ AI エージェント誘導（SKILL.md）の 3 層が明確に分離
- [x] 凝集度: 各層は単一責務、変更理由が単一
- [x] 依存方向: SKILL.md → CLI ガード → read_marketplace_version の単方向、循環なし
- [x] 後方互換性: 既存の `source` 経由呼び出しと関数仕様を完全維持
- [x] テスト網羅: 正常系 C1-C2、異常系 C3-C6、後方互換性 C7-C8 を網羅

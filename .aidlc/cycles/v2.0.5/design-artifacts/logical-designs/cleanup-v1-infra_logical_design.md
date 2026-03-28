# 論理設計: v1インフラ廃止・スクリプトv2対応

## 1. bootstrap.sh の AIDLC_DOCS_DIR 廃止

### 設計意図（Codexレビュー #1 対応）
現状の bootstrap.sh は「共通初期化」と「レガシー設定解決（AIDLC_DOCS_DIR）」が同一モジュールに混在している。本変更で bootstrap.sh を v2 の固定パス群のみに縮退し、レガシー解決はスコープ外の移行スクリプト内に閉じ込める。

### 変更前 → 変更後
| 項目 | 変更前 | 変更後 |
|------|--------|--------|
| bootstrap.sh 提供変数 | `AIDLC_PROJECT_ROOT`, `AIDLC_PLUGIN_ROOT`, ..., `AIDLC_DOCS_DIR` | `AIDLC_PROJECT_ROOT`, `AIDLC_PLUGIN_ROOT`, ...（`AIDLC_DOCS_DIR` なし） |
| `paths.aidlc_dir` カスケード | bootstrap.sh 内で4階層解決 | 削除。必要なスクリプトがローカルにフォールバック定義 |
| `toml-reader.sh` の source | bootstrap.sh が AIDLC_DOCS_DIR 解決のために source | bootstrap.sh からは削除。toml-reader.sh 自体は残す |

### 削除対象
- L44-97: `AIDLC_DOCS_DIR` 算出ブロック全体
  - `_aidlc_resolve_docs_dir()` 関数
  - 4階層カスケード解決ロジック
  - `toml-reader.sh` の source
  - `export AIDLC_DOCS_DIR`
- L16: ヘッダコメントから `AIDLC_DOCS_DIR` を削除

## 2. check-setup-type.sh の修正

### 現状
```
AIDLC_TOML="docs/aidlc.toml"
PROJECT_TOML="${AIDLC_DOCS_DIR:-docs/aidlc}/project.toml"
```

### 修正後
- `AIDLC_TOML` → `.aidlc/config.toml`（v2正式パス）。v1フォールバック `docs/aidlc.toml` は残す
- `PROJECT_TOML` → `docs/aidlc/project.toml` に固定（`AIDLC_DOCS_DIR` を経由しない）。v1→v2移行判定で使用
- `AIDLC_DOCS_DIR` 参照を全て除去

### 判定状態表（Codexレビュー #2 対応）

| `.aidlc/config.toml` | `docs/aidlc.toml` | `docs/aidlc/project.toml` | 判定結果 | 備考 |
|:---:|:---:|:---:|---|---|
| ✓ | - | - | バージョン比較（`cycle_start` / `upgrade` / `warning_newer`） | v2正式パス |
| ✓ | ✓ | - | バージョン比較（v2優先、`docs/aidlc.toml` 無視） | v1残存ファイルは判定に影響しない |
| ✗ | ✓ | - | `migration`（v1フォールバック: `docs/aidlc.toml` から読み取り） | `docs/aidlc.toml` のみの環境 |
| ✗ | - | ✓ | `migration` | v1 project.toml あり |
| ✗ | ✓ | ✓ | `migration` | v1両方あり |
| ✗ | ✗ | ✗ | `initial` | 初回セットアップ |

**優先順位**: `.aidlc/config.toml` > `docs/aidlc.toml` > `docs/aidlc/project.toml`

### API一本化方針（Codexレビュー #2 対応）
- **正本**: `skills/aidlc/scripts/check-setup-type.sh`（bootstrap.sh を source、v2優先のロジック）
- **`prompts/setup/bin/` 版**: 正本のラッパーに変更（`exec "${SCRIPT_DIR}/../../../skills/aidlc/scripts/check-setup-type.sh" "$@"`）
- これにより API 契約が単一実装に統一され、呼び出し元によって判定結果が変わる問題を解消
- テストも正本を参照するよう更新

## 3. check-version.sh の修正

### API一本化方針（Codexレビュー #1, #2 対応、check-setup-type.sh と同一方針）
- **正本**: `skills/aidlc/scripts/check-version.sh`（bootstrap.sh を source、v2優先のロジック）
- **`prompts/setup/bin/` 版**: 正本のラッパーに変更（`exec "${SCRIPT_DIR}/../../../skills/aidlc/scripts/check-version.sh" "$@"`）
- check-setup-type.sh と check-version.sh は組で使われるAPIのため、正本戦略を統一
- **`prompts/setup/bin/` 側の個別ロジック修正はスコープ外**。ラッパー化により正本に委譲

### 正本の修正
- `CONFIG_FILE` → `.aidlc/config.toml` に変更（v1フォールバック `docs/aidlc.toml` も残す）
- `dasel` でのバージョン読み取りパスも `starter_kit_version` のキーに合わせて更新

## 4. update-version.sh の修正

### 現状
- `docs/aidlc.toml` を直接参照（11箇所）

### 修正後
- 全参照を `.aidlc/config.toml` に変更
- sed のパターンは同じ（`starter_kit_version = "X.X.X"`）
- バックアップ・リストアのパスも `.aidlc/config.toml` ベースに

## 5. aidlc-setup.sh のsymlink解決

### 現状の問題
- `resolve_script_dir()` はsymlinkをループで解決して実体パスを返す ✓
- `resolve_starter_kit_root()` は `SCRIPT_DIR` のパターンマッチ `*/skills/aidlc-setup/bin` で判定
- 外部プロジェクトからsymlink経由で実行される場合、`SCRIPT_DIR` は実体パス（スターターキット内）になるので正しく動作する

### 入出力契約（Codexレビュー #5 対応）

**`resolve_script_dir()`**:
- 入力: `$0`（実行されたスクリプトパス）
- 出力: symlinkを全て解決した実体ファイルの親ディレクトリ（絶対パス）
- 例: `/path/to/project/.claude-plugin/skills/aidlc-setup/bin/aidlc-setup.sh`（symlink）→ `/path/to/starter-kit/skills/aidlc-setup/bin`

**`resolve_starter_kit_root()`**:
- 入力: `SCRIPT_DIR`（`resolve_script_dir()` の出力）
- 出力: スターターキットルートの絶対パス
- 現在の判定: `SCRIPT_DIR` が `*/skills/aidlc-setup/bin` にマッチ → 3階層上がルート
- 失敗ケース: プラグインキャッシュ経由（例: `~/.claude/plugins/cache/xxx/skills/aidlc-setup/bin`）ではパターンマッチは成功するが、ルートが正しいスターターキットを指さない可能性
- **追加フォールバック**: パターンマッチ成功後、算出したルートに `skills/aidlc/config/defaults.toml` が存在するか検証。不在の場合は `SCRIPT_DIR` 起点で `git rev-parse --show-toplevel` を試行し、それも失敗時はエラー終了

## 6. sync-package.sh 完全廃止

### 呼び出し元一覧（Codexレビュー #5 対応）
| 参照元 | 参照種別 | 対応方針 |
|--------|---------|---------|
| `prompts/bin/sync-package.sh` | 実体 | 削除 |
| `skills/aidlc/scripts/sync-package.sh` | ラッパー | 削除 |
| `skills/aidlc/steps/setup/02-generate-config.md` | ステップ内参照 | rsync同期セクション自体がv2で不要。ただし02-generate-config.md全体の改修はUnit 003のスコープ外。参照箇所に `<!-- AIDLC-DEPRECATED: sync-package.sh はv2で廃止。プラグインモデルでは不要 -->` コメントを追記 |
| `prompts/setup-prompt.md` | 旧エントリポイント | 本Unit内で簡略化済み（セクション8）。参照消滅 |

### 廃止方針
v2ではプラグインモデルにより rsync 同期が不要になったため、`sync-package.sh` を即時削除する。`02-generate-config.md` 内のrsync同期手順は廃止マーカーを付与し、後続サイクルでのステップファイル整理時に除去する。

## 7. agents-rules.md への即時実装ルール追加

### 追加セクション: 「即時実装優先ルール」
- 位置: 「バックログ管理」セクションの直後
- 内容: バックログに登録するだけでなく、現サイクルで対応可能なものは即時実装を優先する
- 既存の「改善提案のバックログ登録ルール」（rules.md）との適用場面の違いを明記

## 8. setup-prompt.md の簡略化

### 修正後の内容
- `/aidlc setup` への誘導メッセージのみ
- v1時代のsetup手順・ツール要件等は全て削除

## 9. config.toml / defaults.toml の paths.aidlc_dir 削除

### .aidlc/config.toml
- `[paths]` セクションの `aidlc_dir = "docs/aidlc"` を削除
- `[paths]` セクションが空になる場合はセクション自体を削除

### skills/aidlc/config/defaults.toml
- `[paths]` セクションの `aidlc_dir = "docs/aidlc"` を削除
- 同様にセクションが空になる場合は削除

## 10. migrate-config.sh のフォールバック（Codexレビュー #3, #4 対応）

### 責務分離（Codexレビュー #3 対応）
- **移行元設定の参照**: `docs/aidlc/*` を直接参照（v1プロジェクト側資産）
- **移行ガイド表示**: `AIDLC_PLUGIN_ROOT/guides/*` を参照（プラグイン側資産）
- `AIDLC_DOCS_DIR` 互換は移行元設定参照のみに閉じ込める

### 修正方針
- `AIDLC_DOCS_DIR` を参照している箇所（L293: ガイドパス生成）を修正
- bootstrap.sh の公開APIに依存しない: `AIDLC_PLUGIN_ROOT` を使って `guides/jj-migration.md` を組み立てる
- 修正後: `echo "移行手順: ${AIDLC_PLUGIN_ROOT}/guides/jj-migration.md" >&2`
- `AIDLC_PLUGIN_ROOT` は bootstrap.sh で常に提供されるv2正式API

## テスト修正

### test_check_setup_type.sh / test_check_version.sh
- `SETUP_BIN="${SCRIPT_DIR}/../../../prompts/setup/bin"` → `SETUP_BIN="${SCRIPT_DIR}/.."`（正本の `skills/aidlc/scripts/` を参照）
- テスト内のファイルコピーパスも更新

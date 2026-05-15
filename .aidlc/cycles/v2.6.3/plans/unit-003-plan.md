# Unit 003 実装計画: /aidlc v 経路の再現性向上

## 対象 Unit

- **Unit**: 003 - /aidlc v 経路の再現性向上
- **関連 Issue**: #698
- **優先度**: Medium
- **depth_level**: standard（Phase 1 設計を実施）

## 背景・目的

`/aidlc v`（バージョン表示）経路で AI エージェント（Claude Code Opus 4.7 等）が以下 2 種のミスを再発させていた:

1. CLI モードを呼ばずに内部知識から推測値（例: `v2.7.0`）を出力する
2. パス再構築時にプラグインルートと SKILL ベースディレクトリを混同し `scripts/lib/version.sh` を「存在しない」と誤判定する

原因は SKILL.md「バージョン表示」節の構造が以下を要求していたためである:

- `{SKILLベースディレクトリ}` プレースホルダから base dir を解決する手順が明示されていない
- `{SKILLベースディレクトリ}/../../.claude-plugin/marketplace.json` のパス組み立てを AI が毎回再演する必要がある
- 「Bash 呼び出しに失敗 / 不存在の場合のみ `(version unknown)`」の禁則が「内部知識からの推測禁止」として明示されていない
- 本来 AI 実行に不要な経緯情報（zsh OOM クラッシュ経緯 / `read_marketplace_version()` 関数仕様 / Unit・Issue メタ情報）が本文を占め、必要な「結合手順」「禁則」を書くスペースが圧迫されている

本 Unit は #698 提案の A 案（文言追加）と C 案（`version.sh` 自己解決化）の併用で構造的に解消する。

## スコープ

### 含まれるもの（責務）

- `skills/aidlc/scripts/lib/version.sh` の改修:
  - CLI モードガード（`${BASH_SOURCE[0]} == $0`）内で引数省略時にスクリプト自身の位置から marketplace.json を自己解決する
  - 解決ロジック: スクリプト位置 `<repo_root>/skills/aidlc/scripts/lib/version.sh` から `../../../../.claude-plugin/marketplace.json` を相対計算（`..` を 4 段: `lib/` → `scripts/` → `aidlc/` → `skills/` → `<repo_root>`）
  - 引数渡しは test override として後方互換を維持（既存 `read_marketplace_version` 関数の引数仕様は変更しない）
  - 自己解決パスのファイルが不在の場合は通常のエラーフロー（exit 2 / `error:marketplace-json-not-found`）に乗せる
- `skills/aidlc/SKILL.md`「バージョン表示」節の改訂:
  - 「Base directory for this skill:」行から base dir を解決する旨を明示
  - CLI モード呼び出しコマンドを `bash {base}/scripts/lib/version.sh` の 1 形に圧縮（marketplace.json パス引数は省略可と明記）
  - 「Bash を呼ばずに内部知識で version を推測しないこと」の禁則を明示
  - exit 非 0 / 空文字時のフォールバック表示（`(version unknown)`）の手順を維持
  - AI 実行に不要な経緯情報（zsh OOM 経緯 / 関数仕様詳細 / Unit・Issue メタ情報）を退避（退避先: `version.sh` 冒頭コメント / `references/` / 制約事項節）
- 既存テスト `skills/aidlc/scripts/tests/test_read_marketplace_version.sh` の更新:
  - 旧 C3（引数なし → exit 2）を CLI レイヤーと関数レイヤーに分解
    - **C3a**: 引数なし CLI モード自己解決成功（exit 0）
    - **C3b**: 引数なし CLI モード自己解決失敗（デフォルトパス不在 → exit 2 + `error:marketplace-json-not-found`）
    - **C3c**: 関数本体引数空契約（`read_marketplace_version ""` → exit 2 + `error:missing-json-path`）
  - **C9**: 引数渡し（test override）の後方互換確認（exit 0）
- SKILL.md 本文の行数が 500 行制限以内であることを `wc -l` で確認

### 含まれないもの（境界）

- バージョン算出ロジック自体（SemVer パース / 正規化）の変更
- `/aidlc v` 以外のアクション経路（`inception` / `construction` / `operations` / `setup` 等）の改修
- `bin/check-marketplace-version.sh` / `bin/update-version.sh` / `aidlc-setup` / `aidlc-migrate` 等の他経路における marketplace.json 参照ロジックの変更（これらは独自経路を持つため Unit 003 のスコープ外）
- `read_marketplace_version` 関数自身の引数契約変更（後方互換維持のため不変。デフォルト解決は CLI モードガード内に閉じる）

## 実装方針

### Phase 1: 設計

#### ドメインモデル（version 表示の責務分割）

| レイヤー | 責務 | 入出力 |
|---------|------|--------|
| SKILL.md「バージョン表示」節 | AI 実行手順の SoT。base dir 解決手順 + CLI 呼び出し + 表示フォーマット + 推測禁則 | 入力: `version` action / 出力: `AI-DLC Starter Kit v{version}` または `(version unknown)` |
| `version.sh` CLI モードガード | 引数解決（自己解決 or override）と `read_marketplace_version` への委譲 | 入力: `$@`（任意） / 出力: stdout に version 文字列、exit code |
| `read_marketplace_version` 関数 | marketplace.json から `metadata.version` を抽出し SemVer 検証 | 入力: marketplace.json のパス（必須） / 出力: version 文字列、exit code |

#### 論理設計

- **自己解決ロジックの配置**:
  - CLI モードガード内（`if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then ... fi`）に閉じる
  - 関数本体（`read_marketplace_version`）は引数必須のまま変更しない（テスタビリティ維持）
  - これにより、subprocess source / 他 bash script からの source 経由は従来どおり明示パスが必要

- **デフォルトパス算出式**:
  ```bash
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  DEFAULT_MARKETPLACE_JSON="${SCRIPT_DIR}/../../../../.claude-plugin/marketplace.json"
  ```
  - パス構造: `<repo_root>/skills/aidlc/scripts/lib/version.sh` の `SCRIPT_DIR` は `<repo_root>/skills/aidlc/scripts/lib`。`..` を 4 段（`lib/` → `scripts/` → `aidlc/` → `skills/`）たどって `<repo_root>` に到達 → `.claude-plugin/marketplace.json` を結合
  - `bootstrap.sh` が同じ手法（`SCRIPT_DIR` の相対計算）を採用しており設計の整合性あり
  - 用語整理: 本計画では「`<repo_root>`」=リポジトリルート、「`<skill_base>`」=スキルベースディレクトリ（`<repo_root>/skills/aidlc/`）として明示的に分離して使用する

- **CLI モードガードの分岐ロジック**:
  ```bash
  if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
      if [[ $# -eq 0 ]]; then
          SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
          read_marketplace_version "${SCRIPT_DIR}/../../../../.claude-plugin/marketplace.json"
      else
          read_marketplace_version "$@"
      fi
  fi
  ```

- **SKILL.md 改訂方針**:
  - 「必須: 安全な呼び出し経路（CLI モード）」サブセクションを圧縮
  - 「Base directory for this skill: 行を参照」の base dir 解決手順を 1 行で明示
  - コマンドは `bash {base}/scripts/lib/version.sh`（引数省略）の 1 形のみ提示
  - 「注意: Bash ツール経由の zsh OOM 回避ルール」サブセクションは保持（CLAUDE.md 規約への横断参照 SoT として機能している）が、`/aidlc v` 固有の手動 source 経緯記述は version.sh 冒頭コメントに退避し、SKILL.md では「詳細は `version.sh` 冒頭コメント参照」の 1 行に圧縮
  - 「禁則: Bash を呼ばずに内部知識で version を推測しないこと」を新規明示

- **退避先の確定**:
  - `version.sh` 冒頭コメント: zsh OOM 経緯の詳細（Issue #688 由来）+ CLI モードガードの引数契約説明
  - SKILL.md「制約事項」節の例外規定: 既存記述を維持（marketplace.json パス例外）

#### テスト設計

CLI モードと関数本体のレイヤー責務を分けてテストする方針に統一する（Codex 指摘 #2 反映）。

- 新規テストケース（CLI モード自己解決 / レイヤー責務別）:
  - **C3a**（CLI レイヤー: 自己解決成功）: 引数なし CLI モードでデフォルトパスが存在し SemVer 取得 → exit 0、stdout に version 文字列
  - **C3b**（CLI レイヤー: 自己解決失敗）: `version.sh` を一時複製で相対基点をずらす方式により、引数なし CLI モードでデフォルトパス不在 → exit 2、stderr に `error:marketplace-json-not-found`
  - **C3c**（関数レイヤー: 引数空契約）: `read_marketplace_version ""` 直接呼び出し → exit 2、stderr に `error:missing-json-path`（関数契約は不変）
  - **C9**（CLI レイヤー: 後方互換）: 引数渡し（test override）で従来どおり指定パスを使用 → exit 0
- 既存テストの調整:
  - 旧 C3（引数なし → exit 2）は C3b（CLI レイヤー: 自己解決失敗）と C3c（関数レイヤー: 引数空契約）に分解。CLI 契約の検証を弱めず、関数契約も独立にカバーする
- 既存テスト（C1, C2, C4, C5, C6, C8）は変更なしで pass することを確認

**テストレイヤー対応表**:

| テスト ID | レイヤー | 検証内容 |
|----------|---------|---------|
| C3a | CLI モード（自己解決成功） | 引数省略時にスクリプト位置基準で marketplace.json を解決し SemVer を返す |
| C3b | CLI モード（自己解決失敗） | `version.sh` の一時複製で相対基点をずらし、デフォルトパスのファイル不在で exit 2 + `error:marketplace-json-not-found` |
| C3c | 関数本体（引数契約） | `read_marketplace_version ""` で exit 2 + `error:missing-json-path`（CLI ガードを経由しない関数契約） |
| C9 | CLI モード（後方互換） | 引数渡し時は指定パスを使用（test override 経路の維持） |

### Phase 2: 実装

1. **version.sh 改修**:
   - 冒頭コメント更新（自己解決ロジックの存在 + zsh OOM 経緯の退避記述）
   - CLI モードガード内に自己解決分岐を追加
2. **SKILL.md 改訂**:
   - 「バージョン表示」節を圧縮（CLI コマンドの 1 形化 + 推測禁則追加）
   - 「Bash ツール経由の zsh OOM 回避ルール」サブセクションの `/aidlc v` 固有部分を圧縮（横断ルールは保持）
   - 本文行数が 500 以内であることを `wc -l` で確認
3. **テスト追加・調整**:
   - `test_read_marketplace_version.sh` に C3a / C3b / C3c / C9 を追加（旧 C3 を分解）
   - C3b でデフォルトパスを「存在しない状態」にする手段: 現行 `version.sh` には外部注入インターフェース（環境変数 override 等）がないため、**「`version.sh` を一時ディレクトリに複製して相対基点をずらす」方式に限定**する。具体的には `mktemp -d` で空のディレクトリ階層を作成し、その階層内の `lib/version.sh` 位置に本物の `version.sh` をコピーして実行することで、`SCRIPT_DIR` 起点の自己解決結果を「`.claude-plugin/marketplace.json` 不在の場所」に向けさせる
4. **テスト実行**:
   - `bash skills/aidlc/scripts/tests/test_read_marketplace_version.sh` で全テスト pass を確認
5. **回帰確認**:
   - `bin/check-marketplace-version.sh` 等の他経路が引き続き動作することを `bash bin/check-marketplace-version.sh` で確認

## 完了条件チェックリスト

### #698 受け入れ基準

- [x] `version.sh` CLI モードで引数省略時に marketplace.json を自己解決する（実装: `version.sh:200-208`、検証: C3a PASS）
- [x] 引数渡し経路（test override）が後方互換で動作する（検証: C1 / C9 PASS）
- [x] 自己解決パスの marketplace.json が不在の場合は exit 2 + `error:marketplace-json-not-found` を返す（検証: C3b PASS）
- [x] SKILL.md「バージョン表示」節に「Base directory for this skill:」行参照の base dir 解決手順が明示されている（SKILL.md L264）
- [x] SKILL.md「バージョン表示」節に「内部知識から version を推測してはならない」禁則が明示されている（SKILL.md「禁則【絶対遵守】」セクション）
- [x] SKILL.md「バージョン表示」節の CLI 呼び出しコマンドが `bash {base}/scripts/lib/version.sh`（引数省略）の 1 形に圧縮されている（SKILL.md L266）
- [x] AI 実行に不要な経緯情報（zsh OOM 経緯詳細 / 関数仕様詳細 / Unit・Issue メタ情報）が SKILL.md 本文から退避されている（退避先: `version.sh` 冒頭コメント / CLAUDE.md 横断参照）
- [x] `(version unknown)` フォールバック表示（exit 非 0 / 空文字時）の手順が維持されている（SKILL.md L271-275）

### 共通

- [x] SKILL.md 本文が 500 行以内（`wc -l skills/aidlc/SKILL.md` → 298 行）
- [x] `test_read_marketplace_version.sh` 全テスト pass（既存 C1, C2, C4, C5, C6, C8 + 新規 C3a, C3b, C3c, C9 → 28/28 PASS）
- [x] `bin/check-marketplace-version.sh` が引き続き動作（回帰なし、`bin/tests/test_check_marketplace_version.sh` → 14/14 PASS）
- [x] markdownlint で新規エラー 0 件（`npx markdownlint-cli2 skills/aidlc/SKILL.md` → 0 errors）
- [x] AI レビュー（設計 / コード / 統合）が `review_mode=required` に従い実施されている（設計レビュー Set 1: 2R clean / コードレビュー Set 2: 1R clean / 統合レビュー Set 3: 4R clean、unresolved=0、defer=1 / #709）

## リスク・考慮事項

- **自己解決パスの正確性**: `<repo_root>/skills/aidlc/scripts/lib/version.sh` から `../../../../.claude-plugin/marketplace.json`（`..` を 4 段）の相対計算は、ディレクトリ階層構造が変わると壊れる。`bootstrap.sh` 等の他スクリプトも同じ前提を持つため、リポジトリ構造の前提を共有している事実は受容する（変更が必要な場合は別 Issue 化）。**Phase 2 実装直前に再度パス段数を実測検証する**（cd と pwd で確認）
- **既存 C3 テストの挙動変更**: 「CLI モード引数なし → exit 2」を期待していたが、自己解決導入で CLI レイヤーの挙動が変わる。テストを CLI レイヤー（C3a / C3b）と関数本体レイヤー（C3c）に分解することで、CLI 契約と関数契約の両方を独立に検証する（Codex 指摘 #2 反映）
- **SKILL.md 圧縮による情報損失**: 退避先（`version.sh` 冒頭コメント）から元の経緯情報にアクセス可能であることを確保する（コメント内容のレビューで担保）
- **横断ルール（CLAUDE.md / bash-tool-safety.md）への影響**: SKILL.md「Bash ツール経由の zsh OOM 回避ルール」サブセクションは横断参照 SoT 機能を保持。`/aidlc v` 固有の経緯のみ退避し、横断ルール文言は維持する
- 全作業でコマンド置換（`$(...)` / backtick）を Bash ツール引数文字列に含めない（本リポジトリ規約 / Unit 001 の SoT に従う）

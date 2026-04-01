# 論理設計: マイグレーションフロー修正

## 概要

aidlc-migrateスキルの3つのスクリプト（detect/apply-config/verify）に対する修正の論理設計。既存のパイプラインアーキテクチャ（detect → apply → verify）を維持しつつ、starter_kit_version更新とハッシュ比較機能を追加する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

パイプライン＆フィルタ（既存踏襲）。各スクリプトがフェーズを担い、manifest/journalをJSON形式で受け渡す。共通ロジックはライブラリ（version.sh）に集約し、スクリプト間の知識重複を排除する。

## コンポーネント構成

```text
skills/aidlc-migrate/
├── scripts/
│   ├── migrate-detect.sh      [変更] セクション6: ハッシュ比較追加
│   ├── migrate-apply-config.sh [変更] starter_kit_version更新追加
│   ├── migrate-config.sh       [既存] aidlc-setupスキルからの委譲先（クロススキル依存）
│   └── migrate-verify.sh       [変更] version検証チェック追加、journal入力追加
├── config/
│   └── known-hashes.json         [新規] v1テンプレート既知ハッシュ定義
skills/aidlc/scripts/lib/
└── version.sh                  [既存] read_starter_kit_version()を利用
version.txt                     [既存] canonical versionのSingle Source of Truth
```

### コンポーネント詳細

#### config/known-hashes.json（新規）
- **責務**: v1 Issueテンプレートの既知SHA256ハッシュ値を定義
- **依存**: なし（データ定義ファイル）
- **公開インターフェース**: 連想配列 `KNOWN_V1_TEMPLATE_HASHES`

#### migrate-detect.sh セクション6（変更）
- **責務**: Issueテンプレートの所有権判定（ハッシュ比較）
- **依存**: config/known-hashes.json, 既存 `_sha256()` 関数（sha256sum/shasum フォールバック）
- **変更点**: known_filename判定 → hash_comparison判定に変更

#### migrate-apply-config.sh（変更）
- **責務**: config.toml設定移行 + starter_kit_version更新
- **依存**: version.sh (read_starter_kit_version), version.txt, dasel
- **クロススキル依存**: `migrate-config.sh` は `skills/aidlc-setup/scripts/migrate-config.sh` を `SCRIPT_DIR` 相対パスで参照（既存の依存構造を維持。本Unit対象外のリファクタリング）
- **変更点**: migrate-config.sh実行後にversion更新処理を追加

#### migrate-verify.sh（変更）
- **責務**: 移行結果の検証（3項目 → 4項目に拡張）
- **依存**: version.sh (read_starter_kit_version), journal JSON（apply-configの出力）
- **変更点**: starter_kit_version_updated チェックを追加。journal の `expected_version` を参照

## スクリプトインターフェース設計

### config/known-hashes.json

#### 概要
v1 Issueテンプレートの既知SHA256ハッシュ値を連想配列で定義するデータファイル。

#### データ構造
```text
連想配列: KNOWN_V1_TEMPLATE_HASHES
  キー: テンプレートファイル名（backlog.yml, bug.yml, feature.yml, feedback.yml）
  値: SHA256ハッシュ文字列
```

#### 使用方法
sourceして連想配列を参照する。スクリプトとして直接実行しない。

### migrate-detect.sh セクション6 変更仕様

#### 変更前の動作
- テンプレートファイルの存在確認のみ
- `ownership_evidence.method: "known_filename"`, `is_owned: null`
- 全て `action: "confirm_delete"`

#### 変更後の動作
1. `config/known-hashes.json` をsource
2. 各テンプレートファイルの存在確認
3. 存在するファイルのSHA256ハッシュを既存の `_sha256()` 関数で計算（sha256sum/shasumフォールバック対応済み）
4. 既知ハッシュと比較

#### 出力（manifest resourceエントリ）

**ハッシュ一致時**:
```text
resource_type: "issue_template"
path: ".github/ISSUE_TEMPLATE/{name}"
action: "delete"
ownership_evidence:
  method: "hash_comparison"
  is_owned: true
  expected_hash: "{既知ハッシュ}"
  actual_hash: "{計算ハッシュ}"
```

**ハッシュ不一致時**:
```text
resource_type: "issue_template"
path: ".github/ISSUE_TEMPLATE/{name}"
action: "confirm_delete"
ownership_evidence:
  method: "hash_comparison"
  is_owned: false
  expected_hash: "{既知ハッシュ}"
  actual_hash: "{計算ハッシュ}"
```

**既知ハッシュにテンプレート名が存在しない場合**（予期しないファイル名）:
現行と同じ `action: "confirm_delete"`, `method: "known_filename"`, `is_owned: null`

### migrate-apply-config.sh 変更仕様

#### 追加処理の位置
`migrate-config.sh` 実行後、AGENTS.md/CLAUDE.md参照クリーンアップ前

#### canonical versionの取得元
`version.txt`（プロジェクトルート）を唯一のcanonical versionソースとする。`env-info.sh` は config.toml を読み返すだけのため使用しない。これにより「更新したい値を更新先から取得する」自己参照問題を回避する。

#### 処理フロー

1. **前提条件チェック**: `migrate-config.sh` の実行結果を確認
   - `|| true` は維持しつつ、終了コードを別変数に保持
   - 実装: `migrate_output=$("$migrate_script" --config "$config_dest" 2>&1); migrate_script_exit_code=$?` のように `;` で分離
2. **canonical version取得**: `version.txt` を読み取り
3. **条件分岐**:
   - `migrate_script_exit_code != 0` → journal: `status: "skipped"`, `reason_code: "config_migration_failed"`
   - canonical versionが空 → journal: `status: "skipped"`, `reason_code: "canonical_version_unavailable"`
   - dasel不在 → journal: `status: "error"`, `reason_code: "dasel_not_found"`
   - dasel更新失敗 → journal: `status: "error"`, `reason_code: "dasel_write_failed"`
   - 正常 → daselでconfig.toml更新、journal: `status: "success"`

#### Journal出力追加

```text
resource_type: "version_update"
path: ".aidlc/config.toml"
status: "success" | "skipped" | "error"
detail: "{説明文}"
expected_version: "{canonical version}" （success/error時のみ）
reason_code: "{reason}" （skipped/error時のみ）
```

**statusの使い分け**:
- `success`: 更新が正常に完了
- `skipped`: 前提条件不成立（config migration失敗、version.txt不在等）。処理をスキップした意思決定
- `error`: 依存コマンド不在、I/O失敗等の実行時エラー

### migrate-verify.sh 変更仕様

#### インターフェース変更
`--journal` 引数を追加（任意）。指定された場合、apply-configのjournal JSONを読み取り、`version_update` エントリから `expected_version` を取得する。

#### 追加チェック: starter_kit_version_updated

既存3チェック（config_paths, v1_artifacts_removed, data_migrated）の後に追加。

#### 処理フロー

1. journal JSONが提供されている場合:
   a. `version_update` エントリの `status` を確認
   b. `status: "skipped"` → チェックを `ok` (detail: "version update was intentionally skipped") として記録
   c. `status: "error"` → チェックを `fail` (detail: journal の detail を転記) として記録
   d. `status: "success"` → `expected_version` を取得し、ステップ2へ
2. `version.sh` の `read_starter_kit_version()` で config.toml から現在値を取得
3. journal の `expected_version` と完全一致検証（journal なしの場合は `version.txt` から取得）

#### 出力

**一致時**:
```text
name: "starter_kit_version_updated"
status: "ok"
detail: "starter_kit_version correctly set to {version}"
```

**不一致時**:
```text
name: "starter_kit_version_updated"
status: "fail"
detail: "starter_kit_version mismatch: expected={expected}, actual={current}"
```

**skipped時**（journal status=skippedの場合）:
```text
name: "starter_kit_version_updated"
status: "ok"
detail: "version update was intentionally skipped: {reason_code}"
```

**取得失敗時**（version.shエラー等）:
```text
name: "starter_kit_version_updated"
status: "fail"
detail: "Could not read starter_kit_version from config.toml"
```

## 処理フロー概要

### マイグレーションパイプライン全体

1. **detect**: Issueテンプレートをハッシュ比較で判定 → manifest JSON生成
2. **apply-config**: config移行 → migrate-config.sh成功時のみversion.txtからversion更新 → journal JSON生成（expected_version含む）
3. **verify**: 既存3チェック + journal参照によるversion完全一致チェック → result JSON生成

### starter_kit_version更新の安全性フロー

```text
migrate-config.sh実行
  ├── 成功（exit 0）→ version.txtからcanonical version取得
  │                    ├── 取得成功 → daselでconfig.toml更新 → journal: success + expected_version
  │                    └── 取得失敗 → journal: skipped (canonical_version_unavailable)
  └── 失敗（exit != 0）→ journal: skipped (config_migration_failed)

verify時: journal.version_update.expected_version と config.toml実値を比較
```

## 非機能要件への対応

### セキュリティ
- ハッシュ値はスクリプト内ではなくデータファイルに分離（改ざん検知が容易）
- SHA-256ハッシュ取得は既存の `_sha256()` 関数を使用（sha256sum/shasumフォールバック対応）

### 可用性
- version.sh読み取り失敗時はverifyでfail扱い（安全側に倒す）
- dasel不在時はversion更新をerror記録し、journalに詳細を記録
- journal.version_update.status=skipped の場合はverify側もok扱い（意図的スキップ）

## 技術選定
- **言語**: Bash（既存スクリプトと同一）
- **依存コマンド**: jq（既存）, sha256sum/shasum（既存 `_sha256()` で抽象化済み）, dasel（既存依存）
- **ライブラリ**: version.sh（既存共通ライブラリ）
- **canonical versionソース**: version.txt（プロジェクトルート、配布側メタデータ）

## 実装上の注意事項
- `migrate-config.sh` の `|| true` は削除せず、終了コードを別途保持する方式にする（既存動作への影響を最小化）
- `known-hashes.json` はBash連想配列のため `declare -A` を使用（Bash 4+前提、既存スクリプトと同一）
- `migrate-config.sh` は `skills/aidlc-setup/scripts/migrate-config.sh` にあり、`migrate-apply-config.sh` から `SCRIPT_DIR` 相対パスで参照される既存のクロススキル依存。本Unitでは変更しない
- `version.txt` のパスは `AIDLC_PROJECT_ROOT/version.txt` で解決（git rev-parse --show-toplevel で取得済みの値を使用）
- journal の `--journal` 引数は後方互換性のため任意とする。未指定時はversion.txtへのフォールバック

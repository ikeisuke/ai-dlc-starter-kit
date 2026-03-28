# 論理設計: v1残存コード削除

## 概要

`aidlc-setup.sh` からrsync同期・ghqパス解決を削除し、設定ファイルとステップファイルからv1パス参照を整理する。

## 正本とミラーの関係（AIレビュー指摘#2対応）

v2プラグインモデルでは以下の3系統が存在する:

| 系統 | パス | 役割 | 本Unit での扱い |
|------|------|------|----------------|
| **正本（v2）** | `skills/aidlc/steps/` | プラグインが参照する実行時ファイル | 直接編集 |
| **ソース（メタ開発）** | `prompts/package/` | 配布パッケージのソース | 正本と同期して編集 |
| **デプロイコピー** | `docs/aidlc/` | Operations Phase で aidlc-setup 同期されるコピー | Operations Phase の `/aidlc-setup` で自動反映（本Unit では編集不要） |

**同期戦略**: 本Unitでは `skills/aidlc/steps/` と `prompts/package/` の両方を同時に編集する。`docs/aidlc/` は Operations Phase の aidlc-setup 同期で自動反映される。

## ghq削除の前提条件（AIレビュー指摘#3対応）

ghq経由のパス解決を削除する前提:

1. **プラグインインストール形態**: `claude install` でプラグインをインストールすると、リポジトリが `.claude/plugins/cache/` にクローンされる。`aidlc-setup.sh` はその中の `skills/aidlc-setup/bin/` に配置される
2. **SCRIPT_DIR 相対解決の成立条件**: `aidlc-setup.sh` は常にスターターキットリポジトリ内に存在するため、`SCRIPT_DIR` → 3階層上 = リポジトリルート = スターターキットルートが成立する
3. **成立しないケースの代替**: 環境変数 `AIDLC_STARTER_KIT_PATH` で明示指定可能（L206-214 を維持）
4. **メタ開発環境**: `version.txt` + `prompts/package/` の存在チェックで検出（維持）

## 変更詳細

### 1. aidlc-setup.sh の変更

#### 1.1 SYNC_DIRS / SYNC_FILES 削除（L41-57）

配列定義を完全削除。

#### 1.2 _has_file_diff() 削除（L129-180）

関数定義を完全削除。

#### 1.3 --no-sync オプション削除（L83-86）

引数解析の `--no-sync` ケースを削除。`NO_SYNC` 変数の宣言（L30）も削除。

#### 1.4 resolve_starter_kit_root() 簡略化（L204-346）

**変更後の構造**:

```
resolve_starter_kit_root() {
  # 1. 環境変数 AIDLC_STARTER_KIT_PATH（維持: L206-214）
  # 2. SCRIPT_DIR ベース解決（簡略化）
  #    - */skills/aidlc-setup/bin パターンのみ
  #    - 3階層上がルート
  #    - メタ開発検出（version.txt + prompts/package/）は維持
  # 3. フォールバック: エラー（維持: L341-345）
}
```

**削除対象**:
- L229-281: ghq経由のフォールバック解決（v2構造のghq分岐）
- L284-339: v1互換パスパターン（`*/prompts/package/skills/*/bin`、`*/skills/*/bin` の重複ghq解決）

**維持対象**:
- L206-214: 環境変数によるオーバーライド
- L217-228: SCRIPT_DIR ベースの解決（メタ開発検出含む）
- L341-345: フォールバックエラー

#### 1.5 Step 3 cycle_start 分岐の簡略化（L376-419）

- L382-387: `NO_SYNC` 参照を削除
- L389-403: `_has_file_diff()` 呼び出しを削除
- cycle_start で force なしの場合: バージョンが同じならスキップ

#### 1.6 Step 5 v1フォールバックパス削除（L441-474）

- L448-450: v1フォールバック（`prompts/package/bin/migrate-config.sh`）を削除
- スターターキット内の `skills/aidlc/scripts/migrate-config.sh` のみ参照

#### 1.7 Step 6 パッケージ同期 完全削除（L476-574）

Step 6 全体を削除。

#### 1.8 Step 7 v1フォールバックパス削除（L576-607）

- L593, L602-604: v1フォールバック（`prompts/package/bin/setup-ai-tools.sh`）を削除

#### 1.9 ヘルプ・出力整理

- `show_help()` から `--no-sync` を削除
- ヘッダコメントから `rsync同期` の記述を削除
- v1フォールバック設定（L34-38: `docs/aidlc.toml` フォールバック）を削除

### 2. config.toml の変更

#### 2.1 [paths].setup_prompt 削除

```toml
[paths]
# setup_prompt = "prompts/setup-prompt.md"  ← 削除
aidlc_dir = "docs/aidlc"
cycles_dir = ".aidlc/cycles"
```

### 3. ステップファイルの変更（正本 + ソース同時編集）

#### 3.1 operations/04-completion.md（L168前後）

**対象**: `skills/aidlc/steps/operations/04-completion.md` + `prompts/package/prompts/operations/04-completion.md`

setup_prompt の読み取りロジックとフォールバック規則を削除し、`/aidlc setup` 直参照に変更。

#### 3.2 setup/02-generate-config.md（L288前後）

**対象**: `skills/aidlc/steps/setup/02-generate-config.md` + `prompts/package/prompts/setup/02-generate-config.md`（存在する場合）

セクション「7.2.1 setup_prompt パスの設定【初回・移行のみ】」を削除。

#### 3.3 prompts/setup/templates/aidlc.toml.template（L22）

**対象**: `prompts/setup/templates/aidlc.toml.template`

`setup_prompt = "[setup_prompt パス]"` 行を削除。

### 4. SKILL.md の変更

#### 4.1 skills/aidlc-setup/SKILL.md

- 出力フォーマット表から `sync_added`, `sync_updated`, `sync_deleted` 行を削除
- 事前準備の ghq:パス解決手順を簡略化
- 更新対象表をプラグインモデルの説明に変更

### 5. prompts/setup-prompt.md の変更

- v1互換コードブロック（L234-246: `==== v1互換コード ====`）を削除
- setup_prompt 生成・保持を前提とした記述の整理
- ghqパス参照を持つセクションの整理

## 変更後の出力契約（AIレビュー指摘#4対応）

### aidlc-setup.sh 出力キー一覧（変更後）

| キー | 意味 | dry-run | execute |
|------|------|---------|---------|
| `mode:{dry-run\|execute}` | 実行モード | ○ | ○ |
| `starter_kit_path:{path}` | スターターキットパス | ○ | ○ |
| `config_path:{path}` | 設定ファイルパス | ○ | ○ |
| `setup_type:{type}` | セットアップ種別 | ○ | ○ |
| `version_from:{ver}` | 現在バージョン | ○ | ○ |
| `version_to:{ver}` | 更新先バージョン | ○ | ○ |
| `migrate:skipped` | マイグレーションスキップ | ○ | ○ |
| `setup_ai_tools:{status}` | AIツール設定結果 | ○ | ○ |
| `version_updated:{status}` | バージョン更新結果 | ○ | ○ |
| `skip:already-current:{ver}` | 最新のためスキップ | ○ | ○ |
| `status:success` | 完了 | ○ | ○ |

### 廃止キー

| キー | 理由 |
|------|------|
| `sync_added:{file}` | rsync同期削除 |
| `sync_updated:{file}` | rsync同期削除 |
| `sync_deleted:{file}` | rsync同期削除 |
| `sync_done:{path}` | rsync同期削除 |
| `sync_skip:{path}` | rsync同期削除 |
| `sync:skipped` | --no-sync削除 |
| `diff:detected` | _has_file_diff削除 |

### cycle_start 時の判定基準（変更後）

- `force=false` かつ同バージョン → `skip:already-current:{ver}` で終了
- `force=true` → 強制実行（マイグレーション + バージョン更新）
- ファイル差分チェックは行わない（プラグインモデルでは `claude update` で同期）

## 影響分析

### 影響を受けないもの

- `read-config.sh`: 変更なし
- `migrate-config.sh`: 変更なし（マイグレーションロジック自体は維持）
- `check-setup-type.sh`: 変更なし
- `defaults.toml`: 変更なし（`setup_prompt` は既に存在しない）
- `docs/aidlc/`: Operations Phase の aidlc-setup 同期で反映

### 後方互換性

- `--no-sync` オプション: v2.0.4で即時削除（プラグインモデルでは使用されない）
- `setup_prompt` 設定: v2.0.4で即時削除（参照元を同時更新するため安全）
- ghqパス解決: v2.0.4で即時削除（前提条件を満たすため安全）

## AIレビュー反映履歴

- **指摘#1（高）**: `prompts/setup/templates/aidlc.toml.template` を変更対象に追加（3.3）
- **指摘#2（高）**: 正本/ソース/デプロイコピーの3系統を明記し、同期戦略を定義
- **指摘#3（高）**: ghq削除の前提条件を明文化（プラグイン配置形態、SCRIPT_DIR解決条件、代替手段）
- **指摘#4（中）**: 変更後の出力契約・廃止キー一覧・cycle_start判定基準を追加

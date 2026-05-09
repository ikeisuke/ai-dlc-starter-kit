# 論理設計: marketplace.json への version SoT 一本化

## 概要

`marketplace.json.metadata.version` を SoT としてコンポーネント間で参照・更新するための物理コンポーネント配置と、各ファイルでの変更点・呼び出しシグネチャを定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。

## アーキテクチャパターン

**採用パターン**: 既存のレイヤード構造（共通ライブラリ / シェルスクリプト / Markdown ステップ / CI workflow）を維持しつつ、参照源を一本化する「Single Source of Truth Refactoring」を適用する。

**選定理由**:

- 既存呼び出し元の互換性破壊を最小化（CLI / 関数シグネチャは原則維持）
- 4 経路（SKILL.md / 01-setup.md / env-info.sh / lib/version.sh）すべてを `lib/version.sh::read_marketplace_version` 経由で **統一** することで、将来の変更点を 1 箇所に閉じ込める（指摘 #2 対応）
- 旧 `version.txt` 経路を削除することで「複数の正本」アンチパターンを解消

### 抽象化の境界（指摘 #2 対応）

**aidlc コンテキスト内の 4 経路**: すべて `lib/version.sh::read_marketplace_version` 経由で統一する（直接 `dasel` / `jq` を呼ばない）。

| 経路 | 抽象化レベル | アクセス方法 |
|------|-------------|-------------|
| SKILL.md「version」アクション | `read_marketplace_version` | `lib/version.sh` を `source` または bash サブシェルで関数呼出（実装詳細は Phase 2） |
| 01-setup.md ステップ5a スキル経路 | `read_marketplace_version` | 同上 |
| 01-setup.md ステップ5a リモート経路 | `read_marketplace_version` の派生（リモート URL 受取版）または `curl + read_marketplace_version` 組合せ | `curl` で marketplace.json を取得 → 一時ファイル経由で `read_marketplace_version` に渡す |
| env-info.sh `get_starter_kit_version()` | `read_marketplace_version` | `lib/version.sh` を `source`（既存 `env-info.sh` は同 lib を bootstrap.sh 経由で読込済） |

**aidlc-migrate コンテキスト**: aidlc lib に依存しない。`jq -r '.metadata.version'` のインライン呼び出しまたは migrate 専用の `lib/` ヘルパーで完結する（指摘 #1 対応 / 後述）。

## コンポーネント構成

### レイヤー / モジュール構成

```text
Version Reference Context（本 Unit のスコープ）
├── Manifest Layer（marketplace.json 抽出）
│   └── lib/version.sh
│       ├── read_marketplace_version(json_path)         [新規]
│       ├── read_starter_kit_version(toml_path)         [既存: 用途を「キャッシュ値検証」に限定]
│       ├── validate_semver(version)                    [既存・流用]
│       └── strip_v_prefix(version)                     [既存・流用]
├── CLI / Tool Layer
│   ├── bin/update-version.sh                           [再構築]
│   ├── bin/check-marketplace-version.sh                [新規 / GATE-5 (A)]
│   └── scripts/env-info.sh
│       └── get_starter_kit_version()                   [内部: marketplace.json 参照に切替]
├── Skill Step Layer
│   ├── skills/aidlc/SKILL.md（version アクション）     [marketplace.json 参照に切替]
│   ├── skills/aidlc/steps/inception/01-setup.md ステップ5a [3 経路を marketplace.json に切替]
│   └── skills/aidlc/guides/version-check.md             [変更不要 / 比較ロジックは保持]
├── Migrate Layer（コンテキスト独立 / aidlc lib 非依存 / 指摘 #1 対応）
│   ├── skills/aidlc-migrate/scripts/migrate-apply-config.sh:217-218 [jq インライン or migrate 専用 lib]
│   └── skills/aidlc-migrate/scripts/migrate-verify.sh:188-189        [同上]
├── CI / Workflow Layer
│   ├── .github/workflows/auto-tag.yml                   [version.txt 廃止に伴い切替]
│   ├── .github/workflows/pr-check.yml                   [PATHS_REGEX 更新]
│   └── （新規ジョブ）marketplace-version-check
├── Documentation Layer
│   ├── README.md                                        [Version バッジ更新]
│   ├── .aidlc/operations.md                             [リリース手順 / CI 要点更新]
│   └── .aidlc/rules.md or README.md                     [config.toml.starter_kit_version の役割明文化]
└── Test Layer
    ├── skills/aidlc/scripts/tests/test_read_marketplace_version.sh  [新規]
    ├── skills/aidlc/scripts/tests/test_read_starter_kit_version.sh  [既存: 残存・必要に応じ修正]
    ├── bin/tests/test_update_version_no_toml_write.sh             [既存: marketplace.json 主体に書き換え]
    └── bin/tests/test_check_marketplace_version.sh                [新規]

削除対象:
├── version.txt
├── skills/aidlc/version.txt
└── skills/aidlc-setup/version.txt
```

### コンポーネント詳細

#### lib/version.sh

- **責務**: SemVer 検証、`marketplace.json.metadata.version` の抽出、`config.toml.starter_kit_version` の検証付き読取
- **依存**: なし（純関数 + ファイル I/O）
- **公開インターフェース**:
  - `read_marketplace_version(json_path) -> stdout: SemVer, exit: 0=ok, 1=コンテンツエラー（key/value missing / 非 SemVer 値）, 2=実行環境エラー（I/O 失敗 + dasel/jq 双方不在を含む）`【新規】
  - `read_starter_kit_version(config_toml_path) -> stdout: SemVer, exit: 0=ok, 1=key missing/duplicate/empty, 2=I/O error`【既存・互換維持】
  - `validate_semver(version) -> exit: 0=valid, 1=invalid`【既存】
  - `strip_v_prefix(version) -> stdout: 正規化値`【既存】

#### bin/update-version.sh

- **責務**: `marketplace.json.metadata.version` を SoT として更新する。`version.txt` 系 3 ファイル更新ロジックは削除
- **依存**: lib/version.sh（`read_marketplace_version` / `read_starter_kit_version` / `validate_semver` / `strip_v_prefix`）、`dasel`/`jq` のいずれか（フォールバック付）
- **公開インターフェース**: 既存 CLI（`--version <ver>` / `--dry-run`）を維持。出力フォーマットは `marketplace_version_*` キーへ変更

#### bin/check-marketplace-version.sh【新規 / GATE-5 (A)】

- **責務**: PR の差分に「version 更新を要する変更」が含まれるとき、`marketplace.json.metadata.version` も更新されているかを検証する pre-release ガード
- **依存（指摘 #5 対応）**: `git diff` / `lib/version.sh::read_marketplace_version` のみ。`gh` 依存は持たない（CI ジョブの `actions/checkout@v4` で base/current 両方の commit を取得済の前提）
- **公開インターフェース**:
  - 引数: `--base <ref>`（比較先、デフォルト `origin/main`）/ `--current <ref>`（比較元、デフォルト `HEAD`）
  - 終了コード: `0=合格`, `1=marketplace.json 未更新で違反`, `2=実行エラー`

#### env-info.sh の get_starter_kit_version()

- **責務**: 旧仕様では `config.toml.starter_kit_version` を返していたが、本 Unit で**返却値の意味を「正本（marketplace.json 値）」に変更**する
- **影響**: 関数名は維持（互換）。出力 1 行 `starter_kit_version:<value>` も変更なし。値の取得元のみ marketplace.json に切替
- **実装**: `lib/version.sh::read_marketplace_version` を経由する（指摘 #2 対応 / 直接 dasel/jq を呼ばない）。env-info.sh は既に `lib/bootstrap.sh` を `source` しており、bootstrap.sh から `lib/version.sh` を追加 `source` する形で取り込む（既存パターン踏襲）
- **依存**: `lib/version.sh::read_marketplace_version` のみ（dasel/jq 直接依存は同関数内に閉じ込める）

> **注**: 関数名 `get_starter_kit_version` は歴史的経緯で残るが、コメントで「正本は marketplace.json から取得」を明記する。

#### Migrate Layer の fallback 切替（GATE-2 (C) / 指摘 #1 対応）

- **対象**: `migrate-apply-config.sh:217-218`, `migrate-verify.sh:188-189`
- **変更内容**: aidlc コンテキストへの逆依存を回避するため、**migrate コンテキスト内で完結**する以下のいずれかの方式を採用する:
  - **方式 A（推奨）**: 各スクリプト内で `jq -r '.metadata.version' "${marketplace_json_path}"` のインライン呼び出し（migrate は既に jq を必須依存として使用）
  - **方式 B**: `skills/aidlc-migrate/scripts/lib/` 配下に `marketplace_version.sh` を新規作成し、`migrate_read_marketplace_version()` 関数を実装。両スクリプトから `source` する
- **採用方式**: Phase 2 のコード生成時点で「migrate 内 2 箇所のみ変更で済むか、それ以上か」で決定。2 箇所のみなら方式 A、3 箇所以上なら方式 B
- **禁止事項**: `skills/aidlc/scripts/lib/version.sh` を直接 `source` してはならない（コンテキスト境界違反）
- **制約**: migrate の主ロジック（journal ベース判定）は不変。`expected_version` の取得経路のみ変更
- **依存**: `jq` のみ（既存依存。dasel 不要）。リモート取得は行わずローカル `marketplace.json` のみ参照

## インターフェース設計

### スクリプトインターフェース設計

#### bin/update-version.sh（再構築後 / 指摘 #4 対応）

##### 後方互換性宣言

本 Unit による `bin/update-version.sh` の出力キー変更（`version_txt:*` / `skill_aidlc_version:*` / `skill_setup_version:*` → `marketplace_version:*`）は **破壊的変更（breaking change）** として明示する。

- **影響範囲調査結果**: 本リポジトリ内で `update-version.sh` の stdout 出力キーを解析している箇所は `bin/tests/test_update_version_no_toml_write.sh` のみ。本 Unit で同期更新するため repo 内の破壊的影響なし
- **外部依存の懸念**: 本スクリプトは内部 CI / リリースフローでしか使われておらず、外部の自動化スクリプトに公開していない（README やドキュメント上で公開 API として案内していない）。リリースノートに「破壊的変更」として記載する
- **CLI 互換維持**: コマンドライン引数（`--version <ver>` / `--dry-run`）と終了コード（`0=成功 / 1=エラー`）は維持
- **互換キー併記しない理由**: 旧キー（`version_txt:*` 等）の併記は version.txt が削除されるため意味が消失する。残すと混乱を招くため新キーに完全置換する

##### 概要

`marketplace.json.metadata.version` を SoT として更新する。

##### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--version <ver>` | 必須 | 新バージョン（v プレフィックス可: `v2.6.0` → `2.6.0` に正規化） |
| `--dry-run` | 任意 | 書き込み実行なし、現在値・新値を表示 |

##### 成功時出力

```text
version_update:success
marketplace_version:<新値>
```

dry-run 時:

```text
version_update:dry-run
marketplace_version_current:<現値>
marketplace_version_new:<新値>
```

- 終了コード: `0`
- 出力先: stdout

##### エラー時出力

```text
error:<エラー種別>
```

エラー種別の例:

- `error:missing-version` / `error:missing-version-value` / `error:invalid-version-format`
- `error:marketplace-json-not-found` / `error:marketplace-json-read-failed` / `error:marketplace-json-write-failed`
- `error:invalid-marketplace-json-format` / `error:dasel-and-jq-unavailable`
- `error:mktemp-failed` / `error:backup-failed`

- 終了コード: `1`
- 出力先: stdout（既存契約踏襲）

##### 削除する出力キー

- `version_txt:<v>` / `version_txt_current:<v>` / `version_txt_new:<v>`
- `skill_aidlc_version:<v>` / `skill_aidlc_version_current:<v>` / `skill_aidlc_version_new:<v>`
- `skill_setup_version:<v>` / `skill_setup_version_current:<v>` / `skill_setup_version_new:<v>`

#### bin/check-marketplace-version.sh

##### 概要

PR の差分に release 関連変更（`CHANGELOG.md` / `.aidlc/operations.md` の version 表記等）が含まれる場合、`marketplace.json.metadata.version` が同 PR 内で更新されているかを検証する。

##### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--base <ref>` | 任意 | 比較先 ref（デフォルト `origin/main`） |
| `--current <ref>` | 任意 | 比較元 ref（デフォルト `HEAD`） |

##### 成功時出力

```text
marketplace_version_check:ok
base_version:<v>
current_version:<v>
```

##### エラー時出力

```text
marketplace_version_check:violation
reason:<reason_code>
detail:<message>
```

`reason_code` の例: `marketplace_version_unchanged`, `marketplace_json_missing`, `invalid_format`

- 終了コード: `0=ok` / `1=violation` / `2=execution-error`

##### トリガー条件（pr-check.yml）

`PATHS_REGEX` を以下に拡張:

```text
^(.+\.md|.+\.toml|\.markdownlint\.json|\.github/workflows/pr-check\.yml|bin/check-bash-substitution\.sh|bin/check-defaults-sync\.sh|\.claude-plugin/marketplace\.json)$
```

（`version\.txt` / `skills/(.+/)?version\.txt` は削除）

### コマンド: lib/version.sh の関数

#### read_marketplace_version(json_path)

- **パラメータ**: `json_path`（string）- marketplace.json の絶対 or 相対パス
- **戻り値**: stdout に SemVer、終了コードは下記の通り
- **終了コード仕様（Round 4 対応 / exit 2 の再定義）**:

  | exit | 意味 | 例 |
  |------|------|-----|
  | 0 | 成功 | 抽出値あり |
  | 1 | コンテンツエラー（`metadata.version` キー不在 / 値が空 / 非 SemVer 値） | パース不能・キー欠落 |
  | 2 | 実行環境エラー（I/O 失敗 + dasel/jq 双方不在を含む） | ファイル不在・読取権限なし・抽出ツール全滅 |

  `error:dasel-and-jq-unavailable` は `exit 2` の表現の 1 つ（実行環境上の制約のため I/O 失敗と同分類）。Phase 2 のテストでは exit 2 となるサブケース全パターンを stdout のエラーメッセージで判別する。
- **副作用**: なし（読取専用）
- **抽出ロジック（指摘 #3 対応 / 仕様確定）**: dasel 優先（`dasel -i json '.metadata.version'`）→ jq フォールバック（`jq -r '.metadata.version'`）。両ツール不在時は exit 2 で `error:dasel-and-jq-unavailable` をエラー出力（**`grep+sed` 最終フォールバックは持たない**）。理由: JSON のネスト・エスケープを `grep+sed` で安全にパースできないため、不確実な抽出を避ける。CI 環境（ubuntu-latest）には `jq` がプリインストール、ローカル開発環境は `dasel` 必須前提（既存 `env-info.sh` と整合）

#### read_starter_kit_version(config_toml_path)【既存・互換維持】

- 既存の振る舞いを維持。コメントを追加: 「本関数の戻り値は config.toml キャッシュ値であり正本ではない。正本は `read_marketplace_version` を使用すること」

## データモデル概要

### ファイル形式: .claude-plugin/marketplace.json

- **形式**: JSON
- **正本フィールド**: `metadata.version`（SemVer 文字列）
- **更新主体**: `bin/update-version.sh`
- **直接編集**: 禁止（CI ガードで検出）

### ファイル形式: .aidlc/config.toml

- **形式**: TOML
- **キャッシュフィールド**: `starter_kit_version`（SemVer 文字列）
- **役割**: アップグレード差分検出のためのローカルキャッシュ値（正本ではない）
- **更新主体**: `aidlc-setup` / `aidlc-migrate`（本 Unit 範囲外）

## 処理フロー概要

### ユースケース1: `/aidlc version` 実行

**ステップ**:

1. SKILL.md「バージョン表示」セクションで `read_marketplace_version` を呼び出す（経由パス: スキルベースディレクトリ → `../../.claude-plugin/marketplace.json` を解決）
2. exit 0 + stdout に値 → 「AI-DLC Starter Kit v{version}」を表示
3. exit ≠ 0 または値が空 → 「AI-DLC Starter Kit (version unknown)」を表示

**関与するコンポーネント**: SKILL.md, lib/version.sh

### ユースケース2: `env-info.sh starter_kit_version` 出力

**ステップ**:

1. env-info.sh の `get_starter_kit_version()` が呼ばれる
2. 内部で `lib/version.sh::read_marketplace_version "${marketplace_json_path}"` を呼び出す（`bootstrap.sh` 経由で同 lib を `source` 済 / 指摘 #2 対応）
3. `read_marketplace_version` が dasel 優先 / jq フォールバックで `metadata.version` を抽出し stdout に返す（両ツール不在時は exit 2）
4. 取得値を stdout に `starter_kit_version:<value>` 形式で出力（取得失敗時は空値）

**関与するコンポーネント**: env-info.sh, lib/version.sh::read_marketplace_version, marketplace.json

### ユースケース3: Inception ステップ5a の 3 経路 version 取得

**ステップ**:

1. **リモート**: `curl -s --max-time 5 https://raw.githubusercontent.com/ikeisuke/ai-dlc-starter-kit/main/.claude-plugin/marketplace.json` 取得 → `dasel`/`jq` で `.metadata.version` 抽出
2. **スキル**: スキルベースディレクトリ（SKILL.md の親ディレクトリ）から `../../.claude-plugin/marketplace.json` を解決 → `read_marketplace_version` 呼び出し
3. **ローカルキャッシュ**: `read-config.sh starter_kit_version` で `config.toml` キャッシュ値を取得（正本ではないことを明記）
4. 各値を `guides/version-check.md` の比較ロジックに渡す（比較ロジックは保持）

**関与するコンポーネント**: 01-setup.md, curl, dasel/jq, lib/version.sh, read-config.sh

### ユースケース4: リリース時の version bump

**ステップ**:

1. Operations Phase で `bin/update-version.sh --version v2.6.0` を実行
2. `marketplace.json.metadata.version` が `2.6.0` にアトミック更新（mktemp + mv パターン）
3. dry-run / 通常モードのいずれも `marketplace_version_*` 出力に変更

**関与するコンポーネント**: update-version.sh, lib/version.sh, marketplace.json

### ユースケース5: pre-release CI ガード

**ステップ**:

1. PR 作成 / synchronize 時に `pr-check.yml` の `marketplace-version-check` ジョブが起動
2. `bin/check-marketplace-version.sh --base origin/main` で base/current の `metadata.version` を比較
3. リリース関連変更（`CHANGELOG.md` 等）が含まれるが version 未更新 → exit 1 で fail

**関与するコンポーネント**: pr-check.yml, check-marketplace-version.sh, lib/version.sh, git（gh 不依存 / 指摘 #5 対応）

### ユースケース6: auto-tag

**ステップ**:

1. main へ push → `auto-tag.yml` 起動
2. `marketplace.json` から `metadata.version` を抽出（`dasel -i json '.metadata.version' < .claude-plugin/marketplace.json` または jq フォールバック）
3. 既存タグがなければ `v{version}` を作成・push

**関与するコンポーネント**: auto-tag.yml, dasel/jq

## 非機能要件（NFR）への対応

### 正確性

- **要件**: 移行前後でバージョン表示・比較ロジックが同一値を返すこと
- **対応策**:
  - `read_marketplace_version` のテストで `metadata.version` が正しく抽出されることを保証
  - dasel / jq の **2 経路** で同一値を返すことを単体テストで検証（grep+sed フォールバックは廃止のためテスト対象外 / 指摘 #3 対応）
  - 移行直後は手動で `/aidlc version` 出力と `env-info.sh starter_kit_version` 出力を目視確認（実装承認時）

### 段階性（依存順序遵守）

- **要件**: 参照側移行 → ファイル削除の順序を厳守
- **対応策**: 論理段階を 4 段（バックフィル → 参照側コード切替 → 削除 + CI ガード追加 → ドキュメント更新）に分け、各段でテスト実行。`squash-unit` で最終 1 コミットに集約

### 観測性

- **要件**: pre-release / CI ガードで `marketplace.json` 未更新を検出可能
- **対応策**: `bin/check-marketplace-version.sh` + `pr-check.yml` 新規ジョブ。violation 時は明示的な reason_code を出力

### 互換性

- **要件**: 外部 CLI 互換（`bin/update-version.sh --version`）/ 関数 API 互換（`read_starter_kit_version`）/ env-info.sh 出力契約（`starter_kit_version:<v>`）を維持
- **対応策**:
  - `update-version.sh` の `--version` / `--dry-run` 引数は維持。出力キーのみ `marketplace_version_*` に変更
  - `read_starter_kit_version` は名前・シグネチャを維持し、コメントで用途を限定
  - `env-info.sh` の出力 1 行（`starter_kit_version:<value>`）はそのまま維持

## 技術選定

- **言語**: Bash (>= 3.2 / macOS BSD 互換)
- **依存ツール**（指摘 #3 対応 / Round 2 反映）:
  - `dasel` v3.x（既存環境での主依存、env-info.sh の前提。JSON 抽出の優先ツール）
  - `jq` 1.6+（dasel 不在時のフォールバック。CI 環境（ubuntu-latest）にプリインストール）
  - `curl --max-time 5`（リモート取得、既存通り）
  - **`grep` / `sed` は JSON 抽出のフォールバックとしては使用しない**（廃止）。本 Unit のシェルスクリプト全般でテキスト整形等に使用するのは引き続き許容
- **テストフレームワーク**: 既存の bash assert スタイル（`bin/tests/`, `skills/aidlc/scripts/tests/`）

## 実装上の注意事項

- **JSON 改行保持**: `marketplace.json` の書き込みは末尾改行を含めて保持する（`dasel put` は末尾改行を保持しないため、必要に応じて手動制御）
- **アトミック書込**: 同一 FS 上で `mktemp` + `mv` パターンを使用（既存 `update-version.sh` の方式踏襲）
- **shellcheck**: 新規スクリプト（`check-marketplace-version.sh`）は shellcheck 通過を必須
- **依存ツール不在時の挙動**: `dasel` / `jq` 双方不在 → `update-version.sh` は exit 1 with `error:dasel-and-jq-unavailable`（CI 環境では jq が必ず利用可能なため実害は限定的）
- **テスト容易性**: `lib/version.sh` の関数は副作用ない純関数として保持し、`source` してテストできる構造を維持

## 不明点と質問

[Question] `read_marketplace_version` のキー一意性検証は不要か（`metadata.version` は JSON のため自然と単一値）。
[Answer] 不要。JSON は構文上 `metadata.version` キーが重複できないため、TOML での重複検証（`read_starter_kit_version` の grep -c）は本関数では不要。dasel/jq の抽出結果が空文字または非 SemVer の場合のみエラー扱い。

[Question] `dasel put` で JSON を書き換える場合、既存フォーマット（インデント・改行）は保持されるか。
[Answer] dasel v3 はデフォルトで `--pretty=true`（2 スペースインデント保持）。末尾改行については、`update-version.sh` 側で書き込み後に末尾改行が消えていないかを検証し、必要なら追加する。テストでは「diff 比較で metadata.version 行のみ変更」を検証する。

[Question] `bin/check-marketplace-version.sh` の「リリース関連変更」検出基準は何か。誤検知を避けたい。
[Answer] 本 Unit ではシンプルなアプローチを採用: PR 差分に以下のいずれかが含まれる場合に「リリース関連変更」と判定する:
- `CHANGELOG.md` の編集
- `.aidlc/operations.md` の編集

これらが含まれかつ `marketplace.json.metadata.version` が変更されていない場合に violation。誤検知時は手動でラベル `skip-version-check` を付与して回避（フォールバック策）。詳細実装は Phase 2 で確定。

> **注（Round 3 反映）**: 過渡期に挙げていた `version.txt` の編集条件は、本 Unit 内で `version.txt` 系 3 ファイルを削除するため判定基準から除外する。`PATHS_REGEX` も本 Unit で `version\.txt` を除外済みであり、判定基準と一致させる。

[Question] auto-tag.yml は dasel / jq のどちらを使うか。GitHub Actions の ubuntu-latest にはどちらも利用可能。
[Answer] **jq を採用**。理由: ubuntu-latest に jq がプリインストールされており追加 setup 不要。auto-tag は CI 専用のため env-info.sh の dasel 優先方針とは独立に判断する。

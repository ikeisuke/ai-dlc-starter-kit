# Design 003: v2 → v3 migration 実装（new-cycle-only + archive-only）

- trace: work item 003-migrate-v2-to-v3-core
- matrix_case: risky_standard
- design_mode: full

## Goal

v2 consumer が `docs/v3/migration.md` §6 の手順方針に沿って v3 へ移行できる実装を提供する
（Epic #736 7-c / AC-3〜AC-6）。推奨モード new-cycle-only（v2 config 読み込み → v3 config 生成 +
state.json 初期化）を必須実装とし、archive-only（v2 cycles の所在 index 生成のみ）を併せて実装する。
best-effort は未実装案内 + 安全中断のみ提供する。

## Context

### 規範ドキュメントと確定事項

- **migration.md §6（手順方針の正本）**: (1) v2 config 読み込み → v3 config 生成（キーマッピング +
  不要キー警告） → (2) 移行モード選択の人間確認 → (3) モード別データ変換 → (4) 変換結果の人間確認 →
  (5) state.json 初期化。担当スキルは `/aidlc-migrate`（フェーズコマンドではなく移行専用 extension /
  RFC §4.3）。
- **キーマッピング（migration.md §3.1 / schema 正本は data-model.md §11）**: v2 34 キー → v3 8 キー。
  維持 7 キー（`rules.depth_level.level` / `rules.automation.mode` / `rules.reviewing.mode` /
  `rules.reviewing.tools` / `rules.reviewing.exclude_patterns` / `rules.release.changelog` /
  `rules.release.version_tag`、いずれも identity mapping）+ v3 新規 1 キー
  （`rules.release.required_ci_zero_fallback`、生成時に既定 `false` を適用し v2 から引き継がない）。
  ドロップ 27 キーは**警告のみでエラーにしない**（非互換点 #3「未サポートキーは無視される」と整合）。
- **state-init.sh（skills/aidlc-v3/scripts/）**: `state-init.sh <current_cycle> [file]` の
  create-only 生成（`ln` による原子化 / 既存 state.json があれば exit 1）。cycle id 健全性ガード
  `^[A-Za-z0-9][A-Za-z0-9._-]*$`。exit 0/1/2 規約。`AIDLC_STATE_NOW` でテスト時刻固定可。
- **片方向移行（rollback 不可）**: migration.md §1/§5/§7 に方針記述あり。ただし §6 手順に
  実行時警告の出力位置は未規定 → 本設計 D3 で確定する。
- **archive-only index の生成先・フォーマット**: migration.md 未規定 → 本設計 D5 で確定する。

### 既存実装・インフラ

- `skills/aidlc-migrate/` は v1→v2 移行スキル（steps/01-preflight → 02-execute → 03-verify、
  scripts/migrate-detect / apply-config / apply-data / cleanup / verify + lib/path-guard.sh）。
  SKILL.md は v1→v2 前提の直列 3 ステップのみで、バージョン分岐ルーティングは未実装。
- テスト: `tests/migration/*.bats`（bats 形式）は CI `migration-tests.yml` が
  **ディレクトリ単位**（`bats tests/migration/ ...`）で実行するため、同ディレクトリへの
  ファイル追加は workflow 編集なしで CI 対象になる。fixtures は `tests/fixtures/` 配下。
- parse-guard（`bin/check-frontmatter-parse-guard.sh`）の走査対象は `skills/aidlc-v3/scripts`
  のみ（lib/ と tests/ を除く）。`skills/aidlc-migrate/` 配下は対象外。
- cycle 構造の世代差: v2 以前の cycle は `.aidlc/cycles/<ver>/` 配下に `inception/` /
  `construction/` / `operations/` / `requirements/` / `story-artifacts/` 等のサブディレクトリ構造、
  v3 cycle は `work-items/` を持つフラット構造（本リポジトリに全 149 cycle が実在）。
- **define フローとの統合ギャップ**: `steps/define.md` 4-3 は `state-init.sh` を無条件実行し、
  既存 state.json があると exit 1 で停止する。migration が state.json を初期化（§6 手順 5 /
  AC-3）した後に consumer が define を実行すると衝突する → 本設計 D6 で解決する。

### 制約

- リポジトリ規約「ドッグフーディング特殊処理を本体に埋めない」: 分岐はすべてファイル存在の
  opt-in シグナルまたは明示引数で表現する。
- bash-tool-safety 規約（コマンド置換禁止は Bash ツール引数文字列が対象。スクリプト内部の
  `$(...)` は対象外）。result-out 関数を作る場合は `_local_<fn>_` 命名規約に従う。
- スコープ外: best-effort の実データ変換（後続サイクルへ defer）、v2 runtime 互換維持、v2 EOL 運用。

## Design

### D1: 実装配置 — 既存 `skills/aidlc-migrate` 拡張（新規スキルを作らない）

**決定**: v2→v3 migration は既存 `skills/aidlc-migrate` スキルの拡張として実装する。

理由:

1. migration.md §6 が担当スキルを `/aidlc-migrate` と規範的に指定している（移行専用 extension）。
2. marketplace 登録済みスキルの再利用で consumer 側の導入手順が増えない（新規スキル登録不要）。
3. `tests/migration/` の CI 配線・`lib/path-guard.sh` 等の既存移行インフラをそのまま再利用できる。

v1→v2 の既存 steps/scripts は**無変更**とし、v2→v3 は独立した step ファイル + スクリプト群を
新設する（両世代のロジックを混在させない）。

新規 / 変更ファイル一覧:

| ファイル | 種別 | 責務 |
|---------|------|------|
| `skills/aidlc-migrate/SKILL.md` | 変更 | 移行元バージョン検出ルーティング節を追加（D2） |
| `skills/aidlc-migrate/steps/v3-migrate.md` | 新規 | v2→v3 フロー全体のオーケストレーション（D3） |
| `skills/aidlc-migrate/scripts/migrate-v3-preflight.sh` | 新規 | v2→v3 前提検証 + 片方向警告出力（D3-0/1） |
| `skills/aidlc-migrate/scripts/migrate-v3-config.sh` | 新規 | v2 config 読取 → v3 config プラン生成 / 適用（D4） |
| `skills/aidlc-migrate/scripts/migrate-v3-archive-index.sh` | 新規 | v2 cycles 所在 index 生成（D5） |
| `skills/aidlc-v3/steps/define.md` | 変更 | 4-3 に state.json 初期化済み resume 経路を追記（D6） |
| `tests/migration/migrate-v3-*.bats` | 新規 | bats テスト 3 本（D7） |
| `tests/fixtures/v2-config-generations/` | 新規 | v2 config 世代差 fixtures（D7） |

### D2: SKILL.md ルーティング（移行元バージョン検出）

SKILL.md 冒頭に「移行対象の判定」節を追加し、ファイル存在の opt-in シグナルのみで分岐する:

| 判定（評価順） | ルーティング |
|--------------|------------|
| `.aidlc/state.json` が存在 | 既に v3 移行済み。案内して終了（書き込みなし） |
| v1 マーカー（`docs/aidlc.toml` 等 / 既存 01-preflight の検出条件） | 既存 v1→v2 フロー（steps/01〜03） |
| `.aidlc/config.toml` が存在 + `.aidlc/state.json` 不在 | v2→v3 フロー（`steps/v3-migrate.md`） |
| いずれも不在 | AI-DLC 未セットアップ。`aidlc-setup` を案内して終了 |

v1 と v2 のマーカーが同時に存在する場合は v1→v2 を優先し、v1→v2 完了後に再実行で v2→v3 に
進む 2 段階移行を案内する（1 実行 1 世代）。

### D3: v2→v3 フロー（`steps/v3-migrate.md`）

migration.md §6 の 5 手順を以下の 7 ステップに展開する。人間確認ゲート（★）は 2 箇所。
**スクリプトは非対話・決定的**とし、ゲートと対話は step ファイル（AI エージェント）の責務に置く。

| Step | 内容 | §6 対応 | 書き込み |
|------|------|--------|---------|
| 0 preflight | `migrate-v3-preflight.sh` 実行（git repo / clean worktree / `.aidlc/config.toml` 存在 / `.aidlc/state.json` 不在 / jq 存在） | 前提 | なし |
| 1 片方向警告 | **片方向移行（rollback 不可）警告をユーザーに明示**（AC-5） | §1/§5/§7 | なし |
| 2 ★ モード選択 | new-cycle-only（推奨）/ archive-only / best-effort の 3 択を提示し人間が選択 | 手順 2 | なし |
| 3 プラン生成 | `migrate-v3-config.sh --plan` で変換プラン（keep/default/drop/warn）を提示 + 新 cycle id をユーザーに確認（`^[A-Za-z0-9][A-Za-z0-9._-]*$` 検証）+ archive-only 時は index プレビュー | 手順 1/3 | なし |
| 4 ★ 変換結果確認 | プラン全体（v3 config 内容 / state.json 初期値 / index 内容）を提示し人間が承認 | 手順 4 | なし |
| 5 適用 | `migrate-v3-config.sh --apply` →（archive-only 時）`migrate-v3-archive-index.sh` → `state-init.sh <cycle>` | 手順 3/5 | あり |
| 6 サマリ | 適用結果 + 警告一覧の再掲 + 次アクション（`/aidlc-v3 define`）案内。commit はユーザー責務（migration は commit しない） | - | なし |

- **片方向警告の出力位置（未定義ギャップの確定）**: Step 1（モード選択ゲートの前）で step が
  警告文を明示するのを正とし、加えて `migrate-v3-preflight.sh` が stderr に
  `warn:one-way-migration:...` 行を出力する（スクリプト単体実行でも警告が届く二重化）。
  Step 4 の承認プロンプトにも「適用後は v2 への巻き戻しを保証しない」を再掲する。
- **best-effort の安全中断（AC）**: Step 2 で best-effort が選択された場合、未実装である旨と
  後続サイクルで提供予定（Epic #736 / v2 EOL 3 条件とセット）を案内し、**書き込みゼロ**で
  終了する（exit 0 / 中断は正常系）。
- Step 5 の適用順序は「config → index → state.json」とする。state.json 生成を最後に置くことで、
  途中失敗時に「v3 移行済みマーカー（= state.json）だけが存在する部分状態」を作らない
  （D2 の判定が state.json を移行済みシグナルとするため）。

### D4: config 変換仕様（`migrate-v3-config.sh`）

```text
Usage: migrate-v3-config.sh --plan [--source <v2-config>] [--target <v3-config>]
       migrate-v3-config.sh --apply [--source <v2-config>] [--target <v3-config>]
既定: --source .aidlc/config.toml / --target .aidlc/config.toml
Exit: 0 正常 / 1 入力・検証エラー（source 不在・パース不能） / 2 システムエラー
```

- **読取**: 維持 7 キーを awk によるセクション追跡型の最小 TOML 抽出で読む（対応型は当該キーの
  実型のみ: string / bool / array of string。汎用 TOML パーサは実装しない）。
  `skills/aidlc/scripts/read-config.sh` は 4 階層 defaults マージを行うため**使わない**
  （migration では「v2 project config に明示された値」だけを移行対象とし、未設定キーは
  v3 既定値に委ねる、という区別が必要なため）。
- **生成**: v3 config.toml は data-model.md §11 の 8 キーを**全て明示値**で出力する
  （v2 明示値があればその値、なければ §11 既定値。`required_ci_zero_fallback` は常に `false`）。
  ヘッダコメントに migration 由来である旨と生成手段を記録する。
- **enum / 型検証**: 維持キーの値が v3 の enum / 型に適合しない場合は警告 + §11 既定値へ
  フォールバックする（エラーにしない / 非互換点 #3 と同思想）。
- **drop 警告**: v2 config の全終端キーを列挙し、維持 7 キー以外（§3.1 の 27 キーおよび
  未知・カスタムキーを含む）を `drop:<key>` として警告出力する。**エラーにしない**。
- **出力形式（--plan）**: 行指向の構造化出力（`keep:<key>=<value>` / `default:<key>=<value>` /
  `drop:<key>` / `warn:<code>:<detail>`）。step はこれを人間向けの表に整形して提示する。
- **--apply**: 同一ディレクトリ mktemp + `mv` の atomic replace で target を上書きする
  （state-write.sh と同じ「置換は mv」プリミティブ）。

### D5: archive-only index 仕様（未定義ギャップの確定）

- **生成先**: `.aidlc/v2-archive.md`（`.aidlc/cycles/` 配下に置かない: v3 ツールの cycle
  ディレクトリ走査と衝突させないため）。
- **判定**: `.aidlc/cycles/*/` を列挙し、v3 フラット構造マーカー（`work-items/` ディレクトリ）を
  **持たない**ものを archive 対象とする（v1/v2 世代差を吸収する消極マーカー方式。
  リポジトリ固有名の判定は持たない）。
- **内容**: 見出し + 生成日時 + 「v2 以前の資産は参照用に残置され v3 ツールから操作不可」の注記 +
  cycle 一覧表（ディレクトリ名 / 主要成果物の存在: `intent`・`units`・`progress.md`・`history`・
  `release_notes`）。
- **冪等性**: 再実行時はファイル全体を再生成する（追記しない）。既存ファイルがある場合も
  atomic replace で置換する。
- exit 規約は D4 と同一（0/1/2）。

### D6: state.json 初期化と define フロー統合

- **再利用**: `state-init.sh` を 2 候補フォールバックで解決して呼び出す
  （`skills/aidlc-v3/scripts/state-init.sh` → `skills/aidlc/scripts/state-init.sh`）。
  後者は v3 本流化（Phase 7 / `skills/aidlc-v3` → `skills/aidlc` 置換）後の位置であり、
  リネーム後も migration が壊れないための汎用 2 候補ルックアップとする。
- **cycle id**: Step 3 でユーザーが確認した新 cycle id を渡す（consumer 自身の次サイクル識別子）。
- **define 4-3 との統合（衝突解消）**: `skills/aidlc-v3/steps/define.md` 4-3 に以下の resume
  経路を追記する: 「`.aidlc/state.json` が既に存在し、`current_cycle` が Step 2 で確定した
  cycle と一致し、かつ `define_completed: false` の場合、4-3（`state-init.sh`）を skip して
  4-4 に進む。`current_cycle` が不一致の場合は状態を提示して停止する（上書きしない）」。
  これは migration 固有分岐ではなく「state.json 初期化済み環境での define 再開」という
  汎用規則として記述する（ドッグフーディング特殊処理にも該当しない）。

### D7: テスト・検証構造

- **bats テスト**（`tests/migration/` に追加 → `migration-tests.yml` がディレクトリ単位実行のため
  workflow 編集なしで CI 対象）:
  - `migrate-v3-config.bats`: --plan/--apply、keep/default/drop 分類、enum 外値フォールバック、
    世代差 fixtures、atomic replace、exit code 規約
  - `migrate-v3-archive-index.bats`: v2/v3 混在 cycles での判定、冪等再生成、空 cycles
  - `migrate-v3-preflight.bats`: state.json 既存で中断、config 不在で中断、dirty worktree で中断、
    片方向警告行の出力
- **fixtures**（`tests/fixtures/v2-config-generations/`）: 世代差 3 種
  - `gen-early-minimal/`: 初期世代相当（維持キーがほぼ未設定 / 既定値フォールバック検証）
  - `gen-2.5.5-full/`: 本リポジトリ相当の 34 キーフルセット
  - `gen-unknown-keys/`: 未知キー・カスタムキー混入（警告のみでエラーにしないことの検証）
- **静的検証**: 新規スクリプト全てに shellcheck をローカル実行して green を確認。parse-guard は
  走査対象（`skills/aidlc-v3/scripts`）に新規スクリプトを置かないため既存 green を維持する
  （define.md はドキュメントで対象外）。既存テストスイート（bats / v3 scripts/tests）の
  非退行も確認する。

## Rollback Note

- **適用前の復元保証**: preflight で clean worktree を必須とするため、適用直前の状態は git で
  完全に復元できる。migration スクリプトは commit を行わない（ユーザーが確認してから commit）。
- **適用後の切り戻し手順**: 書き込みは 3 点のみ（`.aidlc/config.toml` 置換 / `.aidlc/state.json`
  新規 / `.aidlc/v2-archive.md` 新規）。ファイルレベルの切り戻しは
  `git checkout -- .aidlc/config.toml` + `rm .aidlc/state.json .aidlc/v2-archive.md` で完了する。
  ただし **v2 runtime 互換・v2 サポート継続は保証しない**（migration.md §1/§5/§7 の
  「片方向移行」の意味）— この限定を実行時警告（D3 Step 1/4）で consumer に明示する。
- **部分失敗時**: D3 Step 5 の適用順序（config → index → state.json 最後）により、途中失敗時も
  「state.json だけ存在する移行済み誤認状態」は生じない。失敗時は上記ファイルレベル切り戻しで
  再実行可能な初期状態に戻せる。
- **本 work item 実装自体の切り戻し**: develop Step 6 で work item 単位の単一 commit に集約する
  ため、revert 1 つで全変更（新規スクリプト・SKILL.md ルーティング節・define.md 追記・テスト）が
  戻る。v1→v2 既存フローへの変更は SKILL.md のルーティング節追加のみで、revert の影響は局所に
  留まる。

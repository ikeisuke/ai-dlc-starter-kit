# 論理設計: Unit 001 feedback_mode 5 値拡張 + マイグレーション + 初回 wizard

## 概要

ドメインモデル（`unit_001_feedback_mode_config_and_wizard_domain_model.md`）を、
既存の `skills/aidlc/scripts/lib/` 階層と `skills/aidlc-migrate/scripts/` 階層に
シェルスクリプト関数として落とし込むための論理設計。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成・I/F・処理フローのみ定義します。

---

## アーキテクチャパターン

**レイヤード（責務分離）アーキテクチャ + 純粋関数優先**

| レイヤー | 役割 | 副作用 | 対話性 |
|---------|------|--------|--------|
| ドメイン純粋関数層 | `feedback_mode_resolve` / `feedback_cap_check` 等 | なし | 非対話 |
| I/O 抽象層 | `read-config.sh` / `write-config.sh` ラップ | ファイル読書 | 非対話 |
| オーケストレーション層 | `feedback_mode_wizard` / `migrate-feedback-mode` | ファイル書 + プロンプト起動 | 対話必須 |
| 純粋適用層 | `migrate-apply-config.sh` 既存路 | ファイル書 | 非対話 |

**選定理由**:

- レビュー指摘 #1 の対応として、`migrate-apply-config.sh` を「純粋適用層」に保持し、対話制御を上位層へ分離
- 純粋関数（resolve / cap_check）は BATS で副作用なくユニットテストできる
- 4 階層 config マージは既存 `read-config.sh` を信頼してラップ層を作らない（YAGNI）

---

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc/scripts/
├── lib/
│   ├── feedback-mode.sh          # 新規: ドメイン純粋関数 + I/O ラップ + 環境判定
│   │   ├── is_interactive_env()           # 環境判定（tty + CI ガード単一化）
│   │   ├── feedback_mode_normalize()      # 旧値→新値 文字列正規化
│   │   ├── feedback_mode_resolve()        # 純粋関数: mode + env → 実行モード（4 値のみ）
│   │   ├── feedback_mode_requires_wizard()  # 純粋関数: mode + env → wizard 起動要否
│   │   ├── feedback_cap_check()           # 純粋関数: mode + count → 起票可否
│   │   └── feedback_mode_save()           # I/O: write-config.sh ラップ
│   └── feedback-mode-wizard.sh   # 新規: 対話オーケストレーション（read -p ベース）
│       └── feedback_mode_wizard()         # 数値選択 + save 委譲。AskUserQuestion 不使用
├── read-config.sh                # 既存: feedback_mode 読込時に normalize 適用するよう更新
├── write-config.sh               # 既存: feedback_mode 書込時に enum バリデーション追加
├── retrospective-generate.sh     # 既存: feedback_mode 解決を feedback-mode.sh に委譲（互換アダプタ層化）
└── retrospective-mirror.sh       # 既存: 同上（feedback_mode_resolve 経由に変更）

skills/aidlc-migrate/scripts/
├── migrate-feedback-mode.sh      # 新規: 対話オーケストレーション（旧値検出 + 同意 + manifest 拡張への積み込み）
├── migrate-detect.sh             # 既存: 旧値検出を本フローに組み込む（detect ステージで feedback_mode_legacy リソース検出）
└── migrate-apply-config.sh       # 既存: 純粋適用層に限定。manifest の resource_type=feedback_mode_migrate を新規処理（write-config.sh ラッパ呼び出し）。対話制御は持たない

skills/aidlc/config/defaults.toml # 既存: feedback_mode の 5 値 enum 制約コメント + 既定値更新
```

### コンポーネント詳細

#### `feedback-mode.sh`（新規 / ドメイン純粋関数 + I/O ラップ）

- **責務**: 5 値の正規化・解決・cap 判定・設定保存。**対話制御は持たない**
- **依存**: `read-config.sh` / `write-config.sh`（既存）
- **公開関数**:
  - `is_interactive_env()`
  - `feedback_mode_normalize(raw)`
  - `feedback_mode_resolve(mode, env_interactive)`
  - `feedback_mode_requires_wizard(mode, env_interactive)`
  - `feedback_cap_check(mode, current, limit)`
  - `feedback_mode_save(mode, scope)`
- **副作用**: `feedback_mode_save` のみ書込。他は純粋関数

#### `feedback-mode-wizard.sh`（新規 / 対話オーケストレーション層）

- **責務**: `read -p` ベースの 5 値数値選択 → `feedback-mode.sh` の `feedback_mode_save` を呼び出し（指摘 #6 への対応で AskUserQuestion 依存を排除）
- **依存**: `feedback-mode.sh`（同階層）。AskUserQuestion / 外部 CLI ツール依存なし
- **公開関数**: `feedback_mode_wizard()`
- **対話前提**: 呼び出し側が `is_interactive_env() == true` をガードしてから呼ぶ。違反時は exit 2
- **副作用**: ファイル書 + 対話プロンプト（stderr に選択肢表示）

#### `migrate-feedback-mode.sh`（新規 / マイグレーション オーケストレーション層）

- **責務**: 旧値検出 → 同意取得 → 確定値を **manifest に積み込んで** `migrate-apply-config.sh` に渡す → 失敗時 rollback 発火（指摘 #4 への対応で「manifest 拡張経路」に固定）
- **依存**: `read-config.sh`（旧値検出）/ `feedback-mode.sh`（is_interactive_env / mapping 解決）/ `read -p` 同意プロンプト / `migrate-apply-config.sh`（既存・拡張） / 既存 backup/rollback 機能
- **公開関数**: `migrate_feedback_mode()` または直接 main 実行
- **副作用**: バックアップ作成 + 同意プロンプト + 適用委譲 + 必要時 rollback 実行

#### `migrate-apply-config.sh`（既存 / 純粋適用層 / 拡張）

- **責務**: 既存通り「manifest 適用（非対話）」。本 Unit で **対話制御は追加しない**（指摘 #1 への対応）
- **追加処理**: manifest の resource_type=`feedback_mode_migrate` を新規処理する関数を追加。`{from, to, consent_outcome}` を受け取り `write-config.sh rules.retrospective.feedback_mode <to>` を実行して journal に追加。書込み失敗時は exit ≥ 1 を返し、上位 `migrate-feedback-mode.sh` の rollback 経路に伝播

---

## インターフェース設計

### exit code 体系（共通契約 / 指摘 #5 対応）

呼び出し側が `set -e` 環境でも安全に使えるよう、以下の規約で統一する:

- **exit 0**: 成功。「警告だが継続可能」（保守値を stdout に出力した未知値ケース）も含む
- **exit 1**: 中断・書込み失敗・rollback 等のランタイム異常
- **exit 2**: 引数エラー / 環境不整合（呼出側のミス、即時失敗させるべき種類）

すべての診断メッセージは stderr に書き出す。フォーマット: `<level>\t<code>\t<detail>`（タブ区切り / 既存 retrospective-generate.sh の規約と整合 / level=`info`/`warn`/`error`）。
これにより `set -e` 環境からの呼出も `mode=$(./feedback-mode.sh ...)` 形式で安全に使える。`exit 0` でも warn が出ることを契約として明示する。

### `feedback-mode.sh` のスクリプトインターフェース

#### `is_interactive_env()`（指摘 #3 対応 / 環境判定の単一化）

- **概要**: 環境判定の正本関数。resolve / wizard / migrate のすべての経路で本関数を呼び出す
- **引数**: なし
- **判定基準**:
  1. `[ -t 0 ] && [ -t 1 ]`（stdin/stdout が tty）でなければ `false`
  2. 環境変数 `${CI:-}` / `${GITHUB_ACTIONS:-}` / `${AIDLC_NON_INTERACTIVE:-}` のいずれかが non-empty なら `false`
  3. すべて満たせば `true`
- **成功時出力**: stdout に `true` または `false` を 1 行
- **終了コード**: 常に `0`
- **副作用**: なし

#### `feedback_mode_normalize(raw)`

- **概要**: 旧値（`silent` / `mirror` / `disabled`）と新値（5 値）を入力として、正規化済みの新値を出力する
- **引数**:

  | 引数 | 必須/任意 | 説明 |
  |------|----------|------|
  | `raw` | 必須 | 設定 / 入力値（任意の文字列） |

- **成功時出力**: 正規化された 5 値のいずれかを stdout に 1 行
- **エラー時出力**: 認識不能 → stderr に `warn\tfeedback_mode_unknown\t<raw>` を 1 行 / stdout には保守値 `disabled` を出力
- **終了コード**: `0`（成功 / 未知値の保守値出力含む）/ `2`（引数不足）
- **写像**:

  | raw | normalized | exit |
  |-----|-----------|------|
  | `interactive` | `interactive` | 0 |
  | `local-issue-only` | `local-issue-only` | 0 |
  | `mirror-only` | `mirror-only` | 0 |
  | `local-and-mirror` | `local-and-mirror` | 0 |
  | `disabled` | `disabled` | 0 |
  | `silent`（旧値） | `interactive` | 0 |
  | `mirror`（旧値） | `mirror-only` | 0 |
  | 空文字 / 未設定 | `interactive` | 0 |
  | 上記以外 | `disabled` | 0（warn を stderr へ） |

#### `feedback_mode_resolve(mode, env_interactive)`（指摘 #1 対応 / 値域を 4 値に固定）

- **概要**: 正規化済み mode と環境から、retrospective 起票処理が分岐に使う**最終実行モード（4 値のみ）**を返す。`interactive` シグナルは返さない
- **引数**:

  | 引数 | 必須/任意 | 説明 |
  |------|----------|------|
  | `mode` | 必須 | 5 値（`feedback_mode_normalize` 通過済み） |
  | `env_interactive` | 必須 | `true` / `false`（呼出側が `is_interactive_env` 経由で取得して渡す） |

- **成功時出力**: `mirror_only` / `local_only` / `both` / `disabled` のいずれかを stdout に 1 行
- **エラー時出力**: 未知 mode → stdout に `disabled` + stderr に warn
- **終了コード**: `0`（成功 / 未知値の保守値出力含む）/ `2`（引数不足）
- **派生表**:

  | mode | env_interactive | output |
  |------|----------------|--------|
  | `interactive` | true | `disabled`（**暫定**。呼出側は事前に `feedback_mode_requires_wizard` で判定し、wizard 起動 → 確定値で再 resolve する） |
  | `interactive` | false | `disabled` |
  | `local-issue-only` | - | `local_only` |
  | `mirror-only` | - | `mirror_only` |
  | `local-and-mirror` | - | `both` |
  | `disabled` | - | `disabled` |

> **重要**: 値域から `interactive` シグナルを排除した。Unit 002〜004 の分岐は 4 値の確定モードのみで完結する。

#### `feedback_mode_requires_wizard(mode, env_interactive)`（指摘 #1 / #2 対応 / 新規）

- **概要**: wizard 起動が必要かを判定する純粋関数。resolve とは別関数として責務分離
- **引数**: `mode` / `env_interactive`（resolve と同じ）
- **成功時出力**: stdout に `true` または `false` を 1 行
- **終了コード**: `0`（成功）/ `2`（引数不足）
- **派生表**:

  | mode | env_interactive | output |
  |------|----------------|--------|
  | `interactive` | true | `true` |
  | `interactive` | false | `false`（resolve が `disabled` に倒すため wizard 起動しない） |
  | その他 4 値 | - | `false` |

#### `feedback_cap_check(mode, current, limit)`

**呼出前提条件（指摘 #2 対応）**: 呼出側は事前に `feedback_mode_requires_wizard(mode, env)` を評価し、`true` なら wizard を起動して確定値で `mode` を上書きしてから本関数を呼ぶ。`mode=interactive` を入力した場合は暫定値（`over=false / scope=none`）を返すのみで、再帰評価は行わない（純粋関数性を保つ）。本契約により呼出順序は `requires_wizard` → `wizard`（必要時） → `resolve` → `cap_check` の 4 段で固定される。


- **概要**: mode と現在の起票数 / 上限から、起票可否と適用範囲を返す
- **引数**:

  | 引数 | 必須/任意 | 説明 |
  |------|----------|------|
  | `mode` | 必須 | 5 値（`feedback_mode_normalize` 通過済み） |
  | `current` | 必須 | 現在のサイクル内 起票済み数（整数） |
  | `limit` | 必須 | `feedback_max_per_cycle`（整数） |

- **成功時出力**: stdout に 2 行（key=value 形式）

  ```text
  over=<true|false>
  scope=<combined|local|mirror|none>
  ```

- **エラー時出力**: 未知 mode → stdout に `over=true` / `scope=none` + stderr に warn
- **終了コード**: `0`（成功 / 未知値の保守値出力含む）/ `2`（引数不足 / 整数ではない）
- **派生表**:

  | mode | scope | over の判定 |
  |------|-------|------------|
  | `interactive` | `none` | `false`（暫定。呼出側は `feedback_mode_requires_wizard` で wizard 起動要否を判定し、wizard 起動後の確定値で再 check する責務を持つ） |
  | `local-issue-only` | `local` | `current >= limit` |
  | `mirror-only` | `mirror` | `current >= limit` |
  | `local-and-mirror` | `combined` | `current >= limit` |
  | `disabled` | `none` | `false` |
  | 未知値 | `none` | `true` |

#### `feedback_mode_save(mode, scope)`

- **概要**: write-config.sh ラップ。enum バリデーション後に保存
- **引数**:

  | 引数 | 必須/任意 | 説明 |
  |------|----------|------|
  | `mode` | 必須 | 5 値のいずれか（保存前に正規化チェック） |
  | `scope` | 任意 | `project` / `local`（既定 `local`） |

- **成功時出力**: write-config.sh の出力をそのまま転送
- **エラー時出力**: enum 違反 → stderr に `error\tfeedback_mode_invalid\t<mode>` + exit 2 / 書込失敗 → exit 1
- **終了コード**: `0`（成功）/ `1`（書込失敗）/ `2`（enum 違反 / 引数不足）

### `feedback-mode-wizard.sh`（対話オーケストレーション）

#### `feedback_mode_wizard()`

- **概要**: `read -p` ベースの数値選択（指摘 #6 対応で AskUserQuestion 不使用）で 5 値を選ばせ、`feedback_mode_save` で保存。最後に保存済み値を stdout に 1 行返す
- **対話手段**: `read -p`（標準入力）+ stderr に選択肢提示 + 数値入力 + バリデーション + 再入力ループ
- **引数**: なし（環境変数で `AIDLC_FEEDBACK_MODE_WIZARD_SCOPE`（既定 `local`）を上書き可）
- **成功時出力**: 保存済みの 5 値のいずれかを stdout に 1 行
- **エラー時出力**:
  - 非対話環境で呼ばれた（`is_interactive_env() == false`） → exit 2 + stderr に warn（呼出側のミス）
  - ユーザー中断（Ctrl-C / Ctrl-D / EOF） → exit 1 + stderr に warn（既存値を維持）
  - 設定保存失敗 → exit 1（write-config.sh の exit を伝播）
- **終了コード**: `0`（成功）/ `1`（中断 / 保存失敗）/ `2`（非対話 / 引数エラー）

### `migrate-feedback-mode.sh`（マイグレーション オーケストレーション / 指摘 #4 対応で manifest 拡張経路に固定）

#### コマンドライン I/F

- **概要**: 旧値を検出し、写像表 + 同意取得結果から確定値を求めて、**manifest に `feedback_mode_migrate` リソースを積み込む**。既存 `migrate-apply-config.sh` がそれを処理することで適用される。`migrate-apply-config.sh` への直接呼び出し / 独立フローは行わない（責務分離 / 単一適用経路）
- **引数**:

  | 引数 | 必須/任意 | 説明 |
  |------|----------|------|
  | `--config` | 任意 | 対象 config.toml パス（既定: `.aidlc/config.toml`） |
  | `--manifest` | 必須 | 上位 aidlc-migrate が生成する manifest JSON のパス。`feedback_mode_migrate` リソースを追記する |
  | `--non-interactive` | 任意 | 強制非対話モード（テスト / CI 用） |
  | `--dry-run` | 任意 | manifest に書き込まず計画のみ表示 |

- **成功時出力**: stdout に journal JSON（既存 migrate-apply-config.sh の形式と整合）

  ```json
  {
    "phase": "feedback_mode_decide",
    "decisions": [
      {
        "resource_type": "feedback_mode_migrate",
        "from": "<legacy>",
        "to": "<new>",
        "consent": "accepted|rejected|not_required|non_interactive_fallback",
        "status": "queued|skipped|aborted"
      }
    ]
  }
  ```

- **manifest 拡張**: 上位（aidlc-migrate）が manifest に `{"resource_type": "feedback_mode_migrate", "from": "<legacy>", "to": "<new>", "consent_outcome": "..."}` を追加。`migrate-apply-config.sh` がこのリソースを処理する追加ロジックを持つ（`write-config.sh rules.retrospective.feedback_mode <to>` を実行 → journal に追加）
- **rollback 責務**: 書込失敗（migrate-apply-config.sh が exit ≥ 1）を上位 aidlc-migrate が受け取り、既存の `aidlc-migrate --rollback` 経路でバックアップ復元。`migrate-feedback-mode.sh` 自身は rollback を発火しない（manifest を積むだけの decide 層 / 責務分離）
- **エラー時出力**: stderr に診断メッセージ
- **終了コード**: `0`（成功 / skipped）/ `1`（同意取得失敗以外のランタイム異常）/ `2`（引数エラー）

---

## データモデル概要

### 設定ファイル形式（既存 TOML）

`skills/aidlc/config/defaults.toml`（既存）に以下を追加:

```toml
# rules.retrospective.feedback_mode の許容値（5 値 enum）:
#   - "interactive"        : 初回 04-completion §1.5 直前に wizard を起動して確定
#   - "local-issue-only"   : プロダクトリポジトリの Issue にのみ起票
#   - "mirror-only"        : upstream（AI-DLC starter kit）の Issue にのみ起票
#   - "local-and-mirror"   : 両方に起票（合算 cap）
#   - "disabled"           : 起票しない（振り返り自体はローカル記録）
# 旧値 "silent" / "mirror" は `aidlc-migrate` で自動マイグレーション。
# `silent` → `interactive`（同意プロンプト必要 / 非対話時 disabled fallback）
# `mirror` → `mirror-only`（同意不要 / 動作互換）
feedback_mode = "interactive"  # v2.5.1 以降の新規セットアップ既定
```

> **既定値の変更**: v2.5.0 では `silent` が既定だった。v2.5.1 では `interactive` を既定とすることで、新規セットアップ時に必ず wizard を起動し、ユーザーが意識して値を選ぶようにする。Intent §「主要設計判断 4」の「未設定（key 不在） → interactive」と整合。

### journal JSON（aidlc-migrate との連携）

既存 `migrate-apply-config.sh` の journal は `applied: [<resource>]` 配列を返す。
本 Unit の追加リソースタイプ:

```json
{
  "resource_type": "feedback_mode_migrate",
  "from": "silent",
  "to": "interactive",
  "consent": "accepted",
  "status": "success",
  "detail": "feedback_mode migrated: silent -> interactive (consent: accepted)"
}
```

---

## 処理フロー概要

### フロー 1: 通常時の retrospective 起票判定（Unit 002 から呼出 / 指摘 #2 対応）

```text
Unit 002（または retrospective-generate.sh の互換アダプタ層）:
  raw = read-config.sh rules.retrospective.feedback_mode
  mode = feedback_mode_normalize(raw)              # 旧値 → 新値 自動正規化
  env_interactive = is_interactive_env()            # 単一化された判定関数
  if feedback_mode_requires_wizard(mode, env_interactive) == "true":
    mode = feedback_mode_wizard()                  # 対話起動 + 保存（mode を確定値で上書き）
    # wizard 後は env_interactive=true は保たれる前提（wizard 実行に対話必須）
  resolved = feedback_mode_resolve(mode, env_interactive)  # 確定 mode で再 resolve
  cap_decision = feedback_cap_check(mode, current_count, limit)  # 確定 mode で cap 判定
  if cap_decision.over == "true":
    skip with reason = max_exceeded
  else:
    起票処理に分岐（resolved に応じて local_only / mirror_only / both / disabled）
```

> **重要**: wizard 実行後、`mode` 変数は確定値（5 値のいずれか）に上書きされ、その後の `resolve` / `cap_check` も確定値で再評価される（指摘 #2 のデータフロー破綻を解消）。`feedback_mode_requires_wizard` で wizard 起動要否を別関数で判定することで、`resolve` の値域から `interactive` シグナルを排除した（指摘 #1 対応）。

### フロー 2: aidlc-migrate 実行時のマイグレーション（指摘 #4 対応 / manifest 拡張経路）

```text
aidlc-migrate メインフロー:
  Stage 1 (detect):
    migrate-detect.sh が manifest を生成
    migrate-feedback-mode.sh --config <path> --manifest <manifest>:
      a. raw = read-config.sh rules.retrospective.feedback_mode
      b. mapping = mapping_factory(raw)            # FeedbackModeMapping を生成
      c. if mapping.to == raw:
           skip（既マイグレーション済み）
         else if mapping.requires_consent == false:
           decided = mapping.to / consent_outcome = "not_required"
         else:
           env_interactive = is_interactive_env()
           if env_interactive:
             read -p で同意プロンプト表示（"silent → interactive に移行しますか？(y/n)"）
             if 'y':
               decided = mapping.to / consent_outcome = "accepted"
             else:
               decided = mapping.non_interactive_fallback / consent_outcome = "rejected"
           else:
             decided = mapping.non_interactive_fallback / consent_outcome = "non_interactive_fallback"
      d. manifest に追記:
         {"resource_type": "feedback_mode_migrate",
          "from": <raw>, "to": <decided>, "consent_outcome": <outcome>}
      e. journal JSON 出力 + exit 0

  Stage 2 (apply / 既存 backup 経路 + migrate-apply-config.sh):
    aidlc-migrate がバックアップを作成（既存機能）
    migrate-apply-config.sh が manifest を処理:
      - 既存 resource_type に加え `feedback_mode_migrate` を新規処理
      - write-config.sh rules.retrospective.feedback_mode <to> を実行
      - 書込失敗 → exit ≥ 1 を上位 aidlc-migrate に伝播
      - 成功時 → journal に追加

  Stage 3 (rollback / aidlc-migrate 上位):
    Stage 2 の書込が exit ≥ 1 を返した場合、aidlc-migrate の既存 rollback 経路で
    バックアップ（.aidlc/config.toml.backup-<timestamp>）から復元
```

> **境界整理（指摘 #4 対応）**:
> - `migrate-feedback-mode.sh`: 旧値検出 + 同意取得 + manifest 積み込みのみ（**書込みもバックアップも rollback もしない**）
> - `migrate-apply-config.sh`: 純粋適用（manifest 処理のみ。対話制御なし）
> - aidlc-migrate 上位: バックアップ作成 / rollback 発火 / トランザクション境界管理（既存責務）

### フロー 3: 04-completion §1.5 から wizard 起動（参考 / Unit 002 が実装）

```text
04-completion §1.5:
  raw = read-config.sh rules.retrospective.feedback_mode
  mode = feedback_mode_normalize(raw)
  env_interactive = is_interactive_env()
  if feedback_mode_requires_wizard(mode, env_interactive) == "true":
    mode = feedback_mode_wizard()
  以降フロー 1 と同じ（cap_check + 起票処理）
```

> 本 Unit は wizard 関数の提供のみで、04-completion §1.5 のステップ記述は Unit 002 が編集する（境界遵守）。

### フロー 4: 既存 retrospective-generate.sh / retrospective-mirror.sh の互換アダプタ層化（指摘 #7 対応）

既存 v2.5.0 の `retrospective-generate.sh` / `retrospective-mirror.sh` は内部で「3 値前提（silent / mirror / disabled）」のチェックを行っている。本 Unit で以下を実施し、新 resolver 経由に統一する:

```text
retrospective-generate.sh / retrospective-mirror.sh:
  既存:
    raw = read-config.sh rules.retrospective.feedback_mode
    if raw not in ("silent", "mirror", "disabled"):
      treat as "silent"
  新（Unit 001 で更新）:
    raw = read-config.sh rules.retrospective.feedback_mode
    mode = feedback_mode_normalize(raw)               # 新 5 値に正規化（旧値も自動変換）
    env_interactive = is_interactive_env()
    resolved = feedback_mode_resolve(mode, env_interactive)
    既存判定 if raw == "mirror" は if resolved in ("mirror_only", "both") に置換
    既存判定 if raw == "silent" は if mode == "interactive" に置換（fallback の意図を保持）
    既存判定 if raw == "disabled" は if resolved == "disabled" に置換
```

> **互換アダプタ層の責務**: 旧値が config に残った状態でも、`feedback_mode_normalize` が新値に変換するため、aidlc-migrate 未実行でも既存スクリプトは正しく動作する（no-op 互換）。本 Unit の変更対象ファイルに `retrospective-generate.sh` / `retrospective-mirror.sh` を含める。

---

## 非機能要件（NFR）への対応

### 互換性

- **要件**: v2.5.0 ユーザーが aidlc-migrate を実行せずに 04-completion §1.5 を実行しても破壊しない
- **対応策**: `feedback_mode_normalize` がすべての入力経路（read-config.sh 経由 + 直接呼び出し）で旧値→新値変換するため、aidlc-migrate 未実行でも no-op 互換動作

### 安全性

- **要件**: 非対話環境では常に `disabled` フォールバック（CI で意図しない Issue 起票が起きない）
- **対応策**:
  - `is_interactive_env()` 関数（tty + CI ガード）で全経路の判定を単一化
  - `feedback_mode_resolve(interactive, env_interactive=false)` を強制的に `disabled` に倒す
  - `feedback_mode_requires_wizard(interactive, env_interactive=false)` も `false` を返す（wizard 起動不可なため）
  - `migrate-feedback-mode.sh` も `--non-interactive` または `is_interactive_env()=false` 時は `non_interactive_fallback` を選択

### 可観測性

- **要件**: BATS テストで写像表全パターンを verify
- **対応策**: 純粋関数なのでユニットテスト容易。journal JSON で migrate 経路の outcome を観測可能

### 保守性

- **要件**: Unit 002〜004 が共有契約として依存できる
- **対応策**: I/F を計画ファイル §「I/F 契約」と本論理設計の双方で固定。stderr フォーマット・exit code 体系を明文化

---

## 技術選定

- **言語**: bash 4+（既存と整合）
- **依存ツール**:
  - `dasel`（既存 read-config / write-config が使用）
  - `jq`（既存 migrate スクリプトが使用）
  - 標準 bash の `read -p`（wizard / 同意プロンプト用、AskUserQuestion 不使用）
- **テストフレームワーク**: BATS（既存テストと整合）
- **新規依存なし**

---

## 実装上の注意事項

### コマンド置換禁止（プロジェクト CLAUDE.md ルール）

- bash スクリプト内で `$(...)` / バッククォート禁止
- 動的値はコンテキスト変数 / `read -r` / 一時ファイル経由で受け渡す
- `migrate-apply-config.sh` 既存コードは `$(...)` を使用しているが、本 Unit ではプロジェクトルールを遵守し、新規実装は別経路で書く（既存コードは本 Unit の責務外のためそのまま維持）

> **既存コードとの整合**: 既存 migrate スクリプトの `$(...)` 使用は v2.5.0 までに導入済み。本 Unit の新規追加コードでは `$(...)` を使用しない。`tools:cross-platform-review` 観点で macOS / Linux 両対応を維持する。

### enum バリデーション

- `feedback_mode_save` は write-config.sh を呼ぶ前に値域チェック
- defaults.toml のコメントは文書化のみで、強制バリデーションは関数側で実装

### 4 階層マージとの整合

- `read-config.sh` の既存 4 階層マージはそのまま使う
- 旧値が複数階層に分散している場合（例: defaults=silent / project=mirror）でも、最終的に解決された 1 値だけを `feedback_mode_normalize` で正規化する
- aidlc-migrate は project 階層（`.aidlc/config.toml`）のみ書換対象。個人設定（`.aidlc/config.local.toml`）には触らない（個人嗜好を保護）

### rollback 粒度

- 1 回の `migrate-feedback-mode.sh` 実行 = 1 トランザクション
- バックアップは書込開始直前に作成（`.aidlc/config.toml.backup-<timestamp>`）
- 書込失敗時 / SIGINT で部分書込み検出時のみ rollback 発火
- 既存 `aidlc-migrate --rollback` のバックアップ命名規則と整合させる

---

## 不明点と質問（設計中に記録）

[Question] AskUserQuestion ツールを bash スクリプトから直接呼ぶ手段が存在するか、それとも Claude Code エージェント側で起動する必要があるか
[Answer] AskUserQuestion は Claude Code エージェントツールであり、bash から直接呼ぶ仕組みはない。**Unit 001 では `read -p` ベースで対話を完結させる方針に固定**（指摘 #6 対応）。理由: bash から呼べない以上「AskUserQuestion 依存」をコンポーネント記述に残すと責務が揺れる。既存 v2.5.0 の対話パターン（`read -p` ベース）と整合し、shell スクリプト単独で完結させる。Claude Code 経由で呼ばれた場合の AskUserQuestion 連携は将来の拡張として保留（本 Unit 範囲外）。

[Question] migrate-feedback-mode.sh は aidlc-migrate のサブコマンドとして登録するか、独立スクリプトか
[Answer] aidlc-migrate のメインフロー（`migrate-detect.sh` → `migrate-apply-config.sh` → `migrate-cleanup.sh`）に組み込む。Stage 1（detect）で旧値検出を行い、Stage 2（apply）の前段で同意取得 → 確定値を manifest に積んで apply 委譲、というパターンが既存責務と整合。`migrate-feedback-mode.sh` は detect / decide ステージとして機能し、確定値書込みは `migrate-apply-config.sh` の resource_type=`feedback_mode_migrate` 拡張で行う。

[Question] feedback_mode_wizard は将来 04-completion §1.5 から呼ばれる際、Unit 001 範囲のテストはどう書くか
[Answer] Unit 001 では `feedback_mode_wizard()` を直接呼ぶ BATS テスト（標準入力モック + 標準出力検証）と、`feedback_mode_save` の単体テストに限定する。04-completion §1.5 経由の統合テストは Unit 002 が `tests/operations-04-completion-feedback-wizard.bats`（仮称）として実装する。

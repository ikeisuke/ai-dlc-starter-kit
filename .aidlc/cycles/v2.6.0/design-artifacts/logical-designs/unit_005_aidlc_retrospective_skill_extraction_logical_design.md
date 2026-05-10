# 論理設計: Unit 005 - /aidlc-retrospective 独立スキル化

## 概要

Operations Phase §1 の振り返り実行ロジックを `aidlc-retrospective` 独立スキルへ全量移転し、`/aidlc r` で起動可能にするためのコンポーネント構成 / 公開インターフェース / スクリプト契約を定義する。コードは書かず、構造定義のみを行う。

---

## アーキテクチャパターン

**採用パターン**: ファサード（Facade）+ ストラテジー（Strategy）+ ガード（Guard）

| パターン | 適用箇所 | 選定理由 |
|---------|---------|---------|
| Facade | `retrospective-api.sh`（公開 API 層） | `aidlc-retrospective` から内部 lib の実装詳細を隠蔽し、単方向境界を確立 |
| Strategy | `CycleResolver`（4 つの解決戦略） | 対象サイクル特定の各データソースを差し替え可能・テスト可能な単位に分離 |
| Guard | `WriteHistoryGuard` の `operations_stage` fail-closed 導出 / `dialog token guard` | 副作用を伴う操作の前で前提条件を強制検証し、誤入力 / 抜け道で破壊的操作が行われないよう保護 |

**選定理由**: 本 Unit は「既存ロジック全量移転 + 境界の明示化」が中核。既存 lib の関数を破壊的に書き換えるのではなく、薄いファサード層で再エクスポートするのが最小破壊で最大の責務分離効果を得られる。誤入力リスク（恣意的な `AIDLC_OPERATIONS_STAGE` / 誤った cycle 検出）を Guard で fail-closed に倒すことで、破壊的変更の安全弁を確保する。

---

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/
├── aidlc/                                    # 既存（拡張）
│   ├── SKILL.md                              # parser 拡張: retrospective (r) アクション追加
│   ├── steps/
│   │   ├── operations/
│   │   │   └── 04-completion.md              # §1.0〜§1.6 実行ロジック削除（案内文のみ残す）
│   │   └── inception/
│   │       └── 01-setup.md                   # 不変（predecessor_resolve_issue は維持）
│   ├── scripts/
│   │   ├── lib/
│   │   │   ├── retrospective-api.sh          # 【新規】公開 API 層（Facade）
│   │   │   ├── cycle-resolver.sh             # 【新規】CycleResolver 独立コンポーネント
│   │   │   ├── retrospective-issue.sh        # 既存（変更なし / 内部実装）
│   │   │   ├── feedback-mode.sh              # 既存（変更なし / 内部実装）
│   │   │   ├── feedback-mode-wizard.sh       # 既存（変更なし / 内部実装）
│   │   │   └── predecessor-issue.sh          # 既存（変更なし / 内部実装）
│   │   └── write-history.sh                  # 拡張: operations_stage 導出ロジック
│   └── templates/
│       └── retrospective_template.md         # 既存（共有テンプレート / 変更なし）
└── aidlc-retrospective/                      # 【新規スキル】
    ├── SKILL.md                              # スキルエントリポイント
    └── steps/
        └── retrospective.md                  # 振り返りフロー本体（§1.0〜§1.6 移植）
```

### コンポーネント詳細

#### `skills/aidlc-retrospective/SKILL.md`（新規）

- **責務**: 独立スキル（L2 独立スキル層）のエントリポイント。bootstrap → CycleResolver 起動 → retrospective フロー実行を順次呼び出す
- **依存（L3 公開コンポーネント層への単方向依存）**:
    - `skills/aidlc/scripts/lib/retrospective-api.sh`（Issue/feedback 系の Facade）
    - `skills/aidlc/scripts/lib/cycle-resolver.sh`（サイクル特定の独立公開コンポーネント）
    - `skills/aidlc/templates/retrospective_template.md`（共有テンプレート）
- **層定義**: 詳細は domain-model.md「ドメインモデル図」末尾の依存規則表を参照。`RetrospectiveAPI` と `CycleResolver` は L3 内で互いに独立した並列コンポーネントであり、`RetrospectiveSkill` から両者を別目的で直接 source することは設計上の正規経路
- **公開インターフェース**:
    - 起動: `/aidlc-retrospective [target_cycle]` または `/aidlc-retrospective`（引数なし）
    - 委譲元: `/aidlc r` / `/aidlc retrospective`（`aidlc` parser 経由）

#### `skills/aidlc-retrospective/steps/retrospective.md`（新規）

- **責務**: 振り返りフロー本体（feedback_mode 解決 → wizard / cap 判定 → 本文構築 → 起票 → spool / mirror）
- **依存**: `retrospective-api.sh` の公開関数 / `templates/retrospective_template.md`
- **公開インターフェース**: 内部手順記述（SKILL.md から委譲される）

#### `skills/aidlc/scripts/lib/retrospective-api.sh`（新規 / Facade）

- **責務**: 既存 `lib/*.sh` を内部 source し、公開 API のみを再エクスポート
- **依存**:
    - `lib/retrospective-issue.sh`（内部 source）
    - `lib/feedback-mode.sh`（内部 source）
    - `lib/feedback-mode-wizard.sh`（内部 source）
    - `lib/predecessor-issue.sh`（内部 source）
- **公開インターフェース**: 6 関数（後述「スクリプトインターフェース設計」）
- **不変条件**:
    - 公開関数は `retrospective_api_*` プレフィックス
    - 非公開関数（内部 lib のヘルパー）は外部から呼ばない契約

#### `skills/aidlc/scripts/lib/cycle-resolver.sh`（新規 / Strategy）

- **責務**: 対象サイクル特定の独立コンポーネント。4 つの Strategy を実行し、優先順位 + fail-safe ガードを適用
- **依存**: `git` / `gh` / `.aidlc/cycles/` ディレクトリ
- **公開インターフェース**: `cycle_resolver_resolve` 関数（後述）

#### `skills/aidlc/SKILL.md`（既存 / 拡張）

- **責務**: `/aidlc` parser に `retrospective` (`r`) アクションを追加
- **変更箇所**:
    - 「ARGUMENTSパーシング」: 短縮形マップに `r → retrospective` 追加
    - 「引数ルーティング」テーブル: `retrospective` (`r`) 行を追加
    - 「独立フロー委譲」テーブル: `retrospective | /aidlc-retrospective` 行を追加
    - 「ヘルプ表示」: `retrospective` 行を追加

#### `skills/aidlc/steps/operations/04-completion.md`（既存 / 縮退）

- **責務（変更後）**: §1 では振り返り実行ロジックを削除し、案内文のみ残す
- **変更箇所**:
    - §1.0〜§1.6 の実行ロジック削除
    - `「振り返りは /aidlc r [cycle] を実行してください」` の案内文に置換
    - §6「次のサイクル開始」付近で `/aidlc i` と並列に `/aidlc r` を表示

#### `skills/aidlc/scripts/write-history.sh`（既存 / 拡張）

- **責務（変更後）**: `operations_stage` を呼出元入力値ではなく実行コンテキストから導出する
- **変更箇所**:
    - `--operations-stage` 引数を維持しつつ、未指定時は実行コンテキストから自動導出
    - `AIDLC_OPERATIONS_STAGE` 環境変数も同様に許可値検証 + fail-closed
    - 状態遷移ガード（`pre-merge → post-merge` の単方向のみ）

#### `skills/aidlc-migrate`（既存 / 拡張）

- **責務（変更後）**: v2.5.x → v2.6.0 アップグレード時に破壊的変更を通知
- **変更箇所**: アップグレード完了メッセージに「Operations 内振り返りは `/aidlc r` に移行されました（v2.6.0 破壊的変更）」を追加

---

## インターフェース設計

### 委譲経路

#### `/aidlc r [target_cycle]` / `/aidlc retrospective [target_cycle]`

- **説明**: `aidlc` parser から `aidlc-retrospective` 独立スキルへの委譲
- **追加コンテキスト**: `target_cycle`（任意 / 例: `v2.5.5`）。空の場合は `CycleResolver` で自動解決
- **委譲後の挙動**: `aidlc` 親スキルは委譲指示「`/aidlc-retrospective {additional_context}` を実行してください。」を出力して終了
- **エラー**: `target_cycle` の形式不正は `aidlc-retrospective` 側で検証（親 parser は素通し）

---

## スクリプトインターフェース設計

### `retrospective-api.sh`（新規）

#### 概要

既存 `lib/*.sh` を内部 source し、`aidlc-retrospective` から呼び出すための公開 API のみを再エクスポートする Facade 層。

#### 出力形式の規約（指摘 #3 反映 / Round 1）

各公開関数は出力タイプを以下に分類する。出力タイプは関数仕様の必須項目とし、呼出側のパース責務もここで定義する:

| タイプ | 出力形式 | 適用関数 | 呼出側パース責務 |
|-------|---------|---------|-----------------|
| A: 副作用あり / 状態 | `key=value` 複数行 | `retrospective_api_create_issue` / `retrospective_api_record_response` | キー単位で `grep -E '^key='` 抽出後 `cut -d= -f2` |
| B: 純粋値 / 単一値 | raw text 1 行 / 単一文書 | `retrospective_api_resolve_feedback_mode` / `retrospective_api_run_wizard` / `retrospective_api_check_cap` / `retrospective_api_compose_body` | stdout 全体をそのまま使用 |

出力タイプはドメインモデル「RetrospectiveAPI 不変条件」に従う。新規関数の追加時は API リファレンスでタイプを必ず宣言する。

#### 公開関数

##### `retrospective_api_resolve_feedback_mode`

- **出力タイプ**: B（raw text 1 行）
- **引数**:
    - `$1` raw_value（`read-config.sh rules.retrospective.feedback_mode` の出力）
- **戻り値**: stdout に正規化済 mode 文字列（`silent` / `mirror` / `disabled` / `interactive` / 未設定 fallback `silent`）
- **副作用**: なし（純粋関数）
- **終了コード**: 0（成功）/ 1（不正値 / 警告）/ 2（fatal）
- **内部委譲先**: `feedback-mode.sh` の `feedback_mode_normalize`

##### `retrospective_api_compose_body`

- **出力タイプ**: B（raw text 単一文書 / Markdown）
- **引数**:
    - `$1` draft_yaml_path（prefill フックの出力 / 空 YAML 可）
    - `$2` kpt_md_path（KPT テンプレ展開済の Markdown）
    - `$3` cycle（対象サイクル / 例: `v2.6.0`）
- **戻り値**: stdout に Issue 本文（Markdown）
- **副作用**: なし（純粋関数）
- **終了コード**: 0 / 2
- **内部委譲先**: `retrospective-issue.sh` の `retrospective_body_compose`

##### `retrospective_api_create_issue`

- **出力タイプ**: A（key=value 複数行）
- **引数**:
    - `$1` body_path（Issue 本文ファイル）
    - `$2` mode（feedback_mode）
    - `$3` cycle
- **戻り値**: stdout に `result=created|spooled|skipped` + `issue_url=` / `reason=` 等の `key=value` 形式
- **副作用**:
    - `gh issue create`（gh available 時）
    - spool 追記（gh 不可時）
    - dialog token verify（内蔵 / 失敗時 exit 4）
- **終了コード**: 0（成功 / spooled / skipped）/ 1（recoverable failure）/ 2（fatal）/ 4（dialog-required）
- **内部委譲先**: `retrospective-issue.sh` の `retrospective_issue_create`

##### `retrospective_api_record_response`

- **出力タイプ**: A（副作用あり / stdout 出力なし。タイプ A の特例として `key=value` 形式の出力なしも許容、終了コードのみで判定）
- **引数**:
    - `$1` cycle
    - `$2` response（`approved` / `denied`）
- **戻り値**: なし（stdout 空）
- **副作用**: dialog token を発行（TTL 300 秒、上書き保存）
- **終了コード**: 0 / 1（不正値）
- **内部委譲先**: `retrospective-issue.sh` の `retrospective_dialog_token_record_response`

##### `retrospective_api_run_wizard`

- **出力タイプ**: B（raw text 1 行）
- **引数**: なし
- **戻り値**: stdout に wizard で確定した mode（`silent` / `mirror` / `disabled` / `interactive`）
- **副作用**: AskUserQuestion 経由でユーザー対話
- **終了コード**: 0
- **内部委譲先**: `feedback-mode-wizard.sh` の `feedback_mode_wizard`

##### `retrospective_api_check_cap`

- **出力タイプ**: B（raw text 1 行 / `over=true|false` の固定書式）
- **引数**:
    - `$1` mode
    - `$2` current_count
    - `$3` limit
- **戻り値**: stdout に `over=true|false`（既存 `feedback_cap_check` の出力をそのまま中継）
- **副作用**: なし（純粋関数）
- **終了コード**: 0
- **内部委譲先**: `feedback-mode.sh` の `feedback_cap_check`
- **備考**: 出力は `key=value` の形式に見えるが、固定キー `over` のみで複数キー展開を行わないためタイプ B（raw text 1 行）として扱う。タイプ A の複数キー展開とは区別する

#### 非公開関数（外部から呼ばない契約）

`_internal_*` プレフィックスを推奨。以下は Phase 2 実装時に明示する:

- `lib/retrospective-issue.sh` 内のヘルパー（`_validate_apply_path` 等）
- `lib/feedback-mode.sh` 内の正規化ヘルパー
- 他 `lib/*.sh` 内の private 関数

### `cycle-resolver.sh`（新規）

#### 概要

対象サイクルを 4 つの Strategy（引数 / ブランチ / git log / cycle dir）で解決する独立コンポーネント。

#### 公開関数

##### `cycle_resolver_resolve`

- **引数**:
    - `$1` additional_context（`/aidlc r` の引数 / 空文字可）
- **戻り値**: stdout に以下の `key=value` 形式（4 行 + summary）

```text
candidate=<cycle>
source_id=<arg|branch|gitlog|cycledir|user_input>
confidence=<high|medium|low>
evidence=<人間可読の決定根拠>
```

- **副作用**: 不一致時は AskUserQuestion を表示（経路 ④）
- **終了コード**:
    - 0 = 成功
    - 1 = 全 Strategy 解決失敗（`source_id=user_input` で最終解決した場合は 0 を返す）
    - 2 = fatal（git / gh コマンドエラー等）

#### 内部 Strategy

各 Strategy は以下の共通シグネチャを持つ（実装は Phase 2）:

```text
strategy_<name>(additional_context) -> ResolutionResult | empty
ResolutionResult: candidate / source_id / confidence / evidence
```

| Strategy | confidence | データソース | trigger 条件 / 評価順序 |
|---------|-----------|-------------|------------------------|
| S1 ArgStrategy | high | 起動引数 | `additional_context` が `vX.Y.Z` 形式 |
| S2 BranchStrategy | high | `git rev-parse --abbrev-ref HEAD` | カレントブランチが `cycle/vX.Y.Z` |
| S3a GitLogStrategy | medium | `git log`（第一選択 / オフライン可）→ `gh pr list`（git log で空なら fallback / オンライン依存） | (1) `git log --merges --first-parent main --pretty='%s' \| grep -oE 'cycle/v[0-9]+\.[0-9]+\.[0-9]+'` の最新値 / (2) (1) が空かつ gh available なら `gh pr list --state merged --base main` の最新 merged cycle/* |
| S3b CycleDirStrategy | low | `.aidlc/cycles/` ディレクトリ | `.aidlc/cycles/v*/` 配下の semver 最大値 |

**S3a 正規仕様（指摘 #4 反映 / Round 1）**:

- **第一データソース: `git log`**（オフライン可 / 高速 / レート制限なし）
- **第二データソース: `gh pr list`**（git log で空かつ gh available 時のみ呼ぶ）
- 両方とも空 → S3a は候補返却なし
- gh 不可かつ git log 空 → S3a は候補返却なし（S3b にフォールバック）

**NFR 対応関係**:

| データソース | レート制限耐性 | オフライン耐性 | 採用順位 |
|-------------|---------------|---------------|---------|
| `git log` | なし（ローカル） | 完全 | 第一 |
| `gh pr list` | あり（API レート） | 不可 | 第二 |

git log を第一選択とすることで、頻繁な呼び出しでも `gh` API レート消費・ネットワーク不在のリスクを排除する。

#### fail-safe ガード

```text
1. 全 Strategy 実行 → 候補リスト
2. 優先順位 S1 > S2 > S3a > S3b で第一候補決定
3. 候補ゼロ → AskUserQuestion で対話的解決
4. 第一候補 confidence != high かつ S3a/S3b 候補不一致 → AskUserQuestion で確認
5. 上記以外 → 第一候補を採用、`evidence` に決定根拠を記録
```

### `write-history.sh` 拡張

#### 変更内容

`operations_stage` の評価ロジックを「呼出元入力値」から「実行コンテキスト導出値」に変更する。既存の `--operations-stage` 引数 / `AIDLC_OPERATIONS_STAGE` 環境変数の API は維持し、内部評価のみを変更。

#### 評価ロジック（疑似コード / Phase 2 で実装）

> **重要（指摘 #1 反映 / fail-closed の徹底）**: `--operations-stage` 引数 / `AIDLC_OPERATIONS_STAGE` 環境変数は **「ヒント値」扱い**であり、単独では採用しない。最終値は必ず**実行コンテキストから導出した値**であり、ヒント値が指定された場合は導出値との一致検証（cross-check）を行う。不一致時は `exit 3`（fail-closed）で拒否する。これにより悪意・誤用入力で `pre-merge` 偽装による Guard 迂回を防ぐ。

```text
function derive_operations_stage():
  # ステップ 1: 実行コンテキストから真の operations_stage を導出
  branch = git rev-parse --abbrev-ref HEAD
  cycle_dir_exists = test -d .aidlc/cycles/{{CYCLE}}
  pr_state = gh pr view <branch> --json state,mergedAt or empty

  derived_stage = null
  if branch == "main" and pr_state.merged and cycle_dir_exists:
    derived_stage = "post-merge"
  elif branch == "main" and cycle_dir_exists and pr_state is empty:
    derived_stage = "post-merge"  # オフライン fallback（gh 不可時のブランチ名判定）
  elif branch matches "cycle/*" and not pr_state.merged:
    derived_stage = "pre-merge"
  elif branch matches "cycle/*" and pr_state is empty:
    derived_stage = "pre-merge"  # オフライン fallback
  else:
    exit 3  # 判定不能 / fail-closed

  # ステップ 2: ヒント値（引数 / 環境変数）の一致検証
  hint_stage = parse_argument("--operations-stage") or $AIDLC_OPERATIONS_STAGE
  if hint_stage is set:
    if hint_stage not in ["pre-merge", "post-merge"]:
      exit 3  # 許可値外（fail-closed）
    if hint_stage != derived_stage:
      # ヒントと実行コンテキスト導出値の不一致 → 偽装の疑い
      stderr "error\thint-mismatch\thint=<hint_stage>\tderived=<derived_stage>"
      exit 3  # fail-closed
  # ヒント値なし、または一致した場合のみ採用
  return derived_stage
```

**契約サマリ**:

- ヒント値は単独では採用されない（必ず導出値と cross-check）
- ヒント値が許可値外（`pre-merge` / `post-merge` 以外）→ exit 3
- ヒント値と導出値の不一致 → exit 3（偽装防止）
- ヒント値なし → 導出値をそのまま採用
- 導出不能（ブランチ判定不能 / cycle dir 不在等）→ exit 3

#### 状態遷移ガード

```text
function apply_state_transition_guard(stage):
  prev_stage = read_last_recorded_stage()  # history/operations.md 等から
  if prev_stage == "post-merge" and stage == "pre-merge":
    exit 3  # 逆遷移禁止
```

---

## データモデル概要

### ファイル形式

#### dialog token ストア（既存 / 不変）

- **形式**: 既存実装（`/tmp/aidlc-retro-dialog-*.txt` 等 / `lib/retrospective-issue.sh` 参照）
- **TTL**: 300 秒（環境変数 `AIDLC_RETRO_TOKEN_TTL_SECONDS` で上書き可）

#### spool ファイル（既存 / 不変）

- **形式**: `cycles/{{CYCLE}}/history/retrospective-spool.md`
- **再送経路**: `scripts/retrospective-resend.sh`

#### history（既存 / 不変）

- **形式**: `cycles/{{CYCLE}}/history/operations.md` / `construction_unitNN.md`
- **operations_stage** は本 Unit で導出ロジック変更（呼出側 API は不変）

---

## 処理フロー概要

### ユースケース 1: `/aidlc r` で振り返りを起動（カレントブランチが `cycle/v2.6.0`）

**ステップ**:

1. ユーザーが `/aidlc r` を実行
2. `aidlc` parser が `retrospective` アクションを検出 → `/aidlc-retrospective` への委譲指示を出力
3. AI エージェントが `/aidlc-retrospective` を起動
4. `aidlc-retrospective/SKILL.md` が bootstrap → `retrospective-api.sh` を `source`
5. `cycle_resolver_resolve "" `（引数空）→ S2 BranchStrategy が `v2.6.0` を返す（confidence=high）
6. `aidlc-retrospective/steps/retrospective.md` がフロー実行:
    - feedback_mode 解決（§1.0 + Step 1）
    - cap 判定 + prefill フック（Step 2）
    - 本文構築（Step 3）
    - AskUserQuestion で起票確認 → `retrospective_api_record_response approved`
    - Issue 起票（Step 4 / dialog token verify 内蔵）
    - update フック（Step 5 / 起票成功時のみ）
7. 起動者へ完了サマリ表示

**関与するコンポーネント**: `AidlcParser` / `RetrospectiveSkill` / `CycleResolver` / `RetrospectiveAPI` / 内部 `lib/*.sh`

### ユースケース 2: `/aidlc r` で振り返りを起動（main ブランチ + マージ済 PR）

**ステップ**:

1. ユーザーが `main` ブランチで `/aidlc r` を実行
2. parser → `/aidlc-retrospective` 委譲
3. `cycle_resolver_resolve` が S2 不可 → S3a/S3b を実行
    - S3a: 最後にマージされた `cycle/v2.6.0` を検出（confidence=medium）
    - S3b: `.aidlc/cycles/v2.6.0/` を検出（confidence=low）
4. S3a/S3b が一致 → 第一候補 `v2.6.0` を採用、`evidence` に「git log で main にマージ済の cycle/v2.6.0 を検出 + .aidlc/cycles/v2.6.0/ ディレクトリ存在」を記録
5. （S3a/S3b 不一致なら AskUserQuestion で確認）
6. 後続フローはユースケース 1 と同じ。ただし Issue 起票は v2.5.x 互換の経路 (b) `cycles/{{CYCLE}}/operations/retrospective.md` ではなく GitHub Issue 起票（v2.5.1+ Unit 002）に従う

**関与するコンポーネント**: 同上 + S3a/S3b の Strategy 実行

### ユースケース 3: `feedback_mode=disabled` 時の opt-out

**ステップ**:

1. `/aidlc r` 起動 → bootstrap 完了
2. `cycle_resolver_resolve` 完了
3. `retrospective_api_resolve_feedback_mode` が `disabled` を返す
4. 起動メッセージ「振り返り機能は無効化されています（feedback_mode=disabled）」を表示
5. exit 0 で終了（Issue 起票なし）

**関与するコンポーネント**: `RetrospectiveSkill` / `RetrospectiveAPI`

### ユースケース 4: `gh_status != available` 時の spool fallback

**ステップ**:

1. ユースケース 1 のステップ 1〜6 と同様
2. `retrospective_api_create_issue` 内部で `gh issue create` 失敗
3. spool 経路で `cycles/{{CYCLE}}/history/retrospective-spool.md` に追記
4. result=spooled を stdout に返す
5. ユーザーへ「gh が利用不可のためスプールしました。次回 gh 利用可能時に retrospective-resend.sh を実行してください」と表示
6. exit 0

**関与するコンポーネント**: 同上 + `lib/aidlc-spool.sh`

### ユースケース 5: dialog token 未発行で起票試行

**ステップ**:

1. ユースケース 1 で AskUserQuestion を経ずに `retrospective_api_create_issue` を呼んだ場合
2. 内部で `retrospective_dialog_token_verify` が失敗 → exit 4
3. 「対話必須ガード: 対話確認トークンの発行 / 検証に失敗したため起票をブロックしました」を表示
4. ユーザーは AskUserQuestion で起票実行可否を再確認 → `retrospective_api_record_response` を再実行 → 再起票

**関与するコンポーネント**: `RetrospectiveAPI` / `dialog token guard`

### ユースケース 6: `write-history.sh` 経由で `cycles/{{CYCLE}}/**` 書き込み試行（main ブランチ）

**ステップ**:

1. `aidlc-retrospective` から `write-history.sh --cycle v2.6.0 --phase operations --content "振り返り完了" --artifacts "cycles/v2.6.0/history/retrospective-spool.md"` 実行
2. `derive_operations_stage()` が `branch=main` + cycle dir 存在 + PR merged を検出 → `operations_stage=post-merge` 導出
3. `cycles/v2.6.0/**` への書き込み試行 → `block_post_merge_write` が exit 3
4. ユーザーへ「マージ前完結契約違反: post-merge で cycles 配下への書き込みは禁止」を表示
5. `aidlc-retrospective` 側は warn として処理を継続（spool 経路で内容は永続化済）

**関与するコンポーネント**: `WriteHistoryGuard`

---

## 非機能要件（NFR）への対応

### 互換性

- **要件**: `[rules.retrospective] feedback_mode` の 5 値が新スキル経由でも従来通り解釈される / 振り返り Issue 本文の構造（KPT セクション + 主因切り分けマトリクス + 事実テーブル）が一致
- **対応策**:
    - 公開 API 層は内部 `lib/*.sh` の関数を re-export するのみで、ロジック自体の改変は行わない
    - Phase 2 テスト工程で 5 値全網羅検証 + 既存 retrospective Issue とのバイナリ一致検証

### 観測性

- **要件**: 移転前後で振り返り Issue 本文の構造が一致
- **対応策**: 既存 `lib/retrospective-issue.sh` の `retrospective_body_compose` を不変のまま流用。Phase 2 テストで Issue 本文の diff 検証

### 責務分離

- **要件**: `aidlc-retrospective` から `aidlc` 本体スキルへの逆参照を作らない
- **対応策**:
    - SKILL.md 内で `/aidlc` スラッシュコマンド呼び出しを禁止する記述を追加
    - `skills/aidlc/steps/operations/**` の参照禁止（ファイル参照境界ルール準拠）
    - 公開 API 層 `retrospective-api.sh` のみを source（内部 lib への直接依存禁止）

### 安全性（fail-closed）

- **要件**: 誤入力 / 抜け道で破壊的操作（マージ前完結契約違反）が起きない
- **対応策**:
    - `WriteHistoryGuard` で `operations_stage` を実行コンテキスト導出
    - 未検証値は exit 3 で fail-closed
    - 状態遷移は `pre-merge → post-merge` の単方向のみ

---

## 技術選定

- **言語**: Bash（既存 lib との互換性 / シェルスクリプト中心の AI-DLC 慣習）
- **フレームワーク**: なし
- **ライブラリ**:
    - `gh` CLI（Issue 起票）
    - `dasel`（TOML 読み出し / 既存 `read-config.sh` 経由）
    - `git`（CycleResolver の S2 / S3a Strategy）
- **データベース**: なし（GitHub Issue + ローカルファイル spool）

---

## 実装上の注意事項

### セキュリティ

- dialog token のローカルファイル保存先は権限 600 を維持（既存実装に準拠）
- 機密情報マスク（`review-flow.md` §「機密情報マスク」）は spool / history / Issue 本文すべてで適用

### パフォーマンス

- `CycleResolver` の S3a Strategy は `gh pr list` を呼ぶため、頻繁な呼び出しは API レート制限に注意。bootstrap 1 回のみの呼び出しに限定
- bootstrap で `lib/*.sh` を多重 source しないよう、`retrospective-api.sh` 内で source guard（`if [[ -z "${RETROSPECTIVE_API_SOURCED:-}" ]]; then ...; fi`）を入れる

### 保守性 / 拡張性

- 公開 API 層 `retrospective-api.sh` は将来的に v3.x 系で API バージョン管理（プレフィックス `retrospective_api_v2_*` 等）を導入できるよう、関数命名規則を明文化する
- `CycleResolver` の Strategy 追加は `cycle-resolver.sh` 内で `strategy_<name>` 関数を追加するだけで拡張可能（既存 Strategy への影響なし）

### CLAUDE.md ルール準拠

- 本 Unit のシェルコマンドはすべて `$(...)` を使わない（バッククォートも禁止）
- 動的値は AI エージェントがコンテキスト変数で置換する（`{{CYCLE}}` 等）
- gh CLI 失敗時の fallback は `gh-api-fallback` ガイド参照（必要時）

### 既存ガイド照合

- `guides/exit-code-convention.md`: 終了コード規約（0=成功 / 1=warn / 2=fatal / 3=マージ前完結違反 / 4=dialog-required）を全関数で統一
- `guides/error-handling.md`: stderr に `error\t<reason>\t<diagnostics>` 形式で出力
- `guides/backlog-management.md`: 振り返り由来 Issue は `retrospective` ラベル + `Retrospective: {cycle}` title 規約を維持

---

## 不明点と質問（設計中に記録）

[Question] `cycle-resolver.sh` を `skills/aidlc/scripts/lib/` に配置するか、`skills/aidlc-retrospective/scripts/` に配置するか確定する
[Answer] **採用案（本設計）**: `skills/aidlc/scripts/lib/cycle-resolver.sh`（共有 lib）。理由は (1) Inception 側 `predecessor_resolve_issue` でも将来再利用される可能性 / (2) 公開 API 層経由の単方向境界と整合 / (3) コピー重複回避。Phase 2 実装で問題があれば `aidlc-retrospective/scripts/cycle-resolver.sh` への移動を検討する

[Question] `retrospective-api.sh` の bootstrap で `AIDLC_BASE` を解決する具体的な順位は？
[Answer] **採用案**: ① `AIDLC_BASE` 環境変数（明示指定）→ ② `${BASH_SOURCE[0]}` の dirname 起点で `../../../skills/aidlc` を相対解決 → ③ `git rev-parse --show-toplevel` 起点で `skills/aidlc` を絶対解決 → ④ `gh repo view --json url` でリモート確認後に warn してフォールバック。Phase 2 実装で `aidlc-feedback` の bootstrap 流儀を再確認して揃える

[Question] `cycle_resolver_resolve` 内の S3a Strategy で `gh pr list` ではなく `git log` から検出する方が安価か？
[Answer] **採用案**: 第一選択 `git log --merges --first-parent main --pretty=format:'%s' | grep -oE 'cycle/v[0-9]+\.[0-9]+\.[0-9]+'`（オフライン可 / 高速）。第二選択 `gh pr list --state merged --base main` は git log で空の場合のみ呼ぶ。Phase 2 実装で確定

[Question] `operations_stage` 自動導出時に main ブランチで PR が存在しないケース（worktree 等）はどう扱うか？
[Answer] **採用案**: `branch=main` + cycle dir 存在 + PR not found → `post-merge`（オフライン fallback と同じロジック）。worktree 環境は親リポジトリに main があれば `git rev-parse --abbrev-ref HEAD` は worktree のブランチ名を返すため、本判定は worktree 上では `branch=cycle/*` となり `pre-merge` 判定される。Phase 2 で worktree シナリオを明示的にテスト

[Question] `aidlc-retrospective` の `version.txt` を新設するか、親 `aidlc` の version に追従するか？
[Answer] **採用案**: 親 `aidlc` の version に追従（`version.txt` 不在）。理由は v2.6.0 の破壊的変更が親スキルと一体不可分のため、独立 version を持つ意義が薄い。`aidlc-feedback` / `aidlc-migrate` / `aidlc-setup` も `version.txt` を持たない（Read 確認済）

[Question] 公開 API 層の関数命名で `retrospective_api_` プレフィックスは既存 lib との衝突しないか？
[Answer] **採用案**: 既存 lib の関数名（`retrospective_issue_create` / `retrospective_body_compose` / `retrospective_dialog_token_*` / `feedback_mode_*` / `feedback_cap_check`）はプレフィックス `retrospective_api_` を持たないため衝突しない。Phase 2 実装時に `grep -n 'retrospective_api_' skills/aidlc/scripts/lib/` で衝突がないことを再確認

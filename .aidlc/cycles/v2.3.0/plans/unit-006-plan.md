# Unit 006 計画: 削減目標達成の計測レポートと #519 クローズ判断

## 目的

#519 コンテキスト圧縮プロジェクトを最終評価し、達成状況を定量的にレポート化したうえで、Issue クローズ判断と次サイクル向けバックログ整備を行う。本 Unit はサイクル v2.3.0 の総括 Unit であり、Unit 001-005 で実装した案D（インデックス集約型）と Tier 2 施策の効果を一括検証する。

主な作業:

1. **計測スクリプト整備**: `bin/measure-initial-load.sh` を新規作成し、v2.2.3 ベースライン（`BASELINE_REF=56c6463747b41ab74108055a933cdfe29781fb43` で参照、`git rev-parse v2.2.3^{commit}` と照合）と v2.3.0 現状を同一スクリプトで計測する。**計測対象ファイルリストの正本はスクリプト内 bash 配列とする**
2. **計測実施**: スクリプトを 2 回連続実行して決定論性を確認し、結果を `measurement-report.md` に転載
3. **計測レポート作成**: `.aidlc/cycles/v2.3.0/measurement-report.md` にスクリプト出力転載・差分・削減率・目標達成判定・boilerplate 削減状況・Intent 成功基準対照表を記録
4. **#519 クローズ判断（2 段階基準）**: **段階 1（計測達成）+ 段階 2（Intent 成功基準項目達成）の両方を満たす場合のみ** `status:done` 付与・クローズ、いずれか未達時は構造化バックログ登録
5. **CHANGELOG.md 更新**: 本サイクルの主要変更点（案D / #553 解決 / Tier 2 施策）を追記

## 背景

- Intent「成功基準」に Inception 初回ロード ≤15,000 tok / Construction ≤17,980 tok / Operations ≤17,209 tok が必達として設定済み
- Unit 001-004 で各フェーズインデックスを実装し、Unit 005 で Tier 2 施策（operations-release スクリプト化、review-flow 簡略化）を統合済み
- Unit 001 / 003 / 004 の中間検証では Inception 13,443 tok / Construction 15,426 tok / Operations 15,394 tok を記録（いずれも目標達成）。ただし Unit 005 で `*/index.md` への参照差し替え（review-routing.md）と SKILL.md の微更新が入っているため、**最終状態の再計測が必要**
- 本 Unit はストーリー 8（計測レポート）とストーリー 9（クローズ判断 + バックログ運営）の両方を完結させる

### 事前計測（参考値、計画作成時点で実施）

設計フェーズ準備として現状を予備計測した結果、すべての目標を達成済みであることを確認:

| フェーズ | v2.2.3 ベースライン | v2.3.0 現状 | 差分 | 削減率 | 目標 | 判定 |
|---------|------------------:|-----------:|------:|------:|------|------|
| Inception | 22,972 tok | 14,655 tok | -8,317 tok | -36.2% | ≤15,000 tok | ✅ |
| Construction | 17,980 tok | 15,567 tok | -2,413 tok | -13.4% | ≤17,980 tok | ✅ |
| Operations | 17,209 tok | 15,502 tok | -1,707 tok | -9.9% | ≤17,209 tok | ✅ |

> 上記は計画策定の前提確認のための参考値である。実装フェーズで成果物としてのレポート作成時に、同一手順を**`bin/measure-initial-load.sh` 経由で再現**し、スクリプトの出力を正本として `measurement-report.md` に転載する（計測値の正本はスクリプト出力のみ。レポートは転載と人間向け解説）。

## スコープ

### 含むもの

#### 計測スクリプト整備（最小限）

- **`bin/measure-initial-load.sh`** を新規作成する（`.gitignore` 配下ではなくリポジトリ内に配置し再現可能性を担保）
  - 引数なしで Inception / Construction / Operations の v2.2.3 ベースラインと v2.3.0 現状の双方を計測し、ファイル別 tok 数と TOTAL を出力する
  - **ベースライン ref の固定**: スクリプト内に `BASELINE_REF="56c6463747b41ab74108055a933cdfe29781fb43"` を定数として持ち、計測前に `git rev-parse v2.2.3^{commit}` の結果と一致することを検証する。不一致時はエラー終了する（タグ差し替え・lightweight tag 揺れの防止）。`v2.2.3` タグは PR #550 のマージコミット `56c64637...` を指しており、Unit 定義文書中の参照値 `d88b0074`（マージ元ブランチの最終コミット）と `skills/aidlc/` 配下のツリー内容は同一だが、`git rev-parse v2.2.3^{commit}` が返す実際のタグコミットを正本とする
  - v2.2.3 側は `git show "$BASELINE_REF":<path>` で取得した内容を一時ディレクトリに展開して計測する（チェックアウトは行わない、タグ参照ではなく commit hash で参照）
  - 計測には `/tmp/anthropic-venv/bin/python3` + `tiktoken` (`cl100k_base`) を使用する。`tiktoken` 不在時はエラー終了
  - 出力フォーマットは `<tokens> tok  <path>` 形式で、各フェーズの末尾に `TOTAL` 行を出す（v2.3.0 ベースで Unit 001-004 の検証記録と一致させる）
  - **計測対象ファイルリストの正本化**: 計測対象ファイルリストは `bin/measure-initial-load.sh` 内の bash 配列を**唯一の正本**とする。本計画書および `measurement-report.md` は参考表示のみで、スクリプトと不一致が発生した場合はスクリプトを真とする
  - **決定論性の保証**: 同一 ref・同一 tokenizer・同一ファイル集合では tok 数は決定的に同じ値になる前提で実装する。誤差許容ロジックは入れない

#### 計測対象ファイル（参考表示、正本は `bin/measure-initial-load.sh`）

**v2.2.3 ベースライン（インデックス化前 / フェーズステップ全ロード）**:

| フェーズ | ファイル群 |
|---------|---------|
| 共通 | `SKILL.md` / `steps/common/rules-core.md` / `steps/common/preflight.md` / `steps/common/session-continuity.md` |
| Inception | + `steps/inception/{01-setup, 02-preparation, 03-intent, 04-stories-units, 05-completion}.md` |
| Construction | + `steps/construction/{01-setup, 02-design, 03-implementation, 04-completion}.md` |
| Operations | + `steps/operations/{01-setup, 02-deploy, 03-release, 04-completion}.md` |

**v2.3.0 現状（インデックス化後 / フェーズインデックスのみ）**:

| フェーズ | ファイル群 |
|---------|---------|
| 共通 | `SKILL.md` / `steps/common/rules-core.md` / `steps/common/preflight.md` / `steps/common/session-continuity.md` |
| Inception | + `steps/inception/index.md` |
| Construction | + `steps/construction/index.md` |
| Operations | + `steps/operations/index.md` |

> v2.2.3 / v2.3.0 ともに `06-backtrack.md` / `operations-release.md` / `review-flow.md` / `review-routing.md` 等の必要時ロードファイルは含めない（初回ロード総量計測のため）。

#### 計測レポート（成果物）

- **`.aidlc/cycles/v2.3.0/measurement-report.md`** を新規作成
  - 章構成:
    1. 概要（目的・計測条件・`BASELINE_REF` の commit hash・計測コマンド）
    2. 計測対象ファイル一覧（`bin/measure-initial-load.sh` の出力をそのまま転載した参考表示。正本はスクリプト）
    3. v2.2.3 ベースライン計測結果（フェーズ別ファイル別 tok + TOTAL、スクリプト出力転載）
    4. v2.3.0 計測結果（フェーズ別ファイル別 tok + TOTAL、スクリプト出力転載）
    5. 差分サマリ（v2.2.3 → v2.3.0、tok 数差・削減率・目標達成判定）
    6. boilerplate 削減（自動解消扱い）の達成状況（下記「boilerplate 削減状況の確認」の表を転載）
    7. 中間検証との突合（Unit 001 / 003 / 004 の中間値と最終値の差）
    8. Intent 成功基準への対照（必須基準・動作保証基準の各項目について Unit 001-005 の検証記録から達成状況を引用）
    9. 結論（全目標達成 / 一部未達）
  - 計測値の正本は `bin/measure-initial-load.sh` の出力のみ。本レポートは出力の転載と人間向け解説を担う

#### #519 クローズ判断と Issue 操作

##### クローズ判断の 2 段階基準（機械的）

#519 のクローズには以下の **2 段階基準を全て満たすこと**を必須とする。1 つでも未達なら未達パスを実行する。

**段階 1: 計測達成基準**（`bin/measure-initial-load.sh` の TOTAL 値で判定）

| 項目 | 必達閾値 | 判定 |
|------|---------|------|
| Inception 初回ロード | ≤ 15,000 tok | TOTAL 値の単純比較 |
| Construction 初回ロード | ≤ 17,980 tok | TOTAL 値の単純比較 |
| Operations 初回ロード | ≤ 17,209 tok | TOTAL 値の単純比較 |

**段階 2: Intent 成功基準項目の達成確認**（既存 Unit 実装/検証記録から引用）

Intent §成功基準の必須・動作保証項目を、本 Unit では新規検証せず、Unit 001-005 の実装・検証記録から該当箇所を引用して達成状況を確認する。**Unit 001 のみ `_implementation.md` 命名で、Unit 002-005 は `_verification.md` 命名**である点に注意:

| Intent 基準 | 検証元 Unit | 引用先（実在パス） |
|------------|-----------|--------|
| フェーズインデックスファイル全フェーズ作成 | Unit 001 / 003 / 004 | `unit_001_inception_phase_index_implementation.md` / `unit_003_construction_phase_index_verification.md` / `unit_004_operations_phase_index_verification.md` |
| インデックスに 3 点（目次・分岐・判定）集約 | Unit 001 / 003 / 004 | 同上 |
| コンパクション復帰インデックスのみで一意判定 | Unit 002 | `unit_002_universal_recovery_base_verification.md` |
| #553 再現ケースで Inception 復帰成功 | Unit 002 | `unit_002_universal_recovery_base_verification.md` |
| 全フェーズステップ実行が現行と同じ結果 | Unit 001-004 | 上記 4 ファイル |
| AIレビュー・セミオートゲート・コンパクション復帰・意思決定記録の機能 | Unit 001-005 | 上記 4 ファイル + `unit_005_tier2_integration_verification.md` |
| Tier 2 施策の採用項目（operations-release / review-flow） | Unit 005 | `unit_005_tier2_integration_verification.md` |

> いずれも `.aidlc/cycles/v2.3.0/construction/units/` 直下に存在するファイル。実装フェーズで存在確認と参照内容の引用を行う。

両段階すべて達成 → クローズ。いずれか未達 → 未達パス。

##### 達成時の操作

- `gh issue comment 519 --body-file <一時ファイル>`（クローズ判断コメント、計測サマリ + Intent 基準対照表を含む）
- `gh issue edit 519 --add-label "status:done" --remove-label "status:in-progress"`
- `gh issue close 519 --reason completed`

##### 未達時の操作（構造化バックログ登録）

未達カテゴリを以下から特定し、該当する全カテゴリについて個別バックログ Issue を作成する:

| カテゴリ | 検出条件 | バックログラベル | クローズ阻害? |
|---------|---------|-----------------|:-------------:|
| `tok-target-missed` | 段階 1 のいずれかが閾値超過 | `backlog,type:feature,priority:high` | はい |
| `behavior-regression` | 段階 2 の動作保証項目で回帰検出 | `backlog,type:bugfix,priority:high` | はい |
| `recovery-regression` | #553 再現ケース失敗（段階 2） | `backlog,type:bugfix,priority:high` | はい |
| `tier2-incomplete` | Tier 2 施策（operations-release / review-flow）の達成不足 | `backlog,type:feature,priority:medium` | はい |
| `boilerplate-incomplete` | 「自動解消扱い」boilerplate 削減が確認できない（Intent 必達項目に非含、補助項目） | `backlog,type:refactor,priority:low` | いいえ |

- **クローズ阻害「いいえ」のカテゴリ**: バックログ Issue は作成するが、#519 クローズは可能（段階 1 + 段階 2 達成時）
- **クローズ阻害「はい」のカテゴリ**: バックログ Issue を作成し、#519 はクローズしない

各バックログ Issue は `[Backlog] {category}: {要約}` をタイトルとし、本文に `#519 未達項目` への参照と該当する Unit / 検証記録への参照を含める。#519 はクローズしない。

- **本サイクルの予測**: 事前計測で全目標達成済み・Unit 001-005 の検証記録もすべて完了済みのため、達成パスを基本シナリオとする

#### CHANGELOG.md 更新

- **`CHANGELOG.md`** の v2.3.0 セクションに以下を追記:
  - 案D（インデックス集約型プログレッシブロード）の実装
  - #553 の根本解決（汎用復帰判定基盤、`phase-recovery-spec.md`）
  - Tier 2 施策（`operations-release.sh` 化、`review-routing.md` 抽出）
  - Inception / Construction / Operations 初回ロードの削減結果（実測値）
- フォーマットは既存の `CHANGELOG.md` のセクション構造に従う（該当セクションが未作成の場合は `## v2.3.0 (YYYY-MM-DD)` を新設）

#### boilerplate 削減状況の確認（機械的・補助項目）

- Intent で「自動解消扱い」と定義された Tier 2 施策 3 つ目（ステップファイル内 boilerplate 削減）について、実装後に達成状況を機械的に確認
- **位置づけ**: Intent §成功基準の必達項目には含まれず「自動解消扱い」のため、本 Unit では結果を記録するが**未達であっても #519 クローズ判断（段階 1 / 段階 2）には影響しない補助的な確認項目**として扱う。Tier 2 施策（`operations-release.sh` 化等）の副作用で一部フェーズの合計 tok が増加することがあり得るが、必達基準（初回ロード閾値）と Intent 成功基準項目（動作保証等）が達成されていれば #519 はクローズ可能
- **確認方法（2 軸）**:

  **軸 1: ステップファイル群の合計 tok 削減**（メトリクス）
  - 各フェーズのステップファイル群（`steps/{phase}/01-setup.md` 〜 `04/05-completion.md`）について v2.2.3（`git show "$BASELINE_REF":<path>`）と v2.3.0 の合計 tok 数を tiktoken (cl100k_base) で計測
  - **判定式**: 各フェーズで「v2.3.0 ステップファイル群合計 tok ≤ v2.2.3 ステップファイル群合計 tok」
  - 単純な grep 件数では「index.md への参照記述追加」と「ロジック自体の冗長記述」を区別できないため、tok 数による合計削減を正本判定とする

  **軸 2: index.md 集約証跡**（4 パターンの存在確認）
  - 代表パターン × フェーズ適用範囲表:
    | パターン名 | grep 正規表現 | Inception | Construction | Operations |
    |---------|-------------|:---------:|:------------:|:----------:|
    | automation_mode 分岐 | `automation_mode` | ○ | ○ | ○ |
    | depth_level 分岐 | `depth_level` | ○ | ○ | ○ |
    | AI レビュー分岐参照 | `review-flow\.md\|review-routing\.md` | ○ | ○ | ○ |
    | エクスプレス分岐 | `express` | ○ | ○ | - |
  - ○: そのフェーズで意味を持つパターン（index.md 集約証跡の対象）
  - -: そのフェーズに存在しないパターン（要件外）
  - **判定式**: 各フェーズの index.md に、そのフェーズで ○ となるパターンがすべて少なくとも 1 件以上登場していること（`grep -l` で確認）
- **出力**: `measurement-report.md` §6 に以下を掲載
  - 軸 1: フェーズ × ステップファイル群合計 tok の比較表（v2.2.3 / v2.3.0 / 差分 / 削減率 / 判定）
  - 軸 2: 3×4 のフェーズ × パターン applicability 表 + index.md 出現確認
- **判定方針（非阻害）**:
  - 軸 1 は PASS / FAIL を記録するのみ。FAIL 時は理由注記（Tier 2 施策の副作用等）と `boilerplate-incomplete` バックログ候補化のみで、**#519 クローズには影響しない**
  - 軸 2 は applicability `○` パターンすべての出現を要求するが、これも補助項目であり #519 クローズ阻害ではない
  - boilerplate 削減全体が「自動解消扱い」（Intent §成功基準 必達項目に非含）のため、計測値はレポートに残すが、いずれの軸も #519 クローズ判断には影響しない

### 含まないもの

- **インデックス化自体の実装**（Unit 001-004 完了済み）
- **Tier 2 施策の実装**（Unit 005 完了済み）
- **MCP / ツールベース検索の設計・実装**（次サイクル切り出し済み）
- **Operations Phase の通常リリース作業**（ブランチマージ・タグ作成等は Operations Phase で実施）
- **既存スクリプト（`scripts/operations-release.sh` 等）の変更**
- **新たな reviewing スキル追加・既存スキル内部実装変更**
- **`.aidlc/cycles/v1.*/`、`v2.0.*/`、`v2.1.*/`、`v2.2.*/` の既存サイクル成果物**の参照・変更（読み取り専用履歴データ）

## 設計方針

### 1. 計測の再現可能性と決定論性

- 計測コマンドを `bin/measure-initial-load.sh` に固定化することで、Unit 006 完了後も同一手順で再計測可能とする
- **ベースライン参照は `BASELINE_REF=56c6463747b41ab74108055a933cdfe29781fb43` で commit hash 固定**。v2.2.3 タグの差し替え・lightweight tag 揺れを防止するため、計測前に `git rev-parse v2.2.3^{commit}` の結果と一致確認を行い、不一致時はエラー終了
- v2.2.3 ファイルの取得は `git show "$BASELINE_REF":<path>` で行い、ワーキングツリーに影響を与えない
- 一時ディレクトリは `mktemp -d` で取得し、スクリプト終了時に自動削除する
- **同一 ref・同一 tokenizer・同一ファイル集合では tok 数は決定的**。スクリプトを 2 回連続実行してバイト単位で完全一致することを検証し、誤差許容ロジックは入れない

### 2. 計測対象ファイルリストの単一情報源

- **正本は `bin/measure-initial-load.sh` 内の bash 配列のみ**
- 本計画書および `measurement-report.md` への記載は参考表示であり、スクリプトと不一致が発生した場合は**スクリプトを真とする**（計画書ではなくスクリプト）
- レポートはスクリプト出力の転載と人間向け解説を担当する

### 3. クローズ判断の 2 段階機械的基準

#519 のクローズには以下の **2 段階すべての達成が必須**:

- **段階 1（計測達成）**: スクリプト出力の TOTAL 値と Intent 必達基準（≤15,000 / ≤17,980 / ≤17,209）の単純比較。3 フェーズすべて達成
- **段階 2（Intent 成功基準項目）**: Unit 001-005 の検証記録から該当箇所を引用し、Intent §成功基準の必須・動作保証項目すべての達成を確認

主観的判断は排除する。いずれか 1 段階でも未達の場合は未達パス（構造化バックログ登録）を実行し、#519 はクローズしない。

### 4. CHANGELOG 更新の最小原則

- 既存の `CHANGELOG.md` フォーマットを変更しない
- v2.3.0 セクションは「概要」+「主な変更」+「実測削減量」の 3 要素のみとし、詳細はサイクルの履歴ファイル群に委譲

## 対象ファイル

### 新規作成

| パス | 種別 | 概要 |
|------|------|------|
| `bin/measure-initial-load.sh` | スクリプト | 計測コマンドラッパー（v2.2.3 / v2.3.0 双方を計測） |
| `.aidlc/cycles/v2.3.0/measurement-report.md` | レポート | スクリプト出力の転載と達成判定の人間向け解説（計測値の正本はスクリプト出力） |
| `.aidlc/cycles/v2.3.0/construction/units/unit_006_measurement_and_closure_verification.md` | 検証記録 | 完了条件チェック・実装記録 |
| `.aidlc/cycles/v2.3.0/history/construction_unit06.md` | 履歴 | `/write-history` 経由で追記 |

### 編集

| パス | 編集内容 |
|------|---------|
| `CHANGELOG.md` | v2.3.0 セクションに本サイクルの主要変更点と削減実績を追記 |
| `.aidlc/cycles/v2.3.0/story-artifacts/units/006-measurement-and-closure.md` | 実装状態を「未着手」→「完了」に更新 |

### 編集対象外（明示）

- `skills/aidlc/SKILL.md` / `steps/common/*` / `steps/{phase}/index.md`（計測対象であり、計測中は変更しない）
- 既存スクリプト（`scripts/*.sh`）
- v2.2.3 以前のサイクル成果物

## 設計成果物（Phase 1）

- ドメインモデル: `.aidlc/cycles/v2.3.0/design-artifacts/domain-models/unit_006_measurement_and_closure_domain_model.md`
- 論理設計: `.aidlc/cycles/v2.3.0/design-artifacts/logical-designs/unit_006_measurement_and_closure_logical_design.md`

## 実装記録（Phase 2）

- 実装記録: `.aidlc/cycles/v2.3.0/construction/units/unit_006_measurement_and_closure_verification.md`

## 検証手順

### 検証 1: `bin/measure-initial-load.sh` 構文と実行

- `bash -n bin/measure-initial-load.sh` がエラーゼロ
- `bash bin/measure-initial-load.sh` を実行し、Inception / Construction / Operations の v2.2.3 / v2.3.0 双方の計測値が出力される
- 出力フォーマットが `<N> tok  <path>` + `TOTAL` 行で構成されている
- スクリプト内の `BASELINE_REF` 検証ロジックが正常動作する（`git rev-parse v2.2.3^{commit}` との一致確認が成功する）

### 検証 2: 決定論性検証

- `bin/measure-initial-load.sh` を**同一 ref 上で 2 回連続実行**し、出力が完全一致（バイト単位）すること。差分があれば即時失敗（決定論性違反）
- 同一 ref・同一 tokenizer・同一ファイル集合では tok 数は決定的であるため、誤差許容ロジックは入れない

### 検証 3: 計測値の閾値判定

- **v2.2.3 ベースライン整合**: スクリプト出力の v2.2.3 値が Intent 必達基準（Inception 22,972 / Construction 17,980 / Operations 17,209）と完全一致（差分ゼロ）
- **v2.3.0 閾値判定**: スクリプト出力の v2.3.0 TOTAL が以下を満たす:
  - Inception ≤ 15,000 tok
  - Construction ≤ 17,980 tok
  - Operations ≤ 17,209 tok
- 事前計測値（Inception 14,655 / Construction 15,567 / Operations 15,502）は**参考情報**であり、判定基準ではない（計画策定時点との差は閾値判定の対象外）

### 検証 4: 計測レポートの完全性

- `measurement-report.md` 9 章すべてが存在する
- 3 フェーズすべての計測結果と差分・削減率が明示されている
- 目標達成判定（≤15,000 / ≤17,980 / ≤17,209）が各フェーズについて記載されている
- §8 に Intent 成功基準項目の達成対照表が含まれている

### 検証 5: boilerplate 削減確認の機械検証（2 軸）

- **軸 1: ステップファイル群 tok 削減**: 各フェーズについて、`steps/{phase}/0[1-5]-*.md` 群の合計 tok 数を tiktoken (cl100k_base) で計測し、`v2.3.0 合計 tok ≤ v2.2.3 合計 tok` を確認
- **軸 2: index 集約証跡**: 各フェーズの index.md に対し、そのフェーズで applicability `○` となるパターンの存在を `grep -l` で確認（Inception/Construction は 4 パターン、Operations は `express` を除く 3 パターン）
- §6 に 2 軸の結果テーブルが掲載されている

### 検証 6: #519 クローズ判断 2 段階基準

- **段階 1（計測）**: 検証 3 が全フェーズ達成
- **段階 2（Intent 基準）**: §8 の対照表で全項目達成
- **両段階達成時の操作**: クローズ判断コメント投稿 / `status:done` ラベル付与 / `status:in-progress` 削除 / Issue クローズ がすべて完了
  - 確認: `gh issue view 519 --json state,labels` で `state="CLOSED"` かつ `status:done` ラベル存在
- **未達時の操作**: 該当する全カテゴリについてバックログ Issue が作成され、本文に `#519` 参照と該当 Unit 検証記録への参照を含む

### 検証 7: CHANGELOG.md

- v2.3.0 セクションが追加されている
- 案D / #553 解決 / Tier 2 施策 / 削減実績の 4 要素が記載されている

### 検証 8: markdownlint と bash substitution チェック

- `bash skills/aidlc/scripts/run-markdownlint.sh v2.3.0` がエラーゼロ（`markdown_lint=false` の場合はスキップ可）
- `bash bin/check-bash-substitution.sh` が違反ゼロ（CI と同じデフォルトスコープ `skills/aidlc/steps/`）

## 完了条件チェックリスト

### 計測スクリプト

- [ ] **【計測スクリプト新設】** `bin/measure-initial-load.sh` が新規作成され、引数なしで Inception / Construction / Operations の v2.2.3 / v2.3.0 双方を計測できる
- [ ] **【BASELINE_REF 固定】** スクリプト内に `BASELINE_REF="56c6463747b41ab74108055a933cdfe29781fb43"` が定数として定義されている
- [ ] **【BASELINE_REF 検証】** 計測前に `git rev-parse v2.2.3^{commit}` の結果と `BASELINE_REF` の一致確認が行われ、不一致時はエラー終了する
- [ ] **【計測スクリプト構文】** `bash -n bin/measure-initial-load.sh` がエラーゼロ
- [ ] **【決定論性】** スクリプトを 2 回連続実行し、出力がバイト単位で完全一致する
- [ ] **【単一情報源】** 計測対象ファイルリストの正本がスクリプト内の bash 配列であり、計画書および `measurement-report.md` には参考転載のみが存在する

### 計測値判定（段階 1: 計測達成基準）

- [ ] **【v2.2.3 ベースライン整合】** スクリプト出力の v2.2.3 値が Intent 必達基準（Inception 22,972 / Construction 17,980 / Operations 17,209）と完全一致（差分ゼロ）
- [ ] **【v2.3.0 達成: Inception】** v2.3.0 Inception 初回ロード ≤ 15,000 tok（必達基準）
- [ ] **【v2.3.0 達成: Construction】** v2.3.0 Construction 初回ロード ≤ 17,980 tok（必達基準）
- [ ] **【v2.3.0 達成: Operations】** v2.3.0 Operations 初回ロード ≤ 17,209 tok（必達基準）

### 計測レポート

- [ ] **【計測レポート新設】** `.aidlc/cycles/v2.3.0/measurement-report.md` が 9 章構成で作成されている
- [ ] **【レポート §1 概要】** 目的・計測条件・`BASELINE_REF` commit hash・計測コマンドが記載されている
- [ ] **【レポート §3 ベースライン】** v2.2.3 のフェーズ別ファイル別 tok と TOTAL が記載されている
- [ ] **【レポート §4 実測】** v2.3.0 のフェーズ別ファイル別 tok と TOTAL が記載されている
- [ ] **【レポート §5 差分】** v2.2.3 → v2.3.0 の差分 tok と削減率 % が 3 フェーズすべてについて記載され、目標達成判定が明示されている
- [ ] **【レポート §6 軸 1: ステップファイル群 tok 削減】** 各フェーズについて、ステップファイル群の合計 tok 数が計測値とともに掲載されている。判定結果（PASS/FAIL）も明示。FAIL の場合は理由（Tier 2 施策の副作用等）が注記される。**本項目は補助的確認のため未達でも #519 クローズには影響しない**
- [ ] **【レポート §6 軸 2: index 集約証跡】** 3×4 のフェーズ × パターン applicability 表が掲載され、各 index.md に該当する applicability `○` パターンがすべて少なくとも 1 件以上出現することが確認されている（Operations は `express` を除く 3 パターン、Inception/Construction は 4 パターン）
- [ ] **【レポート §7 中間値突合】** Unit 001 / 003 / 004 の中間検証値と最終値の差が記載されている
- [ ] **【レポート §8 Intent 対照】** Intent 成功基準項目の達成状況が、Unit 001-005 の検証記録への参照付きで対照表化されている
- [ ] **【レポート §9 結論】** 段階 1（計測）と段階 2（Intent 基準）の双方の総合判定が明示されている

### #519 クローズ判断（段階 2: Intent 成功基準）

- [ ] **【段階 2 評価】** Intent 必須基準・動作保証基準の各項目について、Unit 001-005 の検証記録から達成状況が引用されている
- [ ] **【#519 クローズ判断コメント】** クローズ判断コメント（計測サマリ + Intent 基準対照表）が `gh issue comment 519` で投稿されている（達成 / 未達のいずれも）
- [ ] **【#519 達成時操作】** 段階 1 + 段階 2 ともに達成時: `status:done` ラベル付与 + `status:in-progress` 削除 + `gh issue close 519 --reason completed` が完了し、`gh issue view 519 --json state,labels` で確認できる
- [ ] **【#519 未達時操作（構造化）】** いずれかの段階が未達時: 未達カテゴリ（`tok-target-missed` / `behavior-regression` / `recovery-regression` / `tier2-incomplete` / `boilerplate-incomplete`）ごとにバックログ Issue が作成され、本文に `#519` 参照と該当 Unit 検証記録への参照を含む（達成時は本項目スキップ）

### CHANGELOG とリント

- [ ] **【CHANGELOG 更新】** `CHANGELOG.md` の v2.3.0 セクションに案D / #553 解決 / Tier 2 施策 / 削減実績の 4 要素が記載されている
- [ ] **【markdownlint】** `markdown_lint=true` の場合のみ実施し、エラーゼロ（`false` ならスキップ可）
- [ ] **【bash substitution check】** `bash bin/check-bash-substitution.sh` が違反ゼロ

### スコープ遵守

- [ ] **【スコープ遵守】** Unit 001-005 で実装した成果物（`SKILL.md` / `steps/common/*` / `steps/{phase}/index.md` / `phase-recovery-spec.md` / `operations-release.sh` / `review-routing.md` 等）への変更が一切行われていない（純粋な計測・レポート Unit）

## 依存関係

### 前提 Unit

- Unit 001（Inception Phase Index、計測対象）
- Unit 002（汎用復帰判定基盤、計測対象）
- Unit 003（Construction Phase Index、計測対象）
- Unit 004（Operations Phase Index、計測対象）
- Unit 005（Tier 2 施策、計測対象）

### 本 Unit を依存元とする Unit

- なし（本 Unit はサイクル v2.3.0 の総括 Unit）

## 関連 Issue

- #519: コンテキスト圧縮メイン Issue（クローズ対象）

## リスクと留意事項

- **計測値の決定論性**: 同一 ref・同一 tokenizer・同一ファイル集合では tok 数は決定的に同じ値になる。実装時計測と事前計測の差は、計画策定後に他ファイル変更が混入していない限り発生しない。発生した場合はファイル変更を原因として精査する（誤差許容では通さない）
- **未達シナリオ**: 事前計測で全目標達成済み・Unit 001-005 検証記録もすべて完了済みのため、未達パスは実質的に発動しない見込み。ただしレポート構造とバックログ登録手順は構造化された未達パスとして記述しておく
- **CHANGELOG.md フォーマット**: 既存セクション構造を維持するため、実装フェーズで `CHANGELOG.md` の現状を読み込み、フォーマットを把握してから追記する
- **#519 のクローズタイミング**: クローズは本 Unit 内で実施する。Operations Phase でのリリース後ではなく、Construction Phase で計測完了次第クローズ判断を確定する（Unit 定義通り）
- **`bin/measure-initial-load.sh` の配置**: `bin/` 直下に配置することで CI / 手動実行の双方からアクセスしやすくなる。`scripts/` ではなく `bin/` を選択する理由は、既存の `bin/check-bash-substitution.sh` と同じ階層に揃えるため
- **Intent 成功基準対照表の引用整合**: 段階 2 評価では Unit 001 のみ `unit_001_inception_phase_index_implementation.md`、Unit 002-005 は `unit_NNN_*_verification.md` を引用するため、引用箇所のパス・記述が変更されていないことを実装時に確認する。引用元が見つからない場合は対照表に明示し、検証記録の補強で対応する

# AI-DLC v3 フルリニューアル計画

## 前提

3 つの深掘り分析（本質/偶有分析・スクリプト必要性分析・状態/設定分析）、構造調査・ワークフロー調査、および v3 設計メモの結果を統合。v2 の漸進的改善ではなく、v3 としてゼロから設計し直す前提で策定。

## v2 の何が問題か（根本原因の特定）

### 1. Claude 3.5 時代の防御ロジックが全体の 60% を占める

ステップ Markdown 6,436 行のうち約 3,900 行は、旧モデル向けの「やってはいけない」「こうしろ」「こうするな」型の防御的指示。モダン AI モデル（Opus 4.x 等）ではこれらの大部分は冗長であり、簡潔な記述に置き換えられる。

- review-flow.md: 366 行中 74% が防御ロジック。本質的フローは ~20 行
- 03-implementation.md: 166 行中 64% が Self-Healing Loop 防御
- rules-core.md: 149 行中 51% が dasel アンチパターン（旧モデル用）
- commit-flow.md: 134 行中 53% が squash 事故防止

### 2. 推論ベースの復帰判定が過剰に複雑

phase-recovery-spec.md（819 行）は「ファイルの有無からステップを推論する」仕組み。明示的な状態マーカーを書き込めば ~50 行で済む。推論方式は「状態を壊さない」思想だが、代わりに仕様の複雑度を膨大に支払っている。

### 3. 10 個のレビュースキルが同一構造の複製

reviewing-common-base.md を 10 箇所に sync-reviewing-common.sh で同期するという DRY 違反。各スキルの差分は「観点テンプレート」だけ。

### 4. リーフスクリプトの肥大化

138 スクリプト（30,303 行）のうち、ステップから呼ばれるエントリーポイントは 15 本。20 本のリーフスクリプトはステップから一度も参照されない。安全境界が不要な単純処理（ディレクトリ作成、ブランチ作成、環境情報取得等）までスクリプト化している。

### 5. ステップファイルに 4 つの責務が混在

手順・エージェント仕様・復帰ロジック・後方互換注記が同一ファイルに同居。ただし「AI プロンプトファイルは自己完結性が重要」という反論がある。

---

## v3 AI-DLC Principles

v3 は単なる軽量タスクランナーではなく、AI-DLC の思想を維持した再設計である。以下を core の設計原則とする。

### 1. AI is a lifecycle collaborator, not a code generator

AI は実装だけでなく、Intent 明確化、作業分割、設計、検証、リリース準備、振り返りに関与する。AI の役割は「コード生成」ではなく、ライフサイクル全体の協働者である。

### 2. Human judgment remains explicit

スコープ、リスク、リリース、不可逆操作、機密情報の扱いは人間が判断する。automation は人間判断を消すものではなく、低リスク反復作業の摩擦を下げるために使う。

### 3. Intent-to-release traceability is mandatory

各 work item は intent、scope、acceptance criteria、test、release result に追跡可能である。「なぜ作るか」から「何をリリースしたか」までが切れないことを core の品質条件にする。

### 4. Work is decomposed into value-delivering units

作業単位は単なる技術タスクではなく、ユーザー価値または運用価値を届ける単位として定義する。内部リファクタでも、価値・リスク・検証方法を明示する。

### 5. Workflow weight adapts to risk

tiny / normal / risky によって成果物、レビュー、検証の厚みを変える。全作業に同じ儀式を強制しない一方で、高リスク変更は明示的に重く扱う。

### 6. Context is a first-class artifact

AI が中断・復帰・継続できるよう、state、journal、work item を明示的に管理する。会話履歴ではなく、リポジトリ内成果物を継続文脈の正本にする。

### 7. Reflection feeds the next cycle

reflect は任意実行だが、得られた Try / lesson は次の define で参照される。振り返りは反省文ではなく、次の作業・Issue・ルール変更につながる行動として扱う。

---

## AI-DLC 方法論の保全

v3 は技術的な簡素化だが、AI-DLC の方法論的特徴はすべて維持する。削減対象は「実装の複雑さ」であり、「方法論の深さ」ではない。

### 保全する方法論要素

| 方法論要素 | v2 での実装 | v3 での実装 | 変更理由 |
|-----------|------------|------------|---------|
| 会話の逆転（AI 提案 → 人間承認） | 各ステップの暗黙的フロー | 各ステップに承認ゲートを明示 | Opus 4.x は明示すれば確実に従う |
| Unit 概念（独立価値提供ブロック） | 04-stories-units.md + index.md 分岐 | build.md に work item ループ全体を記述 | 1 ファイル完結で依存解決も含む |
| 3 フェーズ構造 | 3 ディレクトリ × 複数ステップ | 3 ファイル（フェーズの意味は同一） | 構造簡素化のみ、フェーズの責務は不変 |
| Depth Level 分岐 | 設定値 + ステップ内条件分岐 | 設定値 + ステップ内条件分岐（維持） | 変更なし |
| Automation Mode | manual/semi_auto/full_auto | manual/semi_auto/full_auto（維持） | 変更なし |
| レビュー品質ゲート | 10 スキル + review-flow.md | 1 スキル + パラメタライズ | 観点は全数維持、配送構造のみ変更 |
| Self-Healing Loop | 03-implementation.md 内の防御ロジック | build.md 内に簡潔に記述 | ループ自体は維持、冗長な指示を削減 |
| Express モード | 専用ルーティング | SKILL.md ルーティング（維持） | 変更なし |
| Retrospective (KPT) | 独立スキル | 独立スキル（維持） | 変更なし |

### 防御ロジックと方法論ロジックの区別

v2 の 60% を占める「防御ロジック」と、AI-DLC 固有の「方法論ロジック」は異なるもの。v3 で廃止するのは前者のみ。

**廃止する防御ロジック（旧モデル向け）**:
- 「dasel を使うな、Read ツールを使え」（rules-core.md の 51%）
- 「squash 時に history ファイルを消すな」（commit-flow.md の 53%）
- 「レビューで無限ループするな、5 ラウンドで打ち切れ」の冗長な繰り返し説明
- Self-Healing Loop の「テスト失敗時にテストを書き換えるな」の多重警告

**維持する方法論ロジック（AI-DLC 固有）**:

承認ゲート v2 → v3 対応:

| v2 ゲート | v3 ゲート | 変更 |
|----------|----------|------|
| Intent 承認 | Intent 承認 | 維持 |
| Stories 承認 | (廃止) | work item 分割に吸収 |
| Unit 定義承認 | Work Item 承認 | 名称変更、承認は維持 |
| Plan 承認 | Design 承認に統合 | normal: 簡易 design 承認、risky: design + risk analysis 承認 |
| Design 承認 | Design 承認 | 維持（normal/risky で厚みが変わる） |
| Code Review | Code Review | 維持（normal/risky で実行） |
| Integration Review | Integration Review | 条件付き（複数 work item 完了時のみ） |
| Deploy Review | Deploy Review | 条件付き（risky のみ） |
| (なし) | Pre-merge Review | 新設（常に実行） |

- レビュー上限: 最大 5 ラウンド、未解決なら人間にエスカレーション
- Defer 戦略: OUT_OF_SCOPE / TECHNICAL_BLOCKER を明示理由付きで defer → 自動 Issue 化
- スコープ保護: Intent 要件を defer する場合は人間確認必須（破壊的変更検出）
- Self-Healing Loop: コード生成 → テスト → 自動修正提案 → リトライのサイクル自体
- Unit 依存解決: 依存グラフに基づく実行順序の自動提案
- Depth Level 分岐: minimal（設計スキップ）/ standard（全工程）/ comprehensive（リスク分析・シーケンス図追加）

---

## v3 設計原則

### P1: 方法論ファースト

AI-DLC の 7 Principles を実装の判断基準とする。特に「会話の逆転」（AI 提案 → 人間承認）と「Minimize Stages, Maximize Flow」（承認ゲートは本質的な判断ポイントのみ）を両立させる。技術的簡素化で方法論を毀損しない。

### P2: 防御ロジックを簡潔に書き直す

Claude 3.5 Sonnet 用の冗長な防御ロジックを簡潔に書き直す。ルールの数ではなく記述量を削る。モダン AI モデルは「何をすべきか」を簡潔に書けば十分で、同じ警告の多重繰り返しや冗長な説明は不要。ただし安全ルール自体は残す — rules.md ~80 行に集約し、モデル差し替え・軽量モデル利用時にも workflow correctness を維持できる最低限の safety rules は保持する。方法論ロジック（承認ゲート・レビュー上限・Defer 戦略等）は防御ロジックではないので維持する。

### P3: 明示状態 > 推論

復帰判定はファイル存在の推論ではなく、state.json への明示的ステータス書き込みで行う。仕様を 819 行 → ~50 行に削減。AI 向け状態は JSON、人間向け成果物は Markdown と責務を分離する。

### P4: 安全境界が必要な操作はスクリプトに残す

スクリプトの要否は「AI にできるか」ではなく「安全境界が必要か」で判断する。CLAUDE.md / AGENTS.md で確立された安全パターン（file-based interface、read-config.sh 経由の TOML パース、state-write.sh 経由の atomic 書き込み、コマンド置換禁止のための wrapper）はスクリプトとして維持する。スクリプト化しないのは、安全境界が不要かつ AI が inline で正確に実行できる処理（mkdir -p、git checkout -b、uname 等の単純コマンド）に限る。

### P5: スキルは最小数

メインスキル 1 + レビュースキル 1 + ユーティリティ数個。10 個のレビュースキルは 1 個にパラメタライズ。

### P6: 設定は実質 2 キー

ほとんどのユーザーが触るのは `automation`（semi_auto/full_auto）と `depth_level`（standard/comprehensive）だけ。残りはデフォルトで動く設計にする。

### P7: consumer 互換性はマイグレーションで担保

v2 → v3 のマイグレーションパスを用意する。v2 の config.toml / progress ファイルを v3 形式に変換するスクリプトを同梱。ただし v2 との runtime 互換は維持しない（クリーンカット）。

---

## v3 ワークフロー

### コマンド設計

```text
/aidlc define    目的・スコープ・作業単位を決める（Inception）
/aidlc build     次の work item を実装・検証・完了する（Construction）
/aidlc release   main に安全に取り込む（Operations）
/aidlc reflect   任意で振り返り、改善 Issue を作る（Retrospective）
/aidlc status    現在地と次アクションを表示する（読み取り専用）
/aidlc doctor    設定・git・gh・state の問題を診断する
/aidlc express   define + build + release を連続実行する（小規模変更用）
```

**コマンド名変更の理由**: v2 では「名前変更は不要」という判断があった。これは v2 が漸進的改善であり、既存ユーザーへの認知コストに見合う価値がなかったため。v3 はワークフロー自体をゼロから再設計しており、define / build / release / reflect という名前はフェーズの実際の行為をより直接的に表現する。新規ユーザーが「何をするフェーズか」を名前から即座に理解できることを優先した。継続性のために旧名称（inception / construction / operations / retrospective）はエイリアスとして維持する。

### v2 との対応

| v2 コマンド | v3 コマンド | 備考 |
|------------|------------|------|
| inception | define | エイリアスとして inception も維持 |
| construction | build | エイリアスとして construction も維持 |
| operations | release | エイリアスとして operations も維持 |
| retrospective | reflect | エイリアスとして retrospective も維持 |
| express | express | 維持 |
| (なし) | status | 新設。v2 では preflight 内に埋め込まれていた現在地表示を独立 |
| (なし) | doctor | 新設。v2 では preflight + recovery spec に分散していた診断を集約 |

### 引数なし実行

`/aidlc`（引数なし）は state.json と work item frontmatter からフェーズを導出し、適切なコマンドに自動ルーティングする。state.json が存在しない場合は define に遷移する。

---

## Traceability 設計

v3 core は、AI-DLC の「Intent から Release までの一貫性」を保つため、以下の trace chain を維持する。

### Trace Chain

```text
intent.md
  -> work-items/*.md
  -> designs/*.md        (normal / risky のみ)
  -> tests / checks
  -> reviews/*.md        (normal / risky または必要時)
  -> journal.md
  -> release.md
  -> reflect.md          (任意)
  -> 次 cycle の define input
```

### Work Item の必須リンク

各 work item は最低限以下を持つ。

- **Intent reference**: どの intent / scope に対応するか
- **Acceptance criteria**: 完了条件
- **Verification**: どのテスト・確認で完了を判断するか
- **Release note impact**: release に書く必要があるか

### Traceability の正本

state.json はサイクルレベルの状態（define 完了、release 状態）のみ保持する。work item の trace 情報（intent_refs、acceptance criteria、verification status 等）は各 work-items/*.md の frontmatter と本文に正本を置く。フェーズは state.json と work item 状態から導出する（後述の「フェーズ導出ロジック」参照）。

### define への反映

次 cycle の define では、前 cycle の以下を読む。

- journal.md の未解決事項
- reflect.md の Try / Issue
- release 後に残った follow-up
- blocked / withdrawn work item

これにより、reflect が任意でも「学びを次に反映する」AI-DLC の流れを core に残す。

---

## データモデル

### ディレクトリ構造

```text
.aidlc/
  config.toml
  state.json
  cycles/
    v3.0.0/
      intent.md
      work-items/
        001-example.md
      designs/
        001-example.md       (normal / risky のみ)
      reviews/
        001-example.md       (normal / risky のみ)
      journal.md
      release.md
      reflect.md             (任意)
```

### 分散状態モデル

v3 は状態を 2 箇所に分散して管理する。

- **state.json**: サイクルレベルの状態（define 完了フラグ、release 状態）。書き込みタイミングは define 完了時と release 時のみ（single-actor moment）
- **work-items/*.md frontmatter**: 各 work item の個別状態。作業者がそれぞれの work item ファイルを更新する

この分散により、複数人が異なる work item を並行作業しても state.json がコンフリクトしない。

#### state.json

目的:

- AI / script がサイクルレベルの状態を機械的に判定する
- フェーズを導出するための最小限の入力を提供する
- doctor で schema validation 可能にする

schema:

```json
{
  "schema_version": "3.0",
  "current_cycle": "v3.0.0",
  "define_completed": false,
  "release": {
    "pr_number": null,
    "ready": false,
    "merged": false
  },
  "updated_at": "2026-06-04T00:00:00Z"
}
```

書き込みタイミング:

| フィールド | 書き込みタイミング | 書き込み主体 |
|-----------|------------------|------------|
| define_completed | define の Step 4 完了時 | define 実行者 |
| release.pr_number | PR 作成時 | release 実行者 |
| release.ready | PR ready 化時 | release 実行者 |
| release.merged | merge 直前の最終コミット | release 実行者 |

**release.merged の書き込みタイミング**: merge 後はブランチが消えるため書き換え不可。release.merged: true は merge 前の最終コミットで書き込む。

#### Work Item Frontmatter

各 work-items/*.md の YAML frontmatter で work item 個別の状態を管理する。

```yaml
---
id: "001"
status: pending
size: normal
risk: medium
assigned: null
dependencies: []
---
```

frontmatter fields:

| フィールド | 型 | 説明 |
|-----------|---|------|
| id | string | work item 識別子 |
| status | enum | pending / in_progress / blocked / done / withdrawn |
| size | enum | tiny / normal / risky |
| risk | enum | low / medium / high |
| assigned | string or null | 担当者（複数人並行作業時） |
| dependencies | array | 依存する work item ID のリスト |

status enum:

```text
pending       まだ着手していない
in_progress   作業中
blocked       外部依存等で待ち
done          完了
withdrawn     取り下げ
```

size enum:

```text
tiny      typo / small docs / 単一ファイル軽微修正 / 挙動リスク低
normal    通常の機能追加 / 小中規模リファクタ / docs+code 両方影響
risky     release / migration / security / state model 変更 / 複数サブシステムまたがり
```

risk enum:

```text
low       既存パターン踏襲、影響範囲が限定的
medium    一部新規、テストで担保可能
high      前例なし、または失敗時の復旧コストが高い
```

#### フェーズ導出ロジック

フェーズは state.json と work item frontmatter から導出する。state.json に current_phase は保持しない。

| 条件 | 導出フェーズ |
|-----|-----------|
| define_completed: false | define |
| define_completed: true かつ work item に done/withdrawn 以外がある | build |
| define_completed: true かつ全 work item が done/withdrawn | release 可能 |
| release.merged: true | complete（reflect 可能） |

この導出により、build → release のフェーズ遷移で「誰が変えるか」問題が発生しない。最後の work item を done にした作業者が、自動的に release 可能状態を作る。

### size と depth_level の関係

size は per-work-item、depth_level は per-cycle のグローバル設定。両者は独立だが組み合わせで実際の作業量が決まる。

| | depth_level: minimal | depth_level: standard | depth_level: comprehensive |
|---|---|---|---|
| size: tiny | 実装のみ | 実装のみ | 実装 + 短い理由記録 |
| size: normal | 実装 + テスト | 実装 + 簡易 design + テスト + review | 実装 + design + リスク分析 + テスト + review |
| size: risky | (risky は minimal 不可) | design + テスト + review + rollback note | design + リスク分析 + テストプラン + 複数 review + rollback note |

### Work Item テンプレート

```markdown
---
id: "001"
status: pending
size: normal
risk: medium
assigned: null
dependencies: []
---

# Work Item 001: Example

## Goal

何を達成するか。

## Scope

- 含むもの
- 含まないもの

## Acceptance Criteria

- [ ] 条件 1
- [ ] 条件 2

## Traceability

- Intent refs: scope:example
- Acceptance refs: AC-001, AC-002
- Verification: test command or manual check
- Release note required: no

## Size / Risk

- Size: normal
- Risk: medium
- Reason: 理由

## Dependencies

- none

## Implementation Notes

必要な場合のみ記録。
```

### Journal

journal.md は追記型の軽量記録。v2 の history より簡素にする。

目的:

- 作業証跡を残す
- 全 step の詳細記録を義務化しない
- 次 cycle の define で参照可能にする

形式:

```markdown
# Journal: v3.0.0

## 2026-06-04

- define completed: intent and 3 work items created
- build started: 001-example (size: normal)

## 2026-06-05

- build completed: 001-example
- build started: 002-normalize-state (size: tiny)
- build completed: 002-normalize-state
- release ready: PR #123
```

### 成果物一覧（フェーズ別）

| フェーズ | 必須成果物 | 任意成果物 |
|---------|----------|----------|
| define | intent.md, work-items/*.md, state.json | stories.md, decisions.md |
| build (tiny) | journal 追記 | - |
| build (normal) | designs/*.md, journal 追記 | reviews/*.md |
| build (risky) | designs/*.md, reviews/*.md, journal 追記 | risk-analysis.md, rollback-note.md |
| release | release.md, journal 追記 | changelog 追記 |
| reflect | reflect.md | Issue 作成 |

---

## Core / Extension 境界

### Core に残すもの

- `.aidlc/config.toml`（プロジェクト設定）
- `.aidlc/state.json`（状態管理）
- cycle / work item 管理
- define / build / release / status / doctor
- git branch / commit / PR の最低限の操作
- review の基本ルーティング（aidlc-review skill 呼び出し）
- journal への軽量記録
- state.json schema validation（doctor 経由）
- Express モード（define + build + release チェーン）

### Extension に分けるもの

| Extension | v2 での位置 | v3 での扱い |
|-----------|------------|------------|
| GitHub ProjectsV2 | gh-project-* scripts (~10本) | 廃止。core の責務ではない（ProjectsV2 は GraphQL / field option / view / workflow が絡み、プロジェクト管理ツールの責務） |
| GitHub Milestone 自動管理 | milestone-ops.sh | aidlc-milestone extension（opt-in） |
| GitHub Release 自動作成 | operations-release.sh の一部 | config.toml の version_tag で opt-in |
| Retrospective mirror | retrospective-mirror.sh | aidlc-retrospective extension 内 |
| Upstream feedback | feedback skill | 廃止。starter kit 固有の dogfooding 機能 |
| Kiro agent install | install-kiro-agent skill | 別リポジトリに分離 |
| v1/v2 migration | migrate-* scripts | aidlc-migrate skill（v3 リリース時に同梱） |
| Advanced squash CI checks | squash internal CI | config.toml opt-in |

---

## v3 アーキテクチャ

### スキル構成: 17 → 5

```text
skills/
  aidlc/                       メインスキル（唯一のエントリーポイント）
    SKILL.md                   ルーティング + 共通ルール（~200行）
    steps/
      define.md                1 ファイル完結（~200行）
      build.md                 1 ファイル完結（~250行）
      release.md               1 ファイル完結（~150行）
      recovery.md              明示状態ベースの復帰仕様（~50行）
      rules.md                 コアルール集約（~80行）
    scripts/                   必須スクリプトのみ（~30本）
    templates/                 成果物テンプレート
    config/
      defaults.toml            デフォルト設定（~50行）

  aidlc-review/                統合レビュースキル（10→1）
    SKILL.md                   パラメータで観点切替
    perspectives/              観点別テンプレート
      intent.md
      stories.md
      units.md
      plan.md
      design.md
      code.md
      integration.md
      deploy.md
      security.md
      premerge.md

  aidlc-setup/                 初期設定（維持）
  aidlc-migrate/               v2→v3 マイグレーション
  aidlc-retrospective/         振り返り（維持、ただし軽量化）
```

### ステップ構成: 35 ファイル 6,436 行 → 5 ファイル ~730 行

**最大の変更点**: フェーズごとにステップを個別ファイルに分割するのをやめ、1 フェーズ = 1 ファイルに統合する。

理由:
- AI は 1 ファイルを全量読み込む方が、複数ファイルを on_demand で読む（現行）より正確に動作する
- index.md の「読み込み契約」「チェックポイント表」「分岐ロジック」が不要になる
- ファイル分割は人間開発者の「関心の分離」パターン。AI エージェントにはオーバーヘッド

各ファイルの想定行数:

| ファイル | 行数 | 含む内容 |
|---------|------|---------|
| define.md | ~200 | intent 定義、work item 分割、size/risk 判定、承認ゲート、state 初期化 |
| build.md | ~250 | work item 選定、size 別分岐 (tiny/normal/risky)、design、実装、テスト、Self-Healing Loop、review ルーティング、Unit 依存解決、depth_level 分岐 |
| release.md | ~150 | 全 work item 完了確認、PR 本文作成、release review、merge、post-merge cleanup、tag (opt-in) |
| recovery.md | ~50 | state.json ベースの復帰ルール、フォールバック推論（~10行） |
| rules.md | ~80 | コアルール（bash-tool-safety、commit 規約、config 読み取り規約等） |

### 復帰仕様: 819 行 → ~50 行

**現行（推論ベース）**:
```text
13 のチェックポイント × 4-5 の入力アーティファクト判定
各チェックポイントに priority_order, undecidable_return, fallback chain
ArtifactsState の fileExistenceMap + progressMarks + progressFlags を組み合わせて推論
```

**v3（分散状態 + フェーズ導出）**:
```markdown
# Recovery Rules

フェーズ導出ロジック（state.json + work item frontmatter から導出）:

  define_completed: false                              → define
  define_completed: true かつ未完了 work item あり       → build
  define_completed: true かつ全 work item done/withdrawn → release 可能
  release.merged: true                                 → complete（reflect 可能）

復帰時はフェーズを導出し、フェーズ内の進捗は成果物の存在で判定する。
state.json が存在しない場合は define の Step 1 から開始する。
state.json が壊れている場合は doctor を実行するよう案内する。

フォールバック推論（state.json 破損時）:
  - intent.md が存在し work-items/ が空 → define（work item 分割から）
  - work-items/ が存在し未完了 item あり → build
  - work-items/ が存在し全 item done/withdrawn → release
  - 上記いずれにも該当しない → define（最初から）
```

推論の複雑さを「フェーズ導出 + frontmatter」に移す。state.json への書き込みは define 完了時と release 時のみ（single-actor moment）。work item の状態更新は各 work-items/*.md の frontmatter を直接編集する。state.json 書き込みはスクリプト（state-write.sh）経由で atomic 性を担保する。

### スクリプト構成: 138 本 30,303 行 → ~40 本 ~12,000 行

**残すもの（AI が苦手 or atomic 性が必要）**:

| カテゴリ | 本数 | 理由 |
|---------|------|------|
| lib/ コア (bootstrap, validate, toml-reader, version) | 5 | 全スクリプトの基盤 |
| state-read.sh / state-write.sh / state-validate.sh | 3 | state.json の atomic 操作 + schema validation |
| work-item-next.sh | 1 | 依存グラフ解決 + 次 work item 選定 |
| operations-release.sh | 1 | PR/merge/tag の atomic 操作チェーン |
| write-history.sh (→ write-journal.sh) | 1 | journal ファイルの structured 書き込み |
| read-config.sh / write-config.sh | 2 | TOML パース（AI は TOML 操作が不正確になりうる） |
| squash-unit.sh | 1 | git rebase の複雑な操作 |
| pr-ops.sh / issue-ops.sh | 2 | GitHub API wrapper |
| retrospective-* (統合後) | 2 | KPT 生成 + Issue 化 |
| check-* (CI 用) | 5 | CI gate 判定 |
| migrate-* | 3 | v2→v3 マイグレーション |
| doctor.sh | 1 | 診断ロジック集約 |
| bin/ コア | ~12 | CI/CD、品質チェック |

**廃止するもの**:

| カテゴリ | 本数 | 理由 |
|---------|------|------|
| verify-*-recovery.sh | 3 | 推論ベース復帰が不要に |
| setup-branch.sh | 1 | AI inline で git checkout -b 可能 |
| validate-git.sh | 1 | AI inline で git status 確認可能 |
| init-cycle-dir.sh | 1 | AI inline で mkdir -p 可能 |
| env-info.sh | 1 | AI inline で uname 等確認可能 |
| suggest-version.sh | 1 | AI inline で semver 計算可能 |
| run-markdownlint.sh | 1 | AI inline で npx markdownlint 可能 |
| main-repo-health-check.sh | 1 | AI inline で各種チェック可能 |
| gh-project-* | ~10 | GitHub Projects 連携は廃止 |
| sync-reviewing-common.sh | 1 | レビュースキル統合で不要 |
| check-backlog-mode.sh + resolve-backlog-mode.sh | 2 | AI inline で判定可能 |
| retrospective 5本→2本統合 | -3 | generate/verify/validate/mirror/resend → generate + publish |
| 各種 aidlc-*-info.sh | 3 | AI inline で情報取得可能 |
| milestone-ops.sh | 1 | extension 化 |
| テストの一部 | ~20 | 廃止スクリプトのテスト |

### 設定構成: 34 キー → 8 キー

**v3 defaults.toml**:

```toml
[rules]
automation = "semi_auto"     # manual | semi_auto | full_auto
depth_level = "standard"     # minimal | standard | comprehensive

[rules.git]
merge_method = "squash"      # merge | squash | rebase
default_branch = "main"

[rules.reviewing]
enabled = true
external_reviewer = ""       # "codex" | "" (empty = self-review only)

[rules.documentation]
language = "ja"              # ja | en

[rules.milestone]
enabled = false

[rules.release]
version_tag = false            # true の場合、merge 後に git tag を作成
changelog = false              # true の場合、merge 後に changelog を追記
early_pr = false               # true の場合、define 完了時に Draft PR を作成（デフォルトは release で作成）

[rules.retrospective]
enabled = true                 # core config（extension ではなく基本設定）
```

残り 26 キーの扱い:
- 7 キーは動作に影響しない情報フィールド（project_name 等） → intent.md に記述
- 8 キーは AI が文脈から自動判断可能（branch_mode, pr_labels 等） → 廃止、AI 判断に委ねる
- 6 キーは使用頻度が極めて低い → 廃止（必要なユーザーは rules.md で自然言語指示）
- 5 キーは他キーに統合 → depth_level や automation に吸収

### レビュースキル: 10 → 1

**aidlc-review SKILL.md の設計**:

```markdown
---
name: aidlc-review
description: AI-DLC unified review skill
---

# AI-DLC Review

## 引数

perspective: intent | stories | units | plan | design | code | integration | deploy | security | premerge

## 実行

1. perspectives/{perspective}.md を読み込む
2. reviewing-common-base の共通フローを実行
3. perspective 固有の観点でレビュー

perspective が省略された場合は、state.json の current_phase と current_work_item から自動判定する。
```

**v2 → v3 review 対応**:

| v2 skill | v3 perspective | 実行条件 |
|----------|---------------|---------|
| reviewing-inception-intent | intent | define 完了時 |
| reviewing-inception-stories | stories | define 完了時（depth_level: comprehensive） |
| reviewing-inception-units | units | define 完了時 |
| reviewing-construction-plan | plan | build 開始時（normal/risky） |
| reviewing-construction-design | design | design 完了時（normal/risky） |
| reviewing-construction-code | code | 実装完了時（normal/risky） |
| reviewing-construction-integration | integration | 複数 work item 完了時 |
| reviewing-operations-deploy | deploy | release 時（risky のみ） |
| reviewing-operations-premerge | premerge | merge 前 |

**size × review マトリクス**:

| size | 実行する review |
|------|----------------|
| tiny | 原則不要。必要時のみ self review |
| normal | code review |
| risky | code + deploy/security review |

sync-reviewing-common.sh が不要に。reviewing-common-base.md は aidlc-review 内に 1 箇所のみ。

---

## フェーズ詳細設計

### define (Inception)

目的: 作るもの、作らないもの、完了条件、作業単位を決める。

```text
Step 1: 環境チェック
  - config.toml 存在確認
  - git status 確認（clean working tree）
  - 前 cycle の journal.md / reflect.md があれば読み込み

Step 2: Intent 定義
  - 目的を 1 文で確認（AI 提案 → 人間承認）
  - scope in / out を確認
  - acceptance criteria を作成
  - intent.md を作成
  ★ 承認ゲート: intent の内容を人間が確認・承認

Step 3: Work Item 分割
  - intent を work item に分割（AI 提案 → 人間承認）
  - 各 work item に size / risk を付与
  - 依存関係を整理
  - work-items/*.md を作成
  ★ 承認ゲート: work item 分割を人間が確認・承認

Step 4: 初期化
  - state.json を初期化
  - cycle ディレクトリ作成
  - journal.md に define 完了を追記
  - git branch 作成 + 初回 commit
  - Draft PR 作成（config.toml で early_pr: true の場合のみ。デフォルトは release フェーズで PR を作成）

state.json 更新:
  define_completed: false → 完了後 true
  （フェーズは define_completed + work item 状態から自動導出）
```

v2 から削るもの:
- milestone 作成（extension 化）
- GitHub Projects 登録（廃止）
- heavy duplicate check（AI 判断に委ねる）
- PRFAQ 強制（任意成果物に）
- decisions 強制（任意成果物に）

### build (Construction)

目的: 次の work item を安全に終わらせる。

```text
Step 1: Work Item 選定
  - work-items/*.md の frontmatter から次の work item を選ぶ（work-item-next.sh）
  - 依存関係を確認（blocked なら次の候補を提示）
  - 選定した work item の size / risk を確認
  - work item frontmatter 更新: status: in_progress

Step 2: 計画 + 設計（normal / risky のみ）
  - tiny: スキップ
  - normal: 簡易 design を designs/*.md に作成
  - risky: design + risk analysis + test plan
  - depth_level: comprehensive の場合はシーケンス図追加
  ★ 承認ゲート: design を人間が確認・承認（normal/risky）

Step 3: 実装
  - acceptance criteria に沿って実装
  - Self-Healing Loop: テスト → 失敗 → 自動修正 → リトライ
  - commit（work item 単位）

Step 4: 検証
  - テスト / lint / build を実行
  - acceptance criteria をチェック

Step 5: レビュー（normal / risky のみ）
  - tiny: スキップ
  - normal: aidlc-review perspective=code を実行
  - risky: aidlc-review perspective=code + deploy/security
  - レビュー上限: 最大 5 ラウンド
  - Defer 戦略: OUT_OF_SCOPE / TECHNICAL_BLOCKER → 自動 Issue 化

Step 6: 完了
  - work item frontmatter 更新: status: done
  - journal.md に完了記録を追記
  - squash commit（設定に応じて）
  - 次の work item がある場合は Step 1 に戻る
  - 全 work item が done/withdrawn の場合は release を案内
```

**work item ループ**: build は 1 回の実行で 1 work item を完了する。全 work item の完了まで `/aidlc build` を繰り返す。全 work item の frontmatter status が done / withdrawn になったら release フェーズへの遷移を提案する（フェーズ導出ロジックにより自動判定）。

**express の実行単位**: express は単一 work item サイクル専用。define で作成される work item が 1 つ（tiny または normal）の場合のみ、define + build + release を連続実行する。define の結果 work item が複数になった場合、express は define 完了後に終了し、build / release を個別に実行するよう案内する。

**依存解決**: work-item-next.sh が依存グラフを走査し、dependencies がすべて done の work item から次の候補を選ぶ。候補が複数ある場合は AI が優先度を提案し、人間が選択する。

### release (Operations)

目的: main に安全に取り込む。

```text
Step 1: リリース準備
  - work item frontmatter で全 work item 完了を確認（blocked/withdrawn は理由付き許容）
  - git status 確認
  - test / CI 状態確認

Step 2: PR 整備
  - PR が未作成の場合は作成する（デフォルトパス。early_pr: true で define 時に作成済みの場合は更新のみ）
  - PR 本文を作成または更新
  - release.md を作成
  - release review を実行（aidlc-review perspective=premerge）
  ★ 承認ゲート: PR ready を人間が確認

Step 3: Merge
  - PR を ready 状態にする
  - CI パス確認
  ★ 承認ゲート: merge を人間が承認（automation: manual/semi_auto の場合）
  - merge 実行

Step 3.5: Pre-merge 最終コミット
  - state.json 更新: release.merged: true（merge 後はブランチが消えるため、merge 前の最終コミットで書き込む）

Step 4: Post-merge
  - ローカル branch 更新（main に switch、feature branch 削除）
  - tag 作成（config.toml で version_tag: true の場合）
  - changelog 追記（config.toml で changelog: true の場合）
  - journal.md に release 完了を追記
```

core から外すもの:
- deploy checklist 強制（project type hook として extension 化）
- monitoring strategy 強制
- distribution feedback 強制
- GitHub Milestone close 強制
- GitHub Release 強制

### reflect (Retrospective)

目的: 改善を次の行動に変える。

```text
Step 1: 振り返り材料の収集
  - journal.md を読む
  - release.md の結果を読む
  - work item の withdrawn / blocked 理由を読む

Step 2: Problem / Try 抽出
  - AI が KPT (Keep / Problem / Try) を提案
  - 人間が確認・編集

Step 3: 行動化
  - Try を Issue 化するか確認
  - 必要な Issue だけ作成
  - reflect.md に記録

Step 4: 完了
  - journal.md に reflect 完了を追記
```

core から外すもの:
- upstream mirror（starter kit 固有）
- cap 管理
- dialog token
- aggregate retrospective issue

### status

目的: ユーザーと AI が「今どこか」を即座に把握する。

state.json と work item frontmatter を読み取り、フェーズを導出して表示する。読み取り専用。

出力例:

```text
Cycle: v3.0.0
Phase: build (derived: define_completed=true, 2/4 items remaining)
Current work item: 002-normalize-state (size: normal, risk: medium, status: in_progress)
Completed: 2/4 (001-example done, 003-cleanup withdrawn)
Blocked: none
Remaining: 002-normalize-state, 004-review-merge
Suggested command: /aidlc build
```

state.json が存在しない場合:

```text
No active cycle found.
Suggested command: /aidlc define
```

### doctor

目的: preflight と recovery を通常フローから分離する。

チェック項目:

```text
[config]     .aidlc/config.toml 存在 + 必須キー確認
[state]      .aidlc/state.json 存在 + schema validation（define_completed, release のみ）
[cycle]      current_cycle のディレクトリパス存在確認
[work-items] work item frontmatter の整合性（status / size / risk / dependencies の妥当性）
[phase]      フェーズ導出結果の表示（state.json + frontmatter → 導出フェーズ）
[git]        git status (clean/dirty), default branch, remote
[gh]         gh auth status
[pr]         active PR の存在・状態確認
[scripts]    必須スクリプトの存在確認
[trace]      trace chain の整合性（intent → work items → designs の参照チェック）
```

doctor は修正を自動実行しない。診断と推奨だけ出す。

出力例:

```text
[config]      OK
[state]       OK (define_completed: true, release.merged: false)
[cycle]       OK
[work-items]  WARN: 002-normalize-state has status: in_progress but no recent commits
[phase]       build (derived: define_completed=true, 2 items remaining)
[git]         OK (branch: cycle/v3.0.0, clean)
[gh]          OK (authenticated as user)
[pr]          OK (PR #123, draft)
[scripts]     OK
[trace]       WARN: work_item 003 has no design file (size: normal, expected)

Recommendations:
  1. Continue: /aidlc build (work item 002 is in_progress)
  2. Create designs/003-*.md before completing work item 003
```

---

## v2 → v3 移行

### 移行方針

- v2 の過去 cycle は archive として残す
- v3 は新 cycle から始めることを推奨
- 完全自動変換は目指さない

### 移行モード

```text
new-cycle-only     v2 過去資産は触らず v3 cycle を開始（推奨）
best-effort        intent / unit / history を v3 形式に変換
archive-only       v2 cycle を archive 扱いとして index だけ作る
```

推奨は `new-cycle-only`。

### データ変換

| v2 | v3 | 変換方法 |
|----|----|---------|
| requirements/intent.md or inception/intent.md | intent.md | パスコピー |
| story-artifacts/units/*.md | work-items/*.md | テンプレート差分を埋める |
| progress.md | state.json | パース + schema 生成 |
| history/*.md | journal.md | 要約統合 |
| operations/release_notes.md | release.md | パスコピー |
| config.toml (34 keys) | config.toml (8 keys) | キーマッピング + 不要キー警告 |

### 移行コマンド

```text
/aidlc-migrate
```

aidlc-migrate スキルが以下を実行:

1. v2 config.toml を読み、v3 config.toml を生成
2. 移行モード選択を人間に確認
3. 選択に応じてデータ変換
4. 変換結果を人間に確認
5. state.json を初期化

---

## 実装計画

### Phase 1: RFC / 設計固定（1 サイクル）

成果物:

- `docs/v3/rfc.md`
- `docs/v3/workflow.md`
- `docs/v3/data-model.md`
- `docs/v3/migration.md`

完了条件:

- core / extension 境界が明記されている
- v3 directory layout が決まっている
- state.json schema が決まっている
- work item template が決まっている
- v2 migration 方針が決まっている

### Phase 2: aidlc-v3 skeleton（1 サイクル）

成果物:

- `skills/aidlc-v3/SKILL.md`
- `skills/aidlc-v3/steps/define.md`
- `skills/aidlc-v3/steps/status.md`
- state scripts (state-read.sh, state-write.sh, state-validate.sh)
- templates (intent.md, work-item.md, journal.md)

完了条件:

- `/aidlc-v3 define` 相当の手順が読める
- state.json の作成仕様がある
- `/aidlc-v3 status` 相当の出力仕様がある
- v2 `skills/aidlc` に影響しない

### Phase 3: define + build tiny flow（1 サイクル）

成果物:

- define 手順実装
- build 手順実装（tiny のみ）
- work-item-next.sh（依存解決）
- cycle ディレクトリ作成ロジック

完了条件:

- 新 cycle が作成できる
- intent.md / work-items/*.md が作成できる
- state.json が初期化される
- tiny work item が design なしで完了できる
- journal に完了記録が追記される

### Phase 4: build normal / risky 分岐（1 サイクル）

成果物:

- build flow に size / risk 分岐追加
- design template
- review routing（aidlc-review skill 連携）
- test plan handling

完了条件:

- tiny は軽く終わる
- normal は簡易 design + review を通る
- risky は risk analysis + 複数 review を通る
- depth_level 分岐が動作する

### Phase 5: release（1 サイクル）

成果物:

- `steps/release.md`
- release.md template
- PR ready / merge / cleanup flow
- release state update

完了条件:

- 全 work item 完了を検出できる
- PR ready にできる
- merge 後 cleanup ができる
- tag / changelog は opt-in

### Phase 6: reflect + doctor（1 サイクル）

成果物:

- `steps/reflect.md`（aidlc-retrospective skill への委譲）
- reflect.md template
- doctor.sh
- status 表示ロジック

完了条件:

- Try を必要な分だけ Issue 化できる
- mirror なしで完結する
- doctor が全チェック項目を診断できる
- status が正しい現在地を表示する

### Phase 7: dogfooding + 本流化（1-2 サイクル）

この repository の v3.x cycle を `skills/aidlc-v3` で回す。

測定項目:

- define 開始時に AI が読むファイル数（v2: 5+ files → v3: 1 file 目標）
- build 1 work item あたりの成果物数（v2: ~8 files → v3: 2-4 files 目標）
- ユーザー確認回数（承認ゲートのみに限定されているか）
- tiny work item 完了までの時間
- recovery / status の分かりやすさ
- v2 より削れた step / script / template 数

本流化の条件:

- dogfooding で 1 cycle 完了
- release まで完走
- v2 より読み込み量と成果物数が明確に減っている
- migration 方針が合意済み

本流化の作業:

```text
skills/aidlc-v3 → skills/aidlc
旧 skills/aidlc → v2-maintenance branch
README を v3 用に刷新
marketplace version を v3.0.0 に更新
```

---

## 最初の Unit 定義

### Unit 001: v3 RFC と data model 固定

目的: v3 フルリニューアルの設計判断を文書化し、prototype の土台を作る。

スコープ:

- `docs/v3/rfc.md`
- `docs/v3/workflow.md`
- `docs/v3/data-model.md`
- `docs/v3/migration.md`
- state.json schema 初版
- work item template 初版

非スコープ:

- 既存 `skills/aidlc` の変更
- v2 migration 実装
- release / reflect 実装
- reviewing skill 統合実装

受け入れ基準:

- v3 core / extension 境界が明記されている
- define / build / release / reflect / status / doctor の責務が明記されている
- state.json schema が例示されている
- work item Markdown template が例示されている
- v2 から v3 への移行方針が明記されている

### Unit 002: aidlc-v3 skeleton

目的: v3 を既存 v2 と独立して試せる skeleton を作る。

スコープ:

- `skills/aidlc-v3/SKILL.md`
- `steps/define.md`
- `steps/status.md`
- `scripts/state-validate.sh`
- `templates/intent.md`
- `templates/work-item.md`
- `templates/journal.md`

受け入れ基準:

- `/aidlc-v3 define` 相当の手順が読める
- state.json の作成仕様がある
- `/aidlc-v3 status` 相当の出力仕様がある
- v2 `skills/aidlc` に影響しない

### Unit 003: define flow 実装

目的: 新 cycle の intent / work item / state を作れるようにする。

スコープ:

- define 手順実装
- cycle ディレクトリ作成
- work item 分割
- size / risk 初期判定
- journal 初期化
- state.json 初期化

受け入れ基準:

- 新 cycle が作成できる
- intent.md が作成できる
- work-items/*.md が作成できる
- state.json が作成できる
- status が次アクションを表示できる

### Unit 004: build tiny flow 実装

目的: 最小作業単位を軽く完了できることを確認する。

スコープ:

- next work item 選定（work-item-next.sh）
- tiny 判定
- 実装 + テスト + journal
- state.json status update

受け入れ基準:

- tiny work item が design なしで完了できる
- state.json の status が done になる
- journal に完了記録が追記される
- status が次の work item を正しく表示する

---

## リスクと対策

### 高リスク: モデル差し替え時の workflow correctness

防御ロジックの記述量を大幅に削減しているため、軽量モデルや将来のモデルで精度が落ちる可能性。

**対策**: rules.md ~80 行に最低限の safety rules を集約し、モデル非依存で workflow correctness を維持する。Phase 3 の define + build tiny で実動作を検証する。rules.md の記述は「モデル最適化ガイダンス」ではなく「最低限の安全ルール」として書く。

### 中リスク: 状態書き込み漏れ

AI が state.json や work item frontmatter への状態書き込みを忘れる可能性。推論ベースは「書き込まなくても復帰できる」のが利点だった。

**対策**:
- state.json の書き込みは define 完了時と release 時のみ（頻度が低く忘れにくい）
- work item frontmatter の更新は各ステップの冒頭で明記
- state-write.sh でバリデーション付き書き込み（不正状態遷移の検出）
- recovery.md にファイル存在からの簡易フォールバック（~10 行の推論ルール）を残す

### 中リスク: state.json 破損で復帰不能

JSON のパースエラーやフィールド欠損で状態が読めなくなる可能性。

**対策**:
- state.json はフィールドが 4 つだけ（schema_version, current_cycle, define_completed, release）なので破損リスクが低い
- work item の状態は各ファイルの frontmatter に分散しているため、state.json 破損時も work item 情報は失われない
- doctor で schema validation
- journal.md と work-items/*.md から best-effort repair 可能にする
- state.json 更新は state-write.sh 経由のみ（直接編集禁止）
- git に commit されているので git restore で最終 commit 時点に復元可能

### 中リスク: consumer プロジェクトの移行コスト

v2 の config.toml / progress / history のフォーマットが変わる。

**対策**: migrate スキルで自動変換。変換できないケースはユーザーに確認。v2 → v3 は片方向移行（rollback 不可）を明示。推奨移行モードは new-cycle-only（過去資産は触らない）。

### 低リスク: tiny/normal/risky 判定の曖昧さ

size の判定基準が曖昧で、AI と人間で認識がずれる可能性。

**対策**:
- work item template に判定基準を明記
- risky への昇格条件を定義（security 影響 / migration / state model 変更 → 自動的に risky）
- 判定不能時は normal に倒す（安全側）
- AI が size を提案し、人間が承認するフロー（Principle #2: Human judgment remains explicit）

### 低リスク: review 統合で品質低下

10 skill → 1 skill の統合で、観点の抜け漏れが発生する可能性。

**対策**:
- focus パラメータで観点を明示的に切り替える
- risky では複数 focus を実行する
- v2 reviewing prompt の良い観点は v3 perspectives/*.md に全数移植する
- size × review マトリクスで実行条件を明確化

### 低リスク: スクリプト廃止の依存見落とし

ステップから直接呼ばれていないリーフスクリプトが、実は hooks や CI から呼ばれている可能性。

**対策**: Phase C でスクリプト廃止前に grep -r で全参照を確認。hooks 設定ファイル、CI ワークフロー、consumer プロジェクトの .claude/ 設定を網羅的にチェック。

---

## 判断が必要なポイント

### 1. v3 の表面コマンド名

- **案 A**: define / build / release / reflect（新名称を正式名に）
- **案 B**: inception / construction / operations / retrospective を維持し中身だけ刷新
- **案 C**: 両方サポート（新名称を主、旧名称をエイリアス）
- **推奨**: 案 C。define/build/release/reflect を主表示としつつ、旧名称もエイリアスで維持。SKILL.md のルーティングテーブルに 4 行追加するだけ

### 2. Express モードの扱い

Express は inception + construction + operations のチェーン。v3 でも維持するか。

- **案 A**: 維持（`/aidlc express` で define + build + release 連続実行）
- **案 B**: 廃止（各フェーズを個別に実行）
- **推奨**: 案 A。小規模変更の体験として有用。実装は SKILL.md のルーティングのみ

### 3. v2 サポート期間

- **案 A**: v3 リリースと同時に v2 EOL
- **案 B**: v3 リリース後、移行条件充足まで v2 メンテナンスモード（セキュリティ / クリティカル修正のみ）
- **推奨**: 案 B（条件付き）。以下の移行信頼性基準をすべて満たした時点で v2 EOL とする:
  1. マイグレーションスクリプトが最低 2 つの consumer プロジェクトでテスト済み
  2. v3 で 1 cycle のドッグフーディングが完了済み
  3. EOL 告知が README / CHANGELOG に 1 バージョン前から掲載済み

### 4. review 統合粒度

- **案 A**: aidlc-review 1 skill + perspective パラメータ
- **案 B**: requirements / change / release の 3 skills
- **案 C**: v2 reviewing-* を当面維持
- **推奨**: 案 A。perspective パラメータで切り替え、state.json から自動判定も可能

### 5. GitHub 前提の強さ

- **案 A**: Core は git のみ、GitHub は extension
- **案 B**: Core に Issue / PR までは含める
- **案 C**: v2 同様 GitHub 前提を強くする
- **推奨**: 案 B。Issue / PR は十分に汎用的。Projects / Milestone / Release だけ extension

### 6. state format

- **案 A**: JSON（state.json）
- **案 B**: TOML（state.toml）
- **案 C**: Markdown frontmatter（progress.md 改良）
- **推奨**: 案 A。JSON は schema validation が容易で、jq でのクエリも標準的

---

## 想定成果

| 指標 | v2 | v3 | 削減率 |
|------|-----|-----|--------|
| スキル数 | 17 | 5 | 71% |
| ステップ MD 行数 | 6,436 | ~730 | 89% |
| スクリプト本数 | 138 | ~40 | 71% |
| スクリプト行数 | 30,303 | ~12,000 | 60% |
| 設定キー数 | 34 | 8 | 76% |
| 復帰仕様行数 | 819 | ~50 | 94% |
| 保守対象ファイル総数 | ~280 | ~80 | 71% |

---

## v2 との非互換点（明示）

1. **ステップファイル構造**: 35 ファイル → 5 ファイル。consumer のカスタムステップは再作成が必要
2. **状態管理**: progress.md（推論ベース自由形式）→ state.json（明示的 schema）
3. **設定キー**: 34 → 8。未サポートキーは無視される（エラーにはしない）
4. **レビュースキル名**: reviewing-inception-intent 等 → aidlc-review 1 本に統合。marketplace.json 更新で再インストール必要
5. **スクリプト API**: 廃止スクリプトを直接呼んでいる consumer は壊れる。consumer がスクリプトを直接呼ぶのは非推奨パスなのでマイグレーション対象外
6. **recovery 動作**: ファイル存在推論 → state.json 明示状態。v2 の progress.md は v3 で認識されない（マイグレーション対象）
7. **コマンド名**: 旧名称（inception 等）はエイリアスとして維持するが、ヘルプ・ドキュメントは新名称（define 等）が主
8. **成果物構造**: history/*.md → journal.md（単一ファイル追記型）
9. **GitHub Projects 連携**: 廃止（core の責務ではない。プロジェクト管理ツールとして外部で運用）
10. **Milestone 自動管理**: core から extension 化（opt-in）

---

## 全体工数

```text
Phase 1 (RFC/設計固定)         ■         1 サイクル
Phase 2 (skeleton)            ■         1 サイクル
Phase 3 (define + build tiny) ■         1 サイクル
Phase 4 (build normal/risky)  ■         1 サイクル
Phase 5 (release)             ■         1 サイクル
Phase 6 (reflect + doctor)    ■         1 サイクル
Phase 7 (dogfooding + 本流化)  ■■        1-2 サイクル
                              ─────────
                              合計 7-8 サイクル
```

v2 の漸進的改善（8-11 サイクル）より少ない。v3 は結果として得られるものが根本的に異なる — 70% のコード削減と、モダンな AI モデル前提の設計。

---

## 最初の一手

**Phase 1: RFC と data model を固定する。**

この計画書の内容を `docs/v3/rfc.md` 等に分割し、state.json schema と work item template を確定させる。ここでの設計判断が Phase 2 以降の全実装の土台になる。

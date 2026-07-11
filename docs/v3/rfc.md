# AI-DLC v3 RFC: 設計判断・core/extension 境界の確定

- **ステータス**: Accepted（Unit 001 設計フェーズで 6 設計判断をユーザー承認ゲートで確定 / 2026-06-10）
- **対象サイクル**: v3.0.0-alpha.1
- **位置づけ**: v3 全体設計の正本。後続 Unit（workflow / data-model / migration）が参照する設計判断の起点
- **入力**: `docs/v3-renewal-plan.md`（計画書。7 Principles・削減定量表・core/extension 境界一覧・6 判断の推奨を内包）
- **スコープ**: 設計判断の確定・境界基準・削減目標・後続引き継ぎ。実装（skeleton / スクリプト）および workflow.md / data-model.md / migration.md の詳細記述は対象外

---

## 1. 概要 / 目的（なぜ v3 か）

AI-DLC v2 は Claude 3.5 世代のモデルを前提に、AI が誤動作しないための防御的記述を積み増す形で進化してきた。モダンモデル（Opus 4.x 等）を前提に置くと、これらの防御記述の大半は冗長であり、方法論そのものではなく「実装の複雑さ」が肥大化している。v3 は **AI-DLC の方法論的特徴を保ったまま、実装の複雑さのみを削減する再設計**である。

### 1.1 v2 の根本課題

計画書 `docs/v3-renewal-plan.md`「v2 の何が問題か（根本原因の特定）」（L7-32）が特定した 5 つの根本原因を、v3 設計の出発点とする。

| # | 根本課題 | 概要 | 計画書 |
|---|---------|------|-------|
| 1 | 防御ロジックが全体の約 60% | ステップ MD 6,436 行のうち約 3,900 行が旧モデル向けの「やってはいけない / こうしろ」型の防御的指示。例: `review-flow.md` の 74%、`03-implementation.md` の 64%、`rules-core.md` の 51%、`commit-flow.md` の 53% | L9-16 |
| 2 | 推論ベースの復帰判定が過剰に複雑 | `phase-recovery-spec.md`（819 行）は「ファイルの有無からステップを推論する」仕組み。明示的な状態マーカーを書けば大幅に簡素化できる | L18-20 |
| 3 | 10 個のレビュースキルが同一構造の複製 | `reviewing-common-base.md` を `sync-reviewing-common.sh` で 10 箇所に同期する DRY 違反。各スキルの差分は観点テンプレートのみ | L22-24 |
| 4 | リーフスクリプトの肥大化 | 138 スクリプト中、ステップから呼ばれるエントリーポイントは 15 本。安全境界が不要な単純処理までスクリプト化している | L26-28 |
| 5 | ステップファイルに 4 責務が混在 | 手順・エージェント仕様・復帰ロジック・後方互換注記が同一ファイルに同居 | L30-32 |

### 1.2 v3 のゴール

- 防御ロジックを削り、方法論ロジック（承認ゲート・レビュー上限・Defer 戦略・スコープ保護・依存解決等）は維持する。
- 推論ベースの復帰を明示状態（state.json + work item frontmatter）ベースへ置換する。
- 10 レビュースキルを 1 スキル + perspective に統合する（観点は全数維持）。
- core を「方法論を最小構成で回す責務」に絞り、それ以外を extension / 別リポジトリ / 廃止に分類する。

定量目標は §6、保全する方法論は §3、境界の分類基準は §4 に示す。

---

## 2. v3 AI-DLC Principles（7 原則）

v3 は単なる軽量タスクランナーではなく、AI-DLC の思想を維持した再設計である。以下 7 原則を core の設計原則とする。

> **参照元**: 本節 7 原則の正本は計画書 `docs/v3-renewal-plan.md`「v3 AI-DLC Principles」節（L36-66）である。RFC は本節でこれを正式に列挙確定する。各原則の英語名は計画書原文を維持する。

1. **AI is a lifecycle collaborator, not a code generator**
   AI は実装だけでなく、Intent 明確化・作業分割・設計・検証・リリース準備・振り返りに関与する。AI の役割は「コード生成」ではなく、ライフサイクル全体の協働者である。

2. **Human judgment remains explicit**
   スコープ・リスク・リリース・不可逆操作・機密情報の扱いは人間が判断する。automation は人間判断を消すものではなく、低リスク反復作業の摩擦を下げるために使う。

3. **Intent-to-release traceability is mandatory**
   各 work item は intent・scope・acceptance criteria・test・release result に追跡可能である。「なぜ作るか」から「何をリリースしたか」までが切れないことを core の品質条件にする。

4. **Work is decomposed into value-delivering units**
   作業単位は単なる技術タスクではなく、ユーザー価値または運用価値を届ける単位として定義する。内部リファクタでも、価値・リスク・検証方法を明示する。

5. **Workflow weight adapts to risk**
   tiny / normal / risky によって成果物・レビュー・検証の厚みを変える。全作業に同じ儀式を強制しない一方で、高リスク変更は明示的に重く扱う。

6. **Context is a first-class artifact**
   AI が中断・復帰・継続できるよう、state・journal・work item を明示的に管理する。会話履歴ではなく、リポジトリ内成果物を継続文脈の正本にする。

7. **Reflection feeds the next cycle**
   reflect は任意実行だが、得られた Try / lesson は次の define で参照される。振り返りは反省文ではなく、次の作業・Issue・ルール変更につながる行動として扱う。

---

## 3. 方法論の保全

> v3 は技術的な簡素化だが、AI-DLC の方法論的特徴はすべて維持する。**削減対象は「実装の複雑さ」であり、「方法論の深さ」ではない**（計画書 L70-72）。

v2 の約 60% を占める「防御ロジック」と、AI-DLC 固有の「方法論ロジック」は異なるものである。v3 で廃止するのは前者のみであり、後者は記述量を削っても**意味として維持**する。

### 3.1 保全する方法論要素

| 方法論要素 | v2 | v3 での扱い |
|-----------|----|-----------|
| 会話の逆転（AI 主導の問いかけ） | あり | 維持 |
| Unit 概念（価値提供単位への分割） | あり | 維持（work item として継続） |
| 3 フェーズ構造 | inception / construction / operations | 維持（define / develop / release に改称、§5.1） |
| Depth Level 分岐 | minimal / standard / comprehensive | 維持（size × depth_level マトリクスとして data-model.md で具体化） |
| Automation Mode | manual / semi_auto / full_auto | 維持 |
| レビュー品質ゲート | 10 スキル + review-flow.md | 1 スキル + perspective パラメータ（観点は全数維持、配送構造のみ変更、§5.4） |
| Self-Healing Loop | あり | 維持（防御的多重警告のみ削減） |
| Express モード | あり | 維持（§5.2） |
| Retrospective（KPT） | あり | reflect として維持（§5.1） |

### 3.2 廃止する防御ロジックと維持する方法論ロジックの区別

- **廃止する防御ロジック例**: dasel アンチパターン列挙 / squash 事故防止の冗長記述 / レビュー無限ループ警告の繰り返し / Self-Healing Loop の多重警告。
- **維持する方法論ロジック**: 承認ゲート、レビュー上限（最大 5 ラウンド）、Defer 戦略（OUT_OF_SCOPE / TECHNICAL_BLOCKER の自動 Issue 化）、スコープ保護、Unit 依存解決、Depth Level 分岐。

この区別が境界判断（§4）の「安全境界」軸とも接続する。

---

## 4. core / extension 境界

境界一覧（何が core で何が extension か）だけでなく、**分類の判断軸**を明文化する。これにより、将来の新機能を一貫した基準で分類できる。

### 4.1 境界原則

> **core = 「AI-DLC の方法論を最小構成で回すために不可欠な責務」**。それ以外は extension。

### 4.2 分類基準（判断軸）

ある機能を core に入れるかは以下の 5 軸で判定する。

| 軸 | core 条件 | extension 条件 |
|----|----------|---------------|
| 方法論必須性 | define → develop → release → reflect の遂行に不可欠 | 無くても 1 cycle を完走できる |
| 汎用性 | git / Issue / PR など広く前提にできる | 特定ツール / サービス固有（Projects / Milestone / Kiro 等） |
| 依存の重さ | 軽量（git CLI / gh の Issue・PR まで） | 重い（GraphQL / field option / view / workflow 等） |
| 安全境界 | atomic 性・schema validation 等の安全境界が必要 | 単純処理で AI inline 可能 |
| ドッグフーディング固有性 | consumer 全員に必要 | starter kit 自身の運用固有（upstream feedback 等） |

### 4.3 代表コンポーネント分類

分類値は次の 4 つに正規化し、各コンポーネントは**単一分類**を持つ。

- **core**: v3 本体に常に含まれる
- **extension(opt-in)**: v3 同梱だが既定 off（設定で有効化）
- **別リポジトリ**: 外部リポジトリに分離
- **廃止**: v3 では提供しない

| コンポーネント | 分類 | 根拠（適用軸） |
|--------------|------|--------------|
| config.toml / state.json / work item 管理 | core | 方法論必須・安全境界 |
| define / develop / release / reflect / status / doctor（コマンド本体） | core | 方法論必須。reflect 本体の最小責務（journal を読み reflect.md / Issue を生成）も core |
| git branch / commit / PR の最低限操作 | core | 汎用・軽量 |
| Issue 操作（defer 自動起票・PR Closes） | core | 汎用・方法論必須（DG-5） |
| aidlc-review（perspective 統合） | core | 方法論必須（品質ゲート） |
| journal 軽量記録 | core | 方法論必須（reflect への入力） |
| Express | core | 方法論（フロー）の一部（DG-2） |
| Milestone 自動管理 | extension(opt-in) | 特定機能固有（既定 off） |
| GitHub Release / version_tag 自動作成 | extension(opt-in) | 特定機能固有（既定 off） |
| v1/v2 migration（aidlc-migrate） | extension(opt-in) | 一時的・移行専用（v3 同梱） |
| Kiro agent install | 別リポジトリ | ツール固有 |
| GitHub ProjectsV2 連携 | 廃止 | 重い依存・プロジェクト管理ツールの責務 |
| Retrospective mirror / upstream feedback | 廃止 | starter kit 固有（ドッグフーディング固有性） |

### 4.4 例外ルール

- **ドッグフーディング特殊処理を本体に埋めない**（プロジェクトルール準拠）: starter kit 自身固有の処理は core 本体に分岐を埋めず、opt-in シグナル / 明示フラグ / wrapper 分離で表現する。consumer 側で何も追加しなくても自然に skip される構造を選ぶ。
- core が GitHub に依存するのは **Issue / PR まで**（DG-5）。それ以深（Projects / Milestone / Release）は extension に隔離し、core は extension 不在でも動作する。

---

## 5. 設計判断（Decision Gate Log）

6 設計判断（DG-1〜DG-6）を一から検討（計画書推奨は一入力として扱う）し、結論が分かれうる論点をユーザー承認ゲートで確定した（2026-06-10、`automation_mode=semi_auto`）。各判断の案・trade-off・結論・理由を以下に記録する。

### 5.1 DG-1: 表面コマンド名

| 項目 | 内容 |
|------|------|
| 論点 | v3 の表面コマンド名をどうするか |
| 案 A | 新名称（define / develop / release / reflect）を正式名にする |
| 案 B | 旧名称（inception / construction / operations / retrospective）を維持し中身だけ刷新 |
| 案 C | 両対応（新名称を主表示、旧名称をエイリアス） |
| trade-off | A は名前から行為が直接わかるが既存ユーザーの認知コストが発生。B は継続性が高いが新規ユーザーに意図が伝わりにくい。C は両者を満たすが、不採用動詞まで別名にすると混乱要因になる |

**結論**: **define / develop / release / reflect** を主表示・正式名とする。旧名（inception / construction / operations / retrospective）は後方互換エイリアスとして維持する。**不採用動詞（build / implement 等）はエイリアスにしない**。

**理由**: 行為を直接表現しつつ継続性を確保する。"build" は compile を連想させるため、設計・実装・テストを含む広義の開発を表す **"develop"** を採用した（計画書推奨の "build" を不採用）。不採用動詞は混乱要因になるため別名登録せず、移行用エイリアスは旧名のみに限定する。

### 5.2 DG-2: Express モード

| 項目 | 内容 |
|------|------|
| 論点 | Express モード（フェーズ連続実行）を維持するか |
| 案 A | 維持（define + develop + release を連続実行） |
| 案 B | 廃止 |
| trade-off | A は小規模変更の体験が良く実装コストも低いが、複数 work item 時の挙動を定義する必要がある。B は単純化できるが小規模変更の摩擦が増える |

**結論**: **維持**（define + develop + release の連続実行）。本 RFC が確定するのは「Express を維持する」までであり、連続実行の適用単位など詳細仕様は workflow.md（Unit 002）で確定する。

**理由**: 小規模変更の体験として有用で、実装は SKILL.md のルーティングのみで完結し低コスト。なお計画書（L803）は Express を**単一 work item サイクル**（define で生成される work item が 1 つの場合）に限定し、複数 work item 時は define 完了後に develop / release を個別実行するよう案内する方針を示している。この適用単位は承認済み設計判断（DG-2 = Express 維持）の範囲外の詳細であり、最終仕様は workflow.md（Unit 002）で確定する（RFC は計画書由来の方針を引き継ぎ事項として記録するに留める）。

### 5.3 DG-3: v2 サポート期間

| 項目 | 内容 |
|------|------|
| 論点 | v3 リリース後の v2 サポート期間 |
| 案 A | v3 リリースと同時に v2 を即 EOL |
| 案 B | 条件付き EOL（移行信頼性基準充足まで v2 をメンテナンスモード維持） |
| trade-off | A は保守対象を即座に一本化できるが consumer の移行を強制しリスクが高い。B は consumer を保護するが v2/v3 並行メンテ期間が発生する |

**結論**: **条件付き EOL**。

**理由**: consumer 保護を優先する。以下 3 条件をすべて満たした時点で v2 を EOL とする。

1. マイグレーションが最低 2 つの consumer プロジェクトでテスト済み
2. v3 で 1 cycle のドッグフーディングが完了済み
3. EOL 告知が README / CHANGELOG に 1 バージョン前から掲載済み

充足までは v2 をセキュリティ / クリティカル修正のみのメンテナンスモードで維持する。共存方針との関係は §5.7 を参照。

### 5.4 DG-4: review 統合粒度

| 項目 | 内容 |
|------|------|
| 論点 | レビュースキルの統合粒度 |
| 案 A | aidlc-review 1 skill + perspective パラメータ |
| 案 B | requirements / change / release の 3 skills |
| 案 C | v2 の reviewing-* 10 スキルを当面維持 |
| trade-off | A は重複と sync スクリプトを解消できるが perspective 設計に責務が集中。B は中間粒度だが分割基準が曖昧。C は変更不要だが DRY 違反を温存する |

**結論**: **aidlc-review 1 skill + perspective**。

**理由**: 10 スキルの重複と `sync-reviewing-common.sh` による同期を解消する。観点は `perspectives/*.md` に全数移植し、品質を維持する。perspective パラメータで切り替え、state.json から自動判定も可能とする（size × review マトリクスの詳細は workflow.md / data-model.md）。

### 5.5 DG-5: GitHub 前提の強さ

| 項目 | 内容 |
|------|------|
| 論点 | core が前提とする GitHub 連携の範囲 |
| 案 A | core は git のみ、GitHub は extension |
| 案 B | core に Issue / PR までは含める |
| 案 C | v2 同様 GitHub 前提を強くする（Projects / Milestone も core） |
| trade-off | A は依存が最軽量だが defer 戦略・PR マージなど方法論必須機能が core で完結しない。B は汎用範囲に限定しつつ方法論を満たす。C は機能が揃うが重い依存を全 consumer に強制する |

**結論**: **core に git + Issue / PR を含め、Projects / Milestone / Release は extension**。

**理由**: Issue / PR は十分に汎用的で、defer 戦略（OUT_OF_SCOPE / TECHNICAL_BLOCKER の自動 Issue 化）や PR マージに必須。一方、Projects / Milestone / Release は重い依存（GraphQL / field option / view 等）であり extension に隔離する。core は extension 不在でも動作する（§4.4）。

### 5.6 DG-6: state format

| 項目 | 内容 |
|------|------|
| 論点 | 状態管理のフォーマット |
| 案 A | 全 JSON（state.json） |
| 案 B | 全 TOML（state.toml） |
| 案 C | 全 Markdown frontmatter（progress.md 改良） |
| ハイブリッド | cycle state は JSON、work item state は Markdown frontmatter |
| trade-off | 単一フォーマットは一貫性が高いが、cycle レベル（書き込み少・schema validation したい）と work item レベル（per-item 並行編集・コンフリクト回避したい）で最適解が異なる |

**結論**: **ハイブリッド**（cycle = `state.json` / work item = Markdown frontmatter）。

**理由**: cycle state は書き込みが少なくコンフリクトしにくいため、JSON で schema validation + jq クエリを行う。work item state は per-item で並行編集が起きるため、分散した Markdown frontmatter でコンフリクトを回避する。フェーズ導出ロジックの正本は data-model.md（Unit 003）に置き、`current_phase` は状態として持たず state.json + frontmatter から導出する。

### 5.7 v2 共存方針（DG-3 と相互参照）

DG-3（条件付き EOL）の結論と、v2 を変更しない前提・consumer runtime 非影響を相互参照させ、EOL 方針と互換保証範囲の関係を明示する。

- **v2 を凍結する（クリーンカット）**: 条件付き EOL 期間中、v2 `skills/aidlc` には**通常改善・v3 互換対応を行わない**（runtime 互換は維持せず、移行は migration（Unit 004）で担保する）。ただし DG-3 のメンテナンスモードに基づく**セキュリティ / クリティカル修正は例外**として最小変更を許容する（§5.3 と整合）。
- **consumer runtime 非影響**: v3 を導入するまで、consumer の v2 はそのまま動作する（v3 リリースが v2 利用者の runtime を壊さない）。
- **コマンド名衝突の扱い（DG-1 と接続）**: v3 は別スキル系統（`aidlc-v3` → 本流化時に `aidlc` を置換）で構築するため、移行期間中は v2 / v3 が別インストールで共存しうる。本流化時に旧名をエイリアス化して衝突を回避する。
- **片方向移行**: 移行は片方向（rollback 不可）であり、v2 runtime 互換は維持しない。詳細は migration.md（Unit 004）。

---

## 6. 削減目標

v2 → v3 の削減目標を、**測定定義に基づく v2 ベースライン再計測値**を正本として示す。計画書 `docs/v3-renewal-plan.md` の概算値（L1326-1334）は方向性の提示であり、本 §6 ではカウント単位を定義したうえで再計測した値を用いる。v3 列は概算目標（`~`）であり、実装フェーズで再計測して確定する。

### 6.1 測定定義（カウント単位）

| 指標 | カウント単位 |
|------|------------|
| スキル数 | `skills/` 配下のスキルディレクトリ数（SKILL.md を持つもの）。extension(opt-in) / 別リポジトリ分は v3 列（core スキル数）に含めない |
| ステップ MD 行数 | `skills/aidlc/steps/**/*.md` の合計行数 |
| スクリプト本数 | `skills/aidlc/scripts/**/*.sh` + `bin/**/*.sh` の数。廃止分は v3 列から除外 |
| スクリプト行数 | 同上スクリプト群の合計行数。extension(opt-in) / 別リポジトリ分は v3 core 目標に含めない |
| 設定キー数 | `config/defaults.toml` の `key = value` 形式キー数（情報フィールドは intent.md へ移すため除外） |
| 復帰仕様行数 | v2 = `phase-recovery-spec.md` + `session-continuity.md` + `compaction.md` の合計行数。v3 = 明示状態管理ベースの recovery 仕様（後続 Unit で確定する recovery 相当 + data-model.md のフェーズ導出 / 破損時方針記述）の合計 |
| 保守対象ファイル総数 | v3 core として保守するファイル数（core スキルの SKILL.md / steps / scripts / templates / config + core 用 `bin/` + `docs/v3/`）。extension(opt-in) / 別リポジトリ / 廃止分は含めない |

### 6.2 削減目標表（再計測ベースライン）

| 指標 | v2 ベースライン（再計測） | v3 目標（概算） | 削減数 | 削減率 | 対象外 / 注 |
|------|----------------------|-------------|-------|-------|-----------|
| スキル数 | 17 | ~5 | ~12 | ~71% | extension 分離分は別管理（core スキル数で数える） |
| ステップ MD 行数 | 6,436 | ~730 | ~5,706 | ~89% | 防御ロジック削減が主因 |
| スクリプト本数 | 97 | ~40 | ~57 | ~59% | 安全境界が必要な分は残す |
| スクリプト行数 | 27,600 | ~12,000 | ~15,600 | ~57% | extension / 別リポジトリ分は core 目標外 |
| 設定キー数 | 34 | ~8 | ~26 | ~76% | 情報フィールドは intent.md へ。終端値は data-model.md で確定 |
| 復帰仕様行数 | 1,019 | ~50 | ~969 | ~95% | 推論 → 明示状態。3 ファイル合算 |
| 保守対象ファイル総数（参考） | 231 | ~80 | ~151 | ~65% | core 限定は実装時に確定。本値は `skills/` 全体の参考値 |

### 6.3 計画書概算値との差分（トレーサビリティ）

再計測値と計画書概算値（L1326-1334）の差を明示する。差は「カウント単位の違い」に起因し、設計判断の結論には影響しない。

| 指標 | 計画書概算（v2） | 再計測（v2） | 差分 | 主因 |
|------|---------------|-----------|------|------|
| スキル数 | 17 | 17 | ±0 | 一致 |
| ステップ MD 行数 | 6,436 | 6,436 | ±0 | 一致 |
| スクリプト本数 | 138 | 97 | −41 | 計画値は `scripts/lib/` や他スキル分も含む広い集計。測定定義は `skills/aidlc/scripts/**` + `bin/**` のみ |
| スクリプト行数 | 30,303 | 27,600 | −2,703 | 同上の集計範囲差 |
| 設定キー数 | 34 | 34 | ±0 | 一致 |
| 復帰仕様行数 | 819 | 1,019 | +200 | 計画値は `phase-recovery-spec.md` 単体。測定定義は 3 ファイル合算 |
| 保守対象ファイル総数 | ~280 | 231 | −49 | 参考値（`skills/` 全体の実測） |

### 6.4 数値ポイントの確定状況

- **設定キー終端値（8 か 12 か）**: 計画書内で終端値が揺れていた（想定成果表・migration 表は 8、設定構成節は 12）。本 RFC は方向性として削減率 ~76%（v3 ~8）を採用し、**v3 設定キーの終端集合は `data-model.md` §11（config.toml schema）で 8 キーに確定済み**である（v3.0.0-beta.3 work item 001。キー名 / 型 / 既定値 / 用途の正本は同節）。
- **v3 各指標の確定値**: v3 列の `~` は概算目標。実装フェーズで再計測して確定する（RFC は方向性と目標規模の提示が主目的）。

---

## 7. 後続フェーズへの引き継ぎ

本 RFC は Phase 2 以降（workflow / data-model / migration）の設計入力である。各決定が後続成果物に与える制約を明示する（粒度: 影響領域 + 制約要旨。具体ファイル確定は後続 Unit 着手時）。

| 決定 | 影響する後続成果物 | 参照すべき制約（要旨） |
|------|------------------|---------------------|
| DG-1 コマンド名 | workflow.md（Unit 002） | 主表示 define / develop / release / reflect、旧名のみエイリアス、build / implement は別名にしない。SKILL.md ルーティング設計に反映 |
| DG-2 Express | workflow.md（Unit 002） | express = define + develop + release チェーン。SKILL.md ルーティングに含める。連続実行の適用単位（計画書 L803 は単一 work item 限定を示唆）は workflow.md で確定 |
| DG-3 条件付き EOL | migration.md（Unit 004） | EOL 3 条件・移行期間中 v2 非変更・runtime 非影響・片方向移行 |
| DG-4 review 統合 | workflow.md（Unit 002）+ aidlc-review 設計 | 各フェーズの review 呼び出しは perspective 指定。size × review マトリクス |
| DG-5 GitHub 前提 | workflow.md / data-model.md | core は Issue / PR まで。Projects / Milestone / Release は extension として参照しない |
| DG-6 state format | data-model.md（Unit 003） | cycle = state.json（JSON schema）、work item = Markdown frontmatter。フェーズ導出ロジックの正本は data-model.md |
| 境界基準（§4） | 全後続成果物 | 新機能の core / extension 分類は §4.2 の判断軸で行う |
| 削減目標（§6） | 実装フェーズ | v3 各指標は測定定義に基づき再計測して確定。設定キー終端値は data-model.md で確定 |

### 7.1 完了条件への対応（unit-001-plan.md チェックリスト）

| 完了条件 | RFC での対応箇所 |
|---------|----------------|
| 7 principles + 参照元 | §2 |
| core / extension 境界 + 分類基準 | §4 |
| 削減目標（baseline / 目標 / 削減数・率 / 対象外） | §6 |
| 6 設計判断の trade-off + 結論 | §5.1〜5.6 |
| Decision Gate Log（分岐論点・承認結果・採用判断） | §5 |
| v2 共存方針 + EOL 相互参照 | §5.7 |
| docs/v3 限定・コード非生成 | 成果物が本ファイルのみ |
| markdownlint | 通過済み（Phase 2 で実行 / 0 errors） |

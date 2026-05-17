# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit v2.6.5（AI-DLC スターターキット改善サイクル）

## 開発の目的

直近 2 サイクル（v2.6.3 / v2.6.4）の運用で表面化した「同一構造のレビュー反復・手順違反・SoT 同期漏れ・委譲フロー UX 摩擦」を、スターターキット本体のフロー・テンプレ・CI ガード・委譲規約に構造的に組み込み、再発を予防する。

本サイクルは以下 5 件の OPEN Issue を 1 サイクルに集約し、Inception / Construction / Operations の各フェーズ起点 + スキル本体改修 + 委譲フロー改修の 5 軸で改善する。

| Issue | 種別 | 起点 | 概要 |
|-------|------|------|------|
| #712 | type:docs / retrospective | Inception | 直近サイクルの完了 Unit との重複検出フローを SoT 化 |
| #679 | type:feature / feedback | Construction | Phase 1 設計起草前の事前コード Read 工程組み込み |
| #641 | type:feature / feedback | Operations | §7.13 直前のマージ前完結契約最終確認プロンプト追加 |
| #714 | type:refactor / retrospective | スキル本体 | defaults.toml 二重 SoT 同期自動化 / 検出ガード強化 |
| #717 | type:feature / feedback | 委譲フロー | `/aidlc <action>` 委譲先スキルの自動継続実行規約化 |

### Issue ↔ Unit ↔ 主要成果物 対応表

| Unit | Issue | 主要成果物（改修対象パス） | Unit 完了条件（1 行） |
|------|-------|--------------------------|---------------------|
| U1 | #712 | `skills/aidlc/steps/inception/*.md`（特に Unit 定義策定ステップ） | Inception で直近 N サイクル完了 Unit スラグ + 関連 CLOSED Issue 番号と突合し重複候補を AskUserQuestion で警告するフローが SoT 化され、本サイクル自体でドッグフーディング検証済み |
| U2 | #679 | `skills/aidlc/steps/construction/*.md` + `skills/reviewing-construction-design/SKILL.md`（観点追加） | Construction Phase 1 設計起草前に「事前コード Read」セクション存在チェックが必須化され、`reviewing-construction-design` の `architecture` focus 観点として組み込まれる |
| U3 | #641 | `skills/aidlc/steps/operations/02-deploy.md`（§7.13 直前） + `operations-release.md`（該当箇所） | §7.13（PR マージ実行）直前に「マージ前完結契約最終確認」AskUserQuestion が automation_mode 非依存・例外なしで常時実行される |
| U4 | #714 | `.github/workflows/`（CI ジョブ追加）+ 必要に応じ `skills/aidlc/scripts/` の同期スクリプト | `skills/aidlc/config/defaults.toml` ↔ `skills/aidlc-setup/config/defaults.toml` の差分を CI で**早期検出する**ガードが追加され（必須要件）、ジョブが本サイクルで failing red→green を実証 |
| U5 | #717 | `skills/aidlc/SKILL.md` L160-191（独立フロー委譲セクション） | `/aidlc r` / `setup` / `migrate` / `feedback` の各エイリアス入力で、AI エージェントが委譲案内テキストを介さず Skill ツール経由で直接対象スキルを invoke する規約が SKILL.md に明文化される |

## ターゲットユーザー

- AI-DLC スターターキットを利用する全プロジェクト（consumer プロジェクト）の AI エージェント・開発者
- AI-DLC スターターキット自身のメタ開発担当（ドッグフーディング経路）

## ビジネス価値

- **品質**: Inception での Unit 重複起案 / Construction 設計レビュー反復 / Operations 手順違反による rollback 工程を未然に削減し、サイクル品質を上げる
- **保守性**: defaults.toml の二重 SoT 同期漏れを CI / Unit 完了処理段階で自動検出することで、リリース直前の修復コミットを削減
- **UX**: `/aidlc r` / `/aidlc setup` 等で委譲案内テキストを介さず直接プロセスが開始されるようにし、AI エージェント操作のステップ数を削減

## 成功基準

### 必須達成条件

- 5 件の Issue がすべて CLOSED され、対応箇所の差分が本サイクル内でマージされること
- #712 改修により、Inception Phase 内で直近 N サイクルの完了 Unit スラグ + 関連 CLOSED Issue 番号と突合し重複候補を警告できる手順が SoT 化される（ドッグフーディングとして本サイクル自体で重複チェックを実証済み: 予定 U1〜U5 のスラグは v2.6.3 / v2.6.4 完了 Unit と一致なし）
- #679 改修により、Construction Phase 1 設計起草前に「事前コード Read」セクション存在が `reviewing-construction-design` の必須観点として組み込まれる
- #641 改修により、Operations §7.13 直前にマージ前完結契約最終確認の AskUserQuestion が常時実行される（適用範囲: §7.13（PR マージ実行）直前の**全経路**、`automation_mode` 非依存、**例外なし**。修正コミット欠落／空 PR／緊急マージ等の例外も非対象として扱い、必ず 1 回提示する）
- #714 改修により、`skills/aidlc/config/defaults.toml` ↔ `skills/aidlc-setup/config/defaults.toml` の差分が **CI で早期検出**される（CI ガード追加が**必須要件**）
- #717 改修により、`/aidlc r` / `setup` / `migrate` / `feedback`（およびそれぞれのコマンド正規形 `/aidlc <action>` における `action ∈ {retrospective, setup, migrate, feedback}` 短縮形入力）の委譲案内テキストを介さず Skill ツール経由で自動継続実行される規約が `skills/aidlc/SKILL.md` に明文化される

### 追加達成条件（任意）

- U4 (#714): CI 検出に加えて Unit 完了処理段階での自動同期スクリプト同梱（必須要件を満たした上で追加で達成できれば望ましい / 設計時にトレードオフ評価）
- U5 (#717): Codex CLI 実機での Skill 連鎖呼び出し挙動検証（Operations Phase 振り返り前段で実機検証 / Gemini CLI は環境未整備のため検証範囲外、記録のみ）

## 期限とマイルストーン

- 本サイクル単独完結（patch リリース v2.6.5）
- Construction Phase: 5 Unit 並列実装可（依存ほぼ無し、U4 のみ aidlc-setup 側参照確認が前段に必要）
- Operations Phase: CI 通過 + マージ前完結契約 + 振り返り

## 制約事項

### 含まれるもの

- `skills/aidlc/steps/inception` 配下: 直近サイクル完了 Unit との重複検出手順の追記（#712）
- `skills/aidlc/steps/construction` 配下: design 起草前の事前コード Read 必須化（#679）。`reviewing-construction-design` 観点追加もスコープ内
- `skills/aidlc/steps/operations` 配下: §7.13 直前のマージ前完結契約最終確認 AskUserQuestion 追加（#641）
- `skills/aidlc/config/defaults.toml` ↔ `skills/aidlc-setup/config/defaults.toml` の同期ガード（#714、**CI ジョブ追加は必須**、Unit 完了処理段階の同期スクリプト同梱は任意）
- `skills/aidlc/SKILL.md` の委譲フロー記述更新（#717）
- 上記改修の回帰テスト・ドッグフーディング検証

### 含まれないもの

- 委譲を廃止して親スキルに統合する案（#717 提案 2、SKILL.md 肥大化リスク回避のため不採用）
- defaults.toml の構造変更（#714 提案 3、共通テンプレ展開は別 epic、本サイクルでは CI ガード方式 / 同期スクリプト方式に限定）
- consumer プロジェクトへの追加配布物（#714 改修は starter kit 自己リポジトリ専用 CI ジョブとして分離、CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」原則準拠）
- #679 関連の派生改修（#633 / #692 等、本サイクルでは親 #679 のみ）
- Issue 自動再分類・新ラベル体系の整備等、5 件の本旨を超える拡張

### 技術的制約

- AI エージェント Bash ツール経由でのコマンド置換禁止（CLAUDE.md 既定）
- マージ前完結契約（Unit 002 / #583）に従い post-merge では cycle 成果物を改変しない
- 既存の `phase-recovery-spec.md` materialized binding 構造を破壊しないこと（#712 関連改修）
- `automation_mode` 非依存で常時 AskUserQuestion を行う対話は本サイクルで増加（#641）

## 不明点と質問（Inception Phase中に記録）

[Question] U4 (#714) の CI ガード実装方針として「CI ジョブ追加のみ」か「Unit 完了処理段階での自動同期スクリプト同梱」かの方針確定は Construction Phase の設計段階で行う想定で良いか？
[Answer] CI 早期検出を**必須要件**として固定する（成功基準「必須達成条件」参照）。Unit 完了処理段階での自動同期スクリプト同梱は「追加達成条件」に分離し、Construction Phase Unit 4 設計段階でトレードオフ評価のうえ採否を決定する。

[Question] U5 (#717) の Claude Code 以外（Codex CLI / Gemini CLI 等）での Skill 連鎖呼び出し挙動検証は Operations Phase で実施する方針で良いか？
[Answer] Operations Phase の振り返り前段で実機検証する。Codex CLI は本サイクルで `codex` review tool として利用可能であることをプリフライトで確認済み。Gemini CLI は環境未整備のため検証範囲外（記録のみ）。

[Question] #712 重複検出フローは「警告のみ」と「ブロック」のどちらをデフォルトとするか？
[Answer] Construction Phase Unit 1 設計段階で確定。Intent としては「警告ベースで AskUserQuestion による継続可否選択」を初期方針とする（ブロックは false positive リスクが大きい）。

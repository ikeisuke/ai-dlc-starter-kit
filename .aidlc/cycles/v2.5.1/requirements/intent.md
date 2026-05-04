# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit v2.5.1 - 振り返りエコシステム総仕上げ

## 開発の目的

v2.5.0 で導入した retrospective 自動生成 + mirror モード + 主因切り分け 3 分類は、運用上以下の課題を抱えている:

1. **`retrospective.md` ローカルファイルと Issue 起票の二重管理**: ローカルの `operations/retrospective.md` と mirror Issue が並存し、永続化先・参照先が分散。次サイクル Inception では `predecessor_retrospective.md` の手動配置か `cycles/{{PREV_CYCLE}}/operations/retrospective.md` の読み込みが必要で、cycle ブランチ削除後はローカル参照経路が壊れる。
2. **起票先選択肢の不足**: `feedback_mode = silent` は「振り返りはするが何の backlog にも反映されない」中途半端状態。プロダクト固有問題のプロダクトリポ起票経路がない (#627)。
3. **主因切り分け 3 分類の手作業負荷**: Unit 007 で導入した「プロダクト固有 / AI-DLC 固有 / 両方」分類と `skill_caused_judgment` 3 質問の下書きが完全手作業で、ユーザー認知負荷が高い。
4. **マージ前レビュー反映の write-history 追加コミット漏れ運用バグ (#616)**: v2.4.3 で実害発生。マージ前完結契約の整合性に穴が残っている。

本サイクルは「振り返りはローカルファイルではなく最初から Issue で完結する」という方針転換により、ファイル/Issue の二重管理を解消し、起票先選択を wizard 化し、主因分類を LLM で下書きする。これにより v2.5.x ブランチで振り返りエコシステムを実用形態に到達させる。

## ターゲットユーザー

- **AI-DLC Starter Kit 開発者（メタ開発、upstream リポジトリ運用者）**: 自リポを使ったドッグフーディング時の振り返り運用を改善
- **AI-DLC を導入するダウンストリーム消費プロジェクト**: プロダクト固有問題のプロダクト Issue 起票と AI-DLC 固有問題の upstream Issue 起票を自動化

## ビジネス価値

- 振り返り output の永続化先が GitHub Issue に統一され、cycle ブランチ削除後も完全参照可能
- 起票先 wizard により消費プロジェクトとメタ開発で適切な default が選択され、認知負荷が下がる
- 主因 LLM 下書きにより 3 分類の精度・速度が向上し、振り返り運用が継続しやすくなる
- マージ前レビュー反映の漏れバグが解消され、運用事故再発を防止

## 成功基準

各基準に観測可能な判定値（CLI 出力 / Issue URL / exit code / 検証コマンド等）を付与する。

- [ ] **ローカルファイル生成撤廃**: `04-completion.md §1.5` 実行後、`.aidlc/cycles/{{CYCLE}}/operations/retrospective.md` が **存在しない**（`test ! -f` で 0 を返す）。代わりに `gh issue view <N> --json url` で起票済み Issue の URL が取得できる
- [ ] **feedback_mode 5 値拡張**: `scripts/read-config.sh rules.retrospective.feedback_mode` で `interactive` / `local-issue-only` / `mirror-only` / `local-and-mirror` / `disabled` のいずれかが取得でき、`config/defaults.toml` に enum 制約が記載される
- [ ] **初回 wizard 動作**: `feedback_mode` 未設定時に Operations 04-completion §1.5 直前で AskUserQuestion 起動。BATS テスト `tests/feedback-mode-wizard.bats` で wizard 起動条件と設定保存パスを検証
- [ ] **LLM 下書き prefilled**: 起票された Issue 本文に主因分類（3 分類のいずれか）と `skill_caused_judgment`（q1/q2/q3 + 引用文）の YAML ブロックが含まれること（`gh issue view <N> --json body | jq` で抽出可能）
- [ ] **predecessor Issue 取得**: 次サイクル Inception 01-setup §4a 実行時、`gh issue list --milestone <PREV_CYCLE> --label retrospective` の結果から前サイクル retrospective Issue が一意に特定でき、本サイクル Intent 前提として参照される（コンテキスト変数 `predecessor_retrospective_issue_url` が設定される）
- [ ] **手動配置案内撤去**: `steps/inception/01-setup.md` 内の `predecessor_retrospective.md` 文字列が grep で 0 件
- [ ] **#616 ガード追加**: `scripts/operations-release.sh verify-git` 実行で未コミット差分があれば exit ≥ 1（`uncommitted=ok` を要求）。BATS テスト `tests/operations-verify-git.bats` で 7.12 後の write-history 後の未コミット検出を verify
- [ ] **後方互換マイグレーション**: `aidlc-setup` または `aidlc-migrate` 実行時に旧 `silent` / `mirror` / `disabled` を新値に自動マッピング。マイグレーション失敗時は警告 + no-op 動作、ロールバック手順がドキュメント化されている
- [ ] **gh 不可時のスプール保存**: `gh_status != available` 時、Issue 起票内容を `cycles/{{CYCLE}}/history/retrospective-spool.md`（永続）にスプールし、次回 `gh` 利用可能時の再送スクリプト（`scripts/retrospective-resend.sh` 等）が用意されている

## 期限とマイルストーン

- v2.5.1 は patch リリース扱い。トレードオフスライダー: 予算小・納期最小・スコープ大・品質最大
- 単サイクル完結。Construction Phase で 4-6 Unit 程度に分解見込み

## 制約事項

- **後方互換**: 旧 `feedback_mode` 値（`silent` / `mirror` / `disabled`）は新値へ自動マッピングされる必要がある。マッピング表は本 Intent §「主要設計判断 4」を参照
- **プラグイン構成原則**: スキル内リソースはスキルベース相対パスで参照（`skills/aidlc/...` 形式禁止）
- **マージ前完結契約**: 振り返り Issue 起票・主因分類 LLM 呼び出し・predecessor 検索 すべてマージ前に完結すること
- **`gh` 依存と消失防止**: 振り返り Issue 起票は `gh_status=available` を前提。`gh` 不可時は **必ずローカルスプール**（`history/retrospective-spool.md`）に保存し、次回 `gh` 利用可能時の再送経路を提供する（消失禁止）
- **LLM 下書き実行マトリクス**: 本 Intent §「主要設計判断 2」の実行マトリクスに従う。primary は Claude Code（メインエージェント or `retrospective-drafter` subagent）、CI/失敗時は手動入力フォールバック
- **コマンド置換禁止**: bash コマンドで `$(...)` / バッククォート禁止（プロジェクト CLAUDE.md ルール）

## 含まれるもの

1. **`04-completion.md §1.5` の Issue 化**: ローカル `retrospective.md` ファイル生成を撤廃し、最初から Issue 起票フローに統合
2. **`feedback_mode` 拡張 + 初回 wizard 化** (#627): プロダクト Issue / upstream Issue / 両方 / disabled の選択肢追加 + AskUserQuestion による wizard + 設定保存フロー
3. **主因分類 LLM 下書き**: 3 分類（プロダクト固有 / AI-DLC 固有 / 両方）と `skill_caused_judgment` を LLM で生成、Issue 本文に prefilled、人間は確認のみ
4. **predecessor handoff の Issue 化**: `01-setup.md §4a` の手動配置参照を撤去し、Issue ラベル/Milestone 検索ベースの取得経路に置き換え。`predecessor_retrospective.md` テンプレ廃止
5. **#616 write-history 追加コミット漏れ修正**: マージ前レビュー反映後の追加コミット未実施フロー漏れに対するガード追加（実装手段は Construction で確定）
6. **後方互換マイグレーション**: 旧 `feedback_mode` 値の自動マイグレーション or 警告付き no-op 動作

## 含まれないもの（OUT_OF_SCOPE）

- **#621 retrospective mirror Issue 自動重複統合 workflow**: ユーザー判断により今サイクルから除外。v2.6.x 以降で別サイクル実装
- **段階 2: mirror vs リポ全体横断検知**: #621 と同じく除外
- **`feedback_max_per_cycle` の閾値変更**: v2.5.0 で導入済みの仕様を維持。ただし新モード別の **適用範囲**は本 Intent §「主要設計判断 5」で確定（変更ではなく、新モード対応の cap 範囲明記のみ）
- **新規 retrospective テンプレ大幅刷新**: KPT + 主因切り分けの構造はそのまま、Issue 化と LLM 下書き対応のみ
- **CI 環境での LLM 自動実行**: `actions/ai-inference` 等の CI 連携は実装しない（手動入力 fallback のみ）。将来サイクルで必要に応じて追加

## リスクと代替案検討

### リスク 1: `retrospective.md` ローカルファイル廃止により、`gh` が利用不可な環境（オフライン/CI 制限）で振り返りが完全に消失

**緩和策（MUST 要件 / 成功基準と対応）**:
- `gh_status != available` 時は **必ず** `cycles/{{CYCLE}}/history/retrospective-spool.md` にスプール（消失禁止）
- `scripts/retrospective-resend.sh` を提供。次回 `gh` 利用可能時にスプール → Issue 起票への再送ができる
- `feedback_mode = "disabled"` 時のみスプール不要（明示的なスキップ意思）
- スプールファイルは `history/` 配下に永続配置し、cycle ブランチ削除後も main に保持される

### リスク 2: 主因分類 LLM 下書きの誤判定で「振り返りの本質」がぶれる

**緩和策**:
- 必ず人間確認・修正フローを挟む（review-flow.md 準拠）
- LLM 出力に対する明示的な「確認済み」マーカー（YAML キー `human_reviewed: true`）を Issue 本文に保持
- LLM 失敗時は手動入力にフォールバック
- LLM 推論結果と人間確認後の最終結果が異なる場合、差分を Issue コメントとして記録（学習データとして観察）

### リスク 3: 後方互換破壊により既存ユーザーの v2.5.0 サイクル中継ができなくなる

**緩和策**:
- 旧 `feedback_mode` 値の自動マイグレーションを `aidlc-migrate` に組み込む（写像表は §「主要設計判断 4」参照）
- マイグレーション未実施時は警告付き no-op で動作継続（破壊しない）
- 既存 `cycles/{{PREV_CYCLE}}/operations/retrospective.md` ファイルが残存する場合の参照経路は **読み取りのみ維持**（廃止対象は新規生成）
- マイグレーション失敗時の **ロールバック手順**: `aidlc-migrate --rollback` で `.aidlc/config.toml` のバックアップ復元（aidlc-migrate 既存機能の再利用）

### リスク 4: v2.5.0 `mirror_state` YAML を Issue 化したときの状態遷移欠落

**緩和策**:
- `mirror_state` 状態（`""` / `pending` / `created` / `skipped:max_exceeded` / `skipped:duplicate` 等）を Issue ラベルで保持（`mirror-state:created` / `mirror-state:skipped-duplicate` 等）
- 本文には YAML ブロックも残し、`gh issue view --json body | jq` で読める。読み取り側（feedback_max_per_cycle 判定や duplicate detector）は新ラベル経路を優先、YAML を fallback とする
- 既存 `cycles/{{PREV_CYCLE}}/operations/retrospective.md` の YAML は読み取り専用パーサで継続サポート（v2.5.0 互換）

## 主要設計判断（Inception で確定）

### 判断 1: 起票先 wizard 実行タイミング

**確定**: **Operations 振り返り起票直前（初回のみ）**。`04-completion.md §1.5` で retrospective Issue を起票する直前、`feedback_mode` が未設定（旧値含む）の場合のみ wizard を起動する。設定保存後はスキップ。

**根拠**: 振り返り Issue の起票という具体アクションと wizard が同一フロー上にあるため、ユーザーは「何を、どこに起票するか」を文脈付きで判断できる。Inception で先回り設定するより、初回の振り返り実行時に設定するほうが認知負荷が低い。

### 判断 2: 主因分類 LLM 下書きの実行マトリクス

**確定**: **primary は Claude Code（メインエージェントまたは `retrospective-drafter` subagent）**。外部 CLI / CI 連携は本サイクルでは含めない。

| 実行環境 | primary | fallback |
|---------|---------|---------|
| 対話セッション（ローカル） | Claude Code 自身（または `retrospective-drafter` subagent） | 手動入力 |
| 非対話セッション / CI | （実装しない / OUT_OF_SCOPE） | 手動入力（CI では skip） |
| LLM 失敗 / タイムアウト | （該当なし） | 手動入力フォールバック |

**根拠**: AI-DLC フロー全体が Claude Code 駆動のため、retrospective drafting も同じエージェントで完結させるのが自然。subagent 化でコンテキスト分離は確保。CI 環境向けの GitHub Models / codex 連携は将来サイクル（v2.6.x 以降）で必要に応じて追加。

### 判断 3: predecessor handoff の Issue 検索キー

**確定**: **前サイクル closed Milestone + `retrospective` ラベル の AND 検索**。`milestone_enabled=true` 前提（既定 false 環境では label のみ fallback）。

**検索優先順位（複数ヒット時の決定規則）**:

1. リポジトリ固定（`gh issue list` の対象は現在の origin リポのみ）
2. 前サイクル Milestone（`gh issue list --milestone <PREV_CYCLE> --label retrospective --state all`）
3. ヒット 1 件 → 自動採用、コンテキスト変数 `predecessor_retrospective_issue_url` に格納
4. ヒット 0 件 → スプールファイル `cycles/{{PREV_CYCLE}}/history/retrospective-spool.md` を fallback で確認
5. ヒット ≥ 2 件 → AskUserQuestion で対話確認（候補一覧を提示し、ユーザーが選択）
6. `milestone_enabled=false` の環境 → label のみで検索 + ヒット ≥ 2 件時は `closedAt` 降順で最新を採用、ユーザーに確認

**根拠**: v2.4.0 / v2.5.0 で Milestone 自動作成・close が `milestone_enabled=true` 前提で実装済み。これを再利用することで実装ノイズが小さく、検索精度が高い。`milestone_enabled=false` のダウンストリーム互換のため、label のみの fallback パスも残す。

### 判断 4: feedback_mode マイグレーション写像

**確定**: 旧→新の写像、適用タイミング、ロールバックを以下に定義。**動作変更を伴うマッピングは必ず初回 `interactive` wizard で明示同意を取る**（自動昇格禁止）。

| 旧値 | 新値 | 動作変更 | 同意取得 |
|------|------|----------|---------|
| `silent`（既定） | `interactive` | あり（記録のみ → 起票判断へ） | wizard で必須（非対話環境は保守的に起票しない） |
| `mirror` | `mirror-only` | なし（名前変更のみ、動作互換） | 不要 |
| `disabled` | `disabled` | なし | 不要 |
| 未設定（key 不在） | `interactive` | あり（新規ユーザー） | wizard で必須 |

**設計原則**: v2.5.0 `silent` は「振り返りはローカル記録のみ・Issue 起票なし」が暗黙のデフォルトだった。v2.5.1 でこれを `local-issue-only` 等に直接マッピングすると意図しない Issue 生成を起こす可能性がある。そのため `silent` → `interactive` に写像し、初回 04-completion §1.5 実行時に wizard で明示同意を取り、ユーザーが選んだ値を保存する。

**適用タイミング**:
- **`aidlc-migrate` 実行時**: v2.5.0 → v2.5.1 のマイグレーション処理として写像表に従い `.aidlc/config.toml` を書き換え。`silent` → `interactive` への変更は **同意プロンプトを表示** し、ユーザーが拒否した場合は `disabled` にフォールバック（保守的に「起票しない」を選ぶ）
- **初回 04-completion §1.5 実行時（マイグレーション未実施 / `interactive` 設定）**: AskUserQuestion で起票先を選択させ、選択結果を `.aidlc/config.toml` に保存（既存 wizard 設定保存パターン踏襲）
- **CI / 非対話環境**: マイグレーションは `aidlc-migrate` 経由のみ。非対話時の `silent` → 新値の自動昇格は禁止 → `disabled` にフォールバック（`interactive` のまま放置すると次回 wizard 必須になり混乱を招く）

**ロールバック手順**: `aidlc-migrate --rollback` で `.aidlc/config.toml.backup-<timestamp>` を復元（既存 aidlc-migrate のロールバック機能を再利用、新規実装は不要）。

**非破壊性検証**: マイグレーション後、ユーザーが `aidlc-migrate --rollback` を実行できる状態が維持される。BATS テスト `tests/feedback-mode-migration.bats` で「対話: silent→interactive＋wizard 拒否時 disabled へ fallback」「非対話: silent→disabled へ自動 fallback」「mirror→mirror-only は同意不要で無警告」を verify。

### 判断 6: 共有契約（Shared Constants / Cross-Unit Contracts）

複数 Unit から参照される命名規約・データ契約を本セクションで一元管理する。Unit 定義はここを正本として参照する。

#### 6.1 ラベル / Milestone 命名規約

| 種別 | 命名規則 | 例 | 用途 |
|------|---------|-----|------|
| retrospective Issue ラベル | `retrospective` | `retrospective` | 振り返り Issue 全般を識別。Unit 002 が起票時に付与、Unit 004 が検索時に使用 |
| mirror_state ラベル | `mirror-state:<value>` | `mirror-state:created`, `mirror-state:skipped-duplicate`, `mirror-state:error` | 振り返り Issue の `mirror_state` を保持。`""` はラベル不要。YAML 値の `:` は `-` に変換 |
| Milestone 名 | `<CYCLE>` | `v2.5.1`, `v2.6.0` | サイクルごとに Issue を集約。v2.4.0 で導入済の規約を踏襲 |

#### 6.2 retrospective Issue 本文構造（Unit 002 の責務 / Unit 003 の prefill 入力）

```markdown
# Retrospective: <CYCLE>

## Keep / Try / Problem
（Markdown セクション）

## 問題項目（Problem）

### 問題 1: <タイトル>

**何が起きたか**: ...
**なぜ起きたか**: ...
**損失と影響**: ...

**主因切り分け**:

| 主因分類 | 該当 | 反映先 |
|----------|------|-------|
| プロダクト固有 | yes/no | ... |
| AI-DLC Starter Kit 固有 | yes/no | ... |
| 両方に責任 | yes/no | ... |

**skill 起因判定**:

```yaml
skill_caused_judgment:
  q1_answer: "yes" | "no"
  q1_quote: "..."
  q2_answer: "yes" | "no"
  q2_quote: "..."
  q3_answer: "yes" | "no"
  q3_quote: "..."
mirror_state:
  state: "" | "pending" | "created" | "skipped:max_exceeded" | "skipped:duplicate" | "error"
  issue_url: ""
  recorded_at: ""
human_reviewed: false  # Unit 003 が確認後に true へ更新
```
```

#### 6.3 LLM 下書き出力契約（Unit 003 → Unit 002 の prefill 経路）

**入力**: 当該サイクルで観測された Problem 一覧（タイトル + 描画情報）。

**出力（YAML 形式 / 1 Problem 1 ブロック）**:

```yaml
problem_drafts:
  - problem_id: <integer>           # 必須: 該当 Problem の連番
    primary_cause: "product" | "ai_dlc" | "both"  # 必須: 3 値のいずれか
    primary_cause_reason: <string>  # 必須: 主因判断の根拠（短文）
    skill_caused_judgment:
      q1_answer: "yes" | "no"       # 必須
      q1_quote: <string>            # 必須（answer="no" の場合は空文字列）
      q2_answer: "yes" | "no"       # 必須
      q2_quote: <string>            # 必須（同上）
      q3_answer: "yes" | "no"       # 必須
      q3_quote: <string>            # 必須（同上）
    confidence: "high" | "medium" | "low"  # 任意: LLM 推論の信頼度ヒント
```

**失敗時の既定値（fallback）**: 全フィールドを空文字列または `"no"` で埋め、`primary_cause = "product"` を仮置き。`human_reviewed: false` のまま Unit 002 に渡し、Unit 003 が AskUserQuestion で人間入力を取得して更新する。

#### 6.4 human_reviewed 付与責任

| Unit | 責任 |
|------|------|
| Unit 002 | Issue 起票時、`human_reviewed: false` で起票本文に YAML を埋め込む |
| Unit 003 | LLM 下書き完了 + 人間確認完了後、Issue 本文を更新して `human_reviewed: true` に変更（または当該 Issue にコメント追記で明示） |

#### 6.5 04-completion §1.5 編集主体

`steps/operations/04-completion.md §1.5` の改修主体は **Unit 002**（retrospective Issue 一本化が中心責務のため）。Unit 001 は関数 / 設定値を提供するのみで、`§1.5` のステップ記述は編集しない。Unit 003 は Unit 002 改修済の `§1.5` ステップに対し下書き呼び出しフックを差し込む。

### 判断 5: feedback_max_per_cycle のモード別適用範囲

**確定**: cap は **モード横断で 1 つの値を共有**（合算上限）。重複検出は対象 Issue ストレージ全体で実施。

| feedback_mode | cap 適用 | 重複検出範囲 |
|---------------|---------|--------------|
| `local-issue-only` | プロダクト Issue 起票数に適用 | プロダクトリポの open Issue |
| `mirror-only` | upstream Issue 起票数に適用 | upstream リポの open Issue |
| `local-and-mirror` | プロダクト + upstream **合算** | 両リポの open Issue |
| `interactive` | 選択された経路のみに適用（合算 or 単独） | 選択経路に応じて切替 |
| `disabled` | 適用なし（スキップ） | 該当なし |

**根拠**: cap は「振り返りでの過剰起票を防ぐ」ためのものなので、起票先が増えても合算で抑制するのが意図に合致。v2.5.0 の `feedback_max_per_cycle = 3` は維持（変更しない）。

## 不明点と質問（Inception Phase中に記録）

（Inception で主要判断は確定済み。Construction Phase で判明した不明点はここに追記）

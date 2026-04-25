# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit v2.4.1 — merge/CI フロー堅牢化 + Markdown 手順書明確化 patch

## 開発の目的

**主目的**: v2.4.0 までに発見された 5 件の patch 級 Issue を同サイクルで解消し、merge フローと Markdown 手順書の堅牢性を底上げする patch リリースとする。対象は以下 5 件:

1. **#601 merge_method 設定保存が PR に追従しない**: Operations 7.13 で `.aidlc/config.toml` に書き込んだ設定変更がマージ実行前に PR へ反映されない bug
2. **#598 必須 Checks が paths フィルタ / Draft skip で発火せず PR が merge 不可になる**: v2.3.6 で入れた paths フィルタ + Draft skip と Branch protection の required checks の整合性が崩れている
3. **#594 Construction Squash ステップが「オプション」表記で誤省略されやすい**: `steps/construction/04-completion.md` の Squash ステップラベルと分岐ロジックの実体が乖離
4. **#600 aidlc-setup 01-detect の複数条件チェック独立実行指針**: `steps/01-detect.md` の 3 条件チェックが自然言語のみで、`&&` 短絡評価による検出漏れが実際に発生
5. **#602 Milestone step.md 構造改善**: v2.4.0 で追加した Milestone 関連 step.md 4 ファイルの構造審査指摘（empirical-prompt-tuning 由来）に対応

### 背景・経緯

1. **#601**: v2.3.5 で Operations 7.13 の `merge_method=ask` フローに設定保存オプションを追加したが、Ready 化後（7.8 以降）に tracked ファイル変更が発生すると PR に反映されずローカルに残る。jailrun v0.3.1 サイクルで実観測
2. **#598**: v2.3.6 で Draft skip と paths フィルタを導入し runner コスト削減を達成したが、Branch protection の required checks 整合性が落ち、該当しない PR が "Expected — Waiting for status to be reported" のまま merge 不可になる事例発生
3. **#594**: v2.3.5 以前から残る「【オプション】」表記により、実運用中の visitory プロジェクトで 2 Unit 連続して Squash がスキップされる事故が発生
4. **#600**: ikeisuke/norigoro プロジェクトで Claude Code が `&&` チェーンで 3 条件を束ね、v1 残骸の検出漏れが発生
5. **#602**: v2.4.0 で追加した Milestone 関連 step.md 4 ファイルを empirical-prompt-tuning で構造審査した結果、計 5 件の改善項目が検出（中優先度 1 件 / 低〜中 1 件 / 低 2 件）

### スコープ範囲と安全性判断

本サイクルは **patch 単発**として位置付け、以下の方針でスコープを確定する:

- **#601 の解決方針**: **案B（マージ前コミット+push フロー明示）**を採用。設定保存を Inception に移動する案A は既存 Operations フローの情報構造変更を伴うため、patch では過剰。マージ実行前に「設定変更のコミット＋追加 push」フローを 7.13 内で明示する最小修正に留める
- **#598 の解決方針**: **常に空ジョブで PASS を返す方式**を採用（方針レベル固定）。paths フィルタ・Draft skip の両スキップ条件で「対象なし → PASS」を明示的に報告する構成を必須要件とする。具体実装（独立の報告 job を追加するか、既存 job 側で skip 条件下に PASS step を追加するか）は Construction Phase の設計レビューで 2 案から選定する（outcome は「required check が常に PASS 状態で報告される」で固定、手段は設計判断に委ねる）
- **#602 のスコープ**: 中優先度を中心に **4 ファイルすべて対応**（02-preparation.md §16 / 05-completion.md §1 / 01-setup.md §11 / 04-completion.md §5.5）。patch スコープで完結可能な最小修正案を適用する
- **CI／workflow／Branch protection** への変更は #598 の対応範囲に限定。`.github/workflows/*.yml` に不要な変更を加えない

## ターゲットユーザー

- **メタ開発者（一次）**: ai-dlc-starter-kit 自体を開発する利用者。#601 / #598 / #594 / #600 / #602 すべて直接恩恵を受ける
- **AI-DLC 利用者（二次）**: 外部プロジェクトで AI-DLC を使う利用者。#601（Operations 7.13）/ #594（Construction Squash）/ #600（setup 判定）の修正は利用者にも直接波及

## ビジネス価値

- **マージフローの堅牢性**: #601 修正により、`merge_method=ask` + 設定保存フローでの PR 未追従事故がなくなる
- **CI 整合性**: #598 修正により、paths フィルタ / Draft 運用下でも required check が安定し、merge blocker による手動 override が不要になる
- **AI エージェントの誤判定抑止**: #594 / #600 の Markdown 手順書明確化により、AI が分岐ロジックを正しく解釈しやすくなる
- **Milestone 手順書の可読性**: #602 対応により v2.4.0 で追加した Milestone 手順書の不明瞭点が解消され、白紙 subagent でも読み切れる構造に揃う

## 含まれるもの

### Unit 構成（予定）

Inception Phase ステップ4（Unit定義）で正式確定する。以下は Intent 段階での Unit 分解候補。

| Unit | 対象 Issue | スコープ | 主要ファイル |
|------|-----------|---------|--------------|
| Unit A | #601 | Operations 7.13 で write-config 後のコミット+push フロー明示 | **主対象**: `skills/aidlc/steps/operations/operations-release.md`（§7.13 本体 L91-118 の設定保存フロー直後にガード追加）／**整合確認**: `skills/aidlc/steps/operations/04-completion.md`（L42 の post-merge 改変禁止ルールとの整合）・`skills/aidlc/steps/operations/02-deploy.md`（L168-184 のサブステップ索引の注記整合）|
| Unit B | #598 | paths フィルタ / Draft skip 下でも required check が常時 PASS 報告される仕組みの追加 | `.github/workflows/pr-check.yml` / `migration-tests.yml` / `skill-reference-check.yml` |
| Unit C | #594 | Squash ステップ表記変更 + commit-flow.md 分岐ロジック明記 | `skills/aidlc/steps/construction/04-completion.md` / `steps/common/commit-flow.md` / `skills/squash-unit/SKILL.md`（必要時）|
| Unit D | #600 | aidlc-setup 01-detect 独立チェック指針の明示 | `skills/aidlc-setup/steps/01-detect.md` |
| Unit E | #602 | Milestone step.md 4 ファイルの構造改善 | `skills/aidlc/steps/inception/02-preparation.md` / `05-completion.md` / `skills/aidlc/steps/operations/01-setup.md` / `04-completion.md` |

### Unit A: #601 merge_method 設定保存のマージ前コミット+push 明示

- `steps/operations/` の Operations 7.13 該当箇所に、`write-config.sh` 実行後のガード手順を追加:
  - `write-config.sh` 完了後、未コミット差分（`.aidlc/config.toml`）を検出
  - 検出時は `AskUserQuestion` で「コミット+push する / follow-up PR で対応する / 破棄する」を選択
  - 「コミット+push」選択時はステップ内でコミットして push（PR に追従させる）
  - 「follow-up PR」「破棄」選択時の具体手順を記述
- 7.13 の前段（Inception Phase 側で `merge_method` を事前確定する大規模リファクタリング）は本サイクル外（v2.5.0 以降で案A を別途検討）
- jailrun v0.3.1 の実際の対処（stash → tag → 新ブランチ follow-up PR）をリファレンスケースとして記述

### Unit B: #598 空ジョブ PASS 方式による必須 Checks 安定化

- `.github/workflows/pr-check.yml` / `migration-tests.yml` / `skill-reference-check.yml` の 3 workflow に対して、**required check が常に PASS 状態で報告される仕組み**を追加する。実装方式は Construction Phase の設計レビューで以下2案から選定:
  - **案1: 独立報告 job の追加**。各 workflow に `report-status` 系の報告ジョブを 1 つ追加し、paths フィルタで対象外の PR でも常に発火し、対象ジョブの実行結果（run / skip / fail）を受けて required check 名と同じチェック名で PASS / FAIL を報告
  - **案2: 既存 job 内の PASS step 追加**。対象ジョブ側で `if:` による skip 条件下に常に PASS を返す step を追加し、check が必ず報告されるようにする
- いずれの案も outcome（required check が常に PASS 状態で報告される）は同一。手段は設計判断に委ねる
- Branch protection の required checks 一覧変更は **行わない**（check 名を変えないため影響なし）
- v2.3.6 で導入した Draft skip による runner 課金抑制効果は維持する

### Unit C: #594 Squash ステップ誤省略の抑止

- **`commit-flow.md`「Squash統合フロー」冒頭に前提チェックを明示**:
  - `rules.git.squash_enabled` を確認し、`false` または未設定なら `squash:skipped:disabled` を返してフローを終了
  - `true` なら次のステップへ進む
- **`steps/construction/04-completion.md` ステップ 7 から「【オプション】」ラベルを除去**し、代わりに「`squash_enabled=true` の場合は必須」と明記
- `skills/squash-unit/SKILL.md` は呼ばれた時点で無条件 squash する現行動作を維持（呼び出し側が分岐責任を持つ設計）
- Unit 003 で 14 コミットに膨らんだ事故のリファレンスは `guides/` にケーススタディとして残さない（patch スコープ内に閉じる）

### Unit D: #600 aidlc-setup 01-detect の独立チェック指針

- `skills/aidlc-setup/steps/01-detect.md` セクション1「早期判定」に以下を追記:
  - 3 条件（セットアップ済み / v1 移行 / 初回）を**独立に `test -f` 等で評価**する具体コマンド例
  - `&&` / `||` チェーン禁止の注意書き（早期終了による検出漏れ防止）
- ikeisuke/norigoro での誤判定事例を reference として記述
- 既存の判定ロジックそのもの（CASE_1 / CASE_2 / CASE_3 の分類）は変更しない

### Unit E: #602 Milestone step.md 構造改善

- **`steps/inception/02-preparation.md` §16**（改善優先度中）:
  - 「1を選択」直後に「選択結果を改行区切りで `SELECTED_ISSUES` として保持する」を 1 行追記
  - `MILESTONE_ENABLED` ガードと `SELECTED_ISSUES` 空時の挙動の結合関係を明示
- **`steps/inception/05-completion.md` §1**（改善優先度低）:
  - `MILESTONE_NUMBER` 抽出例を grep/sed/awk のいずれかで明示
- **`steps/operations/01-setup.md` §11**（改善優先度低〜中）:
  - `11-1 / 11-2 / 11-3` のサブ見出しに「（setup-step11 内部処理）」を併記、または段階表現に変更
- **`steps/operations/04-completion.md` §5.5**（改善優先度低、軽微確認）:
  - 構造審査上は all OK のため、他3ファイルの改訂に伴う引用・相互参照の整合確認のみ

### v2.4.1 サイクル自体の Milestone 運用

- v2.4.0 で本採用した Milestone 運用に従い、サイクル開始時に Milestone `v2.4.1` を作成して対象 Issue（#601 / #598 / #594 / #600 / #602）と本サイクル PR を紐付ける
- メタ開発リポジトリは `milestone_enabled = true` を設定済みのため、Inception 02-preparation / 05-completion の Milestone 手順が適用される

## 含まれないもの

### 本サイクル外（後続サイクル候補）

- **#605** aidlc-setup のマージ後 HEAD を origin/main と同期する処理: feature 級で worktree / 通常ブランチ / detached HEAD の場合分けが必要。v2.5.0 以降で別サイクル検討
- **#601 案A**（Inception で merge_method を事前確定）: Operations 情報構造の大規模変更を伴うため、patch 外。v2.5.0 以降で別途検討
- **#586** progress.md / 判定仕様 / fixture の 3 層整合化リファクタ
- **#592** config.toml.template の個人好み分離
- **#590** AI-DLC 振り返りステップ追加
- **#591** operations-release.md §7.6 明文化
- その他 backlog 一覧の項目

### 明示的除外

- **#598 対応で Branch protection の required checks 一覧を変更しない**（check 名を維持するため）
- **#594 対応で `squash-unit` スキル本体の分岐ロジック追加は行わない**（呼び出し側責任を維持）
- **#601 対応で Inception Phase の既存ステップ構造を変更しない**（Operations 側のガード手順追加に限定）

## 成功基準

### Unit A: #601 merge_method 設定保存

- Operations 7.13 で `write-config.sh` 実行後、未コミット差分検出ガードが動作し、ユーザーが選択した方針（コミット+push / follow-up PR / 破棄）に従って処理される
- **「コミット+push」選択時の終了条件**: マージ実行前に PR に `.aidlc/config.toml` の変更が反映されている（`git log origin/{branch}` に当該コミットが含まれる）。その後マージ実行に進む
- **「follow-up PR」選択時の終了条件**: 現 PR は `.aidlc/config.toml` の設定変更を含めずマージ可能な状態に戻る（`git stash` 等で差分を退避、またはガード手順で提示する follow-up 用ブランチ作成手順が成立）。follow-up PR の作成手順（新ブランチ・コミット・PR 作成コマンド）がステップ手順書に明示されており、番号が `history/operations.md` に追記される。その後現 PR のマージ実行に進む
- **「破棄」選択時の終了条件**: `.aidlc/config.toml` の差分が `git restore .aidlc/config.toml` 等で巻き戻り、`git status` で当該ファイルがクリーンになる（未コミット差分ゼロ）。その後現 PR のマージ実行に進む
- ステップ手順書に「案B」が明示されている（AIエージェントが誤解釈しない）
- jailrun v0.3.1 の再発チェック: 同じ操作を行って差分が残らないこと（「コミット+push」選択時は PR に反映、「follow-up PR」選択時は follow-up PR に記録、「破棄」選択時は差分自体が存在しない）

### Unit B: #598 必須 Checks 安定化

- `pr-check.yml` / `migration-tests.yml` / `skill-reference-check.yml` の 3 workflow について、以下のいずれでも required check が PASS 状態になる:
  - paths フィルタ非該当の PR（例: `skills/aidlc/scripts/*.sh` のみ変更）
  - Draft の間の PR
  - Draft → Ready 遷移後の PR
- `skills/aidlc/scripts/*.sh` のみを変更する動作確認 PR（本サイクル自体でテスト可能）で required check が PASS になり、admin override なしで merge 可能
- v2.3.6 で導入した Draft skip の runner 課金抑制効果が維持されている（対象ジョブ自体はスキップ、報告ジョブのみ実行）

### Unit C: #594 Squash ステップ誤省略抑止

- `commit-flow.md` に前提チェックセクションが追加され、`squash_enabled=false` 時の明示スキップが記述されている
- `04-completion.md` ステップ 7 から「【オプション】」ラベルが除去され、`squash_enabled=true` 時は必須である旨が明記されている
- Construction Phase の Unit 完了処理で AI エージェントが Squash をスキップしない（patch スコープ内での動作確認は困難なため、文書上の明確化で完了）

### Unit D: #600 aidlc-setup 01-detect 独立チェック指針

- `01-detect.md` に独立チェックのコマンド例と注意書きが追加されている
- `&&` / `||` チェーン禁止の指針が明示されている
- AI エージェントが 3 条件を独立評価するよう案内されている

### Unit E: #602 Milestone step.md 構造改善

- `02-preparation.md` §16 に `SELECTED_ISSUES` の構築手順が 1 行追記され、`MILESTONE_ENABLED` ガードと `SELECTED_ISSUES` 空時の挙動の結合関係が明示されている
- `05-completion.md` §1 に `MILESTONE_NUMBER` 抽出例（grep/sed/awk いずれか）が追加されている
- `operations/01-setup.md` §11 のサブ見出しに「（setup-step11 内部処理）」注記または段階表現化が適用されている
- `operations/04-completion.md` §5.5 との相互参照が他3ファイルの改訂と整合している

### サイクル自身の Milestone

- v2.4.1 サイクルの開始時に Milestone `v2.4.1` が作成され、本 Intent で対象とする Issue（#601 / #598 / #594 / #600 / #602）と本サイクル PR が紐付けされる
- マージ後に Milestone `v2.4.1` が close される

### CHANGELOG / README

- `CHANGELOG.md` の `[2.4.1]` 節に対象 Issue 5 件の修正内容が `### Fixed` / `### Changed` / `### Documentation` 等で明記される
- README の関連記述（該当あれば）は更新不要または最小修正に留まる

## 期限とマイルストーン

- v2.4.1 patch リリースとして単一サイクル内で完結
- Construction Phase は Unit 数 5 程度を想定（Unit A / B / C / D / E）。Unit B（CI workflow）と他の Unit は依存関係なし、並列実装可能
- 完了後 Operations Phase で Milestone close + リリースタグ作成

## 制約事項

### 技術的制約

- `.github/workflows/*.yml` の変更は Branch protection の required checks に影響しないよう check 名を維持する必要がある
- Unit B の空ジョブ PASS 方式は GitHub Actions の job 結果報告仕様に依存（`conclusion: success` を明示的に返す設計）
- Unit A のマージ前コミット+push フローはユーザー操作を含むため、`automation_mode=semi_auto` でも `AskUserQuestion` が必要
- メタ開発時の bash コマンド置換（`$()`）禁止ルールが引き続き適用

### 運用上の制約

- Unit B の動作確認は本サイクル自体の PR で行う（`skills/aidlc/scripts/*.sh` のみ変更する小さな動作確認 PR を別立てする選択肢もある）
- Unit C の動作確認（Squash 誤省略の再発防止）は文書改訂で完了とし、実運用での検証は後続サイクルで自然に実施

### 後方互換性

- Unit A の修正は Operations 7.13 のフロー拡張（ガード追加）であり、既存の `merge_method=merge` / `squash` / `rebase` 固定設定の PR には影響しない
- Unit B の修正は check 名を維持するため、Branch protection 設定変更は不要
- Unit C / D / E はすべて Markdown 手順書改訂であり、実行系への影響なし

## 不明点と質問（Inception Phase中に記録）

[Question] Unit B の空ジョブ PASS 方式の具体設計（別 job 追加 / 既存 job 内の step 追加）はどちらを採用するか？
[Answer] Construction Phase の設計レビュー時に決定する。Intent 段階では「常に空ジョブで PASS を返す方式」と方針レベルで固定し、具体設計は Unit B の設計フェーズで 2 案から選定する。

[Question] Unit A のガード手順で、`automation_mode=semi_auto` のセミオートゲート扱いをどうするか？（AskUserQuestion は常に対話必須か）
[Answer] ユーザー選択は常に `AskUserQuestion`（SKILL.md「AskUserQuestion 使用ルール」の「ユーザー選択」種別）。semi_auto でも対話必須。

[Question] 既存コード分析（Reverse Engineering）の範囲をどうするか？
[Answer] メタ開発リポジトリかつ限定スコープのため、影響範囲に絞ったミニマル分析を `requirements/existing_analysis.md` に記録する。対象は `skills/aidlc/steps/operations/04-completion.md` / `02-deploy.md`、`.github/workflows/pr-check.yml` / `migration-tests.yml` / `skill-reference-check.yml`、`skills/aidlc/steps/construction/04-completion.md`、`steps/common/commit-flow.md`、`skills/aidlc-setup/steps/01-detect.md`、`skills/aidlc/steps/inception/02-preparation.md` / `05-completion.md`、`skills/aidlc/steps/operations/01-setup.md` / `04-completion.md`。フル分析（4セクション網羅）は本サイクル外。

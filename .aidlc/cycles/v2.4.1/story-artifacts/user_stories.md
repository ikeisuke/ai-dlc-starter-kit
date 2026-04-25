# ユーザーストーリー

## Epic: v2.4.1 patch — merge/CI フロー堅牢化 + Markdown 手順書明確化

対象 Issue: #601 / #598 / #594 / #600 / #602

---

### ストーリー 1: merge_method 設定保存が PR に追従する
**優先順位**: Must-have

As a メタ開発者（Operations Phase を実行する AI-DLC 利用者）
I want to Operations 7.13 の `merge_method=ask` フローで選んだ「設定を保存する」が、マージ前に PR へ反映されるようガイドされる
So that PR マージ後に `.aidlc/config.toml` の設定変更が未コミットで残らず、follow-up PR の手動作成に追い込まれない

**受け入れ基準**:
- [ ] `operations-release.md` §7.13 の `write-config.sh` 実行直後に「未コミット差分検出ガード」が追加されており、`.aidlc/config.toml` の差分を検出した場合に `AskUserQuestion` で「コミット+push する / follow-up PR で対応する / 破棄する」の3択が提示される
- [ ] 「コミット+push」選択時の手順（`git add .aidlc/config.toml` → `git commit` → `git push`）が手順書に明示されている
- [ ] 「follow-up PR」選択時の手順（`git stash` → 新ブランチ作成 → コミット → PR 作成）が手順書に明示され、作成した PR 番号を `history/operations.md` に追記する指示が含まれる
- [ ] 「破棄」選択時の手順（`git restore .aidlc/config.toml` → `git status` で差分ゼロ確認）が手順書に明示されている
- [ ] すべての選択肢でマージ実行に進む前の終了条件が明記されている（PR 反映確認 / follow-up PR 番号記録 / 差分ゼロ確認）
- [ ] 「案B（マージ前コミット+push フロー明示）」を採用した旨が手順書内のコメントまたは説明文に残されている（AIエージェントが誤解釈しない）

**技術的考慮事項**:
- `AskUserQuestion` は SKILL.md「ユーザー選択」種別のため `automation_mode` に関わらず必須
- jailrun v0.3.1 の実運用事例（`git stash` → tag → 新ブランチ follow-up PR）をリファレンスケースとして手順内に引用可能
- §7.13 直後には「マージ実行確認」ステップがあるため、本ガードはその前に差し込む

---

### ストーリー 2: 必須 Checks が paths フィルタ / Draft skip 下でも PASS 報告される
**優先順位**: Must-have

As a メタ開発者（および AI-DLC 利用者の両方）
I want to `pr-check.yml` / `migration-tests.yml` / `skill-reference-check.yml` の 3 workflow が paths フィルタ非該当・Draft 中・Draft→Ready 遷移後のどのケースでも required check を PASS 状態で報告する
So that Branch protection の required checks で PR が "Expected — Waiting for status to be reported" のまま merge 不可になる事象を解消し、admin override を不要にする

**受け入れ基準**:
- [ ] `paths` フィルタ非該当の PR（例: `skills/aidlc/scripts/*.sh` のみ変更）で 3 workflow の required check が PASS 状態で報告される
- [ ] Draft 状態の PR でも required check が PASS 状態（スキップ扱いではなく conclusion success）で報告される
- [ ] Draft → Ready 遷移後の PR で required check が PASS 状態で報告される
- [ ] **対象ジョブが実際に失敗したときは required check が FAIL として報告され、merge blocker として機能する**（skip 時は success、実失敗時は failure と明確に分岐する）
- [ ] Branch protection の required checks 一覧を変更せず、既存の check 名（`Markdown Lint` / `Bash Substitution Check` / `Defaults TOML Sync Check` / `Migration Script Tests` / `Skill Reference Check`）を維持する
- [ ] v2.3.6 で導入した Draft skip による runner 課金抑制効果が維持される（対象ジョブ本体は skip されるか、ごく軽量な報告処理のみが実行される）
- [ ] **検証ケース1（workflow 変更系）**: 本サイクル自体の PR（`.github/workflows/*.yml` の変更を含む）で各 workflow の required check が PASS 報告され、admin override なしで merge 可能である
- [ ] **検証ケース2（paths 非該当）**: `skills/aidlc/scripts/*.sh` のみ変更するダミー PR または同等条件を再現した検証（例: paths 非該当を意図したテストコミット）で required check の PASS 報告が成立することを Operations Phase 実施前までに確認する

**技術的考慮事項**:
- 実装方式は Construction Phase の設計レビューで以下2案から選定（outcome は同一）:
  - 案1: 独立の報告 job を追加し、対象ジョブ結果を受けて check 名で PASS/FAIL を報告
  - 案2: 対象ジョブ側で `if:` による skip 条件下に常に PASS を返す step を追加
- check 名を変えないため、Branch protection 設定の更新は不要

---

### ストーリー 3: Construction Squash ステップが誤省略されない
**優先順位**: Must-have

As a AI-DLC 利用者（Construction Phase で Unit 完了処理を実行する AI エージェント含む）
I want to `squash_enabled=true` が設定されているときに Construction Phase の Squash ステップが必須として扱われ、AI エージェントが誤って「オプション」と解釈してスキップしない
So that Unit 完了時のコミット履歴が散らばったまま放置される事故を防げる

**受け入れ基準**:
- [ ] `steps/common/commit-flow.md` の「Squash統合フロー」冒頭に前提チェックセクションが追加され、`rules.git.squash_enabled` を確認し `false` または未設定時は `squash:skipped:disabled` を返してフロー終了するよう記述されている
- [ ] `rules.git.squash_enabled=true` の場合は次のステップに進む旨が同セクションで明示されている
- [ ] `steps/construction/04-completion.md` ステップ 7 の見出しから「【オプション】」ラベルが除去されている
- [ ] 同ステップに「`squash_enabled=true` の場合は必須」と明記されている
- [ ] `skills/squash-unit/SKILL.md` 側には分岐ロジックを追加せず、呼び出し側が分岐責任を持つ現行設計が維持されている

**技術的考慮事項**:
- `squash:success` / `squash:skipped` / `squash:error` の既存シグナルフローは維持
- visitory プロジェクトの Unit 003（14 コミット散在）/ Unit 004 の誤省略事例を背景として反映するが、ガイドへのケーススタディ追加は本サイクル外

---

### ストーリー 4: aidlc-setup 01-detect が複数条件を独立評価する
**優先順位**: Should-have

As a AI-DLC 利用者（`/aidlc setup` を実行する AI エージェント含む）
I want to `skills/aidlc-setup/steps/01-detect.md` セクション1「早期判定」で 3 条件（セットアップ済み / v1 移行 / 初回）を `&&` / `||` チェーンで束ねず、独立に評価する指針が明示される
So that `.aidlc/` 不在時に `&&` 短絡評価で v1 残骸の検出が漏れ、誤って「初回セットアップ」と判定する事故が再発しない

**受け入れ基準**:
- [ ] `skills/aidlc-setup/steps/01-detect.md` セクション1 に、3 条件を独立に `test -f` 等で評価する具体コマンド例が追加されている
- [ ] `&&` / `||` チェーンが早期終了により検出漏れを起こすため禁止である旨の注意書きが同セクションに追加されている
- [ ] 既存の CASE_1 / CASE_2 / CASE_3 の分類ロジックは変更されていない（記述の追加のみ）
- [ ] ikeisuke/norigoro で発生した誤判定事例（`.aidlc/` 不在 → `&&` 短絡で v1 検出漏れ）が reference として短く記述されている

**技術的考慮事項**:
- 本 Issue はドキュメント改訂のみで完了。判定スクリプト（もしあれば）の実装変更は不要
- 追記位置は「早期判定」セクション内で、既存の 3 条件リストの直後に「独立チェックの実装指針」小見出しを設ける

---

### ストーリー 5: Milestone step.md が白紙 subagent でも読解できる
**優先順位**: Should-have

As a AI-DLC 利用者（およびメタ開発者）
I want to v2.4.0 で追加された Milestone 関連 step.md 4 ファイルの不明瞭点が解消され、構造審査で指摘された箇所が読解可能になる
So that Inception/Operations Phase の Milestone 操作を AI エージェントが初回から正しく実行できる

**受け入れ基準**:
- [ ] `skills/aidlc/steps/inception/02-preparation.md` §16 の Issue 選択「1を選択」直後に、「選択結果を改行区切りで `SELECTED_ISSUES` として保持する」を 1 行追記
- [ ] 同 §16 で `MILESTONE_ENABLED` ガードと `SELECTED_ISSUES` 空時の挙動の結合関係が明示されている（期待挙動: `MILESTONE_ENABLED=true` かつ `SELECTED_ISSUES` が非空のときのみ early-link スクリプトを呼ぶ。`SELECTED_ISSUES` が空のときは呼び出し側で early-link をスキップする）
- [ ] `skills/aidlc/steps/inception/05-completion.md` §1 に `MILESTONE_NUMBER` の抽出例（grep/sed/awk いずれか）が追加されている
- [ ] `skills/aidlc/steps/operations/01-setup.md` §11 のサブ見出し `11-1 / 11-2 / 11-3` に「（setup-step11 内部処理）」注記が併記、または段階表現に変更されている
- [ ] `skills/aidlc/steps/operations/04-completion.md` §5.5 の他 3 ファイルとの相互参照が整合している（他3ファイルの改訂に伴う参照切れ・記述ズレがない）

**技術的考慮事項**:
- 構造審査は empirical-prompt-tuning 由来。審査対象の Trace 評価上、§5.5 自体は all OK だが引用整合の確認が必要
- ファイル改訂は最小修正案（1行追記 / 見出し併記 / 抽出例追加）のみで完了可能

# ユーザーストーリー

## Epic 1: GitHub Milestone 運用本採用（#597 Unit A-C）

### ストーリー 1: Inception での Milestone 作成・紐付け（Unit B 由来）

**優先順位**: Must-have

As a AI-DLC を使う開発者（メタ開発者・利用者の両方）
I want to サイクルバージョン確定時に Inception Phase の Markdown 手順に従って Milestone を作成し、対象 Issue（backlog / feedback）を紐付けたい
So that サイクル開始段階でサイクル進捗の可視化が標準で得られ、`cycle:v*` ラベル運用に依存せずに「どの Issue がこのサイクルで着地予定か」が GitHub 上で一目で把握できる

**受け入れ基準**:

- [ ] `skills/aidlc/steps/inception/02-preparation.md` ステップ16 から「サイクルラベル付与」記述（`scripts/label-cycle-issues.sh` 呼び出し）が削除され、Milestone 紐付け手順（`gh api --method PATCH repos/OWNER/REPO/issues/NUMBER -F milestone=N`）に置換されている
- [ ] `skills/aidlc/steps/inception/05-completion.md` ステップ1「サイクルラベル作成・Issue紐付け」が削除され、Milestone 作成手順（`gh api repos/OWNER/REPO/milestones --method POST -f title=vX.Y.Z`）に置換されている
- [ ] `gh issue edit --milestone` がトークンスコープで失敗するケース向けに `gh api --method PATCH repos/OWNER/REPO/issues/NUMBER -F milestone=N` フォールバック手順がステップ内に明示されている
- [ ] AI/人間が Inception Phase の Markdown 手順に従って `gh api` を順次実行することで、対話なしで Milestone 作成と対象 Issue の紐付けが完了する（専用スクリプト自動実行は本サイクル対象外）
- [ ] **v2.4.0 サイクル自身は本ストーリーの自動手順を適用しない**（自己参照回避。v2.4.0 Milestone は Inception 完了処理の運用タスクとして手動で作成する。本ストーリーの Markdown 手順は v2.5.0 以降の新規サイクルから標準手順として適用される）

**技術的考慮事項**:
- `gh milestone` サブコマンドは存在しないため REST API 直叩き
- 1 Issue = 1 Milestone 制約（GitHub 仕様）

---

### ストーリー 2: Operations での Milestone close + 紐付け確認（Unit A 由来）

**優先順位**: Must-have

As a AI-DLC を使う開発者
I want to サイクル完了時に Operations Phase の Markdown 手順に従って対象 PR/Issue の Milestone 紐付けを確認し、Milestone を close したい
So that サイクル完了が GitHub Milestone の close 状態として可視化され、進捗バー 100% complete でリリース完了が明確に伝わる

**受け入れ基準**:

- [ ] `skills/aidlc/steps/operations/` の該当ステップ（`02-deploy.md` / `03-release.md` / `04-completion.md` / `operations-release.md` のいずれか適切な箇所）に、Milestone 紐付け確認手順と close 手順が追加されている
- [ ] close 手順は `gh api repos/OWNER/REPO/milestones/{number} --method PATCH -f state=closed` を使用し、対話なしで実行可能
- [ ] 紐付け確認手順は `gh api --method PATCH repos/OWNER/REPO/issues/NUMBER -F milestone=N` を使用し、不足している紐付けを追加可能
- [ ] **Milestone 作成は Unit B 責務であり、Unit A は通常作成しない**。以下の判定規則を**この優先順位**で評価し、最初に該当した規則のみを適用する（重複や逆転を防ぐため一本化）:
  1. 対象タイトル（`{{CYCLE}}`）の **closed Milestone が 1 件以上**（open の有無を問わず） → **エラー停止**（誤再オープンを避けるため、手動判断を要求。同名 closed Milestone がある場合の意図確認を必須化）
  2. 上記非該当 かつ open Milestone が **2 件以上** → **エラー停止**（手動修正が必要、`gh api repos/OWNER/REPO/milestones --state all` で重複候補を提示し、ユーザーに対応を依頼）
  3. 上記非該当 かつ open Milestone が **1 件** → **再利用**（追加作成しない、既存 number を取得して以降の手順で使用）
  4. 上記非該当（open / closed どちらも 0 件） → **fallback 作成**（`gh api repos/OWNER/REPO/milestones --method POST -f title=vX.Y.Z`）+ 警告メッセージ「Milestone vX.Y.Z が不在です。Inception スキップ漏れの可能性があります。fallback で作成します。」
- [ ] `gh api` 失敗時（HTTP 4xx/5xx）は close 操作を実行せず、警告メッセージ「Milestone close 失敗: {API エラー詳細}。手動で `gh api repos/OWNER/REPO/milestones/{number} --method PATCH -f state=closed` を実行してください」を表示してステップを中断する（誤った成功扱いを避ける）
- [ ] fallback 作成が発火する条件・close 中断条件・各警告メッセージのテキストがステップ内に明示されている（実装者が解釈で補わずに済むレベル）

**技術的考慮事項**:
- マージ前完結ルール（v2.3.5 由来）に整合させること（`progress.md` 固定スロットの更新タイミングと矛盾しない位置に Milestone close 手順を配置する）

---

### ストーリー 3: ドキュメント更新によるユーザー周知（Unit C 由来）

**優先順位**: Must-have

As a AI-DLC を初めて使う / アップグレードする開発者
I want to 公開ドキュメント（docs/, README, guides, rules.md）でサイクル運用が Milestone ベースであることを把握したい
So that ラベル運用の旧記述を信じて誤操作することなく、本採用された Milestone 運用を最初から正しく理解できる

**受け入れ基準**:

- [ ] `docs/configuration.md` のサイクル運用セクションのラベル参照（`cycle:v*` 言及・`label-cycle-issues.sh` 言及）が Milestone 参照に書き換えられている
- [ ] `README.md` のサイクル運用記述箇所が Milestone 運用前提に更新されている。**Milestone 進捗バッジ（shields.io 等）は v2.4.0 では追加しない**（追加検討は v2.5.0 以降のバックログ）
- [ ] `skills/aidlc/guides/issue-management.md` のサイクルラベル付与記述（「`cycle:v*` ラベル」言及・`label-cycle-issues.sh` 呼び出し）が Milestone 紐付け手順に書き換えられている
- [ ] `skills/aidlc/guides/backlog-management.md` を更新する: 「Backlog（Milestone 未割当）」の運用説明を追加、サイクル開始時の Milestone 紐付けフローを記述
- [ ] `skills/aidlc/guides/backlog-registration.md` を更新する: 新規 Issue 登録時に Milestone 未割当を初期状態とする旨を明記
- [ ] `skills/aidlc/guides/glossary.md` に「Milestone」エントリを追加（GitHub Milestone を AI-DLC のサイクル管理単位として用いる定義）し、「サイクルラベル」エントリは「v2.4.0 で deprecated、Milestone に置換」の注記付きで残置
- [ ] `skills/aidlc/rules.md` の運用ルール記述が、サイクル運用前提を Milestone に書き換えられている
- [ ] **旧サイクル（v2.3.6 以前）の併記は残さない**: 公開ドキュメントは v2.4.0 以降の Milestone 運用に統一し、過去サイクルの追跡は CHANGELOG / `.aidlc/cycles/v*/` ディレクトリ / `cycle:v*` ラベル（deprecated だが物理残置）で行うことを CHANGELOG（v2.4.0 リリースノート）に明記する

**技術的考慮事項**:
- 公開ドキュメントの統一（旧記述を残さない）方針は、Unit C の設計レビュー時に既存ガイド照合ルール（`skills/aidlc/rules.md`）に基づき、過剰な互換記述が混入しないよう確認する

---

### ストーリー 4: cycle-label.sh / label-cycle-issues.sh の deprecated 化（Unit B 由来）

**優先順位**: Must-have

As a AI-DLC のメンテナ
I want to サイクルラベル系スクリプト（`cycle-label.sh` / `label-cycle-issues.sh`）が deprecated として明示され、フローから呼び出されない状態にしたい
So that 物理削除を後続サイクル（Unit E）で安全に実施するための準備が整い、誤って新規呼び出しが追加されるリスクを抑えられる

**受け入れ基準**:

- [ ] `skills/aidlc/scripts/cycle-label.sh` のスクリプト先頭コメントに「DEPRECATED: v2.4.0 で非推奨化、物理削除は Unit E で実施予定」が記載されている
- [ ] `skills/aidlc/scripts/label-cycle-issues.sh` のスクリプト先頭コメントに同様の deprecation 記述が追加されている
- [ ] **CHANGELOG への両スクリプト deprecation 記載は Unit 007 へ委譲済み**（CHANGELOG `#597` 節は Unit 007 が排他所有）。本ストーリー（Unit 005）はスクリプト先頭コメントへの DEPRECATED 注記のみを担当する
- [ ] Inception Phase の Markdown ステップ（02-preparation.md / 05-completion.md）からの呼び出しが削除されている（ストーリー 1 と整合）
- [ ] 物理削除は本サイクル対象外（Unit E（後続サイクル）で実施）

---

## Epic 2: patch バンドル（#595 / #596 / #588）

### ストーリー 5: aidlc-setup の prompts/package/ 遺物削除（#595）

**優先順位**: Must-have

As a メタ開発者（ai-dlc-starter-kit 自体の開発者）
I want to aidlc-setup スキルの v1 遺物（`prompts/package/` ディレクトリへの言及）を削除したい
So that メタ開発判定が現行構成（v2.0.5 以降のプラグイン構成）に整合し、起動時の判定混乱が解消される

**受け入れ基準**:

- [ ] **本ストーリーの方針は「純削除」に固定**: `skills/aidlc-setup/steps/01-detect.md:89-91`（プロジェクトルート相対）の「メタ開発モード: `prompts/package/` ディレクトリが存在する場合」記述を削除する（代替判定条件への書き換えは本ストーリー対象外）
- [ ] 削除後の動作確認: aidlc-setup スキルを (a) メタ開発リポジトリの dev worktree 内（`.aidlc/config.toml` あり）、(b) 外部プロジェクト想定のテスト用ディレクトリで `.aidlc/config.toml` あり、(c) 同 `.aidlc/config.toml` なし、の 3 ケースで起動し、それぞれ期待される判定（(a) setup 済み遷移、(b) setup 済み遷移、(c) 新規 setup 案内）が表示されることを目視確認する。メタ開発モード判定の言及が出力に含まれないことも合わせて確認する
- [ ] CHANGELOG（v2.4.0 リリースノート）に「`skills/aidlc-setup/steps/01-detect.md` から `prompts/package/` 言及を純削除（代替判定条件は追加しない）」を明記する
- [ ] 代替判定条件（例: `version.txt` + `.claude-plugin/` ベース）の追加は本ストーリー対象外。必要性が確認された場合は **別 Issue / 別ストーリー（v2.5.0 以降のバックログ）** で扱う旨を CHANGELOG または GitHub Issue（後続バックログ Issue を起票）に記録する

**技術的考慮事項**:
- 関連 PR #449（`prompts/package/` 削除 PR）と CHANGELOG L471-473 の参照リンクをコミットメッセージに含める

---

### ストーリー 6a: update-version.sh のスクリプト挙動変更（#596 実装側）

**優先順位**: Must-have

As a メタ開発者
I want to `bin/update-version.sh` がリリース時に `.aidlc/config.toml.starter_kit_version` を上書きしないようにしたい（スクリプト本体の挙動変更）
So that メタ開発時のバージョン三角検証（local / skill / remote）が正しく機能し、メタ開発リポジトリでもアップグレードフローが試験可能になる

**受け入れ基準**:

- [ ] `bin/update-version.sh` の更新対象から `.aidlc/config.toml` の `starter_kit_version` 書き込みが削除されている（`version.txt` と `skills/*/version.txt` のみ更新）
- [ ] `bin/update-version.sh` の dry-run 出力から `aidlc_toml_current` / `aidlc_toml_new` 行が削除されている（`grep -E '^aidlc_toml_(current\|new):' <output>` が 0 行を返すことで確認）
- [ ] `bin/update-version.sh` の成功出力から `aidlc_toml:${VERSION}` 行が削除されている（`grep -E '^aidlc_toml:' <output>` が 0 行を返すことで確認）
- [ ] `.aidlc/config.toml` 関連のテンポラリファイル / バックアップ / ロールバック処理が削除されている（`version.txt` / `skills/*/version.txt` のみ対象）
- [ ] `.aidlc/config.toml` の存在チェック（`config-toml-not-found` エラー）は引き続き残置（リポジトリ整合性検証目的、入力読み取りのみ）
- [ ] **回帰確認**: メタ開発リポジトリで `bin/update-version.sh --version v9.9.9 --dry-run` を実行し、stdout に `version_txt_*` / `skill_aidlc_version_*` / `skill_setup_version_*` 行は含まれ、`aidlc_toml_*` 行は含まれないことを目視確認（`.aidlc/config.toml` が変更対象から外れていることを担保）
- [ ] **既存テスト追従**: `bin/update-version.sh` の既存テスト（`scripts/tests/` または `bin/tests/` 配下にあれば）の期待出力フォーマットが新仕様に追従している。テストが存在しない場合は、その旨を Construction Phase の Unit 計画で明記し、本ストーリーで新規テストを追加するかを決定する

---

### ストーリー 6b: update-version.sh 仕様変更のドキュメント・周知（#596 周知側）

**優先順位**: Must-have

As a AI-DLC 利用者・メタ開発者
I want to `bin/update-version.sh` の hidden breaking change（`.aidlc/config.toml` 上書き廃止 + `aidlc_toml_*` 出力削除）を CHANGELOG / `bin/update-version.sh` 先頭コメント / 設計ドキュメント（rules.md, configuration.md）で把握したい
So that スクリプトの出力に依存している自動化や手順書を持つ利用者が、v2.4.0 アップグレード時に追従修正できる

**受け入れ基準**:

- [ ] CHANGELOG（v2.4.0 リリースノート）に hidden breaking change として明記されている。記載項目は以下の 2 点を含むこと:
  - 「`bin/update-version.sh` の更新対象から `.aidlc/config.toml.starter_kit_version` を除外」
  - 「`bin/update-version.sh` の出力フォーマットから `aidlc_toml_current` / `aidlc_toml_new` / `aidlc_toml:${VERSION}` 行を削除」
- [ ] `bin/update-version.sh` のスクリプト先頭コメントにある「更新対象」リストが新仕様に追従している（`.aidlc/config.toml` の行が削除されている）。**README は本ストーリー対象外**（Milestone 関連の README 更新はストーリー 3 / Unit 007 が所有）
- [ ] `starter_kit_version` の正規の書き換え経路は `aidlc-setup` / `aidlc-migrate` / 将来のアップグレード経路に限定される設計が、`skills/aidlc/rules.md` の「カスタムワークフロー > バージョンファイル更新」セクションまたは新規の `guides/version-management.md`（必要時）で明文化されている
- [ ] `docs/configuration.md` に `starter_kit_version` の意味と書き換え経路に関する記述があれば、新設計に追従している（既存記述がない場合は追加要否を Construction Phase 設計時に判断）

---

### ストーリー 7: pr-ready の closes_list 空配列 bug 修正（#588）

**優先順位**: Must-have

As a AI-DLC 利用者
I want to 関連 Issue を持たないサイクルでも `operations-release.sh pr-ready` がスクリプト経由でエラーなく完結したい
So that ユーザーが直接 `gh pr ready` / `gh pr edit` を実行する回避策に頼らずに済み、Operations Phase のスクリプト経由完結性が保たれる

**受け入れ基準**:

- [ ] `skills/aidlc/scripts/pr-ops.sh:216-245` の `closes_list[@]` / `relates_list[@]` 空配列展開が `set -u` 環境で `unbound variable` を発生させない（`"${closes_list[@]:-}"` 形式または `[[ ${#closes_list[@]} -gt 0 ]]` ガードで囲む）
- [ ] **空配列ケース確認**: 関連 Issue がない PR 本文ファイル（`Closes #` / `Refs #` / `Relates to #` 等の trailer を含まないファイル）を fixture として用意し、`pr-ops.sh` の該当関数を直接実行 → stdout が `issues:none` / `closes:none` / `relates:none` の 3 行を含むことを目視確認（または既存テストランナーで assertion）
- [ ] **既存ケース回帰確認**: 関連 Issue を含む PR 本文ファイル fixture（例: 「Closes #100」「Refs #200, #300」を含む）を用い、stdout が `issues:#100,#200,#300` / `closes:#100` / `relates:#200,#300` 相当（実際の sort/uniq 結果に整合）となることを既存出力と diff 比較
- [ ] 既存テスト（`skills/aidlc/scripts/tests/` 配下に該当テストがあれば）で空配列ケースのカバレッジが追加されているか、新規テストファイルが追加されている。テスト不在の場合は本ストーリーで最小限の bash assertion テストを `tests/test_pr_ops_empty_lists.sh` 相当で追加する

**技術的考慮事項**:
- `set -euo pipefail` を解除する選択は採用しない（安全性のため）。配列展開側で安全化する

---

---

## サイクル運用タスク（ユーザーストーリーから降格、本サイクル限定の DR/運用メモ）

以下は v2.4.0 サイクル固有の手動運用タスクであり、ユーザーストーリーとしては扱わない（INVEST の Independent/Negotiable を弱めるため、ストーリー 1/2 に注記済み）。Inception 完了処理 / Operations 完了処理の運用チェックリストとして実行する。

### 運用タスク T1: v2.4.0 Milestone の手動運用（Inception 完了 → Operations 完了）

**位置づけ**: 自己参照回避のための運用タスク。ストーリー 1（Inception 作成）の手順は v2.4.0 自身に適用しない代わりに、以下を Inception/Operations の運用チェックリストとして実施する。

**実施項目**:

- Inception Phase 完了処理（または直後）に手動で Milestone `v2.4.0` を作成する: `gh api repos/ikeisuke/ai-dlc-starter-kit/milestones --method POST -f title=v2.4.0`
- 対象 Issue（#597 / #595 / #596 / #588）を Milestone `v2.4.0` に紐付ける: `gh api --method PATCH repos/ikeisuke/ai-dlc-starter-kit/issues/{NUMBER} -F milestone={milestone_number}`
- v2.4.0 サイクルの PR が作成されたタイミングで Milestone `v2.4.0` に紐付ける（ストーリー 2 の Operations 紐付け確認手順内で実施可能、ただし本サイクルは Markdown 手順がまだ更新前の可能性があるため運用チェックリストとして補完）
- Operations 完了時に Milestone `v2.4.0` を close する: `gh api repos/ikeisuke/ai-dlc-starter-kit/milestones/{number} --method PATCH -f state=closed`
- v2.3.6 試験運用の Milestone #1 はそのまま維持する（削除・リセットしない）

**ストーリー 1/2 との関係**:
- ストーリー 1 受け入れ基準で「v2.4.0 サイクル自身は本ストーリーの自動手順を適用しない」と注記済み
- ストーリー 2 受け入れ基準で Milestone close と紐付け確認の Markdown 手順は更新するが、v2.4.0 自身の close 実施は本運用タスクとして手動で確認する（手順書更新と運用適用の二重化を避けるため）

---

## Inception 完了時の意思決定記録対象（`inception/decisions.md` 作成計画）

Inception 完了処理（`05-completion.md` のステップ4「意思決定記録【必須チェック】」）で `.aidlc/cycles/v2.4.0/inception/decisions.md` を作成する。本サイクルで記録対象とする意思決定は以下を最低限含むこと（履歴・レビューサマリに記録があるが、`decisions.md` への束ね記録が未実施のため、Inception 完了タスクの受け入れ条件として明示する）:

| ID | タイトル | 出典 |
|----|---------|------|
| DR-001 | #596 を Unit 002（スクリプト挙動変更）と Unit 003（ドキュメント・周知）に分割した理由 | ユーザーストーリー Set 1 P2 #4 対応 |
| DR-002 | ユーザーストーリー 8（v2.4.0 自身の Milestone）を運用タスク T1 に降格した理由 | ユーザーストーリー Set 1 P1 #1 対応 |
| DR-003 | #595 を「純削除」固定（代替判定条件追加は別 Issue 化）とした理由 | ユーザーストーリー Set 1 P3 #5 / Set 2 P2 #2 対応 |
| DR-004 | Operations Phase の Milestone 不在判定を 4 段階優先順位（closed 1+→停止 / open 2+→停止 / open 1→再利用 / 両方 0→fallback 作成）に固定した理由 | ユーザーストーリー Set 1 P2 #3 / Set 2 P2 #1 対応 |
| DR-005 | `cycle-label.sh` / `label-cycle-issues.sh` を v2.4.0 では deprecated 残置とし、物理削除は後続サイクル（Unit E）に持ち越す方針の理由 | Intent / ユーザーストーリー 4 |
| DR-006 | v2.4.0 サイクル自身の Milestone を Inception 完了時に手動で作成する（自己参照回避）方針の理由 | Intent / 運用タスク T1 |
| DR-007 | #595 で代替判定条件（`version.txt` + `.claude-plugin/` ベース等）の追加を本サイクル対象外とし、別 Issue / 別ストーリー（v2.5.0 以降のバックログ）で扱う旨を CHANGELOG または GitHub Issue に記録する方針 | ユーザーストーリー Set 2 P2 #2 / Unit 004 |
| DR-008 | 公開ドキュメント（`docs/configuration.md` / `README.md` / `skills/aidlc/guides/` / `skills/aidlc/rules.md`）は v2.4.0 以降を Milestone 運用に統一し、旧サイクル（v2.3.6 以前）の運用記述は併記しない方針の理由。過去サイクル追跡は CHANGELOG / `.aidlc/cycles/v*/` / `cycle:v*` ラベル（deprecated 物理残置）で代替する判断 | ユーザーストーリー 3 / Unit 007 |

各 DR には「背景 / 選択肢（メリット・デメリット）/ 決定 / トレードオフ（得たもの・犠牲にしたもの）/ 判断根拠」を記載する（`decisions.md` 標準テンプレートに従う）。記録漏れがあれば Inception 完了処理時にユーザーへ確認すること。

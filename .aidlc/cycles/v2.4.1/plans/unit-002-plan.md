# Unit 002 実装計画: 必須 Checks の常時 PASS 報告化

## 対象

- Unit 定義: `.aidlc/cycles/v2.4.1/story-artifacts/units/002-required-checks-always-pass.md`
- 対象 Issue: #598
- 主対象ファイル:
  - `.github/workflows/pr-check.yml`（3 jobs: Markdown Lint / Bash Substitution Check / Defaults TOML Sync Check）
  - `.github/workflows/migration-tests.yml`（1 job: Migration Script Tests）
  - `.github/workflows/skill-reference-check.yml`（1 job: Skill Reference Check）
- DR 参照: DR-003（解決方針 = 常に空ジョブで PASS を返す方式、具体実装は Construction で確定）

## スコープ

3 workflow に存在する**5 つの required check**（`Markdown Lint` / `Bash Substitution Check` / `Defaults TOML Sync Check` / `Migration Script Tests` / `Skill Reference Check`）が、以下のすべてのケースで **意図した結果（PASS / FAIL）を確実に報告する** よう改修する:

- ケース A: paths 該当 + Ready PR（既存挙動を維持: 実 job 実行 → 成功なら PASS、**失敗なら FAIL**。FAIL 伝播は本 Unit でも必須要件）
- ケース B: paths 該当 + Draft PR（現状: 報告なし → 改修で **skip 扱いの PASS** 報告必須）
- ケース C: paths 非該当 + Ready PR（現状: 報告なし → 改修で **skip 扱いの PASS** 報告必須）
- ケース D: paths 非該当 + Draft PR（現状: 報告なし → 改修で **skip 扱いの PASS** 報告必須）

**設計原則**: skip 条件（B/C/D）に該当するときは PASS、実 job が起動して失敗したとき（A の異常系）は required check も FAIL を返す。「常に PASS」は skip 条件下のみで成立し、実失敗を隠蔽してはならない。

## 実装方針

### Phase 1（設計）

#### Phase 1a: 採用方式の確定（設計レビューで決定）

Unit 定義および DR-003 で「常に空ジョブで PASS を返す方式」（方針レベル）が確定済み。具体実装は以下 2 案から設計レビューで決定する。

| 案 | 概要 | メリット | デメリット |
|---|------|---------|-----------|
| **案2（本命）** 既存 workflow の job を常時起動 + 内部 step 分岐 | 既存 workflow の job-level `if:` を削除（または `paths-ignore` 化）し、job は常に起動。最初の step で paths/Draft 該当を判定し、skip 条件なら空処理（exit 0）、非該当なら従来の本処理を実行。check 名 = job 名のまま | 1 workflow に閉じる / check 名と job 名が 1:1 / **FAIL 伝播が自然**（実処理失敗 → job 失敗 → required check も FAIL）/ 同名 check 衝突なし | 既存 workflow の `if:` 削除と冒頭 step 追加が必要（既存挙動の回帰確認が必要） |
| **案1（補欠）** 別 workflow + 同名 job | 既存 workflow と同名 check 名を持つ専用 workflow（paths フィルタなし、Draft skip なし）を追加。実 job が FAIL したときに上書きしない設計が必要 | 既存 workflow に手を入れず副作用最小 | 同名 check が複数 workflow から報告されたときの最新 run 採用挙動依存 / **実 job FAIL の隠蔽リスク**（PASS job が後勝ちすると FAIL が上書きされる）/ 5 check 名分を別 workflow で重複実装 |
| **案3（除外）** 既存 job 内に skip-passing step | 既存 job 内で skip 条件下に empty step | `if:` skip された job 自体は報告されないため、Draft / paths 非該当ケースを救えない（DR-003 の方針外） — 検討対象外 |

**現時点の本命**: **案2** — FAIL 伝播が自然に成立し、check 名と job 名の 1:1 対応が維持され、同名 check 衝突リスクもない。設計レビューで案2 を中心に検討し、案1 は採用ゲートを満たす場合のみ補欠として比較する。

##### 案1 採用ゲート（補欠案として残すための条件）

案1 を採用するには以下の **3 条件すべて**を満たす必要がある。1 つでも満たせない場合は案2 を確定採用:

1. **GitHub 仕様確認**: 「Branch protection の required check が同名 check の最新 run を採用する」挙動が GitHub Actions 公式ドキュメントまたは既知の信頼できる先行事例で確認できる
2. **PASS 報告の動作確認（最小 PoC または事前検証）**: 同名 check が複数 workflow から報告されたとき、`gh pr checks` で該当 check が PASS 報告されることを確認
3. **FAIL 伝播の動作確認（最小 PoC または事前検証）**: 実 job が FAIL したときに required check も FAIL として解決され、別 workflow の PASS が後勝ちで上書き・隠蔽しないことを確認（`gh pr checks` で `fail` 報告 + branch protection で merge ブロックされることを確認）

これら 3 条件のいずれかが満たせない場合は案2（既存 workflow の job を常時起動 + 内部 step 分岐）を採用する。設計レビューで採用案を確定する前に必ず本ゲート判定を明記する。

#### Phase 1b: ドメインモデル / 論理設計

- ドメインモデル: 「PR check 状態モデル」として 5 check × 4 ケース（A〜D）の状態遷移を表現
- 論理設計: 採用案の workflow YAML 構造、`name`/`runs-on`/`steps` の最小仕様、check 名一覧、paths/Draft 条件分岐の挙動説明

### Phase 2（実装）

採用案に応じて以下のいずれかを実施:

- **案2 採用時（本命）**: 既存 3 workflow（`pr-check.yml` / `migration-tests.yml` / `skill-reference-check.yml`）の各 job について、
  - `paths:` フィルタを `paths-ignore:` に置換するか、または `paths:` を削除（trigger は常に発火）
  - job-level の `if: github.event.pull_request.draft == false` を削除（job は常に起動）
  - 各 job の冒頭に paths/Draft 判定 step を追加（例: `if: github.event.pull_request.draft == true || <paths 非該当判定>`）。skip 条件成立時は空処理 + `exit 0`、非該当時は従来の本処理 step（Checkout / 実行系コマンド）を実行
  - `permissions: contents: read` を維持
- **案1 採用時（補欠）**: `.github/workflows/required-checks-pass.yml`（仮称）を新規作成。5 つの required check 名と一致する jobs を定義し、単一 `echo` step で成功を返す。**ただし FAIL 伝播のために、本流 workflow が走る paths 該当 + Ready 状態では本 workflow を起動しない条件分岐**を含める（採用ゲート 3 条件で確認した動作仕様に従う）

### Phase 2b（検証）

- **検証ケース1（workflow 変更系）**: 本サイクル PR (#606) で `.github/workflows/*.yml` が変更されているため paths 該当となり、Draft → Ready 切替時に 5 check が PASS 報告されることを確認
- **検証ケース2（paths 非該当）**: 3 workflow すべての `paths:` フィルタに**いずれにも該当しない**変更のみを含むダミー PR を作成し、5 check が PASS 報告されることを確認
  - 3 workflow の paths まとめ:
    - `pr-check.yml`: `**.md` / `**.toml` / `.markdownlint.json` / `.github/workflows/pr-check.yml` / `bin/check-bash-substitution.sh` / `bin/check-defaults-sync.sh` / `version.txt` / `skills/**/version.txt`
    - `migration-tests.yml`: `skills/aidlc-migrate/scripts/migrate-*.sh` / `skills/aidlc-migrate/scripts/lib/**` / `tests/migration/**` / `tests/fixtures/**` / `.github/workflows/migration-tests.yml`
    - `skill-reference-check.yml`: `skills/**` / `bin/check-skill-references.sh` / `.github/workflows/skill-reference-check.yml`
  - 候補となる「3 paths すべてに非該当」な変更例: `LICENSE`（拡張子なし、3 paths のいずれにもマッチしない）、`bin/` 直下の上記 3 スクリプト以外の新規ファイル、`tests/` 配下の `migration/fixtures` 以外の新規ディレクトリ等
  - 重要: `skills/aidlc/scripts/*.sh` の変更は `skill-reference-check.yml` の `skills/**` に該当するため**ダミー PR としては不適切**
  - ダミー PR は確認後にクローズ（マージしない）
- **検証ケース3（FAIL 伝播確認）**: ケース A の異常系として、実 job が失敗するケース（例: `bin/check-bash-substitution.sh` が exit 1 を返す変更を含む PR）を 1 件作成し、required check が FAIL 報告されること（PASS 報告で隠蔽されないこと）を確認。検証後はその変更を取り消してクローズ
- 確認手段: `gh pr checks <PR番号>` の出力で各 check 名の状態（`pass` / `fail`）を確認

### Phase 3（完了処理）

- 設計／コード／統合 AI レビュー承認（review-flow.md）
- Unit 定義ファイル状態を「完了」に更新
- 履歴記録（`/write-history` で `construction_unit02.md` 追記）
- Markdownlint 実行（`.github/workflows/*.yml` は対象外だが、計画/設計成果物の `.md` を対象）
- Squash 実行（`/squash-unit` Unit 002 中間コミット統合）
- Git コミット + force-with-lease push

## 完了条件チェックリスト

- [ ] 案1 採用ゲート（3 条件: GitHub 仕様確認 + PASS 報告 PoC + FAIL 伝播 PoC）の判定結果が論理設計に明記されている
- [ ] 採用方式（案1/案2）が設計レビューで確定し論理設計に明記されている
- [ ] 5 つの required check 名（`Markdown Lint` / `Bash Substitution Check` / `Defaults TOML Sync Check` / `Migration Script Tests` / `Skill Reference Check`）がすべて維持されている
- [ ] paths 該当 + Ready の既存挙動（実 job 実行 → 成功なら PASS、失敗なら FAIL）が破壊されていない
- [ ] paths 該当 + Draft、paths 非該当 + Ready、paths 非該当 + Draft の 3 ケースで 5 check が PASS 報告される設計になっている
- [ ] **実 job 失敗時に required check が FAIL を報告する**（PASS 報告 job が成功で隠蔽しない）設計になっている
- [ ] runner 利用時間が「PASS 報告 job」分のみ追加（10 秒未満目安）に収まっている
- [ ] workflow 権限が `permissions: contents: read` 相当で維持されている
- [ ] Branch protection の required checks 一覧（check 名）に変更がない
- [ ] 検証ケース1（workflow 変更系、paths 該当 + Ready）で 5 check の PASS 報告を確認
- [ ] 検証ケース2（3 workflow いずれの paths にも非該当）で 5 check の PASS 報告を確認
- [ ] 検証ケース3（実 job 失敗）で required check が FAIL 報告されることを確認
- [ ] 設計 AI レビュー承認
- [ ] コード AI レビュー承認
- [ ] 統合 AI レビュー承認
- [ ] Unit 定義ファイル状態を「完了」に更新
- [ ] 履歴記録（`construction_unit02.md`）
- [ ] Markdownlint 実行（`markdown_lint=true`）
- [ ] Squash 実行（`squash_enabled=true`）
- [ ] Git コミット + force-with-lease push

## 依存関係

- 依存する Unit: なし（Unit 001 と独立並列実装可能）
- 依存する DR: DR-003（#598 解決方針）

## 見積もり

- Phase 1（設計）: 0.5 日（案1 採用ゲートの事前検証含む）
- Phase 2（実装）: 0.5 日
- Phase 2b（検証）: 0.5 日（検証ケース2 のダミー PR + 検証ケース3 の FAIL 伝播確認を含む）
- Phase 3（完了処理）: 0.25 日

合計: 1.75 日規模（Unit 定義の見積もり 1.5〜2 日と整合）

## リスク・留意点

- **GitHub の同名 check 名挙動（案1 採用時のリスク）**: Branch protection の required check が同名 job の最新 run を採用する仕様に依存する。実 job FAIL を別 workflow の PASS が後勝ちで上書き・隠蔽するリスクがあり、案1 を採用するには「採用ゲート」の 3 条件（仕様確認 + PASS 報告 PoC + **FAIL 伝播 PoC**）すべての確認が必須
- **`if:` skip と check 報告の関係**: GitHub Actions では job-level の `if:` で skip されたとき conclusion が `skipped` になり required check として PASS 扱いされない場合がある。案2 採用時は job-level `if:` を削除し step-level で skip 処理することで本問題を回避する
- **検証ケース2 のダミー PR**: 3 workflow いずれの `paths:` にも該当しない変更（例: `LICENSE` 末尾改行追加、`bin/` 直下の listed 以外への新規ファイル追加、`tests/` 配下の `migration` / `fixtures` 以外への新規ファイル追加など）のみを含む別ブランチで PR を作成。確認後はクローズ（マージしない）
- **既存 workflow 動作の非破壊性（案2 採用時）**: 既存 job の `if:` 削除と冒頭 step 追加により、paths 該当 + Ready 状態での本処理が正常に走ることを Phase 2b 検証ケース1 で必ず確認する
- **runner 課金**: 案2 では既存 job が常に起動するが、skip 条件下では 10 秒未満で空処理終了する設計とする。本処理は paths 該当 + Ready 時のみ走るため、v2.3.6 の Draft skip 由来の課金抑制効果は実質維持される

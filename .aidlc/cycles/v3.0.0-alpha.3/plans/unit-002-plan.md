# Unit 002 計画: work-item-next.sh（依存解決による次 work item 選定）

## 対象 Unit

- **Unit**: 002-work-item-next（依存解決による次 work item 選定）
- **サイクル**: v3.0.0-alpha.3（Phase 3）
- **依存 Unit**: なし（独立スクリプト / frontmatter 仕様は `docs/v3/data-model.md` §4 / 選定規則は §5.2 を正本）
- **関連 Issue**: なし
- **depth_level**: standard（設計フェーズあり）/ **review_mode**: required

## 目的（1 文）

`work-items/*.md` の frontmatter（status / dependencies）を走査し、依存解決規則（`docs/v3/data-model.md` §5.2）に従って次に着手可能な work item を一意に選定する読み取り専用スクリプト `work-item-next.sh` を実装する。

## 設計方針（前提認識）

- v3 の安全境界スクリプト層に属する読み取り専用ツール（状態変更しない / RFC P4）。develop フロー（Unit 003）が選定に利用する。
- 選定規則の正本は `docs/v3/data-model.md` §5.2: 新規着手候補は `status: pending` のみ、その `dependencies` が**全て `done`** の item を選定。`withdrawn` 依存先は自動充足しない（`blocked` 相当）。
- Unit 001 で新設した `work-item-validate.sh` が frontmatter スカラー抽出（`read_scalar`）・dependencies 配列パースを実装済み。**同じパースロジックを共有するか独自実装するかを設計フェーズで決定**（D1）。本 Unit は読み取り中心で frontmatter 妥当性は検証済み前提（develop は validate 済みの work-items を入力とする）だが、堅牢性のため最小限の防御は持つ。

## 主要な実装対象

1. **`skills/aidlc-v3/scripts/work-item-next.sh`**: work-items ディレクトリを走査し、各 work item の id / status / dependencies を読み取り、§5.2 規則で次候補を選定して出力する。
2. **依存解決ロジック**: pending かつ全依存が done の候補を抽出。複数候補時は id 昇順で先頭を選定（D3）。
3. **in_progress 挙動**: in_progress work item が存在する場合の扱い（resume 優先 or WARN）を定義（D2）。
4. **境界条件 (a)〜(e)**: (a) pending + 依存 done で選定 / (b) 未完了依存（pending/in_progress/blocked）は除外 / (c) withdrawn 依存は候補外（blocked 相当）/ (d) 不在 dependency ID は WARN + 候補外 / (e) 複数候補時の選定順。
5. **出力フォーマット**: 選定時 `next:<id>:<size>:<relpath>`（size 同梱で Unit 003 の tiny 確認を支援）/ 候補なし `next:none` / WARN は stderr（D4）。
6. **境界テスト**: 候補 status 規約 + (a)〜(e) を網羅する自己完結ハーネス（`mktemp -d` / Unit 001 の test 方式踏襲）。

## 設計フェーズで確定すべき主要判断

| # | 論点 | 選択肢候補 | 備考 |
|---|------|-----------|------|
| D1 | frontmatter パースの共有方針 | (a) `work-item-validate.sh` の `read_scalar` 等を共有 lib（`scripts/lib/work-item-read.sh` 等）に抽出し両者で source / (b) work-item-next.sh 内に独自の軽量パース実装 / (c) 当面は独自実装で重複許容（将来 lib 化を defer） | DRY と責務分離のトレードオフ。validate は「検証」、next は「選定」で責務が異なる。共有 lib 化は両ファイルの結合を生む。設計フェーズで確定 |
| D2 | in_progress work item がある場合の挙動 | (a) resume 優先（in_progress を次候補として返す）/ (b) WARN 表示 + pending 選定継続 / (c) in_progress を返しつつ resume シグナル出力 | develop フローの「1 件ずつ進める」前提との整合。§5.2 は新規選定のみ規定。設計で確定 |
| D3 | 複数候補時の選定 / 返却契約 | **本 Unit は script-level default として id 昇順で 1 件のみ返す**（決定的選定 / Unit 003 develop の Step 1 入力契約）。複数候補時の AI 優先度提案 + 人間選択（`workflow.md` §3.2）は **Unit 003 以降の手順層の責務**であり本スクリプトは扱わない。将来必要なら候補一覧出力（`--list` 等）を追加できる余地を残すが本 Unit では defer | 一意性を担保（決定的選定）。レビュー指摘 #1（develop の入力契約曖昧）を反映し「決定的 1 件返却」を確定 |
| D4 | 出力フォーマット | 選定時 `next:<id>:<size>:<relpath>`（**`size` を含める** = Unit 003 が tiny 確認で再パース不要 / レビュー指摘 #2）/ 候補なし `next:none` / WARN は stderr | state-*.sh / work-item-validate.sh の `key:value` 出力規約と整合。Unit 003 入力契約として size を併せて返す |
| D5 | 終了コード規約 | 0=選定 or 候補なし（`next:none`）の正常 / 1=入力エラー（ディレクトリ不在・0 件等）/ 2=システムエラー | 既存スクリプトの 0/1/2 規約と一致。**「候補なし」は正常（exit 0 + `next:none`）** とし、選定不能をエラーにしない（develop 側が none を判定して release 可能等へ分岐できる） |

> 選定規則の正本は `docs/v3/data-model.md` §5.2、frontmatter は §4。`workflow.md` §3.2（develop の work item 選定）は §5.2 を参照する。

## 完了条件チェックリスト

Unit 002「責務」から抽出:

- [ ] `work-item-next.sh` が work-items ディレクトリを走査し、各 work item の status / dependencies を読み取る
- [ ] 新規着手候補の対象 status が `pending` のみであり、依存が全て `done` の pending work item を選定する（§5.2）
- [ ] `done` / `withdrawn` / `blocked` は新規着手候補から除外される
- [ ] `withdrawn` 依存先を持つ pending item は候補外（blocked 相当 / `done` のみ自動充足 / §5.2）
- [ ] 存在しない dependency ID 参照時は WARN を出力し当該 item を候補外とする（境界 d）
- [ ] in_progress work item が存在する場合の挙動が定義・実装されている（D2 の確定方針）
- [ ] in_progress 存在時の確定方針（resume 優先 / WARN 継続）に対応する専用テスト fixture がある（レビュー指摘 #3）
- [ ] 複数候補時の選定が決定的（id 昇順で 1 件返却 / 境界 e / D3）。候補一覧・人間選択は Unit 003 手順層の責務として本 Unit スコープ外であることが明記されている
- [ ] 読み取り専用であり work item / state を変更しない（NFR）
- [ ] 選定出力に `size` が含まれ Unit 003 が tiny 確認で再パース不要（D4 / レビュー指摘 #2）
- [ ] 出力フォーマット・終了コードが既存スクリプト規約（`key:value` / 0/1/2）と整合する（候補なしは exit 0 + `next:none`）
- [ ] 境界条件 (a)〜(e) + 候補 status 規約を網羅する境界テストが自己完結ハーネスで通る
- [ ] **v2 非影響**: `skills/aidlc/`（v2）配下に変更がない（`git diff` で確認）
- [ ] `bash -n` / shellcheck（利用可能時）/ markdownlint を通過する

## 検証方針

- サンドボックス（`mktemp -d`）に work-items フィクスチャ群を構築し、§5.2 規則と境界 (a)〜(e) の選定結果をアサート（Unit 001 の test-define-flow.sh / test-state-scripts.sh 方式踏襲）。
- v2 ドッグフーディング用 `.aidlc/` は一切変更しない。
- `bash -n` / shellcheck / markdownlint。

## スコープ境界（本 Unit に含まれないもの）

- frontmatter の atomic 書き込み（`work-item-state.sh` の完全実装は後続 / 本 Unit は読み取り中心）
- develop フロー本体（Unit 003）
- release 可能判定（§5.1 評価順 4 / cycle 終端判定 / 別レイヤ）

## リスク

- **R1**: frontmatter パース共有方針（D1）未確定 → 設計レビューで確定。Unit 001 との重複/結合のトレードオフを明示。
- **R2**: in_progress 挙動（D2）が develop フロー（Unit 003）の前提と乖離するリスク → §5.2 と workflow.md §3.2 を正本に確定し、Unit 003 の入力契約と整合させる。
- **R3**: v2 `.aidlc/` 破壊リスク → サンドボックス隔離を徹底。

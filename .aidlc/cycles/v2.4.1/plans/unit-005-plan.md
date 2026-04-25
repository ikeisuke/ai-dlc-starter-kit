# Unit 005 実装計画: Milestone step.md 構造改善（4 ファイル明確化）

## 対象

- Unit 定義: `.aidlc/cycles/v2.4.1/story-artifacts/units/005-milestone-step-md-clarification.md`
- 対象 Issue: #602
- 対象ファイル（4 ファイル）:
  1. `skills/aidlc/steps/inception/02-preparation.md`（§16 Issue 選択 / Milestone 紐付け）
  2. `skills/aidlc/steps/inception/05-completion.md`（§1 Milestone 作成・Issue 紐付け）
  3. `skills/aidlc/steps/operations/01-setup.md`（§11 Milestone 紐付け確認・fallback 判定）
  4. `skills/aidlc/steps/operations/04-completion.md`（§5.5 Milestone close、相互参照整合確認のみ）

## スコープ

empirical-prompt-tuning 由来の構造審査指摘 5 件（中×1 / 低〜中×1 / 低×2 / 軽微×1）を最小修正で解消する。具体的には:

1. **02-preparation.md §16 Issue 選択直後**: 選択結果を改行区切りで `SELECTED_ISSUES` として保持する旨を 1 行追記
2. **02-preparation.md §16 ガード結合**: `MILESTONE_ENABLED=true` かつ `SELECTED_ISSUES` が非空のときのみ early-link 実行、それ以外は呼び出し側でスキップする旨を明示
3. **05-completion.md §1**: `MILESTONE_NUMBER` の抽出例（grep/sed/awk いずれか）を追加
4. **01-setup.md §11**: サブ見出し `11-1 / 11-2 / 11-3` に「（setup-step11 内部処理）」注記を併記
5. **04-completion.md §5.5**: 他 3 ファイル改訂で発生する相互参照の整合確認のみ（本体無改訂）

## 実装方針

### Phase 1（設計）

軽量化のためドメインモデルと論理設計を**単一**にまとめる（Unit 004 と同方針）。

設計内容:

- **責務マップ**: 4 ファイル × 5 指摘の対応関係表（File / 指摘 ID / 対応方法 / 改訂規模）
- **挿入位置・改訂位置の特定**（行番号は v2.4.1 改訂前の状態を基準。一意確定済み）:
  - 02-preparation.md L50 直後: 「**1を選択**」直後行に `SELECTED_ISSUES` 保持の一文を追記
  - 02-preparation.md L64 末尾（`MILESTONE_ENABLED が true の場合` 説明の延長）: AND ガード明示文を 1 項目追記
  - 02-preparation.md L93（`early-link:no-issues-provided` 既存出力）: 下位互換用である旨の注記を 1 行追記（呼び出し側ガードで実運用上は発生しないことを明示、Unit 定義 L46 整合）
  - 05-completion.md L96 直後: `MILESTONE_NUMBER` 抽出例を追加（既存「`number=<N>` を以降のステップで MILESTONE_NUMBER として扱う」の直後に具体例として配置）
  - 01-setup.md L165 / L174 / L191: 各 H4 見出し末尾に「（setup-step11 内部処理）」を併記
  - 04-completion.md §5.5: **本体無改訂**。L247「setup 側 11-1」表記の整合のみ目視確認（4 ファイル改訂後も矛盾しないこと）
- **本文仕様**:
  - 抽出例は `awk -F=` 案を採用（Unit 定義 L47「`grep "number:" | awk '{print $2}'`」例示と同方針で sed より読みやすい。ensure-create 出力の `=` 区切りに最適）
- **責任分離**: Milestone 運用仕様（opt-in ガード既定値、5 ケース判定、create/close フロー）には**触れない**（Unit 定義 L21-22 境界遵守）

### Phase 2（実装）

各ファイルを Edit ツールで個別改訂。改訂粒度の目安:

| ファイル | 想定改訂量 |
|---------|-----------|
| 02-preparation.md | +3〜4 行（SELECTED_ISSUES 保持文 + AND ガード明示文 + L93 下位互換注記） |
| 05-completion.md | +2〜3 行（MILESTONE_NUMBER 抽出例コードブロック） |
| 01-setup.md | 3 行修正（11-1/11-2/11-3 見出し注記併記） |
| 04-completion.md | 0 行（整合確認のみ） |

挿入本文（最終確定後）:

- 02-preparation.md L50 直後挿入:
  ```text
  **1を選択時の追加処理**: 選択した Issue 番号を改行区切りで `SELECTED_ISSUES` 変数として保持する（後続の Milestone 早期紐付けで `--issues "<SELECTED_ISSUES>"` に渡すため）。
  ```
- 02-preparation.md L64 末尾（`MILESTONE_ENABLED が true の場合` 説明の直後）に AND ガード明記:
  ```text
  - 上記に加えて `SELECTED_ISSUES` が非空のときのみ early-link を呼び出す。`SELECTED_ISSUES` が空の場合は呼び出し自体をスキップする（呼び出し側 AND ガード）
  ```
- 02-preparation.md L93（`early-link:no-issues-provided` 既存出力）に下位互換注記を併記:
  ```text
  - `early-link:no-issues-provided`（`SELECTED_ISSUES` が空。**下位互換用の出力**であり、呼び出し側 AND ガードにより実運用上は発生しない）
  ```
- 05-completion.md L96 直後に追記:
  ```bash
  # MILESTONE_NUMBER の抽出例（ensure-create stdout から awk で抽出）
  scripts/milestone-ops.sh ensure-create {{CYCLE}} | grep -oE 'number=[0-9]+' | awk -F= '{print $2}'
  # 例: 出力 "milestone:v2.4.1:created:number=42" → "42" のみが標準出力される
  ```
- 01-setup.md L165 / L174 / L191 の見出し改訂:
  ```diff
  - #### 11-1. Milestone 状態確認（5 ケース判定 + fallback 作成）
  + #### 11-1. Milestone 状態確認（5 ケース判定 + fallback 作成）（setup-step11 内部処理）
  - #### 11-2. 関連 Issue/PR の Milestone 紐付け確認・補完
  + #### 11-2. 関連 Issue/PR の Milestone 紐付け確認・補完（setup-step11 内部処理）
  - #### 11-3. PR の Milestone 紐付け確認
  + #### 11-3. PR の Milestone 紐付け確認（setup-step11 内部処理）
  ```

### Phase 2b（検証）

- **検証ケース 1（02-preparation.md）**: 改訂後に「`SELECTED_ISSUES`」キーで `grep`、保持文 / AND ガード明示文 / 下位互換注記の 3 箇所（既存の `<SELECTED_ISSUES>` 参照を除き）がヒットすることを確認
- **検証ケース 2（05-completion.md）**: 改訂後に `MILESTONE_NUMBER` 抽出例（`awk -F=` 等）がコードブロック内に 1 個以上含まれることを `grep` で確認
- **検証ケース 3（01-setup.md）**: 改訂後に「（setup-step11 内部処理）」が H4 見出しに 3 件含まれることを `grep -c` で確認
- **検証ケース 3b（番号維持確認）**: `grep -E '^#### 11-(1|2|3)\.' skills/aidlc/steps/operations/01-setup.md` で番号 11-1 / 11-2 / 11-3 が改訂後も保持されていることを確認（注記併記のみで番号変更なし）
- **検証ケース 4（04-completion.md）**: `git diff skills/aidlc/steps/operations/04-completion.md` で本体無改訂を確認。L247「setup 側 11-1」表記が改訂後の 01-setup.md と矛盾しないことを目視確認（4 ファイル改訂が `11-1` 番号自体を変更しないため整合維持される）
- **検証ケース 5（相互参照整合）**: 4 ファイル全体に `grep -nE 'MILESTONE_NUMBER|SELECTED_ISSUES|setup-step11|11-1|11-2|11-3'` を実行し、追加・既存の参照キーに不整合がないことを確認（04-completion.md 側のヒットは L247「setup 側 11-1」のみ想定、これが改訂後も維持されること）
- **検証ケース 6（Markdownlint）**: `scripts/run-markdownlint.sh v2.4.1` および `npx markdownlint-cli2` で対象 4 ファイルを直接 lint、改訂前後で error 数増加なし
- **境界保全**: `git diff --name-only skills/aidlc/steps/` で 4 ファイル以外（特に common/ 配下、construction/ 配下、setup-step11.sh 等のスクリプト）が無変更であることを確認
- **`$(...)` 不使用チェック**: 追加した bash 例（特に MILESTONE_NUMBER 抽出例）に `$(...)` が含まれていないことを確認（CLAUDE.md 準拠）

### Phase 3（完了処理）

- 設計 / コード / 統合 AI レビュー承認（review-flow.md、Codex usage limit のためセルフレビュー継続）
- Unit 定義ファイル状態を「完了」に更新
- 履歴記録（`/write-history` で `construction_unit05.md` 作成）
- Markdownlint 実行（`markdown_lint=true`）
- Squash 実行（`/squash-unit` Unit 005）
- Git コミット → force-with-lease push をユーザーに推奨提示

## 完了条件チェックリスト

- [ ] 02-preparation.md §16 に `SELECTED_ISSUES` 保持の一文（1を選択時の追加処理）が追記されている
- [ ] 02-preparation.md §16 に `MILESTONE_ENABLED=true` AND `SELECTED_ISSUES` 非空のときのみ early-link 実行する旨が明示されている
- [ ] 02-preparation.md L93 の `early-link:no-issues-provided` 既存出力に「下位互換用」注記が併記されている
- [ ] 05-completion.md §1 に `MILESTONE_NUMBER` の抽出例（`awk -F=` 形式の pipe one-liner）が 1 例追加されている
- [ ] 01-setup.md §11-1 / §11-2 / §11-3 の H4 見出しに「（setup-step11 内部処理）」注記が併記されている（番号 11-1 / 11-2 / 11-3 は維持）
- [ ] 04-completion.md §5.5 本体は無改訂（L247「setup 側 11-1」表記の整合のみ目視確認）
- [ ] 改訂内容の bash 例に `$(...)` が含まれていない（CLAUDE.md 準拠）
- [ ] 4 ファイル以外（common/ 配下、scripts/、shell 系）は無変更
- [ ] Markdownlint で 0 error（改訂による新規 error なし）
- [ ] 設計 AI レビュー承認（セルフレビュー）
- [ ] コード AI レビュー承認（セルフレビュー）
- [ ] 統合 AI レビュー承認（セルフレビュー）
- [ ] Unit 定義ファイル状態を「完了」に更新
- [ ] 履歴記録（`construction_unit05.md`）
- [ ] Squash 実行（`squash_enabled=true`）
- [ ] Git コミット → force-with-lease push をユーザーに推奨提示

## 依存関係

- 依存する Unit: なし（他 Unit と独立並列実装可能）
- 外部依存: なし（ドキュメント改訂のみ。既存 milestone-ops.sh / setup-step11 の挙動には触れない）

## 見積もり

- Phase 1（設計）: 0.1 日
- Phase 2（実装）: 0.1 日（4 ファイル改訂、ただし 04-completion.md は無改訂）
- Phase 2b（検証）: 0.05 日
- Phase 3（完了処理）: 0.1 日

合計: 0.35〜0.5 日規模（Unit 定義の見積もり「0.5 日規模」と整合）

## リスク・留意点

- **既存ロジック非破壊**: 5 件の指摘はすべて記述追加・注記併記レベルで、Milestone 運用仕様（opt-in ガード既定値、5 ケース判定、create/close フロー）の挙動変更を伴わない。Unit 定義 L21-22 境界遵守
- **`$(...)` 禁止の例外なし**: 追加する MILESTONE_NUMBER 抽出例は pipe ベースの one-liner 形式（`scripts/... | grep -oE ... | awk -F= ...`）を採用し、`$(...)` を使わない。AI エージェントは出力を読み取り次のステップで MILESTONE_NUMBER として扱う方針（`/squash-unit` スキルの「AI が値を事前に解決」と同方針）
- **DR-006 整合**: 本 Unit はドキュメント改訂のみで、`milestone-ops.sh` / `setup-step11` シェルスクリプトには触れない
- **04-completion.md §5.5 本体改訂しない契約**: 構造審査で all OK 判定済みのため、相互参照整合確認のみ実施（Unit 定義 L21）
- **他 Milestone 関連ドキュメント波及禁止**: `guides/issue-management.md` 等は本 Unit のスコープ外（Unit 定義 L23）
- **見出し改訂の番号維持**: `01-setup.md` §11-1 / 11-2 / 11-3 の数字は維持し、注記のみ追加。番号変更は他ファイルからの参照（`grep -rn "11-1\|11-2\|11-3"`）への副作用を伴うため、Phase 1 設計で検索結果を確認する

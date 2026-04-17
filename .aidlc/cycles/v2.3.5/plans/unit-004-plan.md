# Unit 004 実行計画: Construction 側の squash 完了後 force-push 案内追加

## 対象Unit

- **Unit 定義**: `.aidlc/cycles/v2.3.5/story-artifacts/units/004-construction-squash-push-guidance.md`
- **関連Issue**: #574（部分対応: (3) を本 Unit で担当、(1)(2) は Unit 002 で完了済み）
- **優先度**: Medium / 見積もり: S（Small）
- **依存する Unit**: Unit 002（論理依存、完了済み）

## 背景・目的

### Unit 002 完了時点の状況

Unit 002 で `validate-git.sh run_remote_sync()` に `diverged` ステータスを導入し、`operations-release.sh verify-git` のサマリも透過した。`steps/operations/01-setup.md` §6a および `operations-release.md` 7.9-7.11 で `diverged` 検出時の推奨コマンド案内・事前確認・ユーザー選択フローを実装済み。

### 残る課題（Unit 004 のスコープ）

Operations Phase 側の受け入れ体制は整ったが、**Construction Phase 側**では squash 完了後に「リモートに対して何をすべきか」の案内が不足している。具体的には:

- Construction Phase の Unit 完了時に squash-unit.sh がローカルの history を rewrite する
- squash 後、ローカル HEAD は新コミット（squash 後）を指すが、リモート (`origin/cycle/X.X.X`) は古いコミット列を保持したまま
- この状態で Operations Phase を開始すると、Unit 002 で実装した `diverged` 判定が発動する
- しかし **ユーザーはこの時点で既に `git push --force-with-lease` する選択肢があった**（Operations まで待たず、Construction 側で案内されれば squash 直後に push できる）

### 本 Unit のゴール

Construction Phase の squash 完了フローに、`git push --force-with-lease` 推奨コマンドの**静的な事前案内**を追加する。

**スコープの明確化**（レビュー指摘 #1 対応）:
- 本 Unit は **ドキュメントのみの変更**（`04-completion.md` 静的案内）
- リモート状態の動的判定（既に push 済みか否か）は行わない
- `04-completion.md` の現行シグナル（`squash:success` / `squash:skipped` / `squash:error`）で判定できる範囲に限定
- `squash:success` 時のみ案内を表示し、「既に force-push 済みの場合は本案内をスキップしてください」とユーザー向け注記を併記する
- Operations Phase 側（Unit 002）の `validate-git.sh remote-sync` による動的 diverged 検出は引き続き保険として機能（多層防御）

**Unit 002 との役割分担**（レビュー指摘 #2 対応）:

| Phase | 責務 | 推奨コマンドの由来 |
|-------|------|-----------------|
| Construction（本 Unit） | squash 直後の**静的な事前案内** | Markdown 内に推奨コマンド種別（`git push --force-with-lease`）を記述。実値は「自分の環境の remote / upstream に置換して実行」とユーザーに委ねる |
| Operations（Unit 002） | 実行時の**動的な検出と実値表示** | `validate-git.sh remote-sync` が `diverged` を検出した場合、stdout の `recommended_command:` 行の実値をそのまま表示 |

「同じ形式」ではなく「同じコマンド種別（`git push --force-with-lease`）を案内」する役割差を明記する。Construction 側では markdown にリテラルのコマンド例を書くが、Operations 側の動的生成契約とは独立したドキュメントとして扱う。

## スコープ（責務）

Unit 定義「責務」セクションの全項目を本計画のスコープとする。

- **編集対象の第一候補**: `skills/aidlc/steps/construction/04-completion.md`
- squash 完了後のフロー（ステップ 7 Squash 直後、`squash:success` 分岐内）に force-push 推奨コマンド案内を追加
- 案内表示条件: `squash:success` シグナルを受けた場合のみ表示
- 案内抑制条件: `squash:skipped` / `squash:error` の場合は表示しない
- 「既に push 済みの場合は本案内をスキップしてよい」とユーザー向け注記を併記（動的判定はしない）
- 自動実行は行わない（ユーザーが案内に従って明示的に実行する想定）
- 推奨文言: `--force-with-lease` を必ず推奨（`--force` は推奨しない）
- **事前確認の案内を必須併記**（レビュー指摘 #3 対応）:
  - `git log HEAD..<remote>/<upstream_branch>` で upstream 側の差分コミットを確認
  - `git log <remote>/<upstream_branch>..HEAD` でローカル側の差分コミットを確認
  - 上記確認後に「ローカル履歴を正として上書きしてよい」場合のみ実行する旨を明記
  - 他者コミットが含まれる可能性がある場合は実行を中止し、ユーザー判断で rebase / tracking 再設定等を検討する旨を明記

## Unit 002 仕様との関係

Unit 002 では実行時に `validate-git.sh run_remote_sync()` が以下を出力する:

```text
status:diverged
remote:<remote_name>
branch:<local_branch_name>
recommended_command:git push --force-with-lease <remote> HEAD:<upstream_branch>
```

`recommended_command:` 行は**実値**（Unit 002 の文字列契約）を含み、Operations Phase の markdown は**その実値をそのまま表示**する。Construction 側では `validate-git.sh` を呼ばないため、markdown 内に静的なコマンド例（プレースホルダー形式）を記述する。両者は独立した文書として整合するが、**文字列完全一致は目指さない**（指摘 #2 対応）。

Construction 側の記述例（設計で確定）:

```text
git push --force-with-lease <remote> HEAD:<upstream_branch>
```

ユーザーは自分の環境で `<remote>` と `<upstream_branch>` を置換して実行する。

## 変更対象ファイル（論理設計でさらに詰める）

- `skills/aidlc/steps/construction/04-completion.md`
  - ステップ 7（Squash）の `squash:success` 分岐に force-push 案内サブセクションを追加
  - 案内表示条件（`squash:success` のみ）と抑制条件（`squash:skipped` / `squash:error` / 既に push 済み）を記載
  - 推奨コマンド例（プレースホルダー形式、`--force-with-lease` 推奨、`--force` 非推奨）
  - Unit 002 の事前確認（`git log HEAD..<remote>/<upstream_branch>` と `git log <remote>/<upstream_branch>..HEAD`）を併記
  - 「他者コミットが含まれる可能性がある場合は中止」の警告を含める
- 他ファイルへの波及: 不要（Unit 定義「境界」セクションに準拠）。設計フェーズで再確認

## 設計で確定すべき論点

1. **配置**: ステップ 7（Squash）の `squash:success` 分岐内に追加（第一候補）/ ステップ 8（Gitコミット）直後（代替候補）
   - 第一候補のメリット: squash 直後で関心事が一致、`squash:success` シグナル直後に案内を自然に配置できる
   - 代替候補のメリット: Unit PR 作成（ステップ 9）の直前でまとめて案内できる
   - 設計レビューで決定

2. **文言の冗長性**: 事前確認 2 つ + 推奨コマンド + 警告文を全て含めるとセクションが長くなる。最低限のミニマル形式にトーンダウンするか、Unit 002 相当の詳細形式にするか
   - 候補 A: 詳細（Unit 002 と同等の安全基準、4-6 行）
   - 候補 B: ミニマル（推奨コマンド + 事前確認 2 行を簡潔に、3-4 行）
   - 指摘 #3 に基づき候補 A を基本方針とし、設計でトーンを確定

3. **既に push 済みの判定**: markdown 内の注記で十分か、動的判定を簡易的に入れるか
   - 計画方針: 動的判定はスコープ外とし、ユーザー向け注記（「既に force-push 済みなら本案内をスキップ」）で対応（指摘 #1 準拠）

## 完了条件チェックリスト

### ドキュメント

- [ ] `skills/aidlc/steps/construction/04-completion.md` ステップ 7 `squash:success` 分岐に force-push 案内サブセクションを追加
- [ ] 案内表示条件（`squash:success` のみ）と抑制条件を明記
- [ ] 推奨コマンド例（プレースホルダー形式）を記載
- [ ] `--force-with-lease` 推奨・`--force` 非推奨の旨を明記
- [ ] **事前確認の案内を併記**（`git log HEAD..<remote>/<upstream_branch>` と `git log <remote>/<upstream_branch>..HEAD`）
- [ ] 「他者コミットが含まれる可能性がある場合は中止」の警告を含める
- [ ] 「既に push 済みの場合は本案内をスキップしてよい」のユーザー向け注記を含める

### 整合性

- [ ] Unit 002 の `operations-release.md` 7.10 節および `01-setup.md` §6a との**役割差**を明記（Construction=静的案内、Operations=動的検出）
- [ ] 推奨コマンド種別（`git push --force-with-lease`）が Unit 002 と一致することを目視確認
- [ ] Unit 002 の事前確認観点が Construction 側にも反映されていることを目視確認

### テスト・検証

- [ ] markdownlint 実行（`markdown_lint=false` ならスキップ）
- [ ] Construction Phase 実行時に案内が期待通りに表示されるか目視確認（実スクリプトは変更しないため自動テスト不要）

### 完了基準

- [ ] 計画レビュー Codex 承認（auto_approved）
- [ ] 設計レビュー Codex 承認（auto_approved）
- [ ] コードレビュー Codex 承認（auto_approved）※ 本 Unit はドキュメントのみのため「コード」=「Markdown 変更」として扱う
- [ ] 統合レビュー Codex 承認（auto_approved）
- [ ] 設計・実装整合性チェック完了
- [ ] Unit 定義ファイルの実装状態を「完了」に更新
- [ ] 履歴記録（`/write-history`）完了
- [ ] squash 完了 → commit 完了

## 依存 / 前提

- Unit 002 完了済み（`validate-git.sh run_remote_sync()` の `diverged` ステータスと `recommended_command` 形式が確定）
- 外部スクリプト変更なし（本 Unit は markdown のみ変更）
- 動的な「既に push 済み」判定はスコープ外（Unit 002 の Operations Phase 判定が保険として機能）

## リスクと対策

| リスク | 影響 | 対策 |
|--------|------|------|
| 案内が冗長で既存フローを読みづらくする | 中 | 事前確認 + 警告 + 注記を合計 5-8 行に収める。設計でトーンを確定 |
| 推奨コマンド種別が Unit 002 と不一致 | 中 | Unit 002 の `operations-release.md` 7.10 / `01-setup.md` §6a を参照し、種別（`git push --force-with-lease`）を揃える。文字列完全一致は目指さない（指摘 #2） |
| 既に push 済みのユーザーが不必要な force-push を実行してしまう | 中 | 「既に push 済みなら本案内をスキップ」の注記を明記。事前確認で `git log` 差分を確認するよう案内 |
| 他者コミットが含まれる upstream に対して force-push し作業破壊 | 高 | 事前確認（`git log HEAD..<remote>/<upstream_branch>` と逆方向）を必須化（Unit 002 と同等の安全基準、指摘 #3） |
| `--force` を誤って推奨し他者作業を破壊するリスクを助長 | 高 | 推奨コマンドは必ず `--force-with-lease`。`--force` は推奨しない旨を明記 |
| Construction と Operations の文言が重複し保守コスト増 | 低 | 役割差を明記（Construction=静的案内、Operations=動的検出）。独立文書として扱う |

## スコープ外（Unit 定義「境界」セクション準拠）

- `operations-release.sh` の変更（Unit 002 / Unit 003 のスコープ）
- Operations Phase 側の判定変更（Unit 002 のスコープ）
- Construction Phase の squash 実装自体の変更（既存 squash フローに乗るのみ）
- `--force-with-lease` の自動実行
- 動的な「既に push 済み」判定・リモート状態検出（本 Unit はドキュメントのみ）
- `04-completion.md` 以外の Construction ステップファイルへの横展開（設計レビューで必要と判断された場合のみ許容）

## 参照

- Unit 定義: `.aidlc/cycles/v2.3.5/story-artifacts/units/004-construction-squash-push-guidance.md`
- Issue: #574（部分対応、Unit 002 と合わせて完全対応）
- Unit 002 関連ドキュメント:
  - `skills/aidlc/scripts/validate-git.sh`（`run_remote_sync` の `diverged` / `recommended_command` 契約）
  - `skills/aidlc/steps/operations/01-setup.md` §6a
  - `skills/aidlc/steps/operations/operations-release.md` 7.9-7.11 節
- 編集対象: `skills/aidlc/steps/construction/04-completion.md`

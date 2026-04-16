# Unit: Construction 側の squash 完了後の force-push 案内追加

## 概要

Construction Phase の squash 完了後のフローに、diverged が想定される場合のみ `git push --force-with-lease` 推奨コマンドを案内として表示する記述を追加する。既に push 済み or squash 未実施の場合は案内を抑制する。自動実行は行わず、ユーザーが明示的にコマンドを実行する前提とする。

## 含まれるユーザーストーリー

- ストーリー 2: リモート同期チェックが squash 後の divergence を誤検知しない（#574 (3) を担当）

## 責務

- **編集対象の第一候補**: `skills/aidlc/steps/construction/04-completion.md`（現行フローで squash と PR マージが集約されているステップファイル）。設計フェーズで追加編集が必要と判断された場合のみ、他の `steps/construction/*.md` への波及を許容する
- `steps/construction/04-completion.md` の squash 完了後のフローに、`git push --force-with-lease <remote> <branch>` 推奨コマンドの案内記述を追加
- 案内表示の条件: 「squash 実施済み」かつ「未 push」の両方を満たす場合のみ表示
- 既に push 済み（リモートが squash 後の状態と一致）の場合は案内を抑制
- squash 未実施の場合は案内を抑制
- 自動実行は行わない（ユーザーが明示的にコマンドを実行）

## 境界

- 実装対象外:
  - `operations-release.sh` の変更（Unit 002 / Unit 003 のスコープ）
  - Operations Phase 側の判定変更（Unit 002 のスコープ）
  - Construction Phase の squash 実装自体の変更（既存 squash フローに乗るのみ）
  - `--force-with-lease` の自動実行

## 依存関係

### 依存する Unit

- **Unit 002**（論理依存）: Unit 002 で導入する `diverged` ステータス仕様を前提に、Construction 側の案内文言・抑制条件を設計する。Unit 002 完了後に着手する

### 外部依存

- `git` CLI（ユーザーが案内に従って `push --force-with-lease` を実行する想定）

## 非機能要件（NFR）

- **パフォーマンス**: ドキュメント修正のみで性能影響なし
- **セキュリティ**: 案内文言で必ず `--force-with-lease` を推奨（`--force` を推奨しない）。他者コミットを破壊するリスクを抑える
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項

- **案内表示条件の実装**: Construction Phase の squash 実施直後に「squash 実施済み」フラグを持つか、または `git status` / `git log` 相当の状態確認で判定する。具体的な判定方法は設計フェーズで確定
- **コマンド例の具体性**: 案内文言には `<remote>` と `<branch>` のプレースホルダーを含め、ユーザーが自分の環境に合わせてコピー＆ペーストできる形にする
- **Unit 002 で定義される `diverged` ステータス仕様との整合性**: Operations Phase 開始時に `diverged` と判定されるパターン（squash 実施済み＋未 push）と、Construction 側の案内表示条件を一致させる
- **既存 Construction ステップファイルとの整合**: `04-completion.md` の squash と PR マージ集約箇所の流れを壊さないよう、追記のみとする。他ステップファイルへの横展開は設計フェーズで必要性を判断し、不要なら `04-completion.md` のみで完結させる

## 関連Issue

- #574（部分対応）

## 実装優先度

Medium

## 見積もり

**S（Small）** - Construction Phase のステップファイルへの追記のみ。Unit 002 で定義される `diverged` ステータスの仕様を前提とするため、単独着手は不可。変更行数は限定的。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -

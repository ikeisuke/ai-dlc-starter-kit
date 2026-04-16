# Unit: Operations 復帰判定の進捗源移行

## 概要

Operations Phase の復帰判定チェックポイント（`release_done` / `completion_done`）の参照先を `history/operations.md` から `operations/progress.md` に移行する。進捗フラグと GitHub 側の実態確認の AND で判定する二段階方式を導入し、「マージ前完結（7.7 コミット時点で全判定ソース確定）」ルールと整合させる。

## 含まれるユーザーストーリー

- ストーリー 1: Operations 復帰判定が「マージ前完結」ルールと整合する（#579）

## 責務

- `templates/operations_progress_template.md` にステップ7のサブステップ完了フラグ（少なくとも `release_done`, `completion_done` に対応するもの）を追加
- `steps/common/phase-recovery-spec.md` §5.3 の `release_done` / `completion_done` 判定仕様を、`progress.md` のフラグ + GitHub 実態確認の AND 方式に書き換える
- `steps/operations/index.md` §3 の判定チェックポイント表を新しい参照先と整合させる
- 復帰判定を呼び出す `steps/common/compaction.md` / `steps/common/session-continuity.md` の「Operations 復帰判定」記述を更新
- `steps/operations/01-setup.md` / `03-release.md` / `04-completion.md` を確認し、7.8 以降の history 追記を誘導する既存記述がないことを保証（ある場合は削除）
- `steps/operations/index.md` または該当 step に「7.7 最終コミット時点で全判定ソースが確定する」ことを肯定形で明記する（AIエージェントが誤った history 追記を行わないよう方針を明文化）
- 後方互換フロー: 旧形式（v2.3.4 以前のサイクル）で新フラグが不在の場合に従来の history.md 参照へフォールバックするロジックを設ける
- GitHub API 利用不可時の `undecidable:<reason_code>` 戻り値契約への準拠
- 失敗時の rollback 手順（progress.md フラグ再設定・後続 PR での明示的コミット等）の設計ドキュメント化

## 境界

- 実装対象外:
  - Construction Phase 復帰判定のステップレベル化（#554、別サイクル）
  - Inception Phase 復帰判定仕様の変更
  - Operations Phase の他の構造的変更（復帰判定以外）
- `operations-release.sh` / `merge-pr` の動作自体の変更（Unit 002, 003 のスコープ）

## 依存関係

### 依存する Unit

- なし

### 外部依存

- `gh` CLI（GitHub API へのアクセス、`gh pr view --json` 等）
- `git` CLI（リモート同期・PR 状態との照合に使用される場合）

## 非機能要件（NFR）

- **パフォーマンス**: 復帰判定の応答時間は現行と同等（`gh pr view` 1 回の API 呼び出し追加）
- **セキュリティ**: 新たな機密情報を扱わない。`gh` 認証トークンは既存と同じ扱い
- **スケーラビリティ**: N/A（シングルリポジトリ・シングル PR を想定）
- **可用性**: GitHub API 利用不可時は `undecidable:<reason_code>` を返し、安全にユーザー確認へフォールバック

## 技術的考慮事項

- **二段階判定方式**: progress.md の予約フラグ（7.7 コミット時点で記録）と GitHub 実態（PR Ready 状態 / マージ済み状態）の AND で「完了」と判定する。フラグのみで「完了」と扱ってはならない
- **後方互換**: 旧形式の `progress.md` には新フラグが存在しないため、読み取り時に「新フラグ不在」→「旧 history.md 参照」へ段階的フォールバックする
- **phase-recovery-spec.md §6/§8 準拠**: GitHub API 利用不可時は `undecidable:<reason_code>` を返し、`automation_mode=semi_auto` でも自動継続禁止（ユーザー確認フローへ遷移）
- **Materialized Binding**: `phase-recovery-spec.md` と `steps/operations/index.md` の整合を維持する（spec 参照トークン経由）
- **rollback 手順**: 「フラグは立っているが実行が失敗した」「実行が成功したがフラグが書かれていない」両方の不整合パターンに対する具体的な復旧手順を設計ドキュメントに記載
- **AIエージェントへの誘因排除**: 7.8 以降の history 追記を誘導する既存記述を整理し、7.4 のみが正規タイミングであることを明記

## 関連Issue

- #579

## 実装優先度

High

## 見積もり

**L（Large）** - 本サイクルで最も重い Unit。`phase-recovery-spec.md` の規範仕様変更、`operations/progress.md` テンプレート構造変更、後方互換フロー、`undecidable` 契約準拠、rollback 設計、複数ドキュメント整合（`index.md` / `compaction.md` / `session-continuity.md` / `01-setup.md` / `03-release.md` / `04-completion.md` / `operations_progress_template.md`）が含まれる。Materialized Binding の整合確認が必須。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -

# Unit: Milestone step.md 構造改善（4ファイル明確化）

## 概要

v2.4.0 で追加した Milestone 関連 step.md 4 ファイルに対する構造審査（empirical-prompt-tuning 由来）の指摘 5 件（中優先度 1 件 / 低〜中 1 件 / 低 2 件 + 軽微確認 1 件）を、最小修正案に従って解消する（#602）。

## 含まれるユーザーストーリー

- ストーリー 5: Milestone step.md が白紙 subagent でも読解できる

## 責務

- `skills/aidlc/steps/inception/02-preparation.md` §16 の Issue 選択「1を選択」直後に「選択結果を改行区切りで `SELECTED_ISSUES` として保持する」を 1 行追記
- 同 §16 で `MILESTONE_ENABLED` ガードと `SELECTED_ISSUES` 空時の挙動の結合関係を明示（期待挙動: `MILESTONE_ENABLED=true` かつ `SELECTED_ISSUES` が非空のときのみ early-link スクリプトを呼ぶ。`SELECTED_ISSUES` が空のときは呼び出し側で early-link をスキップする）
- `skills/aidlc/steps/inception/05-completion.md` §1 に `MILESTONE_NUMBER` の抽出例（grep/sed/awk いずれか）を追加
- `skills/aidlc/steps/operations/01-setup.md` §11 のサブ見出し `11-1 / 11-2 / 11-3` に「（setup-step11 内部処理）」注記を併記、または段階表現に変更
- `skills/aidlc/steps/operations/04-completion.md` §5.5 の他3ファイルとの相互参照整合を確認し、必要最小限の修正に留める

## 境界

- 構造審査で「all OK」判定の箇所（04-completion.md §5.5 の本体）は新規追加しない
- Milestone 運用自体の仕様変更（opt-in ガードのデフォルト値変更、Milestone 作成・close 手順そのものの変更）は行わない
- 他の Milestone 関連ドキュメント（例: `guides/issue-management.md`）への波及修正は本 Unit のスコープ外（ただし、4 ファイル改訂で発生する相互参照の整合確認は含む）

## 依存関係

### 依存する Unit

- なし

### 外部依存

- v2.4.0 で導入された Milestone 運用フロー（`milestone-ops.sh` early-link / setup-step11 等）
- `rules.github.milestone_enabled` 設定キー

## 非機能要件（NFR）

- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 既存の Milestone 手順が動作しているプロジェクトで記述を追加しても動作互換性が保たれる

## 技術的考慮事項

- §16 の `SELECTED_ISSUES` 構築は改行区切りリスト（`--issues "<番号1>\n<番号2>"`）を想定。bash の heredoc / 改行連結いずれで書くかは 1 パターンに絞って例示
- §16 の `MILESTONE_ENABLED` と `SELECTED_ISSUES` 空時の結合関係は AND ガード（`MILESTONE_ENABLED=true` かつ `SELECTED_ISSUES` が非空のときのみ early-link 実行、それ以外は呼び出し側でスキップ）として表現。既存スクリプトの `early-link:no-issues-provided` 出力は下位互換用（呼び出し側がガードで防ぐため、実運用上はこの出力は発生しない）として残す
- `MILESTONE_NUMBER` 抽出例は `grep "number:" | awk '{print $2}'` 等のシンプルな例に留める
- `01-setup.md` §11 のサブ見出しは番号 `11-1 / 11-2 / 11-3` を維持したまま注記を付加する案を優先（段階表現への変更は副作用（他ファイルの L165 / L174 / L191 参照への影響）を伴うため慎重に判断）

## 関連Issue

- #602

## 実装優先度

Medium

## 見積もり

4 ファイル改訂で 0.5 日規模

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-04-26
- **完了日**: 2026-04-26
- **担当**: Claude (Opus 4.7)
- **エクスプレス適格性**: -
- **適格性理由**: エクスプレスモード無効（通常フロー）

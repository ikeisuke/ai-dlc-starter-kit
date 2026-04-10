# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit v2.3.1 — Operations/Inception ワークフロー改善パッチ

## 開発の目的

**主目的**: v2.3.0 リリース中に発見した3件のワークフロー改善を実施する。

1. **#558 PRマージのユーザー判断化**: Operations Phase の PRマージ実行を `semi_auto` でも常にユーザー確認必須にする。マージは破壊的かつ不可逆な操作であり、`AskUserQuestion使用ルール` の「ユーザー選択」に分類されるべき設計不整合を修正する
2. **#559 コンパクション復帰時の不変ルール違反防止**: コンパクション復帰時にステップファイル再読み込みが省略される問題に対し、復帰検出時に通常フロー継続を禁止し `/aidlc <phase>` の再実行を必須とするガイダンスとガードを導入する
3. **#557/#551 ドラフトPR作成設定の固定化**: Inception Phase 完了時のドラフトPR作成判断を `always/never/ask` で設定可能にし、毎回の確認を省略できるようにする（重複Issue #551 を統合）

## ターゲットユーザー

AI-DLC Starter Kit を使用する開発者（メタ開発者含む）。特に semi_auto モードで運用しているユーザーと、長時間セッションでコンパクションが発生するユーザー。

## ビジネス価値

- **操作安全性向上**: PRマージという不可逆操作に対するユーザー確認の強制により、意図しないマージを防止
- **復帰信頼性向上**: コンパクション復帰時のステップファイル再読み込みを強制し、不完全な手順実行を排除
- **操作効率改善**: ドラフトPR作成の方針を設定で固定化し、毎サイクルの繰り返し確認を省略

## 成功基準

**必須基準**:
- Operations Phase ステップ 7.13 で `automation_mode=semi_auto` 時もマージ実行前に `AskUserQuestion` でユーザー確認が行われる（マージ方法の選択は `merge_method` 設定から自動決定、マージ実行の可否のみユーザー判断）
- コンパクション復帰が検出された場合、通常フロー継続が禁止され、`/aidlc <phase>` の再実行が必須となる。compaction.md の復帰フローで明示的なガードを設ける
- `.aidlc/config.toml` に `rules.git.draft_pr` キー（`always/never/ask`）が追加され、Inception Phase 完了時のドラフトPR作成判断がそれに従う。**未設定時のデフォルト値は `ask`**（現行動作と同等）。`automation_mode` との優先関係: `draft_pr` 設定が `automation_mode` より優先。`draft_pr=always` なら semi_auto/manual に関わらず自動作成、`draft_pr=ask` なら従来どおりユーザー確認

**動作保証基準**:
- `automation_mode=manual` 時: ステップ 7.13 でユーザー確認が行われる（現行と同じ）
- `automation_mode=semi_auto` 時: ステップ 7.13 でユーザー確認が追加される（変更点）、他のステップの自動承認は退行しない
- コンパクション復帰検出テスト: compaction.md 経由の復帰フローで通常フロー継続が発生しないことを確認
- `draft_pr=always/never/ask` の3値それぞれで Inception 完了時のドラフトPR作成挙動が設定に一致する
- v2.3.0 で導入したフェーズインデックス・汎用復帰判定仕様（`phase-recovery-spec.md`）のファイル構造・判定ロジックに変更がない

## スコープ

### 含まれるもの

- **#558**: `steps/operations/02-deploy.md` または `operations-release.md` のステップ 7.13 にユーザー確認ゲートを追加。`operations/index.md` の分岐ロジックセクションにPRマージのユーザー選択分類を明記
- **#559**: `steps/common/compaction.md` にコンパクション復帰検出時の通常フロー継続禁止ガードを追加（検出条件: コンパクション後のサマリーから復帰と判定された場合、動作: `/aidlc <phase>` の再実行を必須とし、再実行なしでの手順継続を禁止する指示を明記）。`steps/common/session-continuity.md` の復帰フロー説明を更新
- **#557/#551**: `config/defaults.toml` に `rules.git.draft_pr` キーを追加（デフォルト値: `ask`、有効値: `always/never/ask`）。`steps/inception/05-completion.md` のステップ5にdraft_pr設定分岐を実装（`always`: gh_status=available なら自動作成、`never`: スキップ、`ask`: 従来どおりユーザー確認）。`automation_mode` より `draft_pr` 設定が優先。#551 をクローズし #557 に統合

### 含まれないもの

- **#556 対話UI「設定に保存」選択肢**: AskUserQuestion の汎用拡張は別サイクルで検討
- **#554 Construction復帰のステップレベルCP**: Unit定義ファイル構造変更を伴うため別サイクル
- **#552 サイクルスコープ妥当性チェック**: 閾値設計が必要で小規模パッチに収まらない
- **#546 PR Closes部分対応判別**: pr-ops.sh の出力フォーマット変更を伴うため別サイクル

## 期限とマイルストーン

- Inception Phase: 本セッション中に完了
- Construction Phase: 3 Unit を段階的に実装（各Issue = 1 Unit）
- Operations Phase: v2.3.1 リリース

## 制約事項

- パッチリリースのためスコープは最小限に留める
- v2.3.0 で導入したフェーズインデックス構造・汎用復帰判定仕様（`phase-recovery-spec.md`）との整合性を維持
- 既存の `config.toml` 設定との後方互換性を維持（新キーのデフォルト値は現行動作と同等）
- メタ開発プロジェクト固有: `skills/aidlc/` 配下のスキルファイル編集が中心

## 関連 Issue

- #558: Operations Phase PRマージのユーザー判断化
- #559: コンパクション復帰時の不変ルール違反防止
- #557: ドラフトPR作成設定の固定化（クローズ対象）
- #551: ドラフトPR自動判定設定（#557 に統合してクローズ）

## 不明点と質問（Inception Phase中に記録）

（現時点で残っている不明点なし）

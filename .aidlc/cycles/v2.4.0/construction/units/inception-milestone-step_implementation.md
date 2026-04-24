# 実装記録: Unit 005 Inception Phase へ Milestone 作成ステップを追加 + cycle-label deprecation

## 実装日時

2026-04-23

## 作成・修正ファイル

### スキルステップ（修正）

- `skills/aidlc/steps/inception/02-preparation.md` L53-L62 周辺 - 「サイクルラベル付与」→「Milestone 紐付け（先行、open=1 のみ）」置換
- `skills/aidlc/steps/inception/05-completion.md` L60-L86 完了時必須ステップ1 - 「サイクルラベル作成・Issue紐付け」→「Milestone 作成・Issue 紐付け（1-1: 確認・作成 5 ケース判定 / 1-2: 一括紐付け awk 抽出 + gh issue edit + gh api PATCH フォールバック）」置換
- `skills/aidlc/steps/inception/05-completion.md` L28-L30 エクスプレスモード ステップ2 - 整合更新
- `skills/aidlc/steps/inception/index.md` L33 / L113 / L208 - 「サイクルラベル」→「Milestone（v2.4.0以降）」更新（3 箇所）

### スクリプト（DEPRECATED 注記追加、機能変更なし）

- `skills/aidlc/scripts/cycle-label.sh` L1 直後（実 L2-L9 範囲）に DEPRECATED 注記 8 行追加
- `skills/aidlc/scripts/label-cycle-issues.sh` 同様に DEPRECATED 注記 8 行追加

### 設計ドキュメント

- `.aidlc/cycles/v2.4.0/plans/unit-005-plan.md`
- `.aidlc/cycles/v2.4.0/design-artifacts/domain-models/unit_005_inception_milestone_step_domain_model.md`
- `.aidlc/cycles/v2.4.0/design-artifacts/logical-designs/unit_005_inception_milestone_step_logical_design.md`

## ビルド結果

該当なし（Markdown 編集 + シェルスクリプト先頭コメント追記のみ、機能変更なし）。`bash -n` syntax check で両スクリプト OK。

## テスト結果

自動テストなし（Markdown 編集 + シェルスクリプトコメント追記のため）。代わりに plan / logical design の動作確認手順で検証:

| 検証項目 | 結果 |
|---------|------|
| サイクルラベル in 02-preparation: 0 | OK |
| サイクルラベル in 05-completion: 0 | OK |
| サイクルラベル in index.md: 0 | OK |
| label-cycle-issues.sh in 02-preparation: 0 | OK |
| scripts/cycle-label.sh または scripts/label-cycle-issues.sh の呼び出し in 05-completion (`grep "scripts/cycle-label.sh\|scripts/label-cycle-issues.sh"`): 0 | OK（出典説明コメント `旧 label-cycle-issues.sh の extract_issue_numbers()` は呼び出しではなく文書参照、grep `scripts/...sh` プレフィックス指定で正しく除外） |
| Milestone in 02-preparation: 4 | OK（≥1） |
| Milestone 作成・Issue 紐付け in 05-completion: 2 | OK（L60 完了時必須 + L28 エクスプレス） |
| gh api POST milestones in 05-completion: 1 | OK（≥1） |
| gh api --method PATCH issues milestone in 05-completion: 1 | OK（フォールバック手順、≥1） |
| Milestone（v2.4.0以降） in index.md: 3 | OK（L33 / L113 / L208） |
| DEPRECATED 注記 in cycle-label.sh: 1 | OK |
| DEPRECATED 注記 in label-cycle-issues.sh: 1 | OK |
| set -euo pipefail 残存 (機能変更なし確認): 両スクリプトで 1 | OK |
| bash -n syntax check: 両スクリプトで OK | OK |

## コードレビュー結果

- [x] セキュリティ: OK（機密情報なし、`gh api` 呼び出しは Markdown 内で OWNER/REPO 動的解決）
- [x] コーディング規約: OK（既存 Markdown スタイル踏襲、bash コメントスタイル踏襲、表形式維持）
- [x] エラーハンドリング: 5 ケース判定で重複作成・命名衝突・混在を停止、PATCH フォールバックで権限/環境差分対応
- [x] テストカバレッジ: 該当なし（自動テスト不要、Markdown 整合性 grep + bash -n で代替）
- [x] ドキュメント: OK（plan / domain model / logical design と完全整合）

AI レビュー: plan 4 反復 + design 4 反復で auto_approved 適格達成。implementation レビューは codex で本記録の整合性を検証する反復で実施。

## 技術的な決定事項

1. **責任分離（02-preparation vs 05-completion）**: 02-preparation 側は「先行紐付け（open=1 && closed=0 のときだけ）」のオプショナル動作とし、PATCH フォールバックは 05-completion ステップ1 に集約（OWNER/REPO 動的解決を必要とするため）
2. **5 ケース判定マトリクス**: open/closed の全組み合わせ（≥2&0 / 1&0 / 0&0 / 0&≥1 / ≥1&≥1）を網羅。実装側で `CLOSED_COUNT >= 1` を最優先停止条件とすることで混在ケースも自動停止
3. **awk 抽出ロジック転記**: `label-cycle-issues.sh` の `extract_issue_numbers()` を Markdown 内に転記（対応形式 5 種維持: Closes #数字 / Fixes #数字 / 各箇条書き付き / - #数字）
4. **PATCH フォールバック自動切り替え**: `gh issue edit --milestone` 失敗時に自動的に `gh api --method PATCH` へ切り替え（権限/環境差分対応）
5. **index.md L113 表現統一**: `Milestone 紐付け（v2.4.0以降）` → `Milestone（v2.4.0以降）紐付け` に変更し、grep `Milestone（v2.4.0以降）` で 3 箇所すべてマッチするよう統一
6. **DEPRECATED 注記の挿入位置**: `#!/usr/bin/env bash` の直後、既存の `# script名 - 説明` の前に挿入（最も目立つ位置）。物理削除は v2.5.0 以降の Unit E
7. **v2.4.0 自身の自己参照回避**: 共有プロダクトの Markdown ステップは「v2.4.0 自身に適用しない」等のサイクル固有注記を持たない。v2.4.0 自身の Milestone は運用タスク T1 で実施済み
8. **CHANGELOG `#597` 節 deprecation 記載は Unit 007 へ委譲**: 本 Unit 完了報告で「Unit 007 の受け入れ基準に CHANGELOG `#597` 節 deprecation 記載追加を依頼」を明記

## 課題・改善点

なし（Unit スコープは完了。CHANGELOG `#597` 節への deprecation 記載は Unit 007 で実施）。

## 状態

**完了**

## 備考

- Issue #597 の Unit B 担当部分は本 Unit でサイクル PR (#599) マージ時に部分対応として進捗。完全 close は Unit 006（Unit A）と Unit 007（Unit C）完了後
- 影響範囲: 5 ファイル（02-preparation.md / 05-completion.md / index.md / cycle-label.sh / label-cycle-issues.sh）
- リスクレベル: Low-Medium（Markdown 編集 + コメント追記のみ、機能変更なし。v2.5.0 以降の最初のサイクルで実運用検証）
- 関連: Unit 006（Operations Phase 側 Milestone close、並列）/ Unit 007（ドキュメント更新 + CHANGELOG `#597` 節、依存後）/ Unit E（後続サイクル、deprecated スクリプト物理削除）

## Unit 007 への引き継ぎ事項【重要】

**Unit 007 の受け入れ基準に追加すべき項目**: CHANGELOG `#597` 節に以下の deprecation 記載を追加すること:

> - `skills/aidlc/scripts/cycle-label.sh` および `skills/aidlc/scripts/label-cycle-issues.sh` を v2.4.0 で非推奨化（hidden breaking change ではないが運用変更）。サイクル運用が GitHub サイクルラベルから GitHub Milestone へ移行したため、新規 Inception Phase からは呼び出されない。物理削除は後続サイクル Unit E（v2.5.0 以降）で実施予定（#597 / Unit 005 / Unit 007）

Unit 005 ではスクリプトヘッダ DEPRECATED 注記のみ追加済み（CHANGELOG への記載は Unit 007 の責務、本ファイルの「Unit 007 への引き継ぎ事項」セクションで委譲明記）。

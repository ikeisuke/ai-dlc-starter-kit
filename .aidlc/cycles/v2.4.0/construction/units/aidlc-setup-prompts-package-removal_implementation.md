# 実装記録: Unit 004 aidlc-setup の prompts/package/ 遺物純削除

## 実装日時

2026-04-23

## 作成・修正ファイル

### スキル（修正）

- `skills/aidlc-setup/steps/01-detect.md` L89-L91 削除（旧「ai-dlc-starter-kit リポジトリ内の場合」+「メタ開発モード: prompts/package」+「通常利用」3 行）+ L88/L92 連続空行を 1 行に整理（-4 行）

### ドキュメント（修正）

- `CHANGELOG.md` v2.4.0 セクション既存 `### Changed`（Unit 003 追加）の直後に `### Removed` 見出し + `#595` 節 1 項目を追加（+4 行）

### 設計ドキュメント

- `.aidlc/cycles/v2.4.0/plans/unit-004-plan.md`
- `.aidlc/cycles/v2.4.0/design-artifacts/domain-models/unit_004_aidlc_setup_prompts_package_removal_domain_model.md`
- `.aidlc/cycles/v2.4.0/design-artifacts/logical-designs/unit_004_aidlc_setup_prompts_package_removal_logical_design.md`

## ビルド結果

該当なし（マークダウン記述削除のみ）

## テスト結果

自動テストなし（ドキュメント更新のため）。代わりに動作確認手順（plan/logical design 共通）で検証:

| 検証項目 | 結果 |
|---------|------|
| (a) メタ開発リポジトリ dev worktree + config.toml あり → 早期判定 #1 前提条件成立 | OK |
| (b) 外部プロジェクト想定 + config.toml あり → 早期判定 #1 前提条件成立 | OK |
| (c) 外部プロジェクト想定 + config.toml/v1 toml なし → 早期判定 #3 前提条件成立 | OK |
| (d) ai-dlc-starter-kit ラベル付 + config.toml なし → 早期判定 #3 前提条件成立 | OK |
| 削除内容直接検証: prompts/package = 0 | OK |
| 削除内容直接検証: メタ開発モード = 0 | OK |
| 削除内容直接検証: ai-dlc-starter-kit リポジトリ内の場合 = 0 | OK |
| 早期判定見出し残存 = 1 | OK |
| 早期判定 #1 残存 = 1 | OK |
| 早期判定 #3 残存 = 1 | OK |
| CHANGELOG Unit 004 言及 = 2（既存 v2.3.6 1 + 新規 v2.4.0 1） | OK |
| CHANGELOG prompts/package = 8（既存 7 + 新規 v2.4.0 1） | OK |
| v2.4.0 セクション内 #595 = 1 | OK |

## コードレビュー結果

- [x] セキュリティ: OK（機密情報なし、純削除のみ）
- [x] コーディング規約: OK（Markdown 記述削除のみ、既存 Keep a Changelog スタイル踏襲）
- [x] エラーハンドリング: 該当なし（記述削除のみ）
- [x] テストカバレッジ: 該当なし（自動テスト不要、fixture 動作確認 + grep 整合性確認で代替）
- [x] ドキュメント: OK（plan / domain model / logical design と完全整合、Unit 003 既存コミット 2ca41bf7 とも整合）

AI レビュー: 後続 codex 反復で実施

## 技術的な決定事項

1. **純削除固定（DR-003）**: 代替判定条件（例: `version.txt` + `.claude-plugin/` ベース）の追加は本 Unit 対象外。Inception 完了処理 `inception/decisions.md` で既に決定済みで、本 Unit からは追加実施なし
2. **代替判定条件は v2.5.0 以降のバックログ（DR-007）**: 必要性が確認された場合は別 Issue で扱う旨を CHANGELOG `### Removed` 節に明記
3. **空行整理**: L88/L92 連続空行を 1 行に整理（可読性・体裁統一のため、Markdown 上は空行 2 つでもアウトラインは破綻しないため任意整形だが、ファイル全体の空行ポリシーと統一する目的で実施）
4. **CHANGELOG 配置**: Keep a Changelog 標準順序（Added / Changed / Deprecated / Removed / Fixed / Security）に準拠して `### Changed` 直後に `### Removed` を配置
5. **GitHub Issue 起票なし**: Unit 定義 L25 「CHANGELOG または GitHub Issue」の選言、CHANGELOG 記載で十分（必要性確認は将来の利用者フィードバックや Operations Phase で判断）

## 課題・改善点

なし（Unit スコープは完了）。(d) ケースの「事前ガイダンス喪失」は plan のリスク評価 Low-Medium として記録済み、CHANGELOG `### Removed` 節に挙動変化（`ai-dlc-starter-kit` クローン直後 + `.aidlc/config.toml` なし時に初回セットアップ確認プロンプトへ直接進む可能性）を明記し、通常利用では対象プロジェクトルートで実行する旨の注意も併記することで利用者への通知を確保。

## 状態

**完了**

## 備考

- Issue #595 の解消方法: 本 Unit でサイクル PR (#599) マージ時に `Closes #595` で auto-close される
- 影響範囲: 2 ファイル（`skills/aidlc-setup/steps/01-detect.md` -4 行 / `CHANGELOG.md` +4 行）
- リスクレベル: Low-Medium（純削除のみ、ただし (d) ケースで事前ガイダンス喪失。確認プロンプトが最終停止点として機能するが旧ガイダンスの代替ではない）
- 関連 PR #449（v2.0.5 で `prompts/package/` 削除）/ 関連 CHANGELOG L482（v2.0.5 削除記録）

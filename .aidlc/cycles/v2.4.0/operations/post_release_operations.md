# リリース後の運用記録

## リリース情報

- **バージョン**: v2.4.0
- **リリース日**: 2026-04-24（予定）
- **リリース内容**: GitHub Milestone 運用本採用（#597）+ patch バンドル（#588 / #595 / #596）の 3 イシュー解消

## 運用状況

メタ開発リポジトリ（AI-DLC スターターキット自体の開発）のため、稼働率・パフォーマンス・ユーザー数等の運用メトリクスは該当なし。リポジトリとしての公開（GitHub）のみが運用対象。

### 想定される運用効果

- **Milestone 運用本採用**: サイクル ↔ Milestone の 1:1 対応により、GitHub Milestones 画面でサイクル進捗（open / closed Issue 件数、完了率）が可視化される
- **`label-cycle-issues.sh` / `cycle-label.sh` deprecated**: `cycle:vX.X.X` ラベル付与スクリプト 2 本を非推奨化。新サイクルでは Inception Phase が自動で Milestone を作成・紐付け
- **Operations Phase Milestone close 自動化**: PR マージ後の `04-completion.md` ステップ 5.5 で `gh api PATCH milestones/{number} state=closed` が自動実行される

## バグ対応

### 修正済みバグ（v2.4.0）

- #588 - PR 操作スクリプトの空配列展開バグ（Unit 001）
- #595 - aidlc-setup の `prompts/package/` 遺物言及（Unit 004、純削除）
- #596 - update-version.sh の `starter_kit_version` 上書きバグ（Unit 002 + Unit 003）

### 未修正バグ

- #598 - 必須 Checks が paths フィルタ / Draft skip で発火せず PR が merge 不可になる（priority:medium、次サイクル候補）

## ユーザーフィードバック

メタ開発のため該当なし。スターターキット利用者向けの周知は CHANGELOG `[2.4.0]` 節（特に `### Deprecated` で `cycle-label.sh` / `label-cycle-issues.sh` / `cycle:vX.X.X` ラベル）で実施済み。

## 改善点の洗い出し

### v2.4.0 で持ち越した改善項目（次サイクル候補）

- **Milestone 進捗バッジの README 追加**（v2.5.0 以降のバックログ、CHANGELOG 明記済み）
- **`cycle-label.sh` / `label-cycle-issues.sh` の物理削除**（v2.5.0 以降で deprecated 期間後に検討）
- #598 PR check 不発火問題の修正

## 次期バージョンの計画

### 対象バージョン

v2.5.0 または v2.4.1（次回 Inception Phase 開始時に決定）

### 候補項目

- 既存バックログから優先度順で選定（#598 / #592 / #591 / #586 など）
- v2.4.0 の実運用で発見された改善（特に Milestone 運用周りの調整）

## 備考

- 本サイクルは Milestone 運用本採用の初回サイクル（Milestone #2 v2.4.0 として実機検証済み）
- Operations Phase 01-setup ステップ 11 / 04-completion ステップ 5.5 / index.md §2.8 補助契約は v2.5.0 以降で本格的に実運用される
- v2.4.0 自身の Milestone close は本サイクル PR マージ後に Operations Phase 04-completion ステップ 5.5 で自動実行される

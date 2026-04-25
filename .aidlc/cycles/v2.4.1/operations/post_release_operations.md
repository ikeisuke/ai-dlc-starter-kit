# リリース後の運用記録

## リリース情報

- **バージョン**: v2.4.1
- **リリース日**: 2026-04-26（予定）
- **リリース内容**: v2.4.0 以降に発見された 5 件の patch 級 Issue（#601 / #598 / #594 / #600 / #602）を同サイクルで解消し、merge フローと Markdown 手順書の堅牢性を底上げする patch リリース

## 運用状況

メタ開発リポジトリ（AI-DLC スターターキット自体の開発）のため、稼働率・パフォーマンス・ユーザー数等の運用メトリクスは該当なし。リポジトリとしての公開（GitHub）のみが運用対象。

### 想定される運用効果

- **Operations 7.13 merge_method 設定保存ガード**（Unit 001 / #601）: `merge_method=ask` のときに `gh pr merge` の選択結果（`--merge` / `--squash` / `--rebase`）を `.aidlc/config.toml` に保存するか必ずユーザーに確認するようになり、設定の暗黙上書きを防止
- **必須 Checks の常時 PASS 報告化**（Unit 002 / #598）: paths フィルタや Draft skip で発火しなかった必須 Checks がブランチ保護で merge 不可状態に陥らないよう、minimal な常時 PASS ジョブを保証
- **Construction Squash ステップの誤省略抑止**（Unit 003 / #594）: `squash_enabled=true` のときに Construction の Squash ステップを誤って省略しないよう、commit-flow.md の表現を強化
- **aidlc-setup 01-detect の独立チェック指針**（Unit 004 / #600）: aidlc-setup の検出ステップが他ステップに依存せず単独で再実行可能であることを明示し、復旧フローを単純化
- **Milestone step.md 構造改善**（Unit 005 / #602）: 03-units の Milestone 関連 4 ファイル（contract / template / examples / decisions）の責務境界を明確化し、empirical-prompt-tuning による構造審査由来の指摘を解消

## バグ対応

### 修正済みバグ（v2.4.1）

- #601 - Operations 7.13 で merge_method=ask のときに保存確認なしで `.aidlc/config.toml` を上書きする問題（Unit 001）
- #598 - 必須 Checks が paths フィルタ / Draft skip で発火せず PR が merge 不可になる問題（Unit 002）
- #594 - Construction Squash ステップが squash_enabled=true でも誤省略され得る問題（Unit 003）
- #600 - aidlc-setup 01-detect の独立性が手順上不明瞭で再実行時に他ステップ前提と誤読され得る問題（Unit 004）
- #602 - Milestone step.md の 4 ファイル構造（contract / template / examples / decisions）の責務境界が不明瞭な問題（Unit 005）

### 未修正バグ

なし（本サイクルで取り組んだ 5 件は全て Closes 対象）

## ユーザーフィードバック

メタ開発のため該当なし。スターターキット利用者向けの周知は CHANGELOG `[2.4.1]` 節（後続ステップ 7.2 で更新予定）で実施。

## 改善点の洗い出し

### v2.4.1 で持ち越した改善項目（次サイクル候補）

バックログ（GitHub Issue `label:backlog`）から継続候補:

- #605 aidlc-setup のマージ後 HEAD を origin/main と同期する処理を追加（priority:medium）
- #592 config.toml.template の個人好み項目を user-global 側に寄せる（priority:medium）
- #591 operations-release.md §7.6 / template / 02-deploy.md の明文化（priority:low）
- #590 AI-DLC に振り返りステップを追加（priority:medium）
- #586 Inception progress.md テンプレートと判定仕様の 3 層整合化リファクタ（priority:medium）
- #585 operations_progress_template.md の固定スロット追加（priority:low）
- #582 cycle 関連ファイルを別リポジトリに分離（priority:medium）
- #581 Operations 復帰判定の new_format 実装完成（priority:medium）
- 他、`label:backlog` の各 Issue を次サイクル Inception 時に優先度評価

## 次期バージョンの計画

### 対象バージョン

v2.5.0 または v2.4.2（次回 Inception Phase 開始時に決定）

### 候補項目

- 既存バックログから優先度順で選定（#605 / #592 / #591 / #590 / #586 など）
- v2.4.1 で導入した merge_method ガード・必須 Checks 常時 PASS の実運用フィードバック反映

## 備考

- 本サイクルは v2.4.0 直後の patch サイクル。Milestone v2.4.1（#3）は本サイクル PR #606 マージ後に Operations Phase 04-completion ステップ 5.5 で自動 close される
- 5 Unit すべて patch 級で、デプロイ・CI/CD・監視戦略・配布の変更はないため Operations Phase ステップ2-5 はスキップ（semi_auto auto_approved）

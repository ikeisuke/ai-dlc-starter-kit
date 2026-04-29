# リリース後の運用記録

## リリース情報

- **バージョン**: v2.5.0
- **リリース日**: 2026-04-29（予定）
- **リリース内容**: 自己改善ループ導入（#590 + #592 コア対応）
  - Unit 001 (#592 部分対応): 個人好みキー 7 種を defaults.toml に集約（4 階層設計の整理）
  - Unit 002 (#592 部分対応): aidlc-setup ウィザードで個人好み推奨案内
  - Unit 003 (#592 部分対応): aidlc-migrate で個人好みキーの user-global 移動提案
  - Unit 004 (#590 部分対応): retrospective テンプレート + Operations 自動生成（skill 起因 6 キー判定）
  - Unit 005 (#590 部分対応): mirror モード `/aidlc-feedback` 連動（下書き → AskUserQuestion → upstream Issue 起票 + URL 追記）
  - Unit 006 (#590 部分対応): 氾濫緩和（重複検出 + サイクル毎上限ガード `feedback_max_per_cycle=3`）

## バックログ整理

### 自動クローズ対象（PR #620 Closes セクション）

PR マージ時に GitHub が自動クローズする Issue。手動クローズは不要。

- #592: config.toml.template の個人好み項目を user-global 側に寄せる（4 階層設計の整理）
- #590: AI-DLC に振り返りステップを追加（自己改善ループ）

### 手動クローズ対象

なし（本サイクルで対応した Issue は全て PR の Closes セクションに記載済み）。

### 次サイクル以降に持ち越し

その他の open backlog Issue（#621, #619, #618, #617, #616, #615, #614, #586 等）は本サイクルのスコープ外。次サイクル以降で個別に対応する。

特に #621（retrospective mirror Issue の自動重複統合 workflow / GitHub Models 駆動）は本サイクル成果物（mirror モードフロー）の上位で動く後段機能であり、Unit 005 / 006 で構築した TSV 契約を継承して上位レイヤーで実装する想定。

## 監視・運用

スターターキット自体のリリースであり、ランタイム監視対象（稼働率・レスポンスタイム）は存在しない。

リリース後の動作確認方法:

1. 別ディレクトリで `aidlc setup` を実行し、新規プロジェクトで `[rules.feedback] upstream_repo` / `[rules.retrospective] feedback_max_per_cycle` が正しくデフォルト解決されることを確認
2. 既存プロジェクトで `aidlc-migrate` の v2.5.0 経路（個人好みキー移動提案）が動作することをスポット確認
3. `feedback_mode = "silent"`（既定）で Operations Phase 完了時に retrospective.md が自動生成されることを確認
4. `feedback_mode = "mirror"` 切替時に Step 5 の mirror フロー（detect → AskUserQuestion → send / record）が動作することを確認

## 既知の問題

なし。本サイクルで識別した運用バグ（#616: PR マージ前レビュー後の write-history 追加コミット漏れ）は次サイクル以降で対応予定。

## 次期バージョンの計画

未定。次サイクル開始時にバックログから優先 Issue を選定する。候補:

- #621: retrospective mirror Issue の自動重複統合 workflow（GitHub Models 駆動 / 本サイクル成果物の上位機能）
- #617: version 管理を marketplace.json に一本化（priority:high）
- #616: 7.12 PR マージ前レビュー後の write-history バグ

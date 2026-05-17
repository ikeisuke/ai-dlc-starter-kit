# リリース後の運用記録

## リリース情報

- **バージョン**: v2.6.4
- **リリース日**: 2026-05-17（予定）
- **リリース内容**: patch サイクル。Operations Phase マージ前 CI 通過確認 + 修復フローの SoT 化（Unit 001 取り下げ / v2.6.3 で実装済み）、`operations-release.sh` への `validate_cycle` 検証拡張、markdown lint 統一エントリポイント化、振り返りスキル `aidlc-retrospective` の opt-in 基盤導入

## 含まれる Unit

- **Unit 001**（取り下げ）: v2.6.3 Unit 004（#694）で完全実装済みのため取り下げ
- **Unit 002**（完了）: `operations-release.sh` への `validate_cycle` 検証拡張 — `cmd_record_release_prep_commit` 必須 / `cmd_pr_ready` 条件付き（#708）
- **Unit 003**（完了）: markdown lint 実行手段の統一エントリポイント化（`npm run lint:md` / #709）
- **Unit 004**（完了）: 振り返りスキル `aidlc-retrospective` の opt-in 基盤導入 + 後方互換確保（patch サブセット / #710）

## バックログ整理

PR #711 の `Closes` セクション記載 Issue は PR マージ時に自動クローズ:

- #694（v2.6.3 振り返り由来 / マージ前 CI 通過確認 SoT 化）
- #708（`validate_cycle` 検証拡張）
- #709（markdown lint 統一エントリポイント化）
- #710（振り返りスキル opt-in 基盤導入 / 部分対応 / 完全廃止は v2.7.0+）

その他 backlog ラベル付き Issue は次サイクル以降での対応とし、本サイクルでは現状維持。

## 次期サイクル候補

- v2.6.5 patch 候補: 直近の振り返りで抽出される改善項目
- v2.7.0 minor 候補: #710 の振り返り Issue 起票方針見直し（完全実装版）

## 備考

- 本サイクルはドッグフーディング配布物のため運用メトリクス（稼働率 / レスポンスタイム / アクティブユーザー数 等）は対象外
- Operations Phase 完了後に `/aidlc r v2.6.4` で振り返りを実施する想定

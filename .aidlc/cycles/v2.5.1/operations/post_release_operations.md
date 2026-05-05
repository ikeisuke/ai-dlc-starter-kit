# リリース後の運用記録

## リリース情報

- **バージョン**: v2.5.1
- **リリース日**: 2026-05-05（予定）
- **リリース内容**: 振り返りエコシステム総仕上げ（feedback_mode 5 値拡張 + 初回 wizard / retrospective Issue 一本化 + spool + mirror_state ラベル / 主因分類 LLM 下書き / predecessor handoff の Issue 検索化 / write-history マージ前追加コミット漏れガード）

## 含まれる Unit

- Unit 001: feedback_mode 5 値拡張 + マイグレーション + 初回 wizard
- Unit 002: retrospective Issue 一本化 + spool + mirror_state ラベル化
- Unit 003: 主因分類 LLM 下書き + 人間確認運用 + verify CLI
- Unit 004: predecessor handoff の Issue 検索化 + テンプレ物理削除
- Unit 005: write-history 追加コミット漏れガード + Unit 004 spool schema fix

## バックログ整理結果

### 自動クローズ対象（PR 628 の Closes セクション）

- #627: PR マージ時に自動クローズされる
- #616: PR マージ時に自動クローズされる

### 手動クローズ実施

- なし（対応済み Issue はすべて Closes 経由）

### バックログ保持（次サイクル以降）

- #629, #621, #619, #618, #617, #615, #614, #586, #582, #581, #573, #568, #554, #552, #545, #536, #492, #443, #442, #441, #440, #436, #405, #398, #304, #281, #31

## 運用上の注意点

- メタ開発プロジェクトのため、CI/CD・監視・配布の追加作業はなし
- `bin/check-defaults-sync.sh` および `bin/check-size.sh` はリリース準備時に実行する（`.aidlc/operations.md` のメタ開発手順参照）

## 次サイクル候補

- v2.6.0 以降のテーマ候補は #621（retrospective mirror Issue 自動重複統合 workflow）等のバックログから選定する

# Unit: markdown lint 実行手段の統一エントリポイント化

## 概要

repo 全体の markdown lint 実行手段を `npm run lint:md` の統一エントリポイント経由に固定し、AI レビュー（codex 等）/ CI / ローカル開発で同一コマンド・同一バイナリ・同一設定を参照できる状態にする。正本は `package.json` の `scripts.lint:md`。既存の `npx markdownlint-cli2` 直接呼び出しは廃止せず、統一エントリポイントから委譲する形を選択する。

## 含まれるユーザーストーリー

- ストーリー 3: markdown lint 実行手段の統一エントリポイント化（#709）

## 責務

- `package.json` の `scripts.lint:md` に統一エントリポイント定義を追加（正本）
- AI レビュー外部 CLI 実行基盤の SoT である `skills/reviewing-common/reviewing-common-base.md` の 1 箇所に統一コマンド `npm run lint:md` を明記（散在防止のため反映先を 1 箇所に固定）
- 既存 `npx markdownlint-cli2` 呼び出しと同一の設定ファイル参照（`.markdownlint-cli2.jsonc` / `.markdownlint.json` / `.markdownlintignore`）を確認
- markdownlint で新規エラー 0 件

## 境界

- `Makefile` ラッパーの追加は本 Unit 対象外（任意 / 必要時のみ）
- 既存の `npx markdownlint-cli2 ...` 直接呼び出し箇所の全置換は本 Unit 対象外（後方互換のため残す。`lint:md` 経由を「推奨」とする）
- consumer プロジェクト（Node エコシステム外）での動作保証は本 Unit 対象外（starter kit 自身のドッグフーディング動作を担保するまで）
- markdownlint-cli2 のバージョンアップグレード / 設定変更は本 Unit 対象外

## 依存関係

### 依存する Unit

- なし（独立 Unit）

### 外部依存

- `npm` / `node`（既存環境）
- `markdownlint-cli2`（既存依存）
- `package.json`（既存）

## 非機能要件（NFR）

- **再現性**: AI レビュー（codex）環境で `npm run lint:md` が `command not found` なく動作する
- **後方互換性**: 既存の `npx markdownlint-cli2` 直接呼び出しを破壊しない

## 技術的考慮事項

- `package.json` の `scripts` セクションに 1 行追加するだけの最小変更
- AI レビュー手順書への明記は SoT 化として行う（複数箇所に散らさない）
- AI エージェント Bash ツール経由の安全パターン遵守

## 関連Issue

- #709（クローズ対象）
- 検出元: v2.6.3 Unit 003 統合レビュー Round 1 指摘 #3
- 親 Issue: #698（/aidlc v 経路の再現性向上）

## 実装優先度

Medium（chore / 開発体験改善）

## 見積もり

0.5 日（最小変更 + docs 更新）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-17
- **完了日**: 2026-05-17
- **担当**: AI Agent (Claude Code)
- **エクスプレス適格性**: -
- **適格性理由**: -

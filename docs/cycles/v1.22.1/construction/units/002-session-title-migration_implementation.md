# 実装記録: Unit 002 - session-titleスキル移行

## 実装概要

session-titleスキルをai-dlc-starter-kitから削除し、外部リポジトリ（claude-skills）からのオプショナルインストールに移行した。

## 変更ファイル一覧

| ファイル | 変更種別 | 内容 |
|---------|---------|------|
| `prompts/package/skills/session-title/SKILL.md` | 削除 | スキル定義ファイル |
| `prompts/package/skills/session-title/bin/aidlc-session-title.sh` | 削除 | スキル実行スクリプト |
| `prompts/package/prompts/inception.md` | 修正 | セクション1.5を【オプション】に変更、外部インストール注記追加 |
| `prompts/package/prompts/construction.md` | 修正 | セクション2.6・4.5を【オプション】に変更、外部インストール注記追加 |
| `prompts/package/prompts/operations.md` | 修正 | セクション2.6を【オプション】に変更、外部インストール注記追加 |
| `prompts/package/prompts/common/ai-tools.md` | 修正 | tools名前空間・session-titleエントリ削除 |
| `prompts/package/guides/skill-usage-guide.md` | 修正 | session-title参照を削除、オプショナルスキルセクション追加 |

## 設計判断

- session-titleは元々オプション機能（非macOS環境では自動スキップ）のため、外部化による機能的な影響はない
- 各フェーズプロンプトのセッション判別設定ステップは「スキルが利用可能な場合のみ実行」に変更
- skill-usage-guide.mdにオプショナルスキルセクションを新設し、外部インストール案内を提供

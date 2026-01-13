# 実装記録: Unit 002 - daselによるTOML読み込み対応

## 概要

プロンプトファイル群でのTOML設定値の読み込みをdasel対応化し、可読性と保守性を向上させた。

## 実装内容

### 変更箇所

| # | ファイル | 対象 | 変更内容 |
|---|----------|------|----------|
| 1 | prompts/setup-prompt.md:56 | starter_kit_version | grep+sed → dasel |
| 2 | prompts/package/prompts/setup.md:122 | project.name | awk → dasel |
| 3 | prompts/package/prompts/setup.md:240 | starter_kit_version | grep+sed → dasel |
| 4 | prompts/package/prompts/operations.md:1057 | setup_prompt | grep+sed → dasel |

### 実装パターン

すべての変更箇所で以下の統一パターンを適用：

```bash
if command -v dasel >/dev/null 2>&1; then
    VALUE=$(dasel -f docs/aidlc.toml -r toml '<path>' 2>/dev/null || echo "")
else
    echo "dasel未インストール - AIが設定ファイルを直接読み取ります"
    VALUE=""
fi
[ -z "$VALUE" ] && VALUE="<default>"
```

### フォールバック

- dasel未インストール時: AIがReadツールで`docs/aidlc.toml`を読み込み、値を解析
- 各箇所にフォールバック指示を追記

## テスト結果

- markdownlint: エラーなし
- AIレビュー: 承認済み
- 動作確認: 4箇所全て正常動作確認済み

## 追加変更（スコープ拡大）

dasel v3系統一のため、以下も追加修正:
- prompts/package/prompts/inception.md（3箇所）
- prompts/package/prompts/construction.md（1箇所）
- prompts/package/prompts/operations.md（3箇所）
- prompts/package/prompts/setup.md（1箇所）
- prompts/package/guides/ai-agent-allowlist.md（インストール方法・使用例）

## 完了状態

- **状態**: 完了
- **完了日**: 2026-01-13

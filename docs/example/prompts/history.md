# プロンプト実行履歴

このファイルには、各フェーズのプロンプト実行履歴を記録します。

---

## 記録テンプレート

以下のフォーマットで履歴をファイル末尾に追記してください：

```
### YYYY-MM-DD HH:MM:SS - フェーズ名

**フェーズ**: [準備/Inception/Construction/Operations]
**実行内容**: [簡潔な説明]

**プロンプト**: [読み込んだプロンプトファイル]

**変数設定**:
- [変数名] = [値]
- ...

**成果物**:
- [作成したファイル一覧]
- ...

**備考**: [特記事項]

---
```

### 追記方法

Bash heredoc を使用してファイル末尾に追記してください：

```bash
cat <<'EOF' | tee -a prompts/history.md
### 2025-11-13 01:09:07 - Inception

**フェーズ**: Inception
**実行内容**: Intent明確化とユーザーストーリー作成

**プロンプト**: prompts/inception.md

**変数設定**:
- PROJECT_NAME = AI-DLC Starter Kit
- VERSION = v1

**成果物**:
- requirements/intent.md
- story-artifacts/user_stories.md
- story-artifacts/units/auth_unit.md

**備考**: テンプレート生成を含む

---
EOF
```

---

## 実行履歴

（ここから履歴が追記されます）

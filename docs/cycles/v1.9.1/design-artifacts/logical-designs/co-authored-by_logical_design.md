# 論理設計: Co-Authored-By設定の柔軟化

## 概要

2つのファイルを修正して、Co-Authored-By設定の柔軟化を実現する。

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/prompts/common/rules.md` | Co-Authored-By参照ルールを追加 |
| `prompts/setup-prompt.md` | aidlc.tomlテンプレートに設定追加、マイグレーションセクション追加 |

**注意**: setup-prompt.md は複数箇所（テンプレートとマイグレーション）を変更するが、1ファイルとしてカウント。

## 変更詳細

### 1. rules.md の変更

**追加位置**: 「Gitコミットのタイミング【必須】」セクションの後

**追加内容**:

```markdown
## Co-Authored-By の設定【重要】

コミットメッセージに追加する Co-Authored-By 情報は `docs/aidlc.toml` で設定します。

**設定の確認**:
`docs/aidlc.toml` の `[rules.commit]` セクションを確認:
- `ai_author` が設定されている場合: その値を使用
- 未設定の場合: デフォルト値 `Claude <noreply@anthropic.com>` を使用

**コミットメッセージ形式**:
```text
{コミットメッセージ}

Co-Authored-By: {ai_author の値}
```
```

### 2. setup-prompt.md の変更

#### 2.1 aidlc.tomlテンプレート（セクション7.2）への追加

**追加位置**: `[rules.git]` セクションの後

**追加内容**:

```toml
[rules.commit]
# コミット設定（v1.9.1で追加）
# ai_author: Co-Authored-By に使用するAI著者情報
# - 形式: "ツール名 <email>"
# - デフォルト: "Claude <noreply@anthropic.com>"
ai_author = "Claude <noreply@anthropic.com>"
```

#### 2.2 マイグレーションセクション（セクション7.4）への追加

**追加内容**:

```bash
# [rules.commit] セクションが存在しない場合は追加
if ! grep -q "^\[rules.commit\]" docs/aidlc.toml; then
  echo "Adding [rules.commit] section..."
  cat >> docs/aidlc.toml << 'EOF'

[rules.commit]
# コミット設定（v1.9.1で追加）
# ai_author: Co-Authored-By に使用するAI著者情報
# - 形式: "ツール名 <email>"
# - デフォルト: "Claude <noreply@anthropic.com>"
ai_author = "Claude <noreply@anthropic.com>"
EOF
  echo "Added [rules.commit] section"
else
  echo "[rules.commit] section already exists"
fi
```

**マイグレーション結果の確認にも追加**:

```bash
grep -A 5 "^\[rules.commit\]" docs/aidlc.toml
```

## 後方互換性

- 既存プロジェクトでは `[rules.commit]` セクションが存在しない
- 未設定時はデフォルト値 `Claude <noreply@anthropic.com>` を使用
- 現状の動作と同じため、既存プロジェクトへの影響なし

**TOMLパーサの互換性**:
- TOML仕様では未知のセクション/キーは無視される
- 古いバージョンのAI-DLCプロンプトは新セクションを認識しないが、エラーにはならない
- dasel等のTOMLパーサも同様に未知セクションを無視する

## テスト観点

1. **新規セットアップ**: aidlc.toml に `[rules.commit]` セクションが含まれること
2. **アップグレード**: マイグレーションで `[rules.commit]` セクションが追加されること
3. **設定参照**: rules.md の説明に従って設定を参照できること
4. **デフォルト動作**: 未設定時にデフォルト値が使用されること

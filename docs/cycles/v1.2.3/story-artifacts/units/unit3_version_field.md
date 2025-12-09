# Unit 3: starter_kit_versionフィールド追加

## 概要
aidlc.tomlにstarter_kit_versionを正式なTOMLフィールドとして追加し、バージョン比較を正しく動作させる。

## 対象ストーリー
- US-3: starter_kit_versionフィールドの追加

## 依存関係
なし

## 修正対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/setup-init.md` | セクション6のテンプレートにフィールド追加 |
| `prompts/setup-init.md` | コメント形式の記述を削除 |
| `prompts/setup-init.md` | アップグレード時のフィールド更新処理追加 |

## 修正内容

### セクション6 テンプレート修正

変更前:
```toml
# AI-DLC プロジェクト設定
# 生成日: [現在日時]
# スターターキットバージョン: [version.txt の内容]

[project]
```

変更後:
```toml
# AI-DLC プロジェクト設定
# 生成日: [現在日時]

starter_kit_version = "[version.txt の内容]"

[project]
```

### セクション3.3 修正

変更前:
```markdown
### 3.3 aidlc.toml のバージョン情報更新

移行後、`docs/aidlc.toml` に `starter_kit_version` フィールドを追加（存在しない場合）:

```toml
# ファイル先頭のコメントに追記
# スターターキットバージョン: [version.txt の内容]
```
```

変更後:
```markdown
### 3.3 aidlc.toml のバージョン情報更新

移行後、`docs/aidlc.toml` に `starter_kit_version` フィールドを追加（存在しない場合）:

```toml
# ファイル先頭に追記
starter_kit_version = "[version.txt の内容]"
```
```

### アップグレード時の更新処理追加

セクション7の前に追加:
```markdown
### 6.5 starter_kit_versionの更新【アップグレードモードのみ】

`docs/aidlc.toml` の `starter_kit_version` フィールドを最新バージョンに更新:

```bash
# 既存のstarter_kit_versionを更新
sed -i '' 's/^starter_kit_version = ".*"/starter_kit_version = "[新バージョン]"/' docs/aidlc.toml
```
```

## 受け入れ基準
- [ ] setup-init.mdのテンプレートに`starter_kit_version = "X.X.X"`フィールドがある
- [ ] コメント形式の記述が削除されている
- [ ] アップグレード時にフィールドが更新される処理がある

## 見積もり
小（プロンプト修正のみ）

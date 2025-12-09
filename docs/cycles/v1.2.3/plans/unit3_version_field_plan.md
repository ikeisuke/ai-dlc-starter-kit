# Unit 3: starter_kit_versionフィールド追加 - 実行計画

## 概要

aidlc.tomlにstarter_kit_versionを正式なTOMLフィールドとして追加し、バージョン比較を正しく動作させる。

## 対象ファイル

- `prompts/setup-init.md`

## 修正内容

### 修正1: セクション6.2 テンプレート修正（行176-180）

**変更前**:
```toml
# AI-DLC プロジェクト設定
# 生成日: [現在日時]
# スターターキットバージョン: [version.txt の内容]

[project]
```

**変更後**:
```toml
# AI-DLC プロジェクト設定
# 生成日: [現在日時]

starter_kit_version = "[version.txt の内容]"

[project]
```

### 修正2: セクション3.3 修正（行80-87）

**変更前**:
```markdown
### 3.3 aidlc.toml のバージョン情報更新

移行後、`docs/aidlc.toml` に `starter_kit_version` フィールドを追加（存在しない場合）:

```toml
# ファイル先頭のコメントに追記
# スターターキットバージョン: [version.txt の内容]
```
```

**変更後**:
```markdown
### 3.3 aidlc.toml のバージョン情報更新

移行後、`docs/aidlc.toml` に `starter_kit_version` フィールドを追加（存在しない場合）:

```toml
# ファイル先頭に追記
starter_kit_version = "[version.txt の内容]"
```
```

### 修正3: セクション6.5追加（セクション7の直前、行222付近）

**追加内容**:
```markdown
### 6.3 starter_kit_versionの更新【アップグレードモードのみ】

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

## 作業手順

1. **Phase 1: 設計** - このUnitはプロンプト修正のみのため、設計フェーズはスキップ
2. **Phase 2: 実装** - setup-init.md の3箇所を修正
3. **検証** - 修正内容が受け入れ基準を満たすことを確認
4. **完了処理** - progress.md更新、history.md追記、コミット

## 備考

- このUnitはドメインモデル・論理設計を必要としない単純なプロンプト修正タスク
- 設計レビューは不要（コード生成がないため）

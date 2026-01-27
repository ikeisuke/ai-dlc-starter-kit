# 論理設計: Issue用基本ラベル移動

## 変更対象

### 1. 削除: `prompts/package/prompts/setup.md`

セクション5「backlogラベル確認・作成」（136-177行目）を削除。

削除後、セクション番号を繰り上げ:
- 旧セクション6 → 新セクション5
- 旧セクション7 → 新セクション6
- ...

### 2. 追加: `prompts/setup-prompt.md`

セクション8.2.5の後（1272行目付近）にセクション8.2.6を追加。

```markdown
#### 8.2.6 Issue用基本ラベルの作成

GitHub CLIが利用可能な場合、バックログ管理用の共通ラベルを作成します。

**前提条件**:
- `gh:available` であること

**処理**:
```bash
docs/aidlc/bin/init-labels.sh
```

**出力例**:
```text
label:backlog:created
label:type:feature:created
...
```
```

## 設計判断

### セクション番号の選択

- `8.2.6` を選択（8.2.5 GitHub Issueテンプレートの後）
- 理由: Issueテンプレートとラベルは関連する機能のため、近くに配置

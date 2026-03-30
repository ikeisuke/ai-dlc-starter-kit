# 論理設計: squash-unit スキル定義

## 概要

`squash-unit.sh` のスキル化に必要なファイル作成と既存ファイルへの追記の論理設計。

## 変更一覧

### 新規作成1: `prompts/package/skills/squash-unit/SKILL.md`

#### YAML front matter

```yaml
---
name: squash-unit
description: "squash-unit.shを実行してUnit完了時またはInception Phase完了時の中間コミットをスカッシュする。commit-flow.mdのスカッシュフロー内で使用。ユーザーが「squash-unit」「squash unit」「スカッシュ」と指示した場合にも使用。"
argument-hint: <cycle> <unit_number> [retroactive]
---
```

#### 本文セクション構成

1. **概要**: 1-2行の説明
2. **引数解決手順**: 表形式で各引数の自動解決方法を記述
3. **実行フロー**: 通常squashの手順（dry-run → 確認 → 実行）
4. **retroactiveモード**: 事後squashの手順
5. **エラーハンドリング**: 出力パターン別の対応
6. **フォールバック**: `commit-flow.md` 手動フローへの誘導

### 新規作成2: シンボリックリンク

```bash
.claude/skills/squash-unit → ../../docs/aidlc/skills/squash-unit
```

### 変更1: `prompts/package/prompts/common/commit-flow.md`

**追記箇所**: 「Squash統合フロー」セクション（L280）の直後、「適用対象判定」（L284）の前。

**追記内容**:

```markdown
> **スキル呼び出し推奨**: `/squash-unit` スキルを使用すると、引数の自動解決・dry-runフロー・エラーハンドリングが統合された形でsquashを実行できます。以下の手順を手動で実行する代わりに、スキル呼び出しを推奨します。
```

## NFR対応

### 後方互換性

- `commit-flow.md` の既存の直接呼び出しフローは完全維持
- スキル呼び出しは「推奨」であり、従来フローへのフォールバックを明記

### セキュリティ

- 引数解決手順でユーザー入力をそのままシェルコマンドに渡さない（AIが値を解決してから組み立てる）
- `--message-file` 経由でコミットメッセージを渡す（コマンドライン引数への直接埋め込みを避ける）

# Unit 002 実装計画: Unit定義ファイル番号付け

## 概要

Unit定義ファイル名に実行順序番号を付与し、依存関係の実行順序を明示する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/inception.md` | ステップ4にUnit定義ファイルの番号付けルールを追加 |
| `prompts/package/prompts/construction.md` | ステップ3にUnit定義ファイルの番号順処理を追加 |
| `prompts/package/templates/unit_definition_template.md` | ファイル名規則の説明を追加 |

## 変更詳細

### 1. inception.md (ステップ4: Unit定義)

追加内容:
```markdown
**Unit定義ファイルの命名規則**:
- ファイル名形式: `{NNN}-{unit-name}.md`（例: `001-setup-database.md`）
- 番号は3桁の0埋め（001, 002, ..., 999）
- 番号は依存関係に基づく実行順序を表す
- 連番の重複は禁止
- 依存関係がないUnitは任意の順番でよいが、優先度順に番号付けを推奨
```

### 2. construction.md (ステップ3: 進捗状況確認)

追加/修正内容:
- Unit定義ファイルのリスト取得コマンドにソートを追加
```bash
ls docs/cycles/{{CYCLE}}/story-artifacts/units/ | sort
```
- 説明文に「番号順に処理する」旨を追記

### 3. unit_definition_template.md

追加内容（テンプレート先頭のコメントとして）:
```markdown
<!--
ファイル名規則: {NNN}-{unit-name}.md
  - NNN: 3桁の0埋め番号（例: 001, 002, ...）
  - unit-name: Unit名のケバブケース（例: setup-database）
  - 番号は依存関係に基づく実行順序を表す
  - 例: 001-setup-database.md, 002-implement-auth.md
-->
```

## 設計方針

このUnitはプロンプト・テンプレートのルール追加のみであり、ドメインモデル設計・論理設計は不要。直接テキスト編集で実装する。

## テスト方針

- 変更後のファイルを目視確認
- 既存のUnit定義ファイル（今回のサイクル v1.4.1）がすでに番号付け形式になっていることを確認

## 完了基準

- [ ] inception.mdにUnit定義ファイルの命名規則を追加
- [ ] construction.mdにUnit定義ファイルの番号順処理を追加
- [ ] unit_definition_template.mdにファイル名規則の説明を追加
- [ ] Unit定義ファイルの実装状態を「完了」に更新
- [ ] 履歴ファイルに記録
- [ ] Gitコミット作成

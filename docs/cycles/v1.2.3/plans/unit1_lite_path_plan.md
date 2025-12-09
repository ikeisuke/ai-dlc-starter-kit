# Unit 1: Lite版パス解決安定化 - 実装計画

## 概要
Lite版プロンプトで「最初のアクション」を固定し、AIが検索に頼らず正しいパスでファイルにアクセスするようにする。

## 問題
- パス情報をプロンプトに書いてもAIが無視する
- 「従わない→見つからない→検索→正しいパス発見」という無駄なフロー

## 対策
「最初に必ずprogress.mdを読め」という強い指示を追加

## 修正対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `docs/aidlc/prompts/lite/inception.md` | 最初のアクション固定セクション追加 |
| `docs/aidlc/prompts/lite/construction.md` | 最初のアクション固定セクション追加 |
| `docs/aidlc/prompts/lite/operations.md` | 最初のアクション固定セクション追加 |

## 実装ステップ

### Phase 1: 設計（このUnitはプロンプト修正のみのため簡略化）

1. 追加するセクションの内容確認

### Phase 2: 実装

1. `docs/aidlc/prompts/lite/inception.md` に「最初のアクション【絶対】」セクションを追加
2. `docs/aidlc/prompts/lite/construction.md` に同セクションを追加
3. `docs/aidlc/prompts/lite/operations.md` に同セクションを追加

### Phase 3: 検証

1. 各ファイルの構文確認
2. 受け入れ基準の確認

## 修正内容

既存の「**注意**」セクションを修正：

変更前：
```markdown
**注意**: 全てのパスはプロジェクトルートからの絶対パスです。
- プロンプト: `docs/aidlc/prompts/`
- テンプレート: `docs/aidlc/templates/`
- サイクル成果物: `docs/cycles/{{CYCLE}}/`
```

変更後：
```markdown
**注意**: Lite版・Full版でファイルパスは同じです。最初に `docs/cycles/{{CYCLE}}/[phase]/progress.md` を読んでください。
- プロンプト: `docs/aidlc/prompts/`
- テンプレート: `docs/aidlc/templates/`
- サイクル成果物: `docs/cycles/{{CYCLE}}/`
```

## 受け入れ基準

- [ ] 3つのLite版プロンプトに「Lite版・Full版でパスは同じ」と「最初にprogress.mdを読む」が追加されている

## 見積もり

小（プロンプト修正のみ、3ファイル）

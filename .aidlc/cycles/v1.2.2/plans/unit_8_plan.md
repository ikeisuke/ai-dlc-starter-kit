# Unit 8 計画: 継続プロンプト必須化 + progress.mdパス明確化

## 概要

Unit完了時・フェーズ移行時に継続プロンプトを必ず提示し、progress.mdのパスを明確にする

## 追加実装（今回のセッションで発見）

- **progress.mdパスの明確化**: AIが`construction/`を見落として読みに行く問題を防止

## 対象ファイルの分類

| ファイル | 分類 | 操作 |
|----------|------|------|
| `prompts/package/prompts/construction.md` | ツール側 | 修正 |
| `prompts/package/prompts/inception.md` | ツール側 | 修正 |
| `prompts/package/prompts/operations.md` | ツール側 | 修正 |
| `prompts/package/prompts/lite/construction.md` | ツール側 | 修正 |
| `prompts/package/prompts/lite/inception.md` | ツール側 | 修正 |
| `prompts/package/prompts/lite/operations.md` | ツール側 | 修正 |

## 変更内容

### 1. コンテキストリセットルール強化（全フェーズ共通）

**変更前**: 「コンテキストリセット推奨」
**変更後**: 「コンテキストリセット必須（ユーザーから連続実行の指示がない限り）」

追加するルール:
```markdown
### コンテキストリセットのルール【必須】

- **デフォルト**: Unit完了時・フェーズ移行時は必ずコンテキストリセットを提示
- **例外**: ユーザーが「続けて」「上からで」「リセットしない」等と明示した場合のみスキップ可能
- **判断基準**: 明示的な指示がなければ、必ずリセット用プロンプトを提示する
```

### 2. progress.mdパスの明確化（construction.md）

**変更箇所**: 「3. 進捗管理ファイル読み込み【重要】」セクション

**変更前**:
```markdown
### 3. 進捗管理ファイル読み込み【重要】

`docs/cycles/{{CYCLE}}/construction/progress.md` を読み込む
```

**変更後**:
```markdown
### 3. 進捗管理ファイル読み込み【重要】

**progress.mdのパス（正確に）**:
```
docs/cycles/{{CYCLE}}/construction/progress.md
                      ^^^^^^^^^^^^
                      ※ construction/ サブディレクトリ内
```

**注意**: `docs/cycles/{{CYCLE}}/progress.md` ではありません。必ず `construction/` ディレクトリ内のファイルを読み込んでください。
```

### 3. inception.md の progress.mdパス明確化

**変更箇所**: 「4. 進捗管理ファイル確認【重要】」セクション

同様に `inception/progress.md` であることを強調

### 4. operations.md の progress.mdパス明確化

**変更箇所**: 「3. 進捗管理ファイル確認【重要】」セクション

同様に `operations/progress.md` であることを強調

### 5. Unit完了時のメッセージ強化（construction.md）

**変更箇所**: 「6. コンテキストリセット推奨」セクション

**変更前**:
```markdown
### 6. コンテキストリセット推奨
Unitが完了しました。コンテキストをリセットして次の作業を開始することを推奨します。
```

**変更後**:
```markdown
### 6. コンテキストリセット【必須】

Unit [名前] が完了しました。

**次のUnitを開始するプロンプト**:
```
以下のファイルを読み込んで、サイクル vX.X.X の Construction Phase を継続してください：
docs/aidlc/prompts/construction.md
```

**注意**: ユーザーから「続けて」「リセットしない」等の明示的な指示がない限り、上記プロンプトを必ず提示してください。
```

### 6. Lite版の継続プロンプト強化

各Lite版プロンプトの「次のステップ」セクションに以下を追加:
- 「必ず提示」という文言
- ユーザー指示がない限りスキップ不可という明記

## 期待される効果

1. AIがprogress.mdのパスを正しく認識する
2. Unit完了時に継続プロンプトが必ず提示される
3. ユーザーがスムーズに次の作業を開始できる

## 注意事項

- ツール側（prompts/package/）の変更なので、次回セットアップ時に反映される
- 現在のサイクルには即時反映されない

# Unit 7: Lite版設計ステップ見直し - 実装計画

## 概要
Lite版でも最低限の設計確認ステップを残し、実装先の判断ミスを防ぐ。
また、パス参照の混乱を防ぐため、プロジェクトルートからの絶対パスであることを明示する。

## 対象ファイル
- `prompts/package/prompts/lite/construction.md`
- `prompts/package/prompts/lite/inception.md`
- `prompts/package/prompts/lite/operations.md`

## 変更内容

### 1. パス参照の明示（全Lite版プロンプト共通）

Full版参照セクションに以下を追加：

```markdown
**注意**: 全てのパスはプロジェクトルートからの絶対パスです。
- プロンプト: `docs/aidlc/prompts/`
- テンプレート: `docs/aidlc/templates/`
- サイクル成果物: `docs/cycles/{{CYCLE}}/`
```

### 2. 簡易設計確認ステップの追加（construction.md）

「スキップするステップ」セクションを以下に変更：

```markdown
### スキップするステップ

**Phase 1（設計フェーズ）を簡略化**:

- **ステップ1: ドメインモデル設計** → スキップ
- **ステップ2: 論理設計** → スキップ
- **ステップ3: 設計レビュー** → **簡易実装先確認**に変更

### 簡易実装先確認【必須】

実装開始前に以下を確認し、計画に明記：

1. **対象ファイルの分類**
   - ツール側（`prompts/`）か成果物側（`docs/`）か
   - 新規作成か既存ファイルの修正か

2. **実装先ファイル一覧**
   - 変更するファイルのパスを全て列挙
   - 各ファイルの変更概要を記載
```

## 実装手順

1. `prompts/package/prompts/lite/construction.md` を修正
2. `prompts/package/prompts/lite/inception.md` を修正
3. `prompts/package/prompts/lite/operations.md` を修正
4. rsync で `docs/aidlc/prompts/lite/` に同期

## 完了基準

- 全Lite版プロンプトにパス注記が追加されている
- construction.mdに簡易実装先確認ステップが追加されている
- rsync同期が完了している

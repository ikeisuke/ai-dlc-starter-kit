# 論理設計: 設定値に応じた条件ロードスキップ

## 概要

フェーズステップファイル内のAIレビュー指示とセミオートゲート判定の参照箇所に、設定値に応じた条件分岐を追加する。

## アーキテクチャパターン

既存テキストへの条件注記の付加。各参照箇所に一行の条件文を追加し、スキップ時の代替動作を明示する。

## 変更対象の詳細マッピング

### Type A: review-flow.md参照（review_mode=disabled時の条件注記）

review-flow.mdは常にロード。disabled時はパス3（ユーザーレビュー）直行を注記。

| # | ファイル | 行 | 現在の記述 | 追加する条件注記 |
|---|---------|----|-----------|----|
| A1 | `construction/01-setup.md` | 103 | `**AIレビュー**: 計画承認前に review-flow.md に従って実施。` | `review_mode=disabled` の場合、review-flow.mdのパス3（ユーザーレビュー）に直行。 |
| A2 | `construction/02-design.md` | 41 | `1. **AIレビュー実施**（review-flow.md に従う）` | 同上 |
| A3 | `construction/03-implementation.md` | 8 | `2. **AIレビュー実施**（review-flow.md に従う）` | 同上 |
| A4 | `construction/03-implementation.md` | 142 | `4. **AIレビュー実施**（review-flow.md に従う...）` | 同上 |
| A5 | `inception/03-intent.md` | 42 | `**AIレビュー**: Intent承認前に review-flow.md に従って...` | 同上 |
| A6 | `inception/04-stories-units.md` | 49 | `**AIレビュー**: ユーザーストーリー承認前に...` | 同上 |
| A7 | `inception/04-stories-units.md` | 93 | `**AIレビュー**: Unit定義承認前に...` | 同上 |

### Type B: rules-automation.md参照（automation_mode=manual時のスキップ）

セミオートゲート判定の参照のみ条件化。manualの場合はユーザー承認固定。

| # | ファイル | 行 | 現在の記述（要約） | 変更内容 |
|---|---------|----|-----------|----|
| B1 | `construction/02-design.md` | 43 | セミオートゲート判定（rules-automation.md参照） | `automation_mode=manual` の場合、セミオートゲート判定をスキップしユーザー承認を実施。 |
| B2 | `construction/03-implementation.md` | 144 | セミオートゲート判定（rules-automation.md参照） | 同上 |
| B3 | `inception/03-intent.md` | 49 | セミオートゲート判定（rules-automation.md参照） | 同上 |
| B4 | `inception/04-stories-units.md` | 56 | セミオートゲート判定（rules-automation.md参照） | 同上 |
| B5 | `inception/04-stories-units.md` | 101 | セミオートゲート判定（rules-automation.md参照） | 同上 |
| B6 | `operations/02-deploy.md` | 11 | セミオートゲート判定（rules-automation.md参照） | 同上 |
| B7 | `operations/03-release.md` | 5 | セミオートゲート判定（rules-automation.md参照） | 同上 |

### 除外（常時ロード維持）

| # | ファイル | 行 | 参照種別 | 除外理由 |
|---|---------|---|---------|---------|
| X1 | `inception/02-preparation.md` | 18 | エクスプレスモード仕様 | manual時でもexpress起動時に必要 |
| X2 | `inception/04-stories-units.md` | 107,117,119,132 | エクスプレスモード・複雑度判定 | express判定で必要 |
| X3 | `construction/03-implementation.md` | 72 | フォールバック条件 | エラー時のユーザー確認で必要 |
| X4 | `common/compaction.md` | 46,93 | コンパクション復帰 | 設定再確認で必要 |
| X5 | `common/rules-core.md` | 67 | 文脈参照 | ロード指示ではない |
| X6 | `construction/04-completion.md` | 38 | 文脈参照 | ロード指示ではない |
| X7 | `construction/02-design.md` | 39 | 順序制約説明 | ロード指示ではなく説明文 |

## review-flow-reference.mdの扱い

- **分類**: review-flow.mdに委譲（除外）
- **理由**: review-flow.md内部の分割参照であり、フェーズステップファイルからの直接参照なし。review-flow.mdがロードされれば内部で必要時に参照される

## 条件注記のテンプレート

### Type A（review-flow.md条件注記）

**追記位置**: 既存のAIレビュー実施指示の末尾に括弧書きで追記
**記法**: 括弧内に条件と代替動作を1文で記述
**無変更条件**: なし（全対象箇所に追記する）

テンプレート:
```markdown
（`review_mode=disabled` の場合は `review-flow.md` のパス3に直行）
```

### Type B（rules-automation.md条件注記）

**追記位置**: 既存のセミオートゲート判定記述の末尾に括弧書きで追記
**記法**: 括弧内にロードスキップ条件を1文で記述
**無変更条件**: 既存文に `automation_mode=manual の場合は従来どおりユーザーに確認` 等の明示的な分岐記述がある場合は無変更（operations/02-deploy.md L11が該当）

テンプレート:
```markdown
（`automation_mode=manual` の場合、`rules-automation.md` の読み込みをスキップしユーザー承認を実施）
```

## 実装上の注意事項

- 既存テキストの意味を変えずに条件注記を追加する（追記のみ）
- Type Bの判定: 既存文に「manual時の動作」が明示的に記載されていれば無変更、なければ追記

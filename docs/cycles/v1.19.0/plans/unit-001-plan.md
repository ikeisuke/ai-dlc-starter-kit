# Unit 001 計画: Overconfidence Prevention原則の導入

## 概要

`prompts/package/prompts/common/rules.md` の「予想禁止・一問一答質問ルール」セクション（L53-80）を「Overconfidence Prevention原則」として再構成する。Amazon AIDLC の overconfidence-prevention.md（MIT-0）を参照元として活用し、確信度判定不明確時のデフォルト動作を明文化する。

## 変更対象ファイル

- `prompts/package/prompts/common/rules.md` （ソース、直接編集対象）
- `prompts/setup-prompt.md` （参照名称の更新）
- `prompts/package/prompts/lite/construction.md` （参照名称の更新）
- `prompts/package/prompts/lite/inception.md` （参照名称の更新）
- `prompts/package/prompts/lite/operations.md` （参照名称の更新）

**注意**: `docs/aidlc/` 配下は rsync コピーのため直接編集しない。Operations Phase の `/upgrading-aidlc` で反映される。

## 責務マトリクス

| セクション | 責務 | 変更方針 |
|-----------|------|---------|
| 質問と回答の記録【重要】 | 不明点の記録仕様（[Question]/[Answer]タグ） | 変更なし（記録の仕組みに特化） |
| Overconfidence Prevention原則【重要】 | 判断・行動規範（いつ・なぜ質問するか） | 新設（既存の「予想禁止〜」を包含・拡張） |

## Amazon AIDLC 参照取り込み契約

**参照元**: `awslabs/aidlc-workflows` / `aidlc-rules/aws-aidlc-rule-details/common/overconfidence-prevention.md` (MIT-0)

| 項目 | 採否 | 理由 |
|------|------|------|
| 原則「When in doubt, ask」 | 採用 | 既存ルールと整合 |
| レッドフラグ指標 | 採用（翻訳・適応） | 品質向上に有効 |
| 成功指標 | 採用（翻訳・適応） | 品質測定に有効 |
| 各フェーズ固有の変更（Requirements/User Stories等） | 非採用 | 既存AI-DLCのフェーズプロンプトと構造が異なるため。必要なら別Unitで対応 |
| Clarification file作成 | 非採用 | 既存の[Question]/[Answer]記録と重複 |

**優先順位**: 既存ルール（rules.md）が優先。Amazon AIDLCは補完・拡張として取り込む。

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: プロンプト変更のみのため、軽量版（概念構造・責務の定義）
2. **論理設計**: 変更前後のセクション構成を定義
3. **設計レビュー**: AIレビュー実施

### Phase 2: 実装

1. **コード生成**: `prompts/package/prompts/common/rules.md` の該当セクションを書き換え + 参照元ファイルの名称更新
2. **テスト**: プロンプト変更のためテストコードは不要。Markdownlint で構文チェック
3. **統合とレビュー**: AIレビュー（code + architecture）

### 変更内容の方針

- 既存の「予想禁止・一問一答質問ルール【重要】」（L53-80）を「Overconfidence Prevention原則【重要】」セクションに包含
- 「質問と回答の記録【重要】」セクション（L50-52）は変更しない（記録仕様として独立維持）
- 以下のサブセクションを構成:
  1. **原則**: 「確信度が低い場合は推測せず質問する」をデフォルト動作として明記
  2. **質問フロー**: 既存のハイブリッド方式質問フローを維持
  3. **質問すべき場面**: 既存の場面リストを拡張（Amazon AIDLC参照）
  4. **レッドフラグと成功指標**: 過信の兆候チェックリスト + 適切な質問行動の成功指標（Amazon AIDLC参照）
- 参照元ファイル（setup-prompt.md、lite/*.md）の名称を新セクション名に更新

## 完了条件チェックリスト

- [ ] `prompts/package/prompts/common/rules.md` に「Overconfidence Prevention原則」セクションが追加されている
- [ ] 既存の「予想禁止・一問一答質問ルール」の内容が新セクション内に包含されている
- [ ] 確信度判定不明確時のデフォルト動作（質問する）が明記されている
- [ ] レッドフラグと成功指標が rules.md に反映されている
- [ ] 参照元ファイル（setup-prompt.md、lite/*.md）の名称が新セクション名と整合している

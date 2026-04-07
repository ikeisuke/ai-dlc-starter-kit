# 実装記録: rules.md 3階層分割

## 実装日時
2026-04-07

## 作成ファイル

### ソースコード
- `skills/aidlc/steps/common/rules-core.md` - 常時ロードされる共通開発ルール（10,049B）
- `skills/aidlc/steps/common/rules-automation.md` - セミオートゲート・エクスプレスモード仕様（2,835B）
- `skills/aidlc/steps/common/rules-reference.md` - Depth Level・設定仕様リファレンス（1,542B）

### 削除ファイル
- `skills/aidlc/steps/common/rules.md` - 元の共通開発ルール（10,891B）
- `skills/aidlc/steps/common/agents-rules.md` - 元のエージェントルール（3,841B）

### 更新ファイル（参照パス更新）
- `skills/aidlc/SKILL.md` - ステップ1ロード指示
- `skills/aidlc/AGENTS.md` - agents-rules.md → rules-core.md
- `skills/aidlc/CLAUDE.md` - テンポラリファイル規約参照先修正
- 12件のステップファイル（全フェーズ）
- `skills/aidlc/guides/glossary.md`

### テスト
- 参照整合性テスト: PASS（旧参照残存0件）
- ファイル存在テスト: PASS（新3ファイル存在、旧2ファイル削除済み）
- サイズNFRテスト: PASS（14,426B < 14,732B）

### 設計ドキュメント
- `.aidlc/cycles/v2.2.1/design-artifacts/domain-models/rules_restructure_domain_model.md`
- `.aidlc/cycles/v2.2.1/design-artifacts/logical-designs/rules_restructure_logical_design.md`

## ビルド結果
成功（Markdownファイルのみのため従来のビルドは不要）

## テスト結果
成功

- 実行テスト数: 3
- 成功: 3
- 失敗: 0

## コードレビュー結果
- [x] 参照整合性: OK（旧参照残存0件）
- [x] 内容等価性: OK（分割前後で漏れなし）
- [x] サイズNFR: OK（14,426B < 14,732B）
- [x] セクション順序: OK（設計と完全一致）

## 技術的な決定事項
- agents-rules.mdの「注意事項」サブセクションは「質問フロー」と内容重複のため統合時に削除（設計通り）
- glossary.mdの`prompts/`パス問題はUnit 002スコープ外（既存問題）として対応せず

## 課題・改善点
- glossary.mdの旧`prompts/`パスの更新（別サイクルで対応）

## 状態
**完了**

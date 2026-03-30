# Unit 002 計画: エクスプレスモード仕様定義

## 概要

`prompts/package/prompts/common/rules.md` の Depth Level 仕様セクションにエクスプレスモードの仕様を追加する。エクスプレスモードは `depth_level=minimal` 時に Unit 数が1以下の場合に有効化される高速パスで、Inception と Construction を1つのフローで完結させる。

## 変更対象ファイル

- `prompts/package/prompts/common/rules.md` — Depth Level 仕様セクションの拡張

## 実装計画

### 1. エクスプレスモード仕様セクションの追加

Depth Level 仕様の「Unit 003向け契約仕様」セクションの後に、新しいサブセクション「エクスプレスモード仕様」を追加する。

内容:
- **適用条件**: `depth_level=minimal` かつ Unit 定義が1つ以下
- **成果物要件**: minimal の既存要件に加え、Inception→Construction 統合フロー（コンテキストリセットスキップ）
- **フォールバック条件**: Unit 数が2以上の場合、通知メッセージを表示し通常フローに遷移
- **フォールバック通知メッセージ**: `「エクスプレスモード適用不可: Unit数が2以上のため通常フローに切り替えます」`（正本をrules.md内に定義）
- **既存モードへの非影響**: `standard` / `comprehensive` ではエクスプレスモード判定自体がスキップされることを明記
- **セミオートゲートとの整合性**: エクスプレスモード時も `automation_mode` の設定に従う

### 2. レベル定義テーブルの更新

レベル定義テーブルに `minimal` の備考としてエクスプレスモードの存在を言及する（テーブル自体は3段階を維持）。

### 3. レベル別成果物要件一覧（minimal）の拡張

minimal セクションにエクスプレスモード固有の要件行を追加:
- Inception + Construction 統合フロー（コンテキストリセットスキップ）

## 完了条件チェックリスト

- [ ] rules.md の Depth Level テーブルにエクスプレスモード（minimal 拡張）の適用条件が定義されている
- [ ] エクスプレスモード適用条件の定義（Unit 数1以下、depth_level=minimal）
- [ ] フォールバック条件と通知メッセージの定義（文言の正本は rules.md 内に定義）
- [ ] 既存モード（standard/comprehensive）への非影響を保証する仕様記述

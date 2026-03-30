# ドメインモデル: Unitブランチ設定統合（最小構成）

## 概念

### Unitブランチ設定（UnitBranchSetting）

**責務**: Unitブランチ機能の有効/無効を制御する設定値

**属性**:

- `enabled`: boolean - Unitブランチ作成提案を行うかどうか

**デフォルト値**: `true`（従来動作を維持）

### 設定参照フロー

1. `docs/aidlc.toml`の`[rules.unit_branch]`セクションを読み込む
2. `enabled`の値を取得
3. 以下の場合は`true`（デフォルト）として扱う:
   - セクションが存在しない
   - `enabled`キーが存在しない
   - 値が`true`/`false`以外（不正値）

## 境界コンテキスト

- **設定管理**: `docs/aidlc.toml`（既存）
- **プロンプト実行**: `prompts/package/prompts/construction.md`（ソース、変更対象）
  - ※ `docs/aidlc/prompts/construction.md`はOperations Phase時にrsyncで反映

## 適用範囲

- **対象**: `construction.md`（通常版）
- **対象外**: `lite/construction.md`（Lite版）- 別途対応を検討

## 補足

このUnitはプロンプト（Markdown）の修正のみのため、エンティティ・集約等の詳細定義は省略。

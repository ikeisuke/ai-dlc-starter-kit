# Unit 4: 割り込み対応ルール - 実装記録

## 基本情報

- **Unit名**: 割り込み対応ルール
- **実装日**: 2025-12-14
- **状態**: 完了

## 実装内容

### 変更ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/prompts/construction.md` | 割り込み対応フローセクションを追加 |

### 追加した機能

作業中の割り込み要望を3分類で対応するフローを定義：

| 分類 | 判定基準 | 対応 |
|------|----------|------|
| 1 | 現在のサイクル・Unitと無関係 | バックログに記録 |
| 2 | 関係あるが別Unitに属する | バックログ or 別Unit定義に追加 |
| 3 | 現在のUnitに関係 | Unit定義に追記 → 設計から実装 |

### 設計成果物

- `docs/cycles/v1.4.0/design-artifacts/domain-models/unit4_interruption_handling_domain_model.md`
- `docs/cycles/v1.4.0/design-artifacts/logical-designs/unit4_interruption_handling_logical_design.md`

## テスト

- プロンプト編集のみのため自動テストなし
- 手動確認: フローの読みやすさ・明確さを確認済み

## 備考

- 当初4分類で設計していたが、ユーザーとの対話により3分類にシンプル化
- 「今すぐ実装するか後でやるか」は分類後に優先度で決める運用に変更

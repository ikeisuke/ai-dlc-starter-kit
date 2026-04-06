# ルールリファレンス

## Depth Level仕様【重要】

成果物詳細度の3段階制御。設定キー: `rules.depth_level.level`（デフォルト: `standard`）

| レベル | 用途 |
|--------|------|
| `minimal` | シンプルなバグ修正・小規模変更。設計省略可 |
| `standard` | 通常の機能開発（デフォルト） |
| `comprehensive` | 複雑な機能開発。リスク分析・代替案検討を追加 |

### レベル別成果物要件

| フェーズ | 成果物 | minimal | standard | comprehensive |
|---------|--------|---------|----------|---------------|
| Inception | Intent | 1-2文 | 背景・目的・スコープ | + リスク分析・代替案 |
| Inception | ストーリー | 主要ケースのみ | INVEST準拠 | + エッジケース網羅 |
| Inception | Unit定義 | 最小限 | 完全な責務・境界・依存 | + 技術的リスク評価 |
| Construction | 設計 | スキップ可 | ドメインモデル+論理設計 | + シーケンス図・状態遷移図 |
| Construction | コード・テスト | 通常通り | 通常通り | + 統合テスト強化 |

無効値の場合は `standard` にフォールバックする。

## 設定仕様リファレンス

以下の設定は `read-config.sh` で読み取る。無効値は各デフォルトにフォールバック。

| 設定キー | デフォルト | 有効値 |
|---------|----------|--------|
| `rules.version_check.enabled` | `true` | `true` / `false` |
| `rules.construction.max_retry` | `3` | 0以上の整数 |

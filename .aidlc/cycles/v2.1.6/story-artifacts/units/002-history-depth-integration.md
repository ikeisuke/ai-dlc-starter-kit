# Unit: history.levelとdepth_level統合

## 概要
rules.history.levelをrules.depth_level.history_levelに��合し、depth_levelからの自動導出と明示的なオーバーライドの両方をサポートする。

## 含まれるユーザーストーリー
- ストーリー 5: history.levelとdepth_levelの統合（#522）

## 責務
- defaults.tomlにrules.depth_level.history_levelを追加（デフォルト: 空=自動導出）
- read-config.sh内で新キー → 旧キーのフォールバックチェーン実装
- プリフライトチェック（手順4）での自動導出ロジック実装
- プリフライト結果の主要設定値にhistory_level表示を追加
- 旧キーrules.history.levelのフォールバック読み取り対応

## 境界
- 履歴記録の実際の書き込みロジック（write-history.sh等）の変更は不要（コンテキスト変数経由で参照される）
- depth_levelの自動導出マッピング以外の履歴制御ロジックは変更しない

## 依存関係

### 依存する Unit
- なし（論理的な依存はない。Unit 001とdefaults.toml・preflight.mdを同時編集する場合は競合に注意）

### 外部依存
- なし

## 非機能要件（NFR）
- **後方互換性**: 旧キーrules.history.levelのみのconfig.tomlでも正常動作すること
- **一貫性**: 同一depth_levelなら全フェーズで同一のhistory_levelが導出されること

## 技術的考慮事項
- 自動導出マッピング: minimal→minimal、standard→standard、comprehensive→detailed
- read-config.shでのフォールバック: version_check/upgrade_checkの互換ロジックを参考
- プリフライトでの一元的な導出により、フェーズ間の不整���を防止

## 関連Issue
- #522

## 実装優先度
High

## 見積もり
小規模（defaults.toml、read-config.sh、preflight.mdの修正）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -

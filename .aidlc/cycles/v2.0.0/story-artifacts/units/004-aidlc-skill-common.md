# Unit: aidlcスキル - 共通基盤

## 概要
統合オーケストレーターSKILL.md（~200行）と `steps/common/` を作成。preflight, rules, compaction, commit-flow, review-flow, session-continuity, context-reset, agents-rules の共通ステップを移行する。

## 含まれるユーザーストーリー
- ストーリー 4: 統合オーケストレータースキル

## 責務
- SKILL.md作成: 引数解析、共通初期化、フェーズルーティング、Expressモード遷移、コンパクション復帰
- `steps/common/preflight.md`: プリフライトチェック
- `steps/common/rules.md`: 共通開発ルール
- `steps/common/compaction.md`: コンパクション対応
- `steps/common/commit-flow.md`: コミットフロー
- `steps/common/review-flow.md`: レビューフロー
- `steps/common/session-continuity.md`: セッション継続
- `steps/common/context-reset.md`: コンテキストリセット
- `steps/common/agents-rules.md`: エージェントルール
- `skills/aidlc/config/defaults.toml`: デフォルト設定値
- `skills/aidlc/config/config.toml.example`: 設定例

## 境界
- 各フェーズ固有のステップは含まない（Unit 005-008で実装）
- テンプレートの移動は本Unitの最後に実施

## 依存関係

### 依存する Unit
- Unit 003: シェルスクリプト移行（依存理由: スクリプトパスが確定している必要がある）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: SKILL.md本文を200行以内に抑える
- **セキュリティ**: 特になし
- **スケーラビリティ**: 特になし
- **可用性**: 特になし

## 技術的考慮事項
- SKILL.md の `body-length` 制限（ERROR: 500行超）に注意
- PoCの結果に基づきオンデマンドReadまたは@参照を選択
- `description` にトリガー条件（"インセプション", "start inception"等）を含める

## 実装優先度
High

## 見積もり
中〜大

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -

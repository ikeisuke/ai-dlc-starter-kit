# Unit: aidlcスキル - Setup Phase

## 概要
`steps/setup/` を作成し、setup-prompt.md（1,267行）とaidlc-setupスキルを統合。v1→v2 config移行機能を含む。

## 含まれるユーザーストーリー
- ストーリー 8: Setup Phaseスキル化

## 責務
- `steps/setup/01-detect.md`: プロジェクト検出（既存AI-DLC構成の判定）
- `steps/setup/02-generate-config.md`: `.aidlc/config.toml` 生成
- `steps/setup/03-migrate.md`: v1→v2移行（`docs/aidlc.toml` → `.aidlc/config.toml`、`docs/cycles/` → `.aidlc/cycles/`）
- 旧 `prompts/setup-prompt.md` の機能を統合
- 旧 `aidlc-setup` スキルの機能を統合

## 境界
- 共通ステップは参照のみ
- 新規プロジェクトの`config.toml`生成と既存プロジェクトの移行のみ

## 依存関係

### 依存する Unit
- Unit 004: aidlcスキル - 共通基盤（依存理由: SKILL.mdのフェーズルーティングが必要）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 特になし
- **セキュリティ**: 特になし
- **スケーラビリティ**: 特になし
- **可用性**: 特になし

## 技術的考慮事項
- v1→v2の設定移行では既存設定値を保持しつつパス構造を変換
- 移行の冪等性を保証（再実行しても問題ない）

## 実装優先度
High

## 見積もり
中

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -

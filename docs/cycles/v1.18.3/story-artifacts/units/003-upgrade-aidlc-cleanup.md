# Unit: upgrade-aidlc.sh改善（--config廃止 + dasel必須化）

## 概要
upgrade-aidlc.sh の不要な `--config` オプションを廃止し、daselを必須依存として明確化することで、コードを簡素化し堅牢性を向上する。

## 含まれるユーザーストーリー
- ストーリー 3: upgrade-aidlc.sh --configオプション廃止 (#264)
- ストーリー 4: upgrade-aidlc.sh dasel必須化 (#263)

## 関連Issue
- #263
- #264

## 責務
- `--config` オプションの引数解析を削除
- `CONFIG_PATH` を `docs/aidlc.toml` にハードコード化
- 下流スクリプトへの `--config` 透過ロジックを削除
- スクリプト冒頭で `command -v dasel` を確認し、未インストール時にエラー終了
- 不要になったdaselフォールバック処理を削除

## 境界
- `read-config.sh` 自体のdaselフォールバックは変更しない（upgrade-aidlc.sh固有の変更のみ）
- `check-setup-type.sh` のdaselフォールバックは変更しない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- dasel（TOML解析ツール）

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- 実装順序: 先に--config廃止 → 次にdasel必須化（--config関連コードの削除後にフォールバック特定が容易になる）
- エラーメッセージにdaselのインストール手順（`brew install dasel` 等）を含める
- リリースノートに--config廃止を明記

## 実装優先度
Medium

## 見積もり
小（既存スクリプトの削除・簡素化が主な作業）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-03
- **完了日**: 2026-03-03
- **担当**: AI

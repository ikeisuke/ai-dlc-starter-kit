# Unit: check-bash-substitution.shスコープ制限

## 概要
`check-bash-substitution.sh` のバリデーションをスターターキット開発リポジトリ（`project.name = ai-dlc-starter-kit`）でのみ実行されるようにスコープを制限する。

## 含まれるユーザーストーリー
- ストーリー 2: check-bash-substitution.shのスコープ制限

## 責務
- `check-bash-substitution.sh` スクリプト内に `project.name` をチェックする条件分岐を追加
- 対象外リポジトリではスキップして正常終了する
- `project.name` 未設定・読取失敗時は警告を出力してスキップする

## 境界
- **修正対象はスクリプト（`bin/check-bash-substitution.sh`）のみ**。呼び出し元プロンプト（Operations Phase等）の修正は行わない
- バリデーションロジック自体の変更は行わない
- 他のバリデーションスクリプトのスコープ制限は対象外

## 依存関係

### 依存する Unit
- なし

### 外部依存
- `docs/aidlc.toml` の `project.name` 設定

## 非機能要件（NFR）
- **パフォーマンス**: 影響なし
- **セキュリティ**: 影響なし
- **スケーラビリティ**: 影響なし
- **可用性**: 影響なし

## 技術的考慮事項
- スクリプト冒頭で `read-config.sh` または直接 `docs/aidlc.toml` を参照して `project.name` を取得
- 呼び出し元のOperations Phaseプロンプトは変更不要（スクリプト自体がスコープ判定を行うため）

## 実装優先度
High

## 見積もり
小規模（条件分岐の追加）

## 関連Issue
- #342

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-17
- **完了日**: 2026-03-17
- **担当**: @ai

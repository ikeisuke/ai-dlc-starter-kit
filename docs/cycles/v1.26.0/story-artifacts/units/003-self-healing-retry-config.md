# Unit: Self-Healingリトライ回数の設定化

## 概要
Construction PhaseのSelf-Healingループの最大リトライ回数を `aidlc.toml` の `rules.construction.max_retry` で設定可能にする。

## 含まれるユーザーストーリー
- ストーリー 3: Self-Healingリトライ回数の設定化

## 関連Issue
- #322

## 責務
- `aidlc.toml` に `rules.construction.max_retry`（デフォルト: 3）を追加
- `construction.md` のSelf-Healingループのハードコード "3回" を設定値参照に変更
- プリフライトチェック時にコンテキスト変数として取得

## 境界
- エラー分類ロジック（recoverable/non_recoverable/transient）の変更は含まない
- Self-Healingループの修正・判定アルゴリズムの変更は含まない
- `max_retry=0` 時のスキップ分岐は設定値に応じた分岐追加として本Unitのスコープに含む

## 依存関係

### 依存する Unit
- Unit 002: プリフライトチェック項目の設定化（依存理由: `aidlc.toml` と `preflight.md` の設定スキーマ拡張が先行する必要があるため）

### 外部依存
- `read-config.sh`（既存実装）

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- `prompts/package/prompts/construction.md` の "最大3回" ハードコード箇所を全て設定値参照に変更
- `prompts/package/prompts/common/preflight.md` の設定値取得に `rules.construction.max_retry` を追加
- バリデーション: 0以上の整数のみ許可。負の値・非数値は警告を表示しデフォルト値3にフォールバック
- `max_retry=0` の場合: Self-Healingループをスキップし、即座にユーザー判断フォールバックに遷移

## 実装優先度
High

## 見積もり
中規模（プロンプト変更 + 設定ファイル追加）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -

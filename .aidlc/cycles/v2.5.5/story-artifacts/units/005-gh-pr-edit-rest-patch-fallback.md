# Unit: gh pr edit スコープ不足エラーの REST PATCH fallback 経路追加

## 概要

`scripts/operations-release.sh pr-ready` の `gh pr edit --body-file` 失敗時に `gh api -X PATCH /repos/{owner}/{repo}/pulls/{number} -F body=@<file>` で REST 直叩きする fallback 経路を組み込む。エラー判別は grep パターン（`read:org` / `read:discussion` / GraphQL field error）で行い、それ以外のエラーは従来通り上位に伝播。

## 含まれるユーザーストーリー

- ストーリー 5: gh pr edit スコープ不足エラーの REST PATCH fallback 経路追加（#626）

## 責務

- `scripts/operations-release.sh pr-ready` で `gh pr edit --body-file` 実行時にスコープ不足エラー（`read:org` / `read:discussion` / GraphQL field error 等）を grep 検出する分岐追加
- 検出時に `gh api -X PATCH /repos/{owner}/{repo}/pulls/{number} -F body=@<file>` で REST PATCH fallback を実行する経路追加
- bats テスト 1 件以上で fallback 動作確認（fixture: `gh pr edit --body-file` がスコープ不足エラーを返す）
- 後方互換テスト: スコープ不足以外のエラーは従来通り上位伝播し、fallback で握り潰さない

## 境界

- `gh pr edit` の他のオプション（`--add-reviewer`、`--milestone` 等）の fallback 化は行わない（OUT_OF_SCOPE）
- エラー判別 grep パターンの将来的な `gh` バージョン更新対応は本 Unit のスコープ外（fixture 失敗で気付ける運用ルールのみ確立）

## 依存関係

### 依存する Unit

- なし（独立 Unit）

### 外部依存

- `gh api` REST PATCH エンドポイント `/repos/{owner}/{repo}/pulls/{number}` の `-F body=@<file>` フォーム入力（v2.42.0+ で確認）

## 非機能要件（NFR）

- **パフォーマンス**: fallback パス時のみ追加 API 呼び出し（通常パスはオーバーヘッドなし）
- **セキュリティ**: REST PATCH 経路でも書き込み権限は `gh` 認証スコープに依存（`read:*` が不足しても `write:pulls` が満たされていれば PATCH は通る）
- **スケーラビリティ**: 該当なし
- **可用性**: スコープ不足リポジトリでも Operations 7.8 が完走する（手動 fallback を排除）

## 技術的考慮事項

- grep 検出キーワード候補: `read:org` / `read:discussion` / `Could not resolve to a User` / `requires.*scope` 等を網羅
- **fixture 更新トリガーの記録先（DR-001）**: Unit 005 完了履歴 `.aidlc/cycles/v2.5.5/history/construction_unit05.md` に「fixture 更新トリガー: gh CLI バージョン更新で read:org スコープ不足エラー文言が変わった場合、bats fixture が失敗することで気付ける」を 1 行以上記録（Unit 001 と保守方針統一）
- **二段階失敗（gh pr edit 失敗 + REST PATCH も失敗）の bats 検証は補足扱い（DR-003）**: 必須要件ではなく、実装者裁量で追加可能。発生頻度極低（読み取り + 書き込みスコープ両方欠落のレアケース）かつエラーログから手動 fallback 可能なため、本サイクル patch スコープ保護を優先して必須化しない

## 関連Issue

- #626（`gh pr edit --body-file` がトークンスコープ不足(read:org 等)で失敗する事象）

## 実装優先度

High

## 見積もり

2〜3 時間（operations-release.sh の分岐追加 + bats テスト 1 件 + 後方互換テスト確認）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-08
- **完了日**: 2026-05-08
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -

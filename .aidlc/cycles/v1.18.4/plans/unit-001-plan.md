# Unit 001 計画: セミオートモードPhase遷移改善

## 概要
Operations Phase開始時の「6. 全Unit完了確認」ステップにセミオートゲート判定を追加し、全Unit完了済みの場合にユーザー確認なしで自動遷移する。

## 変更対象ファイル
- `prompts/package/prompts/operations.md` - ステップ6（L196〜L248）

## 実装計画

### 現状の問題
operations.md の「6. 全Unit完了確認」にはセミオート時の判定ロジックと履歴記録が未定義。全Unit完了時でもセミオートゲート判定がないため、semi_autoモードの自動遷移/フォールバック判定が行われない。

### 修正方針
ステップ6の「全Unit完了の場合」と「未完了Unitがある場合」の分岐にセミオートゲート判定を挿入する。

1. **全Unit完了 + semi_auto**: `auto_approved` として自動遷移
2. **全Unit完了 + manual**: 従来通り確認なしで続行（変更なし）
3. **未完了Unit + semi_auto**: `fallback` として従来フロー（ユーザー確認）
4. **未完了Unit + manual**: 従来通りユーザー確認（変更なし）

### 承認ポイント定義
- **ID**: `operations.startup.unit_verification`
- **グローバルフォールバック条件**: common/rules.md のグローバルフォールバック条件（設定読取失敗、実行エラー、前提不成立）を先に評価
- **承認ポイント固有フォールバック条件**:
  - `incomplete_conditions`: 未完了Unitが存在する
  - `error`: Unit定義ファイルの読み取りや状態判定が不能（グローバルフォールバック条件と同等）

### 履歴記録フォーマット（common/rules.md準拠）

**自動承認時**:
```text
【セミオート自動承認】
【承認ポイントID】operations.startup.unit_verification
【判定結果】auto_approved
【AIレビュー結果】指摘0件
```

**フォールバック時**:
```text
【セミオートフォールバック】
【承認ポイントID】operations.startup.unit_verification
【判定結果】fallback
【reason_code】incomplete_conditions / error
【詳細】未完了Unitあり: {Unit番号リスト} / Unit状態の判定に失敗: {エラー詳細}
```

## 完了条件チェックリスト
- [ ] operations.mdの「6. 全Unit完了確認」セクションにセミオートゲート判定が追加されている
- [ ] 全Unit完了済み時のauto_approved処理が定義されている
- [ ] 未完了Unit時のfallback処理（reason_code: incomplete_conditions）が定義されている
- [ ] 判定不能時のfallback処理（reason_code: error）が定義されている
- [ ] 履歴記録フォーマットがcommon/rules.md準拠（自動承認/フォールバック別）で定義されている

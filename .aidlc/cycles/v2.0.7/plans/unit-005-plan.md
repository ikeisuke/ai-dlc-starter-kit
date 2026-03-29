# Unit 005 計画: ファイル配置設計判断

## 概要

cycles配下のoperation.mdとrules.mdの配置について設計判断を行う。

## 現状調査結果

- `.aidlc/rules.md` — 既に `.aidlc/` 直下に配置済み（プロジェクト固有ルール）
- `.aidlc/operations.md` — 既に `.aidlc/` 直下に配置済み（運用引き継ぎ情報）
- `.aidlc/cycles/*/history/operations.md` — サイクル固有の履歴ファイル（移行対象外）

## 設計判断

**判断: 現状維持**

Issue #454が懸念していた「cycles配下のoperation.mdとrules.md」は、既にv2.0移行で `.aidlc/` 直下に配置されている。追加の移行作業は不要。

### 根拠

**メリット（現状維持）**:
- `.aidlc/rules.md` はプロジェクト全体に適用されるルールであり、cycles配下ではなく `.aidlc/` 直下が適切
- `.aidlc/operations.md` はサイクル間で引き継がれる運用設定であり、cycles配下ではなく `.aidlc/` 直下が適切
- 既にステップファイルが `.aidlc/rules.md` / `.aidlc/operations.md` を正しく参照している

**リスク（移行する場合）**: 該当なし（既に移行済み）

## 実装計画

変更なし（設計判断の記録のみ）。

## 完了条件チェックリスト

- [ ] operation.mdとrules.mdの配置に関する設計判断が完了している
- [ ] 設計判断の根拠（メリット・デメリット）が記録されている
- [ ] 判断結果に基づく実装が完了している（現状維持のため変更なし）

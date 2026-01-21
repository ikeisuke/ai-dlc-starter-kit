# Unit 001 実装計画: 参照方式PoC

## 概要

「ファイルを読み込んでください」指示形式で外部ファイルを参照できることを検証する。
これが成功しなければ他のモジュール化施策（Unit 002, 003）は実施できない。

## 関連Issue

- #74: 外部参照方式のPoC確立

## 変更対象ファイル

1. **検証用ファイル（新規作成）**
   - `prompts/package/prompts/common/poc-test.md` - 検証用外部ファイル

2. **成果物ドキュメント（新規作成）**
   - `docs/cycles/v1.9.0/design-artifacts/domain-models/reference-poc_domain_model.md`
   - `docs/cycles/v1.9.0/design-artifacts/logical-designs/reference-poc_logical_design.md`
   - `docs/cycles/v1.9.0/construction/units/reference-poc_implementation.md`

## 実装計画

### Phase 1: 設計（コードは書かない）

#### ステップ1: ドメインモデル設計

- 参照方式の種類と特徴を整理
- Claude Code と KiroCLI での動作の違いを明確化
- 参照深度の制約を調査・ドキュメント化

#### ステップ2: 論理設計

- 検証手順の設計
- 成功/失敗の判定基準の定義
- ドキュメント化形式の決定

#### ステップ3: 設計レビュー

- 設計内容のユーザー承認

### Phase 2: 実装

#### ステップ4: Claude Code での検証

1. 検証用外部ファイル `poc-test.md` を作成
2. 「`docs/aidlc/prompts/common/poc-test.md` を読み込んでください」形式で参照を試行
3. 参照が成功するか確認
4. 参照深度（ネストした参照）の確認

#### ステップ5: KiroCLI での検証（ユーザー協力が必要）

- KiroCLI 環境での動作確認をユーザーに依頼
- resources フィールドとの併用パターンを確認

#### ステップ6: ドキュメント化

- 参照形式のガイドを作成
- 実装記録を作成

---

## 完了条件チェックリスト

- [x] Claude Codeでの参照動作確認（3段階参照成功）
- [x] KiroCLI での参照動作確認（指示形式調整後、3段階参照成功）
- [x] 参照形式のドキュメント化（reference-guide.md作成）

---

## 備考

- Unit 001 は PoC（概念実証）のため、Phase 1 で設計しながら検証も行う
- 実際のプロンプト修正は行わない（検証のみ）
- 参照漏れチェックは別 Unit（Unit 004）で実施

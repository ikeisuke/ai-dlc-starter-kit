# Unit 4 実装計画: デグレファイル復元

## 概要
v1.2.0で欠落したとされていたファイルについて調査し、対応を行う

---

## 調査結果

### 1. prompt-reference-guide.md
- **当初の想定**: v1.2.0でのディレクトリ再構成時に移行漏れ
- **実際の状況**: 各フェーズプロンプトにガイド内容が組み込まれ、独立したファイルは不要
- **結論**: デグレではなく、リファクタリングにより不要になったファイル
- **対応**: バックログの該当項目を更新

### 2. operations 運用引き継ぎファイル
- **当初の想定**: `docs/aidlc/operations/README.md` が未実装
- **実際の状況**:
  - MimiLoop には `docs/aidlc/operations/handover.md` が存在（サイクル横断の運用引き継ぎ用）
  - ai-dlc-starter-kit には該当ファイルなし → デグレ
- **結論**: スターターキットにテンプレートを追加
- **配置場所の決定**: `docs/cycles/operations.md`
  - 理由: `backlog.md` と同様、サイクル横断情報は `docs/cycles/` 直下に配置
  - `docs/aidlc/operations/` ディレクトリは不要になるため削除

---

## 対応方針

### 1. operations.md テンプレート作成
- `prompts/package/templates/operations_handover_template.md` を作成
- MimiLoop の handover.md を参考に、運用引き継ぎ情報のテンプレートを作成

### 2. setup-init.md 更新
- 初回セットアップ時に `docs/cycles/operations.md` を作成（存在しない場合のみ）
- `docs/aidlc/operations/` ディレクトリ作成を削除

### 3. バックログ更新
- 該当項目を更新

---

## 実装ステップ

1. **テンプレート作成**
   - `prompts/package/templates/operations_handover_template.md`

2. **setup-init.md 更新**
   - operations ディレクトリ作成を削除
   - `docs/cycles/operations.md` のコピー処理を追加（初回のみ）

3. **バックログ更新**
   - `docs/cycles/backlog.md` の該当項目を更新

4. **実装記録作成**
   - `docs/cycles/v1.2.1/construction/units/unit4_implementation.md`

---

## 成果物一覧

| 種類 | ファイルパス | 操作 |
|------|-------------|------|
| 計画 | `docs/cycles/v1.2.1/plans/unit4_degre_fix_plan.md` | 新規作成 |
| テンプレート | `prompts/package/templates/operations_handover_template.md` | 新規作成 |
| プロンプト | `prompts/setup-init.md` | 更新 |
| バックログ | `docs/cycles/backlog.md` | 更新 |
| 記録 | `docs/cycles/v1.2.1/construction/units/unit4_implementation.md` | 新規作成 |

---

## 作成日時
2025-12-06

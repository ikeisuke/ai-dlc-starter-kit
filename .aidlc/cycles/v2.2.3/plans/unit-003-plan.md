# 実行計画: Unit 003 設定値に応じた条件ロードスキップ

## 概要

review_mode・automation_modeの設定値に応じて、不要な共通ファイルのロードをスキップする条件分岐をフェーズステップファイルに追加する。

## 不変条件

1. **フェーズステップファイル自体のロードは省略しない**（SKILL.mdの不変ルール）
2. **steps/common/配下のファイル内容は変更しない**
3. **未定義値・不正値では安全側にフォールバック（ロードする）**
4. **review-flow.mdは常にロードする** — disabled時のパス3（ユーザーレビュー）手順を含むため、ファイル自体のスキップは安全側フローの欠落を招く

## 対象ファイルと変更内容

### review-flow.md の条件分岐

**方針変更**: review-flow.mdのファイルロード自体はスキップしない。`review_mode=disabled` の場合は、各レビュー実施箇所で「review-flow.mdの遷移判定に従いパス3（ユーザーレビュー）に直行する」旨の条件注記を追加する。これにより、disabled時にも安全側フロー（ユーザーレビュー経路）が維持される。

| 対象ファイル | 該当箇所 | 変更内容 |
|-------------|---------|---------|
| `steps/construction/01-setup.md` | L103 計画承認前レビュー | 条件注記追加: `review_mode=disabled の場合、review-flow.mdのパス3（ユーザーレビュー）に直行` |
| `steps/construction/02-design.md` | L39-43 設計レビュー | 同上 |
| `steps/construction/03-implementation.md` | L8 コードレビュー、L142 統合レビュー | 同上 |
| `steps/inception/03-intent.md` | L42 Intentレビュー | 同上 |
| `steps/inception/04-stories-units.md` | L49 ストーリーレビュー、L93 Unit定義レビュー | 同上 |

### rules-automation.md のスキップ条件

**条件化対象**: セミオートゲート判定の参照のみ。
**常時ロード対象（除外）**: エクスプレスモード仕様・複雑度判定・コンパクション復帰の参照。

`automation_mode=manual` の場合、セミオートゲート判定の参照箇所でrules-automation.mdの読み込みをスキップする。

| 対象ファイル | 該当箇所 | 変更内容 |
|-------------|---------|---------|
| `steps/construction/02-design.md` | L43 セミオートゲート判定 | 条件分岐追加: `automation_mode != manual の場合のみ` |
| `steps/construction/03-implementation.md` | L144 セミオートゲート判定 | 条件分岐追加 |
| `steps/inception/03-intent.md` | L49 セミオートゲート判定 | 条件分岐追加 |
| `steps/inception/04-stories-units.md` | L56, L101 セミオートゲート判定 | 条件分岐追加 |
| `steps/operations/02-deploy.md` | L11 セミオートゲート判定 | 条件分岐追加 |
| `steps/operations/03-release.md` | L5 セミオートゲート判定 | 条件分岐追加 |

### 除外（変更しない箇所）

**rules-automation.md参照で常時ロード対象**:
- `steps/inception/02-preparation.md` L18: エクスプレスモード仕様参照 — manualでもexpress起動時に必要
- `steps/inception/04-stories-units.md` L107, L117, L119, L132: エクスプレスモード仕様・複雑度判定参照 — manualでもexpress起動時に必要
- `steps/construction/03-implementation.md` L72: フォールバック条件参照 — エラー時のユーザー確認で必要
- `steps/common/compaction.md` L46, L93: コンパクション復帰時の設定再確認 — 常時必要

**その他の除外**:
- `steps/common/rules-core.md` L67: スコープ保護ルールの文脈参照（ロード指示ではない）

## 条件分岐のフォーマット

```markdown
> **条件ロード**: `automation_mode` が `manual` の場合、セミオートゲート判定はスキップし、ユーザー承認を実施する。
```

## 完了条件チェックリスト

- [ ] review_mode=disabled時に各レビュー箇所でパス3（ユーザーレビュー）直行の条件注記を追加
- [ ] automation_mode=manual時にセミオートゲート判定箇所でrules-automation.mdスキップの条件分岐を追加
- [ ] エクスプレスモード仕様・複雑度判定・コンパクション復帰の参照が常時ロードのまま維持されていること
- [ ] フェーズステップファイル自体のロードが省略されていないこと
- [ ] steps/common/配下のファイル内容が変更されていないこと
- [ ] 未定義値・不正値で安全側にフォールバック（ロードする）する設計であること

# Unit 001 実装計画: semi_autoゲート承認修正

## 対象Unit

- Unit 001: semi_autoゲート承認修正
- 関連Issue: #561

## 目的

semi_autoモードでフォールバック条件非該当のゲート承認が自動承認されない問題を修正する。全フェーズのステップファイル内のゲート承認ポイントで「セミオートゲート判定」への参照を統一的に明示化し、LLMが正しく自動承認判定を行えるようにする。

## 現状分析

### 明示的参照あり（修正不要 or 軽微）

| ファイル | ゲート承認ポイント | 現在の記述 |
|---------|-------------------|-----------|
| `steps/inception/03-intent.md` | Intent承認 | `**セミオートゲート判定**: ...に従う` |
| `steps/inception/04-stories-units.md` | ストーリー承認・Unit定義承認 | `**セミオートゲート判定**: ...に従う`（2箇所） |
| `steps/construction/02-design.md` | 設計承認 | `**セミオートゲート判定**に従い承認処理` |
| `steps/construction/03-implementation.md` | コードレビュー承認 | `**セミオートゲート判定**に従い承認処理` |

### 明示的参照なし or 不十分（修正対象）

#### Construction Phase

| ファイル | ゲート承認ポイント | 現在の記述 | 問題 |
|---------|-------------------|-----------|------|
| `steps/construction/01-setup.md` | 計画承認 | `**セミオート**: フォールバック条件非該当なら自動承認。` | 標準パターンと異なる略記 |
| `steps/construction/03-implementation.md` | 統合レビュー承認 | 要確認 | コードレビュー承認と同ファイル、統合レビュー側の記述確認が必要 |
| `steps/construction/04-completion.md` | 実装承認 | 要確認 | 明示参照の有無を確認 |

#### Operations Phase

Operations Phase のゲート承認ポイントは `index.md` §2.6 に4種類定義されている。各ポイントの実装箇所を個別にマッピングする:

| index §2.6 のゲート | 実装箇所 | 確認対象 |
|---------------------|---------|---------|
| ステップ1（変更確認）の選択 | `steps/operations/02-deploy.md` ステップ1 | 明示参照の有無を確認 |
| 各対話形式ステップ（2/3/4/5/6）計画承認 | `steps/operations/02-deploy.md` ステップ2〜6 各承認ポイント | 各ステップ個別に明示参照の有無を確認 |
| リリース準備計画承認（ステップ7開始時） | `steps/operations/03-release.md` or `operations-release.md` ステップ7開始 | 明示参照の有無を確認 |
| PR Ready化承認 | `steps/operations/operations-release.md` 7.8付近 | 明示参照の有無を確認 |

**注意**: PRマージ実行（ステップ7.13）は「ユーザー選択」分類のため修正対象外。

## 変更方針

### 統一パターン

全ゲート承認ポイントに以下の**単一パターン**を採用する（既存2形式のうちフェーズインデックス経由形式に統一）:

```
**セミオートゲート判定**: `steps/{phase}/index.md` の「2.x automation_mode 分岐」に従う（詳細: `common/rules-automation.md`）。
```

**選択理由**: フェーズインデックスにゲート発生箇所一覧が集約されており、そこを経由する方が責務の集約先が明確になる。直接 `rules-automation.md` のみを参照する形式（Construction の一部で使用中）は、設計フェーズでインデックス経由形式に揃えるか現状維持かを判断する。

### 修正手順

1. 設計フェーズで全ステップファイルの該当箇所を網羅的にリストアップ
2. 各箇所について以下を判定:
   - ゲート承認（セミオートゲート判定の対象）
   - ユーザー選択（対象外、変更しない）
   - 情報収集（対象外、変更しない）
3. ゲート承認に分類される箇所に統一パターンを適用
4. 曖昧な分類の箇所を明確化

### 変更しないもの

- `common/rules-automation.md` のセミオートゲート仕様自体
- SKILL.mdの「AskUserQuestion使用ルール」テーブル自体
- 「ユーザー選択」「情報収集」に分類されるポイント
- 各フェーズの `index.md` のゲート発生箇所一覧（既に正しく定義済み）

## 完了条件チェックリスト

### 網羅性

- [ ] Inception Phase: Intent承認（03-intent ステップ1）に明示参照あり
- [ ] Inception Phase: ストーリー承認（04-stories-units ステップ3）に明示参照あり
- [ ] Inception Phase: Unit定義承認（04-stories-units ステップ4）に明示参照あり
- [ ] Construction Phase: 計画承認（01-setup 完了時）に明示参照あり
- [ ] Construction Phase: 設計承認（02-design 完了時）に明示参照あり
- [ ] Construction Phase: コードレビュー承認（03-implementation ステップ4）に明示参照あり
- [ ] Construction Phase: 統合レビュー承認（03-implementation ステップ6）に明示参照あり
- [ ] Construction Phase: 実装承認（04-completion 開始時）に明示参照あり
- [ ] Operations Phase: ステップ1変更確認（02-deploy ステップ1）に明示参照あり
- [ ] Operations Phase: 各対話形式ステップ計画承認（02-deploy ステップ2〜6 各箇所）に明示参照あり
- [ ] Operations Phase: リリース準備計画承認（ステップ7開始時）に明示参照あり
- [ ] Operations Phase: PR Ready化承認（operations-release 7.8付近）に明示参照あり

### 品質

- [ ] 全ゲート承認ポイントの参照が統一パターンで記述されている
- [ ] 「ユーザー選択」「情報収集」に分類されるポイントは変更されていない
- [ ] `automation_mode=manual` の動作が退行しない（全ゲートでユーザー確認必須のまま）
- [ ] `automation_mode=semi_auto` でフォールバック条件非該���のゲートが `auto_approved` と判定される記述になっている
- [ ] `rules-automation.md` のセミオートゲート仕様自体は変更されていない

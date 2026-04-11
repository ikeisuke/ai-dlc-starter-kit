# 論理設計: semi_autoゲート承認修正

## 概要

全フェーズのステップファイルにおけるゲート承認ポイントに、統一パターンでセミオートゲート判定への参照を追加・修正する。

## アーキテクチャパターン

既存のレイヤー構成（フェーズインデックス → 詳細ステップファイル → 共通ルール）を維持し、参照方向を統一する。

```text
rules-automation.md（セミオートゲート仕様本体）
        ▲
        │ 参照
{phase}/index.md（ゲート発生箇所一覧 + automation_mode分岐定義）
        ▲
        │ 参照
{phase}/NN-{step}.md（詳細手順。各ゲート承認ポイントからindex.md経由で参照）
```

## コンポーネント詳細

### 統一参照パターン

全ゲート承認ポイントに適用��る記述パターン:

```markdown
**セミオートゲート判定**: `steps/{phase}/index.md` の「§2.x automation_mode 分岐」に従う（詳細: `common/rules-automation.md`）。
```

**パ���ーン選択理由**: index.md にゲート発生箇所一覧が集約されているため、ステップファイルからは index.md 経由で参照する方が責務の所在が明確になる。

**例外**: Construction Phase の `02-design.md` と `03-implementation.md` は既に `common/rules-automation.md` 直接参照形式を使用中。これらも統一パターンに揃える。

### 既存の Inception Phase ���タ��ンとの差異

Inception Phase の既存記述:
```markdown
**セミオートゲート判定**: `steps/inception/index.md` の「2.4 automation_mode 分岐」に従う（詳細: `common/rules-automation.md`）。
```

→ 既に統一パターンに準拠。修正不要。

## 変更対象一覧

### ���正（参照パターン統一）

| # | ファイル | 位置 | 現在の��述 | 変更内容 |
|---|---------|------|-----------|---------|
| 1 | `steps/construction/01-setup.md` | ステップ10（計画承認） | `**セミオート**: フォールバック条件非該当なら自動承認。` | 統一パターンに��換 |
| 2 | `steps/construction/02-design.md` | ステップ3 項目3 | `**セミオートゲート判定**に従い承認処理（`common/rules-automation.md` 参照）` | index.md経由形式��統一 |
| 3 | `steps/construction/03-implementation.md` | ステップ6 項目6 | `**セミオートゲート判定**に従い承認処理（`common/rules-automation.md` 参照）` | index.md経由形式に統一 |

### 追加（参照が存在しない箇所に新規追加）

| # | ファイル | 位置 | 追加内容 |
|---|---------|------|---------|
| 4 | `steps/construction/03-implementation.md` | ステップ4（コード生成）完了後 | AIレビュー後にゲート承認参照を追加 |
| 5 | `steps/construction/04-completion.md` | ステップ1（完了条件確認） | `semi_auto なら自動承認` を統一パターンに置換 |
| 6 | `steps/operations/02-deploy.md` | ステップ1（変更確認の選択） | 統一パターン追加 |
| 7 | `steps/operations/02-deploy.md` | ステップ2 開始時（デプロイ準備） | ステップ開始時セクションに統一パターン追加（index「計画承認」に対応） |
| 8 | `steps/operations/02-deploy.md` | ステップ3 開始時（CI/CD構築） | 同上 |
| 9 | `steps/operations/02-deploy.md` | ステップ4 開始時（監視・ロギング戦略） | 同上 |
| 10 | `steps/operations/02-deploy.md` | ステップ5 開始時（配布） | 同上 |
| 11 | `steps/operations/02-deploy.md` | ステップ6 開始時（バックログ整理と運用計画） | 同上 |
| 12 | `steps/operations/02-deploy.md` | ステップ7 開始時（リリース準備計画承認） | 統一パターン追加 |
| 13 | `steps/operations/operations-release.md` | 7.8（PR Ready化） | 統一パターン追加 |

### 変更不要（確認済み）

| ファイル | 理由 |
|---------|------|
| `steps/inception/03-intent.md` | 既に統一パターン準拠 |
| `steps/inception/04-stories-units.md`（2箇所） | 既に統一パターン準拠 |
| `steps/operations/operations-release.md` 7.13 | ユーザー選択（修正対象外） |
| `steps/construction/03-implementation.md` 3c | ユーザー選択（修正対象外） |
| 各フェーズ `index.md` | ゲート発生箇所一覧は正確。変更不要 |
| `common/rules-automation.md` | セミオートゲート仕様本体。変更不要 |

## ���理フロー概要

### 各ゲート承認ポイントでのLLM判��フロー

1. ステップファイルの「セミオートゲート判定」参照を検出
2. 参照先の `{phase}/index.md` §2.x を確認
3. `common/rules-automation.md` のフォールバック条件テーブルを評価
4. フォールバック非該当 → `auto_approved`（ユーザー確認なし）
5. フォールバック該当 → `fallback(reason_code)`（ユーザー確認）

## 実装上の注意事項

- ゲート承認の追加時、周囲の文脈に合った自然な挿入位置を選ぶ（既存の承認記述がある場合はその直後に統一パターンを配置）
- Operations Phase ステップ2〜6は対話形式ステップ。index.md §2.6 では1行（「各対話形式ステップ（2/3/4/5/6）計画承認」）だが、実装箇所は各ステップの**開始時**セクションにそれぞれ追加する（1:N展開、index「計画承認」= 実行前承認に対応）
- Operations Phase リリース準備計画承認は `02-deploy.md` ステップ7の開始時点に配置（`03-release.md` は完了基準の定義ファイルであり、ゲート承認の実行箇所ではない）
- `manual` モードの動作���影響を与えない記述とする（「セミオートゲート判定に従い」は manual 時はユーザー確認を要求するルール）

## 不明点と質問

なし

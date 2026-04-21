# ドメインモデル: Unit 004 - Draft PR 時の GitHub Actions スキップ

## 位置づけ（重要）

本ドキュメントは **GitHub Actions の既存仕様を要約する説明補助資料**である。本 Unit は既存ワークフロー 3 本の起動条件 YAML を変更するのみで、独自のドメインロジック・抽象レイヤーを新設しない。以下の概念はすべて GitHub Actions プラットフォーム側の定義に依拠する外部仕様の写しであり、AI-DLC スキル側に実装されるコードはない。

計画ファイル `.aidlc/cycles/v2.3.6/plans/unit-004-plan.md` の「抽象化の制約」セクションに従い、ここで扱う概念は本 Unit 内で新規に設計するオブジェクトではない。

## 概要

`pull_request` トリガーで走る 3 本のワークフロー（`pr-check.yml` / `migration-tests.yml` / `skill-reference-check.yml`）に対して、Draft PR 期間中は runner 割り当てを発生させずに `skipped` で完了させ、Ready 遷移で初回実行される運用に寄せる（DR-004）。

## 概念モデル（説明補助）

### PullRequestEvent

- **所在**: GitHub Actions プラットフォーム
- **属性（本 Unit が参照する範囲のみ）**:
  - `action`: `opened` / `synchronize` / `reopened` / `ready_for_review` / その他
  - `pull_request.draft`: boolean（Draft 状態フラグ）
- **意味**: PR の状態変化・コミット追加時にワークフローへ渡されるイベントオブジェクト。GitHub Actions の `on.pull_request.types` に列挙された `action` に該当した場合にのみ workflow run が作成される。

### DraftState

- **所在**: GitHub Actions プラットフォーム（`pull_request.draft` コンテキスト）
- **値**: `true`（Draft） / `false`（Ready）
- **意味**: PR が Draft として作成されている、または Draft に戻されている状態。Ready 化（`ready_for_review` イベント）で `false` に遷移する。

### JobGuardDecision

- **所在**: GitHub Actions ワークフロー実行エンジン（ジョブレベル `if` の評価結果）
- **入力**: `github.event.pull_request.draft == false`
- **結果**:
  - `true` → ジョブ実行（runner 割り当て、`in_progress` → `completed`）
  - `false` → ジョブ `skipped`（runner 割り当てなし、分単位消費 0）
- **意味**: ジョブレベル `if` が `false` と評価されたジョブは runner を取らずに `skipped` で完了する。ステップレベル `if` だと runner が起動してからステップがスキップされるため、**分単位消費を避けるにはジョブレベル必須**。

## 判定ルール（GitHub Actions 仕様の要約）

以下は GitHub Actions プラットフォームのドキュメント化された挙動であり、本 Unit では実装しない（既存仕様の写し）。

1. **起動条件判定**（プラットフォーム側）:
   - `on.pull_request.types` に `action` が含まれるか？
   - `on.pull_request.branches` / `paths` / `paths-ignore` の条件を満たすか？
   - すべて満たす → workflow run 作成
2. **ジョブ実行判定**（プラットフォーム側、ジョブレベル `if` 評価）:
   - ジョブの `if` 式を評価
   - `true` → runner 割り当て → ステップ実行
   - `false` → `skipped` で完了（runner 割り当てなし）

## 本 Unit が扱う設定差分（本ドメインで唯一の新規要素）

3 本のワークフロー YAML に対して、上記プラットフォーム仕様を活用する以下の設定を追加する:

| 設定箇所 | 追加内容 | 意図 |
|---------|---------|------|
| `on.pull_request.types` | `[opened, synchronize, reopened, ready_for_review]` | GitHub デフォルトに含まれない `ready_for_review` を追加し、Draft → Ready 遷移で確実に再発火させる |
| `jobs.*.if` | `github.event.pull_request.draft == false` | Draft 中はジョブを `skipped` で完了させ runner 分単位消費を 0 にする |

これらは外部プラットフォーム機能の **設定値**であり、ドメインオブジェクトではない。

## 境界

- GitHub Actions プラットフォームの挙動仕様は本 Unit の範囲外（既存仕様を参照するのみ）。
- ワークフローのジョブステップ内容・ビルドスクリプト・`permissions` は本ドメインの対象外。
- `.github/workflows/auto-tag.yml`（`push` トリガー）は Draft 概念を持たないため対象外。

## 参考資料

- DR-004（`inception/decisions.md`）
- Unit 定義: `story-artifacts/units/004-draft-pr-actions-skip.md`
- GitHub Actions ドキュメント: `pull_request` イベント / ジョブレベル `if`

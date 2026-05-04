# Unit: 主因分類 LLM 下書き + 人間確認運用

## 概要

retrospective Issue 起票時、各「問題項目」に対して主因分類（プロダクト固有 / AI-DLC 固有 / 両方）と `skill_caused_judgment`（q1/q2/q3 + 引用文）を Claude Code 自身（または `retrospective-drafter` subagent）が下書き生成し、本文に prefilled する。LLM 失敗時は手動入力フォールバック、CI / 非対話環境では skip。人間確認 marker `human_reviewed: true` の付与運用と、LLM 推論結果と人間確認後の差分の Issue コメント記録を含む。

## 含まれるユーザーストーリー

- ストーリー 3a: 主因分類 LLM 下書き生成 + 失敗フォールバック
- ストーリー 3b: 主因分類の human_reviewed 確認運用 + 差分記録

## 責務

本 Unit は **LLM 下書き生成 + 人間確認運用** に責任を持つ。Unit 002 への出力データは Intent §「判断 6.3」スキーマに準拠（必須キー、fallback 既定値含む）。

- `retrospective-drafter` subagent 定義（または main agent からの呼び出しヘルパー）
- 主因分類 3 値 + `skill_caused_judgment` q1/q2/q3 引用文の自動下書き生成ロジック（Intent §「判断 6.3」スキーマで Unit 002 に出力）
- LLM 失敗 / タイムアウト時の手動入力フォールバック（AskUserQuestion で 3 分類選択 + Intent §「判断 6.3」fallback 既定値で構造を埋める）
- CI / 非対話環境での skip 判定（Unit 001 の `feedback_mode_resolve()` 結果に従う / `disabled` 動作と同等）
- **Issue 起票後**の人間確認運用: 本 Unit が Issue 本文を更新して `human_reviewed: true` マーカーを付与（Intent §「判断 6.4」responsibility 表に従う）
- LLM 推論 vs 人間確認結果の差分検出 + `[llm-diff]` プレフィックス付き Issue コメント記録
- `scripts/retrospective-verify.sh` 新規実装（`human_reviewed: true` 未付与の Issue を検出して exit ≥ 1）
- 04-completion §1.5 ステップに対する LLM 下書きフック呼び出しの追加（Unit 002 が用意した hook 差し込み口を利用）
- 関連 BATS テスト（`tests/retrospective-llm-draft.bats`, `tests/retrospective-human-review.bats`）

## 境界

- Issue 起票本体および本文構造は Unit 002 が担う（本 Unit は Intent §「判断 6.3」スキーマに従う YAML を Unit 002 に渡し、Unit 002 が共有契約に従って本文に埋め込む）
- `feedback_mode` 判定 / 解決は Unit 001 の `feedback_mode_resolve()` を呼び出す（CI / 非対話 skip 条件は Unit 001 で定義済み）
- 外部 LLM（GitHub Models / codex / claude）連携は本 Unit のスコープ外（`OUT_OF_SCOPE` / 将来サイクル）

## 利用 I/F（他 Unit が提供する関数を呼び出す）

| I/F 提供元 | I/F | 利用シーン |
|-----------|-----|----------|
| Unit 001 | `feedback_mode_resolve()` | 起票実行可否を判定 |
| Unit 002 | `retrospective_body_compose(problem_drafts, kpt_sections)` | 共有契約準拠の Markdown 本文を組み立て |
| Unit 002 | `retrospective_issue_create(body, mode)` | Issue 起票（または gh 不可時のスプール） |

## 依存関係

### 依存する Unit

- Unit 002: retrospective Issue 一本化 + spool + mirror_state ラベル化（依存理由: Issue 起票フローの本文 prefilled 経路と差分コメント追記経路を Unit 002 が提供するため）

### 外部依存

- Claude Code 自身（main agent）または subagent（Task ツール）
- 既存の AskUserQuestion ツール

## 非機能要件（NFR）

- **応答性**: LLM 下書きが 30 秒以内に応答しない場合は手動入力 fallback
- **観測性**: LLM 推論失敗時に明示的なエラーメッセージで原因を伝える
- **学習可能性**: 差分コメント（`[llm-diff]` プレフィックス）が将来の自動分析で抽出可能

## 技術的考慮事項

- subagent 化（推奨）でコンテキスト分離を確保 — main agent の context を肥大化させない
- LLM への入力は当該サイクルの問題項目（KPT の Problem セクション）に限定
- LLM 出力は YAML ブロック形式（v2.5.0 互換）で生成し、Unit 002 の起票フローが本文に埋め込む

## 関連Issue

- #592 partial（Unit 007 主因切り分け 3 分類、本 Unit で LLM 下書き化）

## 実装優先度

Medium-High

## 見積もり

中規模。subagent / 呼び出しヘルパー実装 + 失敗フォールバック + human_reviewed 運用 + 差分記録 + BATS テスト。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -

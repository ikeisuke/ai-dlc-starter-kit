# ドメインモデル: Unit 005 /aidlc 委譲フロー Skill ツール経由自動継続実行規約化

## ステップ 0: 事前コード読込み

> 適用条件: depth_level != minimal の場合のみ必須。minimal は設計ステップ自体スキップ可のため N/A。

### (a) Read 対象ファイル + 目的

| ファイル | 目的 / 既存実装確認結果 |
|---------|------------------------|
| `skills/aidlc/SKILL.md` 「### 独立フロー委譲」セクション | 改修対象。現状は「テキスト案内 → 処理終了」のみで Skill ツール invoke 規約なし |
| Claude Code Skill ツール挙動 | 本セッション中の `aidlc:reviewing-*` スキル連鎖呼び出しで Skill ツール経由 invoke が動作することを実証済み |
| Codex CLI / Gemini CLI 挙動 | Codex CLI は Operations 振り返りで検証予定（任意）。Gemini CLI は環境未整備で本 Unit の検証範囲外 |

### (b) 設計時に意識すべき挙動

- AI エージェントによって Skill ツール挙動が異なる可能性: フォールバックとして従来テキスト案内を維持する必要
- `additional_context` (`/aidlc {action} {ctx}` の `{ctx}` 部分) は委譲先スキルに透過渡しする必要
- Claude Code は本セッション中の `aidlc:reviewing-construction-design` 等の Skill 呼び出しを 1 ターン内で実行可能（実証済み）
- 適用範囲は AI エージェント別に固定する: Claude Code 必須 / Codex CLI 任意 / Gemini CLI 範囲外

### (c) 既存実装に基づく代替案検討

- **採用**: SKILL.md 規約変更のみ。AI エージェント挙動を規範として記述
- **却下 (#717 提案 2)**: 委譲を廃止し親スキルに統合 → SKILL.md 500 行制限 + 独立スキル再利用性低下

## 概要

`/aidlc r` / `/aidlc setup` 等の入力時、AI エージェントが Skill ツール経由で委譲先スキルを直接 invoke する規約。Skill ツール利用不可時は従来テキスト案内にフォールバック。

## 適用範囲（AI エージェント別）

- **Claude Code**: Skill ツール連鎖呼び出し実証済み。**本規約の必須適用対象**
- **Codex CLI**: Operations Phase 振り返りで検証を行う。**本規約の任意適用対象**（検証結果を記録）
- **Gemini CLI**: 本 Unit 時点では環境未整備で検証範囲外。**必須適用対象外**

## エンティティ

### DelegationFlow

- **ID**: `action`（`setup` / `migrate` / `feedback` / `retrospective`）
- **属性**:
  - `action`: enum - 委譲アクション
  - `target_skill`: string - 委譲先スキル名（`aidlc-setup` 等）
  - `additional_context`: string - 透過渡し文字列
  - `invocation_mode`: `InvocationMode`
- **振る舞い**:
  - `attempt_skill_invocation()`: Skill ツール経由で `target_skill` を 1 回試行
  - `suppress_parent_output_on_success()`: 成功時は親スキル追加出力を抑止し、委譲先単独応答を保証
  - `fallback_to_text_announcement()`: 失敗時に従来テキスト案内に降格
  - `restart_from_skill_tool_next_turn()`: 次ターン再入力時は `skill_tool` モードから再開

## 値オブジェクト

### InvocationMode

- enum: `skill_tool` (Skill ツール経由 invoke) / `text_fallback` (テキスト案内)
- **遷移条件**: 初期値 `skill_tool` → 発火条件 (a) ツール未提供 / (b) 1 回目呼び出しが構造的に失敗 → `text_fallback` に降格
- **復帰条件**: フォールバック降格は当該ターン限定。次ターンで `/aidlc {action}` 再入力時は `skill_tool` から再開始（永続降格しない）

## ドメインサービス

### DelegationRouter

- **責務**: action から target_skill 解決 + InvocationMode 判定 + invoke / fallback 実行
- **操作**:
  - `route(action, additional_context)` - DelegationFlow を生成して試行 → 成功時は委譲先単独応答 / 失敗時 fallback メッセージ出力

## ユビキタス言語

- **委譲フロー (Delegation Flow)**: 親スキル `/aidlc` が独立スキル (`/aidlc-setup` 等) に処理を引き継ぐ実行経路
- **Skill ツール経由 invoke**: AI エージェントの Skill ツール (Claude Code / Codex CLI 等) で委譲先スキルを直接呼び出し、ユーザー再入力を介さず連鎖実行する手法
- **InvocationMode**: 委譲呼び出しモード。`skill_tool`（自動継続）/ `text_fallback`（従来案内）の 2 値
- **成功時出力契約**: 成功時は「委譲先スキル単独応答 / 親スキルは invoke のみ / 親スキル追加出力なし（重複出力抑止）」の固定契約
- **フォールバック降格**: Skill ツール経由 invoke が利用不可または失敗時に `text_fallback` モードへ自動降格する動作。再試行はしない（親スキル責務は 1 回試行のみ）
- **モード再開始**: フォールバック降格はターンローカル。次ターン再入力時は `skill_tool` から再開始する

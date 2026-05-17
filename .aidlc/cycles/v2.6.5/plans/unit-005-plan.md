# Unit 005 実装計画: /aidlc 委譲フロー Skill ツール経由自動継続実行規約化

## 対象 Unit

- **Unit**: 005 - /aidlc 委譲フロー Skill ツール経由自動継続実行規約化
- **関連 Issue**: #717（クローズ対象）
- **優先度**: Medium
- **depth_level**: standard

## 背景・目的

現状 `/aidlc r` / `/aidlc setup` / `/aidlc migrate` / `/aidlc feedback` を入力すると、親スキルが案内テキスト「`/aidlc-{action} {ctx}` を実行してください。」を出力して停止する。ユーザーは案内を読んで再入力する必要があり、UX 摩擦がある。

本 Unit は AI エージェントが Skill ツール経由で委譲先スキルを直接 invoke する規約を `skills/aidlc/SKILL.md` の「独立フロー委譲」セクションに明文化し、自動継続実行を実現する。

## 現状調査結果（事前コード Read / depth_level != minimal）

### Read 対象ファイル + 目的

| ファイル | 目的 / 現状記述 |
|---------|----------------|
| `skills/aidlc/SKILL.md` 「### 独立フロー委譲」セクション（見出しアンカー参照、行番号固定参照を避ける） 「### 独立フロー委譲」 | 改修対象。現状は「テキスト案内 → 処理終了」のみ。Skill ツール invoke 規約なし |
| Claude Code Skill ツール挙動 | Skill ツール呼び出しは 1 ターン内連鎖可能（本セッション中の aidlc:* / reviewing-* スキル呼び出しで実証済み） |

### 既存実装の挙動

- 現状: 親スキルがテキスト案内出力 → AI エージェント停止 → ユーザーが `/aidlc-setup` 等を再入力
- 期待挙動: 親スキルが Skill ツール (`/aidlc-{action}`) を直接 invoke → 委譲先スキルが連鎖実行

### 既存実装に基づく代替案検討

- **採用**: SKILL.md 規約変更のみ。AI エージェントの Skill ツール呼び出し挙動を規範として記述
- **却下 (#717 提案 2)**: 委譲を廃止し親スキルに統合 → SKILL.md 肥大化リスク（500 行制限）+ 独立スキルの再利用性低下

## スコープ

### 含まれるもの（責務）

- **必須対応 1**: `skills/aidlc/SKILL.md` 「### 独立フロー委譲」セクション（見出しアンカー参照、行番号固定参照を避ける） の「### 独立フロー委譲」セクション更新
  - 委譲手順を「テキスト案内」から「Skill ツール経由 invoke」中心に書き換え
  - フォールバック（Skill ツール利用不可時の従来案内）を併記。**フォールバック発火条件と復帰動作を 1 節で固定**:
    - 発火条件: (a) Skill ツール未提供 / (b) 1 回目呼び出しが構造的に失敗（ツール not found / 権限エラー / 即時エラー応答）
    - 親スキル責務: 1 回目呼び出し試行のみ。失敗時は再試行せず即フォールバックに降格（テキスト案内 + ユーザー再入力要求）
    - 最終メッセージ形式: 「`/aidlc-{action} {ctx}` を実行してください。」（従来形式 / 既存と同一文言）
    - InvocationMode (`skill_tool` / `text_fallback`) のモード遷移条件と失敗時の単一フローを同節で規定
- **必須対応 2**: 新規約の構成要素を明文化
  - (a) 委譲先スキル名と AskUserQuestion を介さない継続 invoke 手順
  - (b) `additional_context` の透過渡しルール
  - (c) 委譲案内テキストを「実行済み報告」形式に変更
- **必須対応 3**: 委譲廃止案（#717 提案 2）を採用しない旨を **Unit/Issue 側（設計判断ログ）** に記載する。SKILL.md 本体（実行規約）には設計判断経緯を混ぜず、本計画書 + 関連 Issue (#717) 内で完結させる（責務分離）
- **必須対応 4**: Claude Code 実機での `/aidlc r` 等の直接開始検証（本セッション自体が Claude Code 実機）。Construction Phase 完了時に retrofit 検証として `history/construction_unit05.md` に記録
- **任意対応**: Codex CLI 実機での同等挙動検証は Operations Phase 振り返り前段で実施（記録のみ）

### 含まれないもの（境界）

- 委譲廃止して親スキルに統合する案（#717 提案 2、SKILL.md 肥大化リスク回避）
- 独立スキル化（v2.6.0+）自体の見直し
- `/aidlc help` / `/aidlc version` 等の委譲対象外アクションの記述変更
- Gemini CLI 検証（環境未整備）

## 実装方針

### Phase 1: 設計

- ドメインモデル: `DelegationFlow` (action → 委譲先スキル invoke) / `InvocationMode` enum (`skill_tool` / `text_fallback`)
- 論理設計: SKILL.md セクション置換後の構造（規約節 + フォールバック節 + 委譲テーブル）

### Phase 2: 実装

1. SKILL.md 「### 独立フロー委譲」セクションを規約中心の記述に置換
2. Claude Code 実機ドッグフーディング検証を `history/construction_unit05.md` に記録（U5 自身が本セッションで Skill ツール経由 invoke を実証済み: `aidlc:reviewing-*` スキル連鎖呼び出し）

## 完了条件チェックリスト

### #717 受け入れ基準

- [x] `skills/aidlc/SKILL.md` の「### 独立フロー委譲」セクションが Skill ツール経由 invoke 規約に書き換えられている
- [x] フォールバック（Skill ツール利用不可時の従来案内）が併記されている
- [x] `additional_context` の透過渡しルールが明示されている
- [x] 委譲案内テキスト出力形式（「実行済み報告」形式）が明示されている
- [x] 委譲廃止案（#717 提案 2）を採用しない旨が **本計画書または関連 Issue (#717)** に記載されている（SKILL.md 本体には記載しない / 責務分離）
- [x] Claude Code 実機での Skill ツール経由 invoke 検証結果が `history/construction_unit05.md` に記録されている（検証実施は責務 / 記録は完了条件 SoT）
- [x] フォールバック発火条件と復帰動作（1 節で固定）が SKILL.md に明文化されている

### 共通

- [x] markdownlint で新規エラー 0 件
- [x] AI レビュー（設計 / コード / 統合）が `review_mode=required` に従い codex で実施されている

## リスク・考慮事項

- AI エージェント (Claude Code / Codex CLI / Gemini CLI) によって Skill ツール挙動が異なる可能性 → フォールバックとして従来テキスト案内を維持
- SKILL.md 500 行制限: 現状 line 178-191 を置換するため大きな増加なし
- 本リポジトリ規約: Bash ツール引数文字列にコマンド置換 `$(...)` / backtick を含めない

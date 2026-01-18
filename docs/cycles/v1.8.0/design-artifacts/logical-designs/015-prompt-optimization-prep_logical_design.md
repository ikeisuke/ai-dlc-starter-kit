# 論理設計: プロンプト最適化準備

## 対象Unit

- **Unit番号**: 015
- **Unit名**: プロンプト最適化準備
- **関連Issue**: #45

## 前提条件

**重要**: 5つのフェーズプロンプト（setup, setup-prompt, inception, construction, operations）は**同時には読み込まれない**。各フェーズで1つのプロンプトのみが読み込まれる。

したがって、重複の問題は「ユーザー体験への影響」ではなく「メンテナンス性の問題」である。

## 参照パスの方針

- **編集対象**: `prompts/package/prompts/`（ソースファイル）
- **デプロイ後**: `docs/aidlc/prompts/`（rsyncでコピー）
- **プロンプト内参照**: `docs/aidlc/...` を使用（デプロイ後のパス）

## 改善提案一覧

### 提案0: 参照方式の確立（優先度: 最高）

**対象**: 共通ファイル参照の仕組み

**現状の問題**:

- 外部ファイル参照が正しく動作するかの検証が不足
- AGENTS.md方式（`@ファイルパス`）の技術的制約が未確認

**改善案**:

1. 参照方式のPoC（Proof of Concept）を実施
   - どの記法（`@ファイルパス`等）が有効か確認
   - Claude Codeでの動作確認
2. PoCの結果を基に参照方式を確定

**完了条件（DoD）**:

- PoCで参照が動作することを確認
- 参照形式のドキュメント化

**注意**: この提案が完了するまで、他の提案の実装は開始しない

### 提案1: 共通セクションの外部ファイル化（優先度: 高）

**対象**: AI-DLC手法の要約、共通開発ルール

**現状の問題**:

- 4つのプロンプトファイルに同一の「AI-DLC手法の要約」が記載（約18行 × 4）
- 「人間の承認プロセス」「質問ルール」「コミットタイミング」等が3ファイルで重複

**改善案**:

1. `prompts/package/prompts/common/intro.md` を新規作成
   - AI-DLC手法の要約を記載
2. `prompts/package/prompts/common/rules.md` を新規作成
   - 共通開発ルールを記載
3. 各フェーズプロンプトでは参照指示のみ記載

**参照形式**:

```markdown
---
## AI-DLC手法の要約

@docs/aidlc/prompts/common/intro.md を参照してください。
---
```

**削減見込み**: 約250行

**依存関係**: 提案0の完了が前提

### 提案2: AIレビューフローの外部化（優先度: 高）

**対象**: AIレビュー優先ルール【重要】セクション

**現状の問題**:

- inception, construction, operationsの3ファイルに同一フロー（約80行）が記載
- フロー自体が複雑で、プロンプトの可読性を下げている

**改善案**:

1. `prompts/package/guides/ai-review-flow.md` を新規作成
   - 完全なフローを記載
2. 各プロンプトでは概要と参照指示のみ

**簡略化後の形式**:

```markdown
- **AIレビュー優先ルール【重要】**: 人間に承認を求める前に、AIレビューを実行する。
  - 詳細フローは @docs/aidlc/guides/ai-review-flow.md を参照
  - 設定: `docs/aidlc.toml` の `[rules.mcp_review].mode`
```

**削減見込み**: 約160行

**依存関係**: 提案0の完了が前提

### 提案3: 設定確認コードのスクリプト化（優先度: 中）

**対象**: dasel/GitHub CLI確認、バックログモード確認等のbashコードブロック

**現状の問題**:

- 同一パターンのbashコードが5箇所以上で繰り返されている
- 一部はbin/配下にスクリプト化されているが、プロンプトから参照されていない

**改善案**:

1. 既存スクリプトの活用を徹底
   - `bin/check-backlog-mode.sh`（新規）
   - `bin/check-gh-status.sh`（新規）
2. プロンプトにはスクリプト呼び出しのみ記載

**削減見込み**: 約100行

### 提案4: 後方互換性コードの段階的削除（優先度: 低）

**対象**: progress.md関連の後方互換性説明、旧形式バックログ移行

**現状の問題**:

- v1.6.0以前の形式への対応コードが残存
- 十分な期間が経過しており、削除可能

**改善案**:

1. v1.9.0でdeprecation warningを追加
2. v2.0.0で完全削除

**削減見込み**: 約50行

**deprecation対象の具体例**:

- `docs/cycles/{{CYCLE}}/construction/progress.md` への後方互換参照
- `docs/cycles/backlog.md`（旧形式単一ファイル）移行コード
- 旧形式バックログ移行セクション（setup.md内）

### 提案5: Operations Phaseでのプロンプトサイズチェック（優先度: 中）

**対象**: Operations Phase完了時

**現状の問題**:

- プロンプトサイズの肥大化を自動検知する仕組みがない
- 今回のような手動分析が必要

**改善案**:

1. Operations Phaseの完了時チェックに追加
2. 閾値超過時に警告を表示

**実装イメージ**（サブディレクトリ対応版）:

```bash
# プロンプトサイズチェック（サブディレクトリ対応）
TOTAL_SIZE=$(find prompts/package/prompts -name '*.md' -print0 | xargs -0 wc -c | tail -1 | awk '{print $1}')
if [ "$TOTAL_SIZE" -gt 150000 ]; then
  echo "【警告】プロンプト総サイズが閾値を超えています: ${TOTAL_SIZE} bytes"
fi
```

## 次サイクルで作成するバックログ

| タスク | 種類 | 優先度 | 見積もり |
|--------|------|--------|----------|
| 参照方式のPoC確立 | chore | 最高 | 1h |
| 参照漏れチェックの仕組み構築 | chore | 高 | 1h |
| 共通セクションの外部ファイル化 | refactor | 高 | 2h |
| AIレビューフローの外部化 | refactor | 高 | 1h |
| 設定確認スクリプトの整備 | chore | 中 | 1h |
| Operations Phaseサイズチェック追加 | feature | 中 | 1h |
| 後方互換性コードのdeprecation準備 | chore | 低 | 0.5h |

## アーキテクチャ変更の影響

### 変更後のファイル構成

```text
prompts/package/prompts/
├── common/
│   ├── intro.md           # AI-DLC手法の要約（新規）
│   └── rules.md           # 共通開発ルール（新規）
├── setup.md               # セットアップ（参照追加）
├── inception.md           # Inception Phase（簡略化）
├── construction.md        # Construction Phase（簡略化）
├── operations.md          # Operations Phase（簡略化）
├── AGENTS.md
└── CLAUDE.md

prompts/package/guides/
├── ai-review-flow.md      # AIレビューフロー詳細（新規）
├── jj-support.md
└── ...

prompts/package/bin/
├── check-backlog-mode.sh  # バックログモード確認（新規）
├── check-gh-status.sh     # GitHub CLI確認（新規）
└── ...
```

### 移行計画

1. **v1.9.0**: 参照方式PoC確立、外部ファイル作成開始
2. **v1.10.0**: 全プロンプトの簡略化完了
3. **v2.0.0**: 後方互換性コードの削除

## リスクと対策

| リスク | 影響 | 対策 |
|--------|------|------|
| AIが参照先を読まない | 重要なルールが適用されない | 提案0（PoC）で事前検証、動作しない場合は代替案検討 |
| 参照漏れ（記載忘れ） | 必要なルールが欠落 | grepによる必須参照チェックをCIに追加 |
| 参照先更新忘れ | 古いルールが残存 | 参照先一覧（依存マップ）を作成し、更新時に確認 |
| 分割による文脈断絶 | AIの理解度低下 | 参照時の要約を適切に記載 |
| 参照循環 | 読み込みループ | 参照関係を一方向に限定（共通→フェーズの方向のみ禁止） |
| 既存ユーザーへの影響 | 混乱、移行コスト | CHANGELOGでの明確な説明 |
| 参照先変更の影響範囲不明 | 意図しない挙動変化 | 参照先一覧・依存マップで影響範囲を可視化 |

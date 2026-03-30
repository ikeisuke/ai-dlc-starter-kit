# Unit 001: セットアップフロー改善 - 実行計画

## 概要

サイクルセットアップ時のブランチ・ワークツリー操作を改善し、開発者体験を向上させる。

## 対象ファイル

- `prompts/package/prompts/setup.md`

## 修正内容

### 1. lsコマンドの二重スラッシュ問題の修正（優先度: 低）

**現状（154行目）**:
```bash
ls -d docs/cycles/*/ 2>/dev/null | sort -V
```

**問題**: globパターン `*/` に末尾スラッシュがあるため、出力が `docs/cycles/backlog//` のように二重スラッシュになる

**修正案**:
```bash
ls -d docs/cycles/* 2>/dev/null | sort -V
```

### 2. ブランチ・ワークツリー作成フローの改善（優先度: 高）

**現状の問題点**:
- worktree作成時に既存ブランチがあることが前提
- worktreeとブランチの同時作成ができない
- フローが複雑で分かりにくい

**修正方針**:

#### ステップ3の選択肢を統一（worktree設定に関わらず3択）

```text
現在 main/master ブランチで作業しています。
サイクル用ブランチで作業することを推奨します。

1. worktreeを使用して新しい作業ディレクトリを作成する（推奨）
   → ブランチとworktreeを同時に作成します
2. 新しいブランチを作成して切り替える
   → 現在のディレクトリでブランチを作成して切り替えます
3. 現在のブランチで続行する（非推奨）
```

#### worktree作成コマンドの変更

**現状**:
```bash
git worktree add "${WORKTREE_PATH}" "cycle/{{CYCLE}}"
```
- 既存ブランチが必要

**修正案**: ブランチ存在確認を行い、適切なコマンドを選択

```bash
# ブランチ存在確認
if git show-ref --verify --quiet "refs/heads/cycle/{{CYCLE}}"; then
  # 既存ブランチがある場合
  git worktree add "${WORKTREE_PATH}" "cycle/{{CYCLE}}"
else
  # 新規ブランチの場合 - -b オプションでブランチも同時作成
  git worktree add -b "cycle/{{CYCLE}}" "${WORKTREE_PATH}"
fi
```

## 実行計画

### Phase 1: 設計

1. **ドメインモデル設計**: プロンプトフローの構造を文書化
2. **論理設計**: 具体的な修正箇所とコード変更を文書化
3. **設計レビュー**: ユーザー承認

### Phase 2: 実装

4. **コード生成**: setup.mdの修正を実施
5. **テスト生成**: 手動テスト手順を文書化
6. **統合とレビュー**: 動作確認

## 関連バックログ

- `docs/cycles/backlog/chore-setup-worktree-branch-flow.md`
- `docs/cycles/backlog/chore-ls-double-slash-display.md`

## 成果物

- `docs/cycles/v1.6.0/design-artifacts/domain-models/setup-flow-improvement_domain_model.md`
- `docs/cycles/v1.6.0/design-artifacts/logical-designs/setup-flow-improvement_logical_design.md`
- `prompts/package/prompts/setup.md`（修正後）
- `docs/cycles/v1.6.0/construction/units/setup-flow-improvement_implementation.md`

---

作成日: 2026-01-09

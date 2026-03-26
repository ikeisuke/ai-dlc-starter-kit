# 既存コード分析

## サイクル: v1.5.3
## 分析日: 2025-12-28

---

## 1. セットアップ関連

### 1.1 zsh互換性の問題箇所

| ファイル | 行番号 | 問題 |
|---------|--------|------|
| prompts/setup-prompt.md | 56 | `grep -oP` が macOS/zsh で動作しない |
| docs/aidlc/prompts/setup.md | 73 | 同上 |

**問題コード**:
```bash
grep -oP 'starter_kit_version\s*=\s*"\K[^"]+' docs/aidlc.toml
```

**修正案**:
```bash
grep -E 'starter_kit_version\s*=\s*"[^"]+"' docs/aidlc.toml | sed 's/.*"\([^"]*\)".*/\1/'
```

### 1.2 サイクル名引き継ぎ問題

**ファイル**: prompts/setup-prompt.md
**行番号**: 75-106, 804-811

**問題点**:
- ケースB/Cで自動的に`setup.md`を読み込む実装
- セクション10の完了メッセージでは「新しいセッションで」実行するよう指示
- 指示と動作が矛盾

### 1.3 アップグレード後の自動サイクル開始

**ファイル**: prompts/setup-prompt.md
**行番号**: 804-811

**現象**: アップグレード完了後、ユーザーが明示的に指示していないのに自動でサイクル開始フローに入る

---

## 2. AIレビュー関連

### 2.1 MCPレビュー処理

**Inception Phase** (docs/aidlc/prompts/inception.md:119-133):
- mode = "required": MCP利用可能時はレビュー必須、利用不可時は警告
- mode = "recommend": 推奨メッセージを表示（デフォルト）
- mode = "disabled": 何も表示しない

**Construction Phase** (docs/aidlc/prompts/construction.md:181-195):
- 同様の構成

**対象タイミング**:
- Inception: Intent承認前、ユーザーストーリー承認前、Unit定義承認前
- Construction: 設計レビュー前、コード生成後、テスト完了後

### 2.2 レビューがスキップされる条件

| 条件 | 動作 |
|-----|------|
| mode = "disabled" | レビューなし |
| mode = "required" かつ MCP利用不可 | 警告表示（詳細実装が不明確） |

**問題点**: mode = "required" 時の強制実行メカニズムが不明確

---

## 3. worktree関連

### 3.1 現在のworktree作成コマンド

**ファイル**: prompts/package/prompts/setup.md:415-420

**問題のあるコマンド**:
```bash
git -C [元のディレクトリ名] worktree add -b cycle/{{CYCLE}} [元のディレクトリ名]-{{CYCLE}}
```

**問題点**:
- `git -C` で相対パスを使用するとリポジトリディレクトリ基準になる
- メインディレクトリ内にworktreeが作成される

### 3.2 正しいコマンド

```bash
# メインディレクトリから実行
git worktree add ../ai-dlc-starter-kit-{{CYCLE}} cycle/{{CYCLE}}
```

**ポイント**:
- 相対パス `../` を明示的に使用
- `git -C` を使わない

### 3.3 誤ったworktreeの修正手順

```bash
git worktree remove ai-dlc-starter-kit-{{CYCLE}}
git worktree add ../ai-dlc-starter-kit-{{CYCLE}} cycle/{{CYCLE}}
```

---

## 4. CI/CD関連

### 4.1 既存のGitHub Actions

**ファイル**: .github/workflows/auto-tag.yml

**内容**: Mainブランチへのプッシュ時に自動タグ作成のみ

**不足している機能**:
- Markdownリンター
- PRチェック
- ビルド・テスト

---

## 5. v1.5.1 Breaking Change

### 5.1 setup-cycle.md の削除

**問題**: v1.5.1で`setup-cycle.md`が`setup.md`にリネームされた

**影響**:
- v1.5.0以前のプロジェクトでアップグレードせずにサイクル開始すると失敗
- 存在しない`setup.md`を読み込もうとする

**修正案**: スターターキット内の`prompts/package/prompts/setup.md`を参照させる

---

## 6. 問題箇所一覧表

| カテゴリ | ファイル | 行番号 | 問題内容 | 優先度 |
|---------|---------|--------|----------|--------|
| zsh互換性 | prompts/setup-prompt.md | 56 | grep -oP の非互換性 | 中 |
| zsh互換性 | docs/aidlc/prompts/setup.md | 73 | grep -oP の非互換性 | 中 |
| サイクル開始 | prompts/setup-prompt.md | 83, 106 | 自動読み込み vs 新規セッション | 中 |
| サイクル開始 | prompts/setup-prompt.md | 804-811 | 完了メッセージと実装の矛盾 | 中 |
| MCPレビュー | inception.md | 119-133 | mode="required" の詳細未実装 | 高 |
| MCPレビュー | construction.md | 181-195 | mode="required" の詳細未実装 | 高 |
| worktree | setup.md | 415-420 | git -C の誤使用 | 高 |
| CI/CD | auto-tag.yml | - | Markdownリンター未実装 | 中 |

---

## 7. 修正対象ファイル一覧

### セットアップ関連
- `prompts/setup-prompt.md`
- `prompts/package/prompts/setup.md`

### AIレビュー関連
- `prompts/package/prompts/inception.md`
- `prompts/package/prompts/construction.md`
- `prompts/package/prompts/operations.md`（確認が必要）

### CI/CD関連
- `.github/workflows/` に新規ワークフロー追加

**注意**: `docs/aidlc/` は `prompts/package/` の rsync コピーのため、直接編集禁止

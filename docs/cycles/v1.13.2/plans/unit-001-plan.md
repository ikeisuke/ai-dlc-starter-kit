# Unit 001 計画: init-label修正とbacklogディレクトリ条件分岐

## 概要

Issue駆動モード（backlog.mode=issue/issue-only）利用者向けの不具合修正を行う。

## 変更対象ファイル

1. `prompts/setup-prompt.md` - init-labels.sh呼び出しパス修正
2. `prompts/package/bin/init-labels.sh` → `prompts/setup/bin/init-labels.sh` に移動
3. `prompts/package/bin/init-cycle-dir.sh` - backlogディレクトリ作成条件修正

## 現状分析

### 1. init-labels.shの配置問題

- **現状**: `prompts/package/bin/init-labels.sh` にある
- **問題**: セットアップ専用スクリプトが `prompts/package/bin/` にあり、rsyncで不要にコピーされる
- **あるべき姿**: `prompts/setup/bin/init-labels.sh` に配置（セットアップ専用スクリプト）

`setup-prompt.md` のセクション8.2.6（行1306-1329）を確認:

```bash
docs/aidlc/bin/init-labels.sh  # 現在の呼び出しパス（rsync後のパス）
```

修正後:

```bash
prompts/setup/bin/init-labels.sh  # セットアップ専用パス（直接呼び出し）
```

または環境に応じた呼び出し:

```bash
[スターターキットパス]/prompts/setup/bin/init-labels.sh
```

### 2. backlogディレクトリ作成条件

`prompts/package/bin/init-cycle-dir.sh` の行180-185を確認:

```bash
# issue-onlyの場合はスキップ
if [[ "$backlog_mode" == "issue-only" ]]; then
    echo "dir:docs/cycles/backlog:skipped-issue-only"
    ...
fi
```

- 現在: `issue-only` のみスキップ
- 要件: `issue` もスキップすべき
- **修正が必要**

## 実装計画

### Phase 1: 設計

スクリプト修正のため省略（技術的考慮事項に基づく）

### Phase 2: 実装

1. **init-labels.shの移動**
   - `prompts/package/bin/init-labels.sh` → `prompts/setup/bin/init-labels.sh`
   - `docs/aidlc/bin/init-labels.sh` を削除（rsyncコピー先）

2. **setup-prompt.mdの修正**
   - セクション8.2.6の呼び出しパスを修正
   - `docs/aidlc/bin/init-labels.sh` → `[スターターキットパス]/prompts/setup/bin/init-labels.sh`

3. **init-cycle-dir.shの修正**
   - 行180-185の条件を `issue-only` → `issue` または `issue-only` に変更
   - 出力メッセージを `skipped-issue-only` → `skipped-issue-mode` に変更

4. **テスト**
   - `backlog.mode=git` でbacklogディレクトリが作成されることを確認
   - `backlog.mode=issue` でbacklogディレクトリがスキップされることを確認
   - `backlog.mode=issue-only` でbacklogディレクトリがスキップされることを確認

## 完了条件チェックリスト

### Unit定義の責務から抽出

- [x] `prompts/setup-prompt.md` にinit-labels.sh呼び出しを追加（セットアップ・アップグレード両方）
- [x] `prompts/package/bin/init-cycle-dir.sh` のbacklogディレクトリ作成条件を修正（issue/issue-only両方でスキップ）

### 関連Issue（#169）の受け入れ基準から抽出

- [x] `prompts/setup-prompt.md` の初回セットアップフロー（8.2.6節）で init-labels.sh が呼び出される
- [x] `prompts/setup-prompt.md` のアップグレードフロー（8.2.6節）で init-labels.sh が呼び出される
- [x] 既存ラベルは上書きされずスキップされる（init-labels.shの既存機能）
- [x] `prompts/setup/bin/init-labels.sh` が存在する（セットアップ専用スクリプト）

### 関連Issue（#162）の受け入れ基準から抽出

- [x] `backlog.mode=issue` で `init-cycle-dir.sh` を実行すると、`docs/cycles/backlog/` が作成されない
- [x] `backlog.mode=issue-only` で `init-cycle-dir.sh` を実行すると、`docs/cycles/backlog/` が作成されない
- [x] `backlog.mode=git` で `init-cycle-dir.sh` を実行すると、`docs/cycles/backlog/` が作成される
- [x] Issue駆動モード時の出力に `dir:docs/cycles/backlog:skipped-issue-mode` が表示される

### 追加修正（AIレビューで発見）

- [x] `prompts/package/guides/backlog-management.md` のinit-labels.shパスを修正
- [x] `docs/aidlc/guides/backlog-management.md` のinit-labels.shパスを修正
- [x] dasel構文をリポジトリ内で統一（v2/v3共通形式）
- [x] awkフォールバックでインラインコメントを適切に処理

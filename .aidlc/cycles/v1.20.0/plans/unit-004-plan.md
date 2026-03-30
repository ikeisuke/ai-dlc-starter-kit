# Unit 004 計画書 - squash-unit スキル定義

## 概要

`squash-unit.sh` をスキル呼び出しで実行できるようにするためのSKILL.md定義を作成し、`commit-flow.md` にスキル呼び出しの推奨を追記する。

## 変更対象

1. `prompts/package/skills/squash-unit/SKILL.md`（新規作成）
2. `prompts/package/prompts/common/commit-flow.md`（追記）
3. `.claude/skills/squash-unit` → `../../docs/aidlc/skills/squash-unit` シンボリックリンク（新規作成）

## 変更詳細

### 1. SKILL.md 作成

既存スキル（session-title, reviewing-code等）のSKILL.md構造に準拠。

#### YAML front matter

```yaml
---
name: squash-unit
description: "squash-unit.shを実行してUnit完了時またはInception Phase完了時の中間コミットをスカッシュする。commit-flow.mdのスカッシュフロー内で使用される。ユーザーが「squash-unit」「squash unit」「スカッシュ」と指示した場合にも使用。"
argument-hint: <cycle> <unit_number> [retroactive]
---
```

#### 本文構成

1. **概要**: スキルの目的と使用タイミング
2. **引数解決手順**: 各引数の自動解決方法
   - `--cycle`: ブランチ名から抽出（`cycle/` プレフィックス除去）
   - `--unit`: 現在作業中のUnit番号
   - `--vcs`: `rules.vcs.type` から読み取り（デフォルト: `git`）
   - `--base`: コミット履歴からUnit開始コミットの直前を特定
   - `--message` / `--message-file`: Writeツールで一時ファイル作成 → `--message-file` で渡す → 削除
3. **dry-runフロー**: `--dry-run` で対象コミット一覧表示 → 続行確認
4. **実行フロー**: 通常squashとretroactive squashの手順
5. **エラーハンドリング**: エラー出力のパターン別対応、`commit-flow.md` 手動フローへの誘導
6. **retroactiveモード**: `--retroactive --from --to` の使い方

### 2. commit-flow.md への追記

squash実行セクション（L468付近）の前に、スキル呼び出し推奨の記述を追加:
- `/squash-unit` スキルの使用を推奨
- 従来の直接呼び出しフローは維持（フォールバック用）

### 3. シンボリックリンク作成

```bash
ln -s ../../docs/aidlc/skills/squash-unit .claude/skills/squash-unit
```

注: `docs/aidlc/skills/squash-unit/` はセットアップ時に `prompts/package/skills/squash-unit/` から rsync 同期される。開発中は直接 `prompts/package/skills/squash-unit/` を編集し、シンボリックリンクは `docs/aidlc/` 側を指す。

## テスト観点

1. SKILL.md の YAML front matter が既存スキルと整合すること
2. 引数自動解決手順が正確であること
3. dry-runフローが記述されていること
4. エラーハンドリングが網羅されていること
5. commit-flow.md への追記が既存フローを壊さないこと
6. retroactiveモードが記述されていること

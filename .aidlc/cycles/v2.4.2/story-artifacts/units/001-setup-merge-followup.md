# Unit: aidlc-setup マージ後フォローアップ

## 概要

`/aidlc-setup` のアップグレードフロー最終ステップに、PR マージ後の (1) 一時ブランチ削除案内（#607 setup 側）と (2) HEAD 同期（#605）を追加する。両者ともユーザー対話によるオプトイン方式とし、`/aidlc-setup` の既存フロー（コミット完了まで）を破壊しない。

## 含まれるユーザーストーリー

- ストーリー1: アップグレード一時ブランチの自動削除案内（#607、setup スコープのみ）
- ストーリー2: アップグレード後の HEAD 自動同期（#605）

## 責務

- `skills/aidlc-setup/steps/03-migrate.md`（§10「アップグレードの場合」見出し配下に `#### マージ後フォローアップ` サブサブセクションを追加。詳細な配置案は Phase 1 設計レビュー反復2 で確定）に、以下のフローを追加:
  1. **マージ確認ガード**: 「PR をマージしましたか？」をユーザーに **1 回のみ** 確認（はい/いいえ/判断保留 など）。同意時は (2) → (3) → (4) を連続提示
  2. **未コミット差分ガード**: HEAD 同期前に未コミット差分を検出した場合は同期を中断し、stash / commit / 中止のいずれかをユーザーに案内（既定: 中止）
  3. **HEAD 同期案内**: `git fetch origin --prune` 実行後、worktree / 通常ブランチ / detached HEAD の現在状態に応じて 5 サブ条件マトリクスで `origin/main` の最新コミットに HEAD を一致させる
  4. **一時ブランチ削除案内**（HEAD 同期成功後にのみ実行）: `chore/aidlc-v<version>-upgrade` ローカル + リモートブランチの削除を提案 → 同意で `git branch -d` + `git push origin --delete`（push 失敗時は warning + 継続）。3 択（ローカル+リモート / ローカルのみ / スキップ）で push 権限不在ユーザーに対応

**実行順序の根拠**: §9 完了直後の HEAD は `chore/aidlc-v<version>-upgrade` をチェックアウト中。git 制約により現在のチェックアウトブランチを `git branch -d|-D` で削除できないため、HEAD 同期で `chore/...` から離脱した後にのみ一時ブランチ削除を提案する（Phase 1 設計レビュー反復1 指摘 #2 由来、Construction Phase Unit 001 で確定）
- `skills/aidlc-setup/SKILL.md`: 新規ステップ（§9.5 / §10 等）への誘導見出し追記のみ。本体記述は `steps/03-migrate.md` 側に集約
- スキップ選択時はローカル/リモートいずれも変更しない

## 境界

- `aidlc-migrate` 側の一時ブランチ削除案内は Unit 002 で扱う（本 Unit のスコープ外）
- `bin/post-merge-sync.sh` への変更は行わない（Intent 制約準拠）
- マージ済み自動検出（`gh pr view`）は実装しない（誤検出リスクと patch 範囲の制約）

## 依存関係

### 依存する Unit

- なし（Unit 002 / Unit 003 と独立）

### 外部依存

- `git` CLI（標準依存）
- `gh` CLI は使用しない（マージ済み自動検出をスコープ外としたため）

## 非機能要件（NFR）

- **パフォーマンス**: 追加処理は対話 + 数回の `git` コマンド呼び出しのみ。setup フロー全体への影響は無視できる程度
- **セキュリティ**: リモート push 権限がないユーザー環境で実行された場合に warning のみで停止しない（破壊的変更を起こさない）
- **可用性**: 既存の setup フロー（コミットまで）は本 Unit の処理失敗時にも完了している必要がある（追加処理は最終ステップに配置）

## 技術的考慮事項

- **3 ケース分岐の git コマンド系列**: Construction Phase の設計レビューで以下から選定（候補）:
  - 通常ブランチ: `git pull --ff-only` または `git reset --hard origin/main`
  - detached HEAD: `git checkout --detach origin/main`
  - worktree: 当該 worktree のチェックアウト位置を `origin/main` に揃える（具体実装は `git -C <worktree-path> ...` を利用）
- **未コミット差分検出**: `git status --porcelain` の出力を判定基準とする
- **対話 UI**: `AskUserQuestion` 利用が有力候補だが、Construction Phase で確定（Intent §「不明点と質問」Q3 準拠）
- **Unit 002 との重複領域**: #607 のローカルブランチ削除ロジックは Unit 002 と類似。Construction Phase 着手時に共通化（共通関数 / 共通セクション参照）の余地を再評価する

## 関連Issue

- #607（部分対応、setup 側のみ。migrate 側は Unit 002）
- #605（Closes 対象）

## 実装優先度

High

## 見積もり

中〜大規模（手順書追記 + 3 ケース分岐の検証 + 未コミット差分ガード + 対話 UI 確定の不確実性）。Construction Phase で 1 Unit セッション内に収まる想定だが、3 ケース分岐の git コマンド系列確定で設計レビューに 1 ラウンド追加される可能性あり。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-04-26
- **完了日**: 2026-04-26
- **担当**: Claude Code (Opus 4.7)
- **エクスプレス適格性**: -
- **適格性理由**: -

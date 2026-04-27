# Test Walkthrough: Unit 001 - aidlc-setup マージ後フォローアップ

## 概要

本 Unit は Markdown 手順書改訂のため、実装コード単体テストではなく **手順書 walkthrough** をテスト相当として実施する。完了条件チェックリスト（plan）・INV（domain model）・AskUserQuestion パスを逐次照合し、すべての項目が手順書に正確に反映されていることを検証する。

## 検証対象

- `skills/aidlc-setup/steps/03-migrate.md`（§10「アップグレードの場合」配下の `#### マージ後フォローアップ` サブサブセクション、line 64-221）

## 検証結果サマリ

| 項目 | 結果 |
|------|------|
| 完了条件チェックリスト（機能要件） | ✓ 全 12 項目 反映 |
| Issue 終了条件（#607 / #605） | ✓ 全 4 項目 反映 |
| 不変条件（INV-1〜INV-10） | ✓ 全 10 件 反映 |
| AskUserQuestion パス（5 種） | ✓ 全 5 種 定義 |
| 5 サブ条件マトリクス | ✓ 完全反映 |
| markdownlint | ✓ 0 error |

## 詳細検証

### 1. 完了条件チェックリスト（plan 由来）

#### 1.1 機能要件

| # | チェック項目 | 検証結果 | 反映箇所 |
|---|------------|---------|---------|
| 1 | マージ確認ガード（はい / いいえ / 判断保留 の 3 択、AskUserQuestion 使用） | ✓ | line 84-90 |
| 2 | 「いいえ」「判断保留」選択時はローカル / リモートいずれも変更しないことが明示 | ✓ | line 94 |
| 3 | 「はい」選択時の連続フローが順序（マージ確認 → 未コミット差分 → HEAD 同期 → ブランチ削除）で記述 | ✓ | line 68-73 |
| 4 | ローカル削除コマンドが手順書内に記述 | ✓ | line 195-198（`-d`）/ line 202-204（`-D` フォールバック） |
| 5 | リモート削除は `git push origin --delete`、push 失敗時 warning + 継続が明示 | ✓ | line 211-219 |
| 6 | 「未コミット差分ガード」が「HEAD 同期前」に評価される旨が順序保証されている | ✓ | line 68-73, 96-116 |
| 7 | 未コミット差分検出時、stash / commit / 中止の選択肢、既定中止が明示 | ✓ | line 110-114 |
| 8 | `git fetch origin --prune` 実行と `--prune` の副作用注記 | ✓ | line 131, 135 |
| 9 | 通常ブランチ / detached HEAD / worktree の 3 ケース分岐 git コマンド系列が手順書内に記述 | ✓ | line 152-160 |
| 10 | 3 ケース検出ロジックの手順が手順書内に記述 | ✓ | line 138-150 |
| 11 | アップグレードフロー（ケースC）でのみ実行が手順書内に明示 | ✓ | line 66 + (b) サブサブセクション配置で構造的保証 |
| 12 | SKILL.md への誘導見出し追記（Phase 1 設計レビュー結果に従う、不要時はスキップ可） | ✓ | 設計レビュー結果「不要」のため変更なし（README.md / SKILL.md 共に変更なし） |

#### 1.2 Issue 終了条件（Intent 由来）

| # | チェック項目 | 検証結果 | 反映箇所 |
|---|------------|---------|---------|
| 13 | #607（setup 側）: ローカル / リモート削除手順（`git branch -d` / `-D` / `git push origin --delete`）が記述 | ✓ | line 197, 204, 212 |
| 14 | #607（setup 側）: 同意拒否時はローカル / リモートいずれも変更されないことが明示 | ✓ | line 94, line 188-189（スキップ選択肢） |
| 15 | #605: 3 ケース（worktree / 通常ブランチ / detached HEAD）すべてで「ローカル HEAD を `origin/main` の最新コミットに一致させる」git コマンド系列が記述 | ✓ | line 152-160（5 サブ条件マトリクス） |
| 16 | #605: 未コミット差分ガード（中断 / 強制継続 / stash / commit）が定義 | ✓ | line 110-114 |

### 2. 不変条件（INV）の反映

| INV | 内容 | 反映箇所 |
|-----|------|---------|
| INV-1 | オプトイン保証（同意なしで破壊操作を行わない） | line 79（全体の前提）+ 各ステップの選択肢設計で達成 |
| INV-2 | push 失敗の非破壊継続 | line 215-219 |
| INV-3 | 差分保護（stash/commit で解消後に進行、untracked のみは続行） | line 100-116 |
| INV-4 | HEAD 一致条件（同期成功時のみ。ff 不可時はサマリ通知） | line 168-177 |
| INV-5 | `git reset --hard origin/main` 自動実行禁止 | line 164 |
| INV-6 | アップグレードフロー（ケースC）限定 | line 66 + サブサブセクション配置 |
| INV-7 | AskUserQuestion 必須性（automation_mode 非依存） | line 79-80 |
| INV-8 | チェックアウト中ブランチ削除回避 | line 68-75（順序根拠）+ line 181（事前条件） |
| INV-9 | 一時ブランチ削除のオプトイン分離（3 択） | line 185-189 |
| INV-10 | 再検査ループ上限（最大 3 回、AI 内部管理） | line 116 |

### 3. AskUserQuestion パス検証

5 種の `AskUserQuestion` が必要箇所に配置され、各々に `header` / 選択肢 / 後続状態が定義されている:

| # | コマンド名（論理設計由来） | 配置箇所 | header | 選択肢数 |
|---|--------------------------|---------|--------|---------|
| 1 | MergeConfirm | line 82-90 | "マージ確認" | 3（はい / いいえ / 判断保留） |
| 2 | DiffResolution（条件付き） | line 108-114 | "差分解消" | 3（中止 / stash / commit） |
| 3 | SyncConsent | line 118-127 | "HEAD同期" | 2（同意 / スキップ） |
| 4 | BranchDeleteConsent | line 183-189 | "ブランチ削除" | 3（ローカル+リモート / ローカルのみ / スキップ） |
| 5 | BranchDeleteFallbackConsent（条件付き） | line 200-205 | "強制削除確認" | 2（-D 強制 / スキップ） |

### 4. 5 サブ条件マトリクスの完全性

論理設計の 5 サブ条件マトリクスと手順書 line 152-160 の表をセル単位で照合:

| 現在の HEAD 状態 | 検出ロジック | 一次選択コマンド | フォールバック | 整合 |
|-----------------|-------------|----------------|--------------|------|
| 通常ブランチ（main 系） | --git-common-dir == --git-dir AND symbolic-ref == main | git pull --ff-only | ff 不可 → 警告 + スキップ | ✓ |
| 通常ブランチ（フィーチャ系） | --git-common-dir == --git-dir AND symbolic-ref != main | git checkout --detach origin/main | - | ✓ |
| detached HEAD | symbolic-ref exit !=0 | git checkout --detach origin/main | - | ✓ |
| worktree（main 系） | --git-common-dir != --git-dir AND symbolic-ref == main | git pull --ff-only | ff 不可 → 警告 + スキップ | ✓ |
| worktree（フィーチャ系） | --git-common-dir != --git-dir AND symbolic-ref != main | git checkout --detach origin/main | - | ✓ |

### 5. 静的解析

| ツール | 結果 |
|--------|------|
| markdownlint-cli2 | ✓ 0 error（line 0..221 / 全文 PASS） |

## 結論

すべての完了条件・不変条件・AskUserQuestion パス・5 サブ条件マトリクスが手順書に正確に反映されており、markdownlint 違反もない。手順書 walkthrough テスト合格。

## 制約事項（変更不可）

- **実走行検証は本 Unit のスコープ外**: Operations Phase リリース後の運用検証（別リポジトリでの v2.4.1 → v2.4.2 アップグレード走行）に委ねる
- **`AskUserQuestion` ランタイム挙動の検証**: Claude Code 上での AskUserQuestion 表示は手順書記述レベルで検証可能。実 UI レンダリング検証はランタイム環境で実施

# Unit 001 実装計画: aidlc-setup マージ後フォローアップ追加

## 対象

- Unit 定義: `.aidlc/cycles/v2.4.2/story-artifacts/units/001-setup-merge-followup.md`
- 対象 Issue: #607（部分対応、setup 側）/ #605（Closes 対象）
- 主対象ファイル: `skills/aidlc-setup/steps/03-migrate.md`（既存 §9 Git コミットの直後、§10 完了メッセージとの間に新規セクションを追加。具体的な配置案は後述「挿入位置の選択肢」を Phase 1 設計レビューで確定）
- 条件付き対象ファイル: `skills/aidlc-setup/SKILL.md`（「ステップ実行」リスト自体は 3 ステップ列挙で完結しているため、内部節追加のみで済む可能性が高い。SKILL.md 改訂の要否は Phase 1 設計レビューで確定）
- 整合確認のみ:
  - `skills/aidlc-migrate/steps/03-verify.md`（Unit 002 の対象。本 Unit のメッセージテキスト・git コマンド系列を Unit 002 設計レビュー時に流用判断）
  - `bin/post-merge-sync.sh`（既存挙動の理解のみ。本 Unit では変更しない）

## スコープ

`/aidlc-setup` のアップグレードフロー（ケースC）最終ステップに、以下 4 機能項目（**順不同の機能列挙であり、実行順序は次節「実行順序」で別途確定**）を実装する:

- **マージ確認ガード**: 「PR をマージしましたか？」を 1 回のみ確認（はい / いいえ / 判断保留）。「はい」選択時のみ後続の機能を連続提示
- **一時ブランチ削除案内**: `chore/aidlc-v<version>-upgrade` のローカル + リモートブランチ削除を提案 → 同意で `git branch -{d|D}` + `git push origin --delete`（push 失敗時は warning 出力のみで継続）
- **未コミット差分ガード**: HEAD 同期前に `git status --porcelain` で未コミット差分を検出した場合、stash / commit / 中止のいずれかをユーザーに案内し、既定では中止する
- **HEAD 同期案内**: `git fetch origin --prune` 後、worktree / 通常ブランチ / detached HEAD の 3 ケースで HEAD を `origin/main` 最新コミットに揃える

すべてオプトインで、スキップ選択時はローカル / リモートいずれも変更しない。`/aidlc-setup` の既存フロー（§9 コミット完了まで）を破壊しない。

### 実行順序（一意に固定 / Phase 1 設計レビュー反復2 で確定）

**重要な変更（Phase 1 設計レビュー反復1 / 指摘 #2 由来）**: `chore/aidlc-v*-upgrade` ブランチは §9 完了直後に **チェックアウト中** であり、git 制約により現在のチェックアウトブランチを `git branch -d|-D` で削除できない。したがって BranchDelete は HEAD 同期によって HEAD が `chore/...` から離脱した後に実行する順序に確定する。

```text
[Initial]
  ↓
ConfirmMerge（マージ確認ガード: はい / いいえ / 判断保留）
  ├─ いいえ / 判断保留 → [Skip] → 既存 §10 完了メッセージへ
  └─ はい
       ↓
UncommittedDiffGuard（未コミット差分ガード: tracked / untracked 分離判定）
  ├─ 出力空 / untracked のみ → 次へ
  └─ tracked 差分あり → stash / commit / 中止 を提示、既定中止 → [Skip]
       ↓
HeadSync（HEAD 同期案内: 5 サブ条件マトリクス）
  ├─ スキップ → [Skip]（一時ブランチ削除も一律スキップ）
  └─ 同意 → fetch → 5 サブ条件マトリクスに従い同期
       ├─ 成功 → BranchDelete へ進行
       └─ ff 不可 → 警告通知 + 一時ブランチ削除スキップ → [Skip]
       ↓
BranchDelete（一時ブランチ削除案内: HEAD 同期成功後にのみ到達）
  ├─ スキップ → 次へ
  ├─ ローカルのみ削除 → ローカル削除（-d → 失敗時 -D 再確認）
  └─ ローカル+リモート両方 → ローカル削除 → リモート削除（失敗時 warning + 継続）
       ↓
[既存 §10「アップグレードの場合」完了メッセージへ]
```

## 実装方針

### Phase 1（設計）

#### ドメインモデル設計（Markdown 手順書改訂のための状態遷移モデル）

- エンティティ:
  - `MergeConfirmGuard`（はい / いいえ / 判断保留 → 後続フローへの分岐）
  - `BranchDeleteFlow`（ローカル削除 → リモート削除 → 失敗時 warning 継続）
  - `UncommittedDiffGuard`（差分検出 → stash / commit / 中止、既定中止）
  - `HeadSyncFlow`（fetch → 3 ケース分岐: 通常ブランチ / detached HEAD / worktree）
- 状態遷移: 上記「実行順序」セクションの図に従う

#### 論理設計（必須成果物）

Phase 1 設計成果物として以下のマトリクス・選定をすべて確定する:

1. **3 ケース検出ロジック**: 「現在の HEAD 状態」から worktree / 通常ブランチ / detached HEAD を判別する手順を確定
   - 検出候補: `git rev-parse --git-common-dir` と `git rev-parse --git-dir` の比較で worktree 判定
   - `git symbolic-ref -q HEAD` 成功 / 失敗で通常ブランチ vs detached HEAD 判定
2. **3 ケース × git コマンド系列マトリクス（必須）**:

   | 現在の HEAD 状態 | サブ条件 | 一次選択コマンド | フォールバック | 破壊性レベル |
   |-----------------|---------|----------------|--------------|------------|
   | 通常ブランチ（main 系） | ff 可 | `git pull --ff-only` | （ff 不可: 中断 + 推奨案内） | 非破壊 |
   | 通常ブランチ（フィーチャ） | - | `git checkout --detach origin/main`（ブランチ移動を避ける） | - | 非破壊 |
   | detached HEAD | - | `git checkout --detach origin/main` | - | 非破壊 |
   | worktree（main 系 checkout） | ff 可 | `git pull --ff-only` | ff 不可: 中断 + 推奨案内 | 非破壊 |
   | worktree（フィーチャ checkout） | - | `git checkout --detach origin/main` | - | 非破壊 |

   - **`git -C <worktree-path>` は使用しない**: 現在の作業ディレクトリ（=対象 worktree）で直接実行する前提
   - **`git reset --hard origin/main` は一次案に採用しない**: 破壊的操作のため、ff 不可ケースは中断 + 「`git reset --hard origin/main` を手動実行する場合は別ターミナルで」と案内する形で安全側に倒す（設計レビューで再確認）
3. **対話 UI 仕様**:
   - 一次案: `AskUserQuestion`（Claude Code 上での AI エージェント実行前提）
   - フォールバック設計: `AskUserQuestion` 不採用となった場合、静的メッセージ + ユーザーの自由入力を待つ形式（`/aidlc-setup` がスクリプト経由で実行される場合の互換性確保）も Phase 1 設計成果物として記述
   - 設計レビューで一次案を承認後に Phase 2 に進む
4. **ローカル削除コマンド選定**:
   - 一次選択: `git branch -d`（マージ済み判定 + 安全側）
   - フォールバック: `git branch -d` 失敗時は `git branch -D` 提案再確認（squash merge / rebase merge 後はマージ判定が外れるため）
   - Phase 1 設計レビューで `-d` 一次 / `-D` 一次 / 両者並列提示のいずれかを確定
5. **`git fetch --prune` 副作用の評価**: `--prune` はリモート追跡ブランチも整理するため、副作用を手順書内に注記する
6. **挿入位置の選択肢**: 以下 2 案を Phase 1 設計レビューで選択
   - **(a) §9 と §10 の間に新規節として独立配置**: 冒頭に「本セクションはアップグレードフロー（ケースC）でのみ実行される」と明示。初回セットアップ・移行ケースは本セクションをスキップ
   - **(b) §10「アップグレードの場合」サブセクション内に統合**: ケースCのメッセージ表示直前に組み込み、初回・移行ケースとの干渉を構造的に排除
   - リナンバ影響範囲（少なくとも `steps/03-migrate.md` 内 §10 以降のすべて、および「次のステップ: サイクル開始」セクションの連動）を (a) 採用時に棚卸しする
7. **SKILL.md 改訂要否の評価**: 現状の `skills/aidlc-setup/SKILL.md` は「ステップ実行」が 3 ステップ列挙で完結しており、`steps/03-migrate.md` 内の節追加だけで済む可能性が高い。SKILL.md 改訂は Phase 1 設計レビューで「必要 / 不要」を確定し、不要なら本 Unit のスコープから外す

#### Unit 002 との共通化（Phase 1 設計成果物の付帯）

- 一時ブランチ削除のメッセージテキスト・コマンド系列は Unit 002（aidlc-migrate）でも採用候補となる
- 本 Unit では setup 側の文面を確定し、Unit 002 の設計レビュー時に「流用 / 独立記述」を判断する想定
- Unit 定義（Unit 002 側）にすでに「ソフト依存（推奨実装順序: Unit 001 → Unit 002）」が記載されているため、本 Unit は単独で完結し、Unit 002 への共通化判断は Unit 002 のスコープに委ねる（**本 Unit から Unit 002 への新たな依存は導入しない**）

### Phase 2（実装）

- 改訂対象: Phase 1 で確定した挿入位置（(a) または (b) ）に従って `skills/aidlc-setup/steps/03-migrate.md` を更新
- (a) 採用時: §10 以降のリナンバを Phase 1 棚卸し結果に従って一括反映
- (b) 採用時: §10「アップグレードの場合」サブセクション内に組み込み、リナンバなし
- 実装内容: マージ確認ガード / 一時ブランチ削除フロー / 未コミット差分ガード / HEAD 同期フロー（Phase 1 マトリクスに従う）
- アップグレードフロー（ケースC）限定の明示: 冒頭または注記で必ず明示
- SKILL.md 更新: Phase 1 結果が「不要」なら本 Phase で対象外、「必要」なら誘導見出しのみ追記

### Phase 2b（検証）

- **手順書 walkthrough**: 既存 §10 完了メッセージとの順序関係（マージ後の同期 → 完了メッセージ）が破綻しないことを読み合わせで確認
- **3 ケース分岐の動作確認（手順書レベル）**: Phase 1 マトリクスのとおりに記述されているか目視確認
- **markdownlint 実行**: 改訂した Markdown ファイルを対象に `markdown_lint=true` で違反なし確認
- **実走行検証は本 Unit のスコープ外**: Operations Phase リリース後の運用検証（別リポジトリでの v2.4.1 → v2.4.2 アップグレード走行）に委ねる

### Phase 3（完了処理）

- **設計 / コード / 統合 AI レビュー**: `review-flow.md` に従い 3 種実施。`review_mode=required` のためスキップ不可
- **Unit 定義ファイル状態更新**: `story-artifacts/units/001-setup-merge-followup.md` の実装状態を「完了」に更新、完了日記録
- **履歴記録**: `/write-history` スキルで `.aidlc/cycles/v2.4.2/history/construction_unit01.md` に追記
- **Markdownlint 実行**: 改訂対象 Markdown を lint
- **Squash 実行**: `squash_enabled=true` のため `/aidlc:squash-unit` で中間コミットを UNIT_COMPLETE 形式に統合
- **Git コミット**: Squash 後の状態確認

## 完了条件チェックリスト

> **観測条件の境界**: 本 Unit は手順書追加が主体で、実走行検証はスコープ外。完了条件は **「手順書内に該当記述が存在すること」** を基準とする。`git rev-parse HEAD == git rev-parse origin/main` 等の実走行観測は Operations Phase リリース後の運用検証（別リポジトリ）で確認する。

### 機能要件（Unit 定義「責務」由来）

- [ ] `skills/aidlc-setup/steps/03-migrate.md` に「マージ確認ガード」が記述されている（はい / いいえ / 判断保留 の 3 択、対話 UI は Phase 1 で確定したものを使用）
- [ ] 「いいえ」「判断保留」選択時はローカル / リモートいずれも変更しないことが手順書内に明示されている
- [ ] 「はい」選択時の連続フローが明示順序（マージ確認 → 未コミット差分ガード → HEAD 同期 → 一時ブランチ削除）で記述されている（Phase 1 設計レビュー反復1 指摘 #2 由来の順序変更: チェックアウト中ブランチは git 制約で削除不可のため、HEAD 同期で `chore/...` から離脱した後にのみ削除する）
- [ ] ローカル削除コマンドが手順書内に記述されている（`-d` / `-D` の選定は Phase 1 設計レビューで確定済み）
- [ ] リモート削除は `git push origin --delete` を使用、push 失敗時は warning 出力 + 継続（中断しない）が手順書内に明示されている
- [ ] 「未コミット差分ガード」が「HEAD 同期前」に評価される旨が手順書内で順序保証されている（`git status --porcelain` 利用）
- [ ] 未コミット差分検出時、stash / commit / 中止の選択肢が提示され、既定では中止することが手順書内に明示されている
- [ ] 「HEAD 同期案内」で `git fetch origin --prune` 実行と `--prune` の副作用注記が手順書内に記述されている
- [ ] 通常ブランチ / detached HEAD / worktree の 3 ケース分岐の git コマンド系列が Phase 1 マトリクスに従って手順書内に具体的に記述されている
- [ ] 3 ケース検出ロジック（worktree 判定・通常ブランチ vs detached HEAD 判定）の手順が手順書内に記述されている
- [ ] 新規セクションが「アップグレードフロー（ケースC）でのみ実行される」ことが手順書内に明示されている（挿入位置 (a) 採用時は冒頭、(b) 採用時はサブセクション位置で構造的に排除）
- [ ] SKILL.md への誘導見出し追記は Phase 1 設計レビュー結果に従う（必要時のみ追記、不要なら本項目はスキップ可）

### Issue 終了条件（Intent 由来、観測単位は手順書記述）

- [ ] **#607（setup 側）**: ユーザー同意時に `chore/aidlc-v*-upgrade` のローカル / リモートブランチを削除する手順（`git branch -{d|D}` および `git push origin --delete`）が手順書内に記述されている
- [ ] **#607（setup 側）**: 同意拒否時はローカル / リモートいずれも変更されないことが手順書内に明示されている
- [ ] **#605**: 同意時、3 ケース（worktree / 通常ブランチ / detached HEAD）すべてで「ローカル HEAD を `origin/main` の最新コミットに一致させる」git コマンド系列が手順書内に記述されている
- [ ] **#605**: 未コミット差分があるケースのガード手順（中断 / 強制継続 / stash / commit）が手順書内に定義されている

### プロセス要件

- [ ] 設計 AI レビュー承認（`review_mode=required`）
- [ ] コード AI レビュー承認（同上）
- [ ] 統合 AI レビュー承認（同上）
- [ ] Unit 定義ファイル状態を「完了」に更新
- [ ] 履歴記録（`construction_unit01.md`）
- [ ] Markdownlint 実行（`markdown_lint=true`）
- [ ] Squash 実行（`squash_enabled=true`）
- [ ] Git コミット

## 依存関係

- **依存する Unit**: なし（Unit 002 / Unit 003 と独立並列実装可能。Unit 定義 §依存関係と整合）
- **Unit 002 との関係**: 本 Unit から Unit 002 への新たな依存は導入しない。Unit 002 定義側に「ソフト依存（推奨実装順序: Unit 001 → Unit 002）」が記載されており、共通フォーマット流用判断は Unit 002 の設計レビュー時に行う

## 見積もり

- Phase 1（設計）: 0.25〜0.5 日
- Phase 2（実装）: 0.25〜0.5 日
- Phase 2b（検証）: 0.25 日
- Phase 3（完了処理）: 0.25 日

合計: 1.0〜1.5 日規模（Unit 定義の見積もり「中〜大規模」と整合）。

**上振れ要因**:

- 3 ケース分岐 × 通常/フィーチャ サブ条件のマトリクス確定で設計レビューに 1 ラウンド追加された場合、Phase 1 が +0.25 日（合計 1.0〜1.75 日）
- 挿入位置 (a) を採用しリナンバが大規模化した場合、Phase 2 が +0.25 日

## リスク・留意点

- **既存 §10 完了メッセージとの順序関係**: 新規セクションは §9 と §10 の間または §10 内サブセクション。Phase 1 設計レビューで挿入位置 (a)/(b) を確定し、リナンバ影響範囲を棚卸しする
- **アップグレードフロー（ケースC）限定の明示**: 新セクションは `chore/aidlc-v*-upgrade` ブランチが存在するアップグレード走行のみで意味を持つ。初回セットアップ / 移行ケースとの干渉を構造的に排除する
- **3 ケース分岐の git コマンド選定**: `git pull --ff-only` を非破壊な一次選択とし、ff 不可（force-push 履歴等）の場合は中断 + 推奨案内（`git reset --hard origin/main` の手動実行ガイダンス）にとどめる。`git reset --hard` を本フローで自動実行することは破壊性のため避ける（Phase 1 設計レビューで再確認）
- **worktree 検出ロジック**: `git rev-parse --git-common-dir` と `git rev-parse --git-dir` の比較等で worktree か main repository かを判別する手順を Phase 1 で確定する
- **対話 UI 採否の確定タイミング**: `AskUserQuestion` を Phase 1 一次案、設計レビューで承認後 Phase 2 へ進む。不採用時のフォールバック（静的メッセージ + 自由入力）も Phase 1 設計成果物として用意する
- **ローカル削除コマンド `-d` / `-D` の選定**: squash merge / rebase merge では `-d` がマージ判定外となり失敗するため、Phase 1 設計レビューで一次選択を確定する
- **`git fetch --prune` の副作用**: リモート追跡ブランチが整理されるため、副作用注記を手順書内に必ず入れる
- **メタ開発時の即時検証困難性**: 本 Unit は手順書追加が主体で、実走行検証は Operations Phase リリース後の運用検証（別リポジトリ）に委ねる。完了条件は「手順書内に該当記述が存在すること」を基準とし、Unit 完了条件と Issue 終了条件の境界を明確化する
- **SKILL.md 改訂要否**: 現状の SKILL.md は 3 ステップ列挙で完結しており、`steps/03-migrate.md` 内の節追加のみで済む可能性が高い。Phase 1 設計レビューで要否を確定する

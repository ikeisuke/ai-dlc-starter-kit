# Unit 002 実装計画: aidlc-migrate マージ後フォローアップ追加

## 対象

- Unit 定義: `.aidlc/cycles/v2.4.2/story-artifacts/units/002-migrate-merge-followup.md`
- 対象 Issue: #607（migrate 側拡大解釈、本 Unit のスコープ確定は DR-016 を参照）
- 主対象ファイル: `skills/aidlc-migrate/steps/03-verify.md`（§4 PR 作成案内の後ろに新規 §5「マージ後フォローアップ」を追加。同時に §4 末尾の `/aidlc inception` 案内文を §5 末尾に移動）
- 条件付き対象ファイル: `skills/aidlc-migrate/SKILL.md`（変更要否は Phase 1 設計レビューで確認、現状の SKILL.md は 3 ステップ列挙で完結している場合は変更不要）
- 整合確認のみ:
  - `skills/aidlc-setup/steps/03-migrate.md`（Unit 001 で確定したマージ後フォローアップ手順との文面・コマンド系列の整合）
  - DR-016（対象ブランチを `aidlc-migrate/v2` に修正した経緯）

## 現行 `skills/aidlc-migrate/steps/03-verify.md` の構造（Phase 1 着手前の確認）

```text
§1 移行後検証
§2 一時ファイルの削除
§3 完了メッセージ          ← 「v1→v2 移行が完了しました」（migrate スクリプトの作業完了通知）
§4 コミットとPR作成        ← 末尾に「PRをマージ後、新しいサイクルを開始するには /aidlc inception」案内あり
```

新規 §5 を §4 の後に追加する。§4 末尾の `/aidlc inception` 案内文は §5 末尾（マージ後フォローアップ完了直後）に移動することで、「PR push → §5 マージ後フォローアップ → `/aidlc inception` 案内」という直線的な流れを維持する。挿入位置の確定は Phase 1 設計レビューで再確認し、必要に応じて DR-017 として decisions.md に記録する。

## スコープ

`/aidlc-migrate` の最終ステップ（PR push 完了後）に、以下 3 機能項目を実装する:

- **マージ確認ガード**: 「v1→v2 マイグレーション PR をマージしましたか？」（はい / いいえ / 判断保留）
- **チェックアウト位置切替案内 + 簡易差分チェック**: 現在ブランチが `aidlc-migrate/v2` の場合、削除前に HEAD を `origin/main` に detach する手順（git 制約: チェックアウト中ブランチは削除不可）。`git checkout --detach` 実行前に `git status --porcelain` で tracked 差分の最低限チェックを行い、検出時は HEAD 切替を中止して案内
- **一時ブランチ削除案内**: `aidlc-migrate/v2` ローカル + リモートブランチ削除を 3 択（ローカル+リモート / ローカルのみ / スキップ）で提案。ローカル削除は `-d` 一次 + 失敗時 `-D` 再確認、リモート削除は push 失敗時 warning + 継続（Unit 001 で確定したパターン流用）

すべてオプトインで、スキップ選択時はローカル / リモートいずれも変更しない。`/aidlc-migrate` の既存フロー（§4 PR push まで）を破壊しない。

### 実行順序（一意に固定 / Unit 001 で確立した順序原則を踏襲）

```text
[§4 PR push 完了直後]
  ↓
ConfirmMerge（マージ確認ガード: はい / いいえ / 判断保留）
  ├─ いいえ / 判断保留 → [Skip] → §5 末尾の `/aidlc inception` 案内へ
  └─ はい
       ↓
HeadDetachGuard（チェックアウト位置切替案内 + 簡易差分チェック）
  - `git symbolic-ref --short HEAD` で現在ブランチ確認
  - 出力 == `aidlc-migrate/v2`:
       ├─ `git status --porcelain` で tracked 差分検出時 → 切替を中止し、tracked 差分の解消（stash / commit）を案内 → 案内のみで [Skip]（一時ブランチ削除も一律スキップ）
       └─ tracked 差分なし → `AskUserQuestion`（同意 / スキップ）
              ├─ 同意 → `git fetch origin --prune` → `git checkout --detach origin/main` → BranchDelete へ
              └─ スキップ → [Skip]（一時ブランチ削除も一律スキップ、INV-8 反映）
  - 出力 == `aidlc-migrate/v2` 以外（既に他ブランチ / detached HEAD）:
       └─ HEAD 切替不要 → BranchDelete へ直接進む（チェックアウト中でないため `git branch -d` 実行可能）
  - `aidlc-migrate/v2` ブランチ自体が存在しない:
       └─ BranchDelete もスキップ → §5 末尾の `/aidlc inception` 案内へ
       ↓
BranchDelete（一時ブランチ削除案内: HEAD 切替成功後または既に他ブランチの場合に到達）
  ├─ スキップ → §5 末尾の `/aidlc inception` 案内へ
  ├─ ローカルのみ削除 → ローカル削除（-d → 失敗時 -D 再確認）
  └─ ローカル+リモート両方 → ローカル削除 → リモート削除（失敗時 warning + 継続）
       ↓
[§5 末尾の `/aidlc inception` 案内へ（§4 から移動）]
```

### Unit 001 との差分（スコープ縮小）

> **不変条件番号体系の注記**: 以下は Unit 001 で確立した INV 番号を流用する。INV-3（差分保護フル機能）/ INV-4（HEAD 一致条件）/ INV-6（アップグレードフロー限定）/ INV-10（再検査ループ上限）は本 Unit では適用しない（Unit 001 のみで適用）。

- **未コミット差分ガード（フル機能、INV-3）スコープ外**: stash / commit / 中止 の 3 択提示や再検査ループは扱わない。**ただし**「マージ確認 → HEAD 切替」直前で `git status --porcelain` を実行し、tracked 差分検出時は HEAD 切替を中止する**最低限のチェック**は本 Unit に含める（Phase 1 設計レビュー反復1 指摘 #4 対応）
- **5 サブ条件マトリクス（INV 群の一部）スコープ外**: HEAD 切替は `aidlc-migrate/v2` チェックアウト中の 1 ケースのみ対応。worktree / detached HEAD / main 系判定は本 Unit では扱わない
- **fetch + 完全な HEAD 同期（INV-4）スコープ外**: HEAD 切替は「`origin/main` に detach する」最低限のみ。`git pull --ff-only` 系（main 系ブランチ更新）は対象外

## 実装方針

### Phase 1（設計）

#### Phase 1 設計成果物（必須）

1. **挿入位置の最終確定**: §5 を §4 の後に追加し、§4 末尾の `/aidlc inception` 案内を §5 末尾に移動する方針を確定（DR-017 として decisions.md に記録するか計画書追記で対応、Phase 1 で判断）
2. **SKILL.md 改訂要否の確定**: `skills/aidlc-migrate/SKILL.md` の構造を確認し、変更要否を判断
3. **Unit 001 03-migrate.md からの流用箇所マッピング表**:

   | 流用元（Unit 001 03-migrate.md 行番号） | Unit 002 該当箇所 | 文言調整内容 |
   |--------------------------------------|------------------|------------|
   | マージ確認ガード（line 82-94） | §5.1 マージ確認 | 質問文を「v1→v2 マイグレーション PR をマージしましたか？」に変更 |
   | HEAD 同期同意 + 副作用説明（line 118-131） | §5.2 HEAD 切替 | スコープ縮小（5 サブ条件マトリクス削除）、`git fetch --prune` 副作用注記は流用、`origin/main` detach のみに限定 |
   | 5 サブ条件マトリクス（line 152-160） | §5.2 検出ロジック | 削除（aidlc-migrate/v2 チェックアウト中の 1 ケースのみ） |
   | 一時ブランチ削除案内 3 択（line 183-189） | §5.3 ブランチ削除 | ブランチ名を `aidlc-migrate/v2` 固定に変更、`<version>` プレースホルダ削除 |
   | ローカル削除フォールバック（line 200-207） | §5.3 削除フォールバック | そのまま流用、ブランチ名のみ変更 |
   | リモート削除失敗時の動作（line 215-219） | §5.3 リモート削除 | そのまま流用、ブランチ名のみ変更 |

#### ドメインモデル設計（縮約版）

- エンティティ:
  - `MergeConfirmGuard`（Unit 001 と同様）
  - `HeadDetachGuard`（aidlc-migrate/v2 チェックアウト確認 + 簡易 tracked 差分チェック + detach 同意）
  - `BranchDeleteFlow`（Unit 001 と同様、3 択 + フォールバック）
- 状態遷移: 上記「実行順序」セクションの図に従う
- 不変条件:
  - INV-1（オプトイン保証）: Unit 001 と同様
  - INV-2（push 失敗の非破壊継続）: Unit 001 と同様
  - INV-5（破壊的コマンド回避: `git reset --hard` 自動実行禁止）: Unit 001 と同様
  - INV-7（AskUserQuestion 必須性、フォワード互換）: Unit 001 と同様
  - INV-8（チェックアウト中ブランチ削除回避）: Unit 001 と同様、HeadDetachGuard で保証
  - INV-9（一時ブランチ削除のオプトイン分離: 3 択）: Unit 001 と同様

#### 論理設計（縮約版）

- 挿入位置: `skills/aidlc-migrate/steps/03-verify.md` の §4 の後に新規 §5「マージ後フォローアップ」サブセクションを追加。§4 末尾の `/aidlc inception` 案内文（line 67-74）は §5 末尾に移動
- HEAD 切替コマンド: `git fetch origin --prune` → `git checkout --detach origin/main`
- ブランチ削除コマンド: `git branch -d aidlc-migrate/v2` → 失敗時 `-D` 再確認、リモート `git push origin --delete aidlc-migrate/v2`
- 簡易 tracked 差分チェック: `git status --porcelain` で `??` 以外の行が含まれる場合は HEAD 切替を中止
- 対話 UI: `AskUserQuestion`（Unit 001 で確定したパターン流用）
- ブランチ名: `aidlc-migrate/v2` 固定（バージョン展開不要）

### Phase 2（実装）

- 改訂対象: `skills/aidlc-migrate/steps/03-verify.md` の §4 の後に新規 §5 を追加。§4 末尾の `/aidlc inception` 案内文は §5 末尾に移動
- 実装内容: Phase 1 で確定したマッピング表に従い、Unit 001 03-migrate.md の該当箇所を流用してブランチ名・質問文・スコープ縮小を反映

### Phase 2b（検証）

- markdownlint 実行
- 手順書 walkthrough（Unit 002 の機能要件を逐次照合）

### Phase 3（完了処理）

- 設計 / コード / 統合 AI レビュー（Unit 001 と同様、`review_mode=required` のためスキップ不可）
- Unit 定義状態を「完了」に更新、履歴記録、Markdownlint、Squash、Git コミット

## 完了条件チェックリスト

> **観測条件の境界**: 本 Unit は手順書追加が主体で、実走行検証はスコープ外。完了条件は **「手順書内に該当記述が存在すること」** を基準とする。

### Phase 1 設計成果物（Phase 1 設計レビュー反復1 指摘 #6 対応）

- [ ] §5 挿入位置が確定し、§4 末尾の `/aidlc inception` 案内移動方針が記録されている（計画書追記または DR-017）
- [ ] SKILL.md（`skills/aidlc-migrate/SKILL.md`）改訂要否が Phase 1 設計レビューで確定している
- [ ] Unit 001 03-migrate.md からの流用箇所マッピング表が Phase 1 設計成果物に含まれている

### 機能要件（Unit 定義「責務」由来）

- [ ] `skills/aidlc-migrate/steps/03-verify.md` に「マージ確認ガード」が記述されている（はい / いいえ / 判断保留 の 3 択、AskUserQuestion 使用）
- [ ] 「いいえ」「判断保留」選択時はローカル / リモートいずれも変更しないことが手順書内に明示されている
- [ ] 「はい」選択時の連続フローが順序（マージ確認 → HEAD 切替 → ブランチ削除）で記述されている
- [ ] HEAD 切替コマンド（`git fetch origin --prune` + `git checkout --detach origin/main`）が手順書内に記述されている
- [ ] HEAD 切替が「現在ブランチが `aidlc-migrate/v2` の場合のみ実行」という条件が手順書内に明示されている
- [ ] 「現在ブランチが `aidlc-migrate/v2` 以外」の場合は HEAD 切替不要で BranchDelete に直接進む旨が手順書内に明示されている（指摘 #2 対応）
- [ ] HEAD 切替前の簡易 tracked 差分チェック（`git status --porcelain`）と検出時の中止案内が手順書内に記述されている（指摘 #4 対応）
- [ ] HEAD 切替スキップ時 / 切替失敗時は一時ブランチ削除も一律スキップする旨が明示されている（INV-8 反映）
- [ ] `git fetch origin --prune` の副作用注記（リモート追跡ブランチ整理、ローカルブランチ非影響）が手順書内に記述されている（指摘 #3 対応）
- [ ] BranchDeleteConsent が 3 択（ローカル+リモート / ローカルのみ / スキップ）で提示されている
- [ ] ローカル削除コマンド（`git branch -d aidlc-migrate/v2` 一次 + 失敗時 `-D` 再確認）が記述されている
- [ ] リモート削除は `git push origin --delete aidlc-migrate/v2` を使用、push 失敗時 warning + 継続が明示されている
- [ ] §4 末尾の `/aidlc inception` 案内文が §5 末尾（または独立 §6 として §5 直後）に移動されている。**実装上の運用**: 読みやすさを優先し独立 §6「次のサイクル開始の案内」として配置（統合レビュー反復1 指摘 #1 対応）

### Issue / Decision 整合（指摘 #7 対応で観測境界を明確化）

- [ ] DR-016 に従い対象ブランチを `aidlc-migrate/v2`（固定名、v1→v2 マイグレーション専用）と明記
- [ ] 本 Unit の構成方針（Issue #607 の精神を migrate 側に拡張）が履歴記録（`construction_unit02.md`）または手順書注記で明示されている。**PR 本文への記述は Operations Phase のスコープ**

### プロセス要件

- [ ] 設計 AI レビュー承認（`review_mode=required`）
- [ ] コード AI レビュー承認（同上）
- [ ] 統合 AI レビュー承認（同上）
- [ ] Unit 定義ファイル状態を「完了」に更新
- [ ] 履歴記録（`construction_unit02.md`）
- [ ] Markdownlint 実行（`markdown_lint=true`）
- [ ] Squash 実行（`squash_enabled=true`）
- [ ] Git コミット

## 依存関係

- **依存する Unit**: なし（Unit 定義 §依存関係に従い独立並列実装可能）
- **Unit 001 との関係**: ソフト依存（推奨実装順序: Unit 001 → Unit 002）。Unit 001 で確定したパターン（AskUserQuestion 仕様、git コマンド系列、warning メッセージ）を流用する。本 Unit から Unit 001 への影響はなし

## 見積もり

- Phase 1（設計）: 0.25 日（Unit 001 の縮約版 + マッピング表）
- Phase 2（実装）: 0.25 日（Unit 001 のパターン流用）
- Phase 2b（検証）: 0.25 日
- Phase 3（完了処理）: 0.25 日

合計: 1.0 日規模（Unit 定義の見積もり「小規模〜中規模」と整合、Unit 001 完了後のパターン流用で短縮）

## リスク・留意点

- **対象ブランチ名の混乱**: 当初 Unit 定義は `chore/aidlc-v<version>-upgrade` を対象としていたが、DR-016 で `aidlc-migrate/v2` に修正済み。手順書では `aidlc-migrate/v2` のみを対象とする（混乱を避けるため複数ブランチ対応はしない）
- **Unit 001 とのパターン流用**: Phase 1 設計成果物のマッピング表に従い、AskUserQuestion 仕様 / git コマンド系列 / warning 文面を Unit 001 03-migrate.md から流用。文言の微調整（migrate 文脈に合わせた質問文など）は Phase 2 で対応
- **HEAD 切替の限定性**: Unit 001 の 5 サブ条件マトリクスは適用しない。HEAD 切替は `aidlc-migrate/v2` チェックアウト中 → `origin/main` への detach のみ。他のブランチ状況は本 Unit では対象外（migrate のフロー特性上、別ブランチでこの手順を実行する想定はない）
- **アップグレードフロー（ケースC）限定の明示**: 本フローは `/aidlc-migrate` 走行時のみ実行され、初回セットアップ / アップグレード（aidlc-setup）とは無関係。`steps/03-verify.md` 自体が migrate 専用ファイルのため構造的に保証される
- **メタ開発時の即時検証困難性**: 本 Unit は手順書追加が主体で、実走行検証は Operations Phase 後の運用検証に委ねる
- **#607 関連付けの精度**: Issue #607 本文は setup スコープのみ言及。Unit 002 は #607 の「精神」（マージ後一時ブランチ削除案内）を migrate 側に拡張するもの。Operations Phase の PR 本文 / CHANGELOG では「#607 setup 側を Unit 001 で対応 + migrate 側の同等処理を Unit 002 で追加」と明示する
- **将来の追加マイグレーション拡張性（指摘 #9 対応）**: `aidlc-migrate/v2` 固定名は v1→v2 マイグレーション専用の前提に依存する。将来 v2→v3 等の追加マイグレーションが導入される場合、ブランチ名固定の前提を再評価する必要がある（v2.4.2 では v1→v2 のみが migrate 対象のため固定で問題なし）
- **HeadDetachGuard の分岐網羅性（指摘 #2 対応）**: 計画書 §実行順序の状態遷移図で、(1) `aidlc-migrate/v2` チェックアウト中 + 同意 → BranchDelete、(2) `aidlc-migrate/v2` チェックアウト中 + スキップ / 切替失敗 → 一時ブランチ削除一律スキップ、(3) 既に他ブランチ → HEAD 切替不要で BranchDelete 直接進行、(4) `aidlc-migrate/v2` ブランチ自体が存在しない → BranchDelete もスキップ の 4 ケースを明確に分岐。Phase 1 設計レビューで状態遷移図を再確認

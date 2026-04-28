# Unit 001 実装計画: rules.md ブランチ運用文言の実装整合（#612）

## 対象

- Unit 定義: `.aidlc/cycles/v2.4.3/story-artifacts/units/001-rules-md-branch-naming-doc-align.md`
- 対象 Issue: #612（Closes 対象。サイクル PR でクローズ）
- 主対象ファイル:
  - `.aidlc/rules.md`「Worktree 運用ルール」セクション（L267〜L298 周辺）
  - `skills/aidlc-setup/SKILL.md`（役割対比節の有無を Phase 1 で確定）
  - `skills/aidlc-migrate/SKILL.md`（役割対比節の有無を Phase 1 で確定）
- 整合確認のみ（変更しない可能性が高い）:
  - `bin/post-merge-sync.sh`（既存対応: `cycle/*` + `upgrade/*`。`chore/aidlc-v*-upgrade` 未対応の最小修正要否を Phase 1 で確定）
  - `skills/aidlc-setup/steps/03-migrate.md`（既に `chore/aidlc-v<version>-upgrade` で記述済み。grep 検証のみ）

## スコープ

「実装は v2.4.2 で `chore/aidlc-v<version>-upgrade` 命名で稼働済み」かつ「実装側のリネームは対象外」という前提に基づき、Issue #612 の C 案（ルール／ドキュメントだけ更新）に整合させる:

- **`.aidlc/rules.md` 文言整合**: L274 の `upgrade/vX.X.X` を `chore/aidlc-v<version>-upgrade` 命名に整合
- **役割対比の追加**: `cycle/vX.X.X`（スターターキット自身のリリース）と `chore/aidlc-v<version>-upgrade`（ダウンストリーム消費プロジェクトでの追従用一時ブランチ）の **用途対比節** を `.aidlc/rules.md` に追加
- **`aidlc-setup` / `aidlc-migrate` SKILL.md 文言補強**: 役割対比の要点を SKILL.md にも追記し、用途の混同を構造的に解消（Phase 1 設計レビューで「SKILL.md の追記が必要 / 不要」を確定）
- **grep 検証による全洗い出し**: 旧命名 `upgrade/v*` の残存 / `chore/aidlc-v*-upgrade` の言及を `.aidlc/rules.md` および `skills/aidlc-{setup,migrate}/` 配下から確認し、検証結果を `design.md` または `history` に記録
- **`bin/post-merge-sync.sh` 最小修正の判定**: `chore/aidlc-v*-upgrade` プレフィックス削除サポート追加要否を Phase 1 設計レビューで確定（追加するなら最小修正、不要なら対象外）

### スコープ外（Unit 定義「境界」由来）

- **実装側のブランチ命名変更（リネーム）**: 既に新命名で稼働中のため対象外
- **過去サイクルで作成された `upgrade/v*` ブランチ（既存）の処理**: 対象外（既存安全制約として `upgrade/*` 削除パターンを残置）
- **スターターキット自身向けの `aidlc-setup` 抑止ロジック（Issue #612 案 A）**: 対象外
- **`bin/post-merge-sync.sh` の大規模リファクタ**: `chore/aidlc-v*-upgrade` 対応追加が必要と判定された場合でも、最小修正にとどめる

## 実装方針

### Phase 1（設計）

#### ドメインモデル設計

文言整合主体のため、概念モデルとして以下を整理する（小規模）:

- エンティティ:
  - `BranchRolePolicy`（用途別ブランチ命名ポリシー）
    - `CycleBranch`: `cycle/vX.X.X` — スターターキット自身のリリース・サイクル開発
    - `ChoreUpgradeBranch`: `chore/aidlc-v<version>-upgrade` — ダウンストリーム消費プロジェクトの追従用一時ブランチ
    - `LegacyUpgradeBranch`: `upgrade/v*` — 過去サイクル名残（読み出し互換のみ、新規作成しない）
- ルール:
  - 命名は **用途**（リリース vs 追従）を反映する
  - `aidlc-setup` がアップグレード走行時に作成するのは `ChoreUpgradeBranch`
  - `bin/post-merge-sync.sh` のマージ済み削除対象は `cycle/*` と `upgrade/*`（既存）+ `chore/aidlc-v*-upgrade`（追加要否は Phase 1 確定）

#### 論理設計

1. **`.aidlc/rules.md` 改訂内容の確定**:
   - L274 の文言修正（`upgrade/vX.X.X` → `chore/aidlc-v<version>-upgrade`）
   - 役割対比節（新規追加）: 「Worktree 運用ルール」セクションの冒頭または「ブランチ運用フロー」直前に「ブランチ命名と用途対比」サブセクションを追加
     - 対比表形式: 用途 / 命名 / 作成主体 / 削除契機 / 例
   - L298 の文言整合: 以下の 2 パターンを Phase 1 設計レビューで A/B 選択（`bin/post-merge-sync.sh` 修正方針 §5 と連動）
     - **L298-A（post-merge-sync.sh 未修正の場合）**: 「`cycle/` および `upgrade/` プレフィックスのマージ済みブランチのみ削除対象（安全制約）。`upgrade/*` は過去サイクル名残として残置され、新規アップグレードは `chore/aidlc-v<version>-upgrade` を使用する」と注記
     - **L298-B（post-merge-sync.sh 修正の場合）**: 「`cycle/`、`chore/aidlc-v*-upgrade`、`upgrade/`（過去サイクル名残）プレフィックスのマージ済みブランチを削除対象とする（安全制約）」と列挙
2. **対比節の挿入位置選択肢**（Phase 1 設計レビューで確定）:
   - **(a)** 「Worktree 運用ルール」冒頭（L267 直後）に新規サブセクションとして配置
     - 選択指針: セクション全体の冒頭で読者が最初に用途対比を把握できる（命名の混同を入口で抑止）
   - **(b)** 「ブランチ運用フロー」サブセクション内の冒頭注記として配置
     - 選択指針: フロー直前で対比の必要性が文脈付きで提示される（フロー読解時に直接参照しやすい）
3. **`skills/aidlc-setup/SKILL.md` 追記要否の判定**:
   - 必要なら「ダウンストリーム向け運用 vs スターターキット自身は `cycle/vX.X.X`」の 1〜2 行注記を追加
   - 不要（rules.md 側のみで十分）と判定された場合は本対象から外す
4. **`skills/aidlc-migrate/SKILL.md` 追記要否の判定**:
   - migrate は v1→v2 マイグレーション専用で `upgrade/v*` 命名との直接関係は薄いが、Unit 定義「責務」に従い `skills/aidlc-migrate/` 配下の grep 結果（`upgrade/v` および `chore/aidlc-v` の検出有無）を必ず記録した上で追記要否を判断する
   - 追記要否にかかわらず grep 結果の記録自体は必須（design.md または history に保存）
   - 「v1→v2 移行時に作成されるブランチ命名と、リリース用 `cycle/vX.X.X` との混同回避」が必要なら 1〜2 行注記を追加
5. **`bin/post-merge-sync.sh` 最小修正の確定**:
   - 既存対応: `cycle/*` + `upgrade/*`
   - 新命名 `chore/aidlc-v*-upgrade` のマージ済み削除対象追加が必要かを判定（追加する場合は §1 の L298-B、追加しない場合は §1 の L298-A と連動）
   - 追加するなら、`chore/aidlc-v*-upgrade` のリスト列挙を 2 箇所（ローカル・リモート）に追加する最小修正

### Phase 2（実装）

- `.aidlc/rules.md` 改訂: Phase 1 で確定した内容を反映
- `skills/aidlc-setup/SKILL.md` 追記: Phase 1 で「必要」と判定された場合のみ
- `skills/aidlc-migrate/SKILL.md` 追記: 同上
- `bin/post-merge-sync.sh` 最小修正: Phase 1 で「必要」と判定された場合のみ
- grep 検証: 改訂後に基本パターン（`upgrade/v` の残存）と追加パターン（`upgrade/v|chore/aidlc-v` の網羅）を再実行し、結果を `history/construction_unit01.md` に記録

### Phase 3（完了処理）

- 設計 / コード / 統合 AI レビュー（`review_mode=required`）
- Unit 定義ファイル状態を「完了」に更新
- 履歴記録（`construction_unit01.md`）
- Markdownlint 実行（`markdown_lint=true`）
- Squash 実行（`squash_enabled=true`）
- Git コミット

## 完了条件チェックリスト

> **観測条件の境界**: 本 Unit は文言整合が主体で、実走行検証は Operations Phase リリース後の運用検証に委ねる。完了条件は **「ドキュメント内に該当記述が存在すること」「grep 検証で残存がないこと」** を基準とする。

### 機能要件（Unit 定義「責務」由来）

- [x] `.aidlc/rules.md` の L274 が `chore/aidlc-v<version>-upgrade` 命名に整合されている
- [x] `.aidlc/rules.md` の L298 の `upgrade/` / `chore/aidlc-v*-upgrade` プレフィックス言及が、`bin/post-merge-sync.sh` の実装と整合している（Phase 1 設計レビューで選択した L298-A / L298-B のいずれかで更新されている）
- [x] `.aidlc/rules.md` に「ブランチ命名と用途対比」を示す節（または対比表）が追加されている
- [x] 対比節に少なくとも以下の 2 用途が明示されている:
  - `cycle/vX.X.X`（スターターキット自身のリリース）
  - `chore/aidlc-v<version>-upgrade`（ダウンストリーム消費プロジェクトの追従用一時ブランチ）
- [x] `skills/aidlc-setup/SKILL.md` の追記要否が Phase 1 設計レビューで確定し、必要時は対比要点が追記されている（不要なら本項目はスキップ可）
- [x] `skills/aidlc-migrate/SKILL.md` の追記要否が Phase 1 設計レビューで確定し、必要時は追記されている（不要なら本項目はスキップ可）
- [x] `skills/aidlc-migrate/` 配下の grep 結果（`upgrade/v` および `chore/aidlc-v` の検出有無）が、追記要否にかかわらず `design.md` または `history/construction_unit01.md` に記録されている
- [x] `bin/post-merge-sync.sh` のプレフィックス対応最小修正が Phase 1 で確定し、必要時のみ反映されている（不要なら本項目はスキップ可）
- [x] grep 検証で `.aidlc/rules.md`、`skills/aidlc-setup/`（SKILL.md + steps/ 配下）、`skills/aidlc-migrate/`（SKILL.md + steps/ 配下）配下に未対応の `upgrade/v` 残存がない（過去サイクル対応のため意図的に残す箇所は明示）
- [x] grep 検証結果が `history/construction_unit01.md` または `design.md` に記録されている

### Issue 終了条件（Issue #612 由来、観測単位はドキュメント記述）

- [x] **#612**: `.aidlc/rules.md` の Worktree 運用ルールセクション全体（L267〜L298）が `chore/aidlc-v<version>-upgrade` 命名と整合し、`upgrade/*` 既存言及（過去サイクル名残）と矛盾していない
- [x] **#612**: ダウンストリーム向け運用と、スターターキット自身が `cycle/vX.X.X` を使う点の役割対比が `.aidlc/rules.md` に明示されている

### プロセス要件

- [x] 設計 AI レビュー承認（`review_mode=required`）
- [x] コード AI レビュー承認（同上）
- [x] 統合 AI レビュー承認（同上）
- [x] Unit 定義ファイル状態を「完了」に更新
- [x] 履歴記録（`construction_unit01.md`）
- [x] Markdownlint 実行（`markdown_lint=true`）
- [x] Squash 実行（`squash_enabled=true`）
- [x] Git コミット

## 依存関係

- **依存する Unit**: なし（Unit 002 / 003 / 004 と独立並列実装可能）

## 見積もり

- Phase 1（設計）: 0.15〜0.25 日
- Phase 2（実装）: 0.15〜0.25 日
- Phase 3（完了処理）: 0.20〜0.25 日

合計: 0.5〜0.75 日規模（Unit 定義の見積もり「S（Small）: 1 セッション程度」と整合）。

## リスク・留意点

- **既存 `upgrade/*` プレフィックス言及との整合**: `bin/post-merge-sync.sh` は過去サイクル名残として `upgrade/*` 削除を残している。`.aidlc/rules.md` 文言で「過去サイクル名残として `upgrade/*` も既存スクリプトの安全範囲に含まれる」点を補足するか、Phase 1 設計レビューで判断
- **対比節の表現**: v2.4.0 の Milestone 運用本採用 / v2.4.2 の post-merge フォローアップと整合させる（Unit 定義「技術的考慮事項」由来）
- **メタ開発時の即時検証困難性**: `aidlc-setup` の実走行は別リポジトリでのリリース後検証に委ねる。本 Unit の完了条件は「ドキュメント内記述」と「grep 検証」を基準とする
- **`.aidlc/rules.md` の編集境界**: META-001 例外で許可されるのはあくまで該当セクション。他セクションへの波及修正は対象外

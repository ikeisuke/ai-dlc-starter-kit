# Unit 007 計画: 公開ドキュメントのサイクル運用記述を Milestone 参照に書き換え

## 対象 Unit

- **Unit ファイル**: `.aidlc/cycles/v2.4.0/story-artifacts/units/007-docs-milestone-rewrite.md`
- **担当ストーリー**: ストーリー 3（ドキュメント更新によるユーザー周知、Unit C 由来）
- **関連 Issue**: #597（Unit C 担当部分）
- **依存 Unit**: Unit 005（完了済み）/ Unit 006（完了済み）
- **見積もり**: 2〜3 時間

## 課題と修正方針

### 課題

GitHub Milestone 運用本採用（#597）の周知側として、公開ドキュメント（guides / glossary）のサイクル運用記述を Milestone 参照に書き換える。Unit 005 / 006 で更新した Inception/Operations の Milestone 手順と整合させる必要がある。CHANGELOG `#597` 節は本 Unit が排他所有し、Unit 005 から委譲された `cycle-label.sh` / `label-cycle-issues.sh` の deprecation 記載と Unit 006 から委譲された Operations Phase 側追加機能記載を含める。

### 修正方針

**実態調査の結果**: `docs/configuration.md` / `README.md` / `.aidlc/rules.md` には `cycle:v*` ラベル / `label-cycle-issues.sh` の言及は存在しない（grep 全件確認）。Unit 定義の該当責務はこれらのファイルでは **空集合（no-op）** と確認したため、本 Unit のスコープから除外する。Unit 定義の `skills/aidlc/rules.md` への言及はリポジトリに存在しない（参照誤り）ため、Unit 定義側でも `.aidlc/rules.md` への修正および no-op 注記を本サイクル中に同期反映済み。

よって本 Unit の実装対象は **guides 4 ファイル + CHANGELOG 1 ファイル** に絞る:

1. **`skills/aidlc/guides/issue-management.md`** L52-L58 「サイクルラベル付与」を「Milestone 紐付け」に書き換え（Inception Phase が自動紐付け実施、手動時は `gh issue edit --milestone`、失敗時フォールバックで `gh api PATCH` + Inception ステップ参照）。L177 「関連ファイル」の `label-cycle-issues.sh` 行を deprecation 注記付きに更新。また、旧 `docs/aidlc/guides/backlog-management.md` のパス誤記があれば実在パス `skills/aidlc/guides/backlog-management.md` に修正
2. **`skills/aidlc/guides/backlog-management.md`** L23 ラベル構成、L94-L98 サイクルラベル付与、L138-L141 サイクルラベル作成、L146-L154 将来検討事項（マイルストーン作成は本採用済み）を Milestone 運用に書き換え
3. **`skills/aidlc/guides/backlog-registration.md`** 出力テンプレートに「Milestone 未割当を初期状態とする」旨の注記追加（L48 出力テンプレート末尾、または L46 注記行隣接）
4. **`skills/aidlc/guides/glossary.md`** に「Milestone」エントリ追加（GitHub Milestone を AI-DLC のサイクル管理単位として用いる定義）。「サイクルラベル」エントリは現状未掲載のため、deprecated 注記付きの新規エントリとして追加（過去ドキュメント参照の可逆性確保）
5. **`CHANGELOG.md` `[2.4.0]` 節**に新規 `#597` 節を追加:
   - 旧サイクル（v2.3.6 以前）の併記を残さない方針、過去サイクル追跡は CHANGELOG / `.aidlc/cycles/v*/` ディレクトリ / `cycle:v*` ラベル（deprecated 物理残置）で行う旨
   - Inception Phase Milestone 作成ステップ追加（Unit 005 由来）の概要
   - Operations Phase Milestone close + 紐付け確認 + fallback 作成手順追加（Unit 006 由来）の概要
   - `cycle-label.sh` / `label-cycle-issues.sh` の deprecation（Unit 005 から委譲）

### 配置検討

| 候補 | 配置先 | 理由 | 採否 |
|------|-------|------|------|
| (A) `### Changed` 節に Milestone 運用本採用を記載 | CHANGELOG | 既存運用の変更なので Changed が適切 | **採用** |
| (B) `### Added` 節に Milestone 運用本採用を記載 | CHANGELOG | Inception/Operations ステップ追加は Added 的 | 採用検討（Added と Changed の併用） |
| (C) `### Deprecated` 節に cycle-label.sh / label-cycle-issues.sh を記載 | CHANGELOG | スクリプト本体は物理残置だが運用上 deprecated | **採用** |

→ 採用: (A) + (C)、ただし新規追加部分は **`### Added`**（Inception/Operations Milestone ステップは新規機能）+ **`### Changed`**（運用方針の変更）+ **`### Deprecated`**（cycle-label 系スクリプトと cycle:v* ラベル）の 3 セクション併記方針を取る。

### Unit 005 / 006 完了記録の引き継ぎ事項との整合確認

- **Unit 005 引き継ぎ事項**（`inception-milestone-step_implementation.md` Unit 007 への引き継ぎ事項【重要】セクション）: `cycle-label.sh` / `label-cycle-issues.sh` deprecation の CHANGELOG `#597` 節記載 → 本 Plan の方針 5 (`### Deprecated`) に反映
- **Unit 006 引き継ぎ事項**（`operations-milestone-close_implementation.md` Unit 007 への引き継ぎ事項【重要】セクション）: Operations Phase Milestone close + 紐付け確認 + fallback 作成手順追加の CHANGELOG `#597` 節記載 → 本 Plan の方針 5 (`### Added`) に反映

### マージ前完結ルールとの整合確認

本 Unit はドキュメント編集のみで GitHub 側操作を含まない。CHANGELOG / guides / glossary は全て cycle ブランチ配下のファイルとして `.aidlc/cycles/{{CYCLE}}/**` 外に位置するため、PR マージ後の cycle ブランチファイル更新ガード（`write-history.sh` exit 3）の対象外。コミット完了 → PR Ready 化 → main マージで通常の Operations Phase に進む。

### 修正詳細

#### 1. `skills/aidlc/guides/issue-management.md`

##### 修正箇所 1: L52-L58「サイクルラベル付与」セクション

```markdown
2. **Milestone 紐付け**
   - Milestone の正式作成と関連 Issue 紐付けは Inception Phase の `05-completion.md` ステップ 1 で実施（主経路: `gh issue edit --milestone`、権限/環境差分による失敗時フォールバック: `gh api --method PATCH`）
   - `02-preparation.md` ステップ 16 は既存 Milestone がある場合のみ先行紐付けする補助動作（Unit 005 / #597）
   - 補足: 旧サイクル（v2.3.6 以前）で使用していた `cycle:v*` ラベル付与スクリプト（`label-cycle-issues.sh`）は v2.4.0 で deprecated（物理残置）
```

##### 修正箇所 2: L177「関連ファイル」

```markdown
- `skills/aidlc/scripts/issue-ops.sh` - Issue操作スクリプト
- `skills/aidlc/scripts/label-cycle-issues.sh` - サイクルラベル一括付与スクリプト（**v2.4.0 で deprecated**、Milestone 運用本採用により Inception ステップへ移行）
- `skills/aidlc/guides/backlog-management.md` - バックログ管理ガイド
```

**注**: 旧 `docs/aidlc/guides/backlog-management.md` パスは現リポジトリに存在しない（過去構成の遺物）。本書き換えで実在パス `skills/aidlc/guides/backlog-management.md` に修正する。

#### 2. `skills/aidlc/guides/backlog-management.md`

##### 修正箇所 1: L22-L23「対応開始時に追加するラベル」

```markdown
**対応開始時の Milestone 紐付け（v2.4.0 以降）**:
- Milestone は Inception Phase の `05-completion.md` ステップ 1 で正式作成する（`vX.X.X` 形式、例: `v1.8.0`）。`02-preparation.md` ステップ 16 は既存 Milestone がある場合のみ先行紐付けする補助動作
- Issue 紐付けも `05-completion.md` ステップ 1 で正式実施（主経路: `gh issue edit --milestone "vX.X.X"`、権限/環境差分による失敗時フォールバック: `gh api --method PATCH`）
- 旧運用の `cycle:vX.X.X` ラベルは v2.4.0 で deprecated（物理残置、新サイクルでは付与しない）
```

##### 修正箇所 2: L94-L98「Inception Phase」サイクルラベル付与

```markdown
1. **バックログ確認**: 既存のバックログ項目を確認し、今回のサイクルで対応する項目を選定
2. **Milestone 紐付け**: 対応する項目を v2.4.0 以降の Milestone に紐付け（Inception Phase が自動実施）
   ```bash
   # 手動復旧パターン A-1: gh 利用可能 + duplicate/closed 混在の復旧時
   # 完了条件: title == "vX.X.X" の Milestone が open=1, closed=0 となること（同名 closed が残ると後続ステップが closed_count >= 1 で再停止する）
   # まず同名 Milestone 一覧を確認:
   gh api "repos/$OWNER/$REPO/milestones?state=all" --jq "[.[] | select(.title == \"vX.X.X\") | {number, state}]"
   # 不要 duplicate は close ではなく title 変更（例: vX.X.X-archived-YYYY-MM-DD）または delete で同名衝突を除去:
   gh api --method PATCH "repos/$OWNER/$REPO/milestones/<dup_number>" -f title="vX.X.X-archived-2026-04-23"
   # または:
   gh api --method DELETE "repos/$OWNER/$REPO/milestones/<dup_number>"
   # 整理後は A-2 で Issue 再紐付けに進む
   ```

   ```bash
   # 手動復旧パターン A-2 (Issue): gh 利用可能 + Issue 側 LINK_FAILED の復旧時。主経路:
   gh issue edit {ISSUE_NUMBER} --milestone "vX.X.X"
   # 権限/環境差分により失敗する場合のフォールバック:
   gh api --method PATCH "repos/OWNER/REPO/issues/{ISSUE_NUMBER}" -F milestone={MILESTONE_NUMBER}

   # 手動復旧パターン A-2 (PR): gh 利用可能 + PR 側 LINK_FAILED の復旧時。
   # GitHub 仕様により PR は Issue API 経由で Milestone を操作する:
   gh api --method PATCH "repos/OWNER/REPO/issues/{PR_NUMBER}" -F milestone={MILESTONE_NUMBER}
   # または GitHub UI 上で PR を開き、右サイドバーの Milestone を手動選択
   ```

   ```bash
   # 手動復旧パターン B: gh 利用不可時。REST API 直叩き（PAT が必要）または GitHub UI で手動操作。
   # 1. リポジトリ URL から OWNER/REPO を確認（例: github.com/OWNER/REPO）
   # 2. GitHub UI の Milestones 一覧（https://github.com/OWNER/REPO/milestones）または以下の REST API で MILESTONE_NUMBER を取得:
   curl -H "Authorization: token <PAT>" \
     -H "Accept: application/vnd.github+json" \
     "https://api.github.com/repos/OWNER/REPO/milestones?state=all" \
     | jq '.[] | select(.title == "vX.X.X" and .state == "open") | .number'
   # 上記が 1 件でない場合は紐付けせず、先に duplicate/closed 衝突を解消する（パターン A-1 相当を REST/UI で実施）
   # 3a. Issue に Milestone を紐付け:
   curl -X PATCH -H "Authorization: token <PAT>" \
     -H "Accept: application/vnd.github+json" \
     https://api.github.com/repos/OWNER/REPO/issues/{ISSUE_NUMBER} \
     -d '{"milestone": <MILESTONE_NUMBER>}'
   # または: GitHub UI 上で Issue を開き、右サイドバーの Milestone を手動選択

   # 3b. PR に Milestone を紐付け（GitHub 仕様により PR は Issue API 経由）:
   curl -X PATCH -H "Authorization: token <PAT>" \
     -H "Accept: application/vnd.github+json" \
     https://api.github.com/repos/OWNER/REPO/issues/{PR_NUMBER} \
     -d '{"milestone": <MILESTONE_NUMBER>}'
   # または: GitHub UI 上で PR を開き、右サイドバーの Milestone を手動選択
   ```
```

##### 修正箇所 3: L138-L142「サイクルラベル作成」注記

```markdown
**注**: サイクル管理は v2.4.0 以降 GitHub Milestone に移行しました。Milestone は Inception Phase の `05-completion.md` ステップ 1 で正式作成・関連 Issue 紐付けを行います。`02-preparation.md` ステップ 16 は既存 Milestone がある場合のみ先行紐付けする補助動作です。旧運用の `cycle:vX.X.X` ラベルは deprecated（物理残置、Operations 担当者の判断で個別対応）:

```text
旧運用（v2.3.6 以前、deprecated）: `gh label create "cycle:v1.8.0" ...` を手動実行していた
新運用（v2.4.0 以降）: Milestone 作成の主経路は Inception Phase の `05-completion.md` ステップ 1。Milestone 不在時は Operations Phase の `01-setup.md` ステップ 11 が fallback 作成する。手動対応が必要なのは `gh` 利用不可時、または duplicate/closed 混在・`LINK_FAILED` で自動処理が停止した後の復旧時のみ
```
```

##### 修正箇所 4: L146-L154「将来検討事項」

```markdown
## 関連機能の現状（v2.4.0 時点）

GitHub Milestone との連携は v2.4.0 で本採用済み:

- **Inception Phase の `05-completion.md` ステップ 1 での Milestone 作成**: Inception Phase 完了処理として自動実施（Unit 005 / #597）
- **Operations Phase の `04-completion.md` ステップ 5.5 での Milestone close**: サイクル完了時に自動実施（Unit 006 / #597）
- **Operations Phase の `01-setup.md` ステップ 11 での Milestone 紐付け確認・fallback 作成**: Operations 開始時に自動実施（5 ケース判定 + 冪等補完原則）

将来的な追加検討:

- Unit 完了時の Issue 自動クローズ（現状: サイクル PR マージで Closes キーワード経由の auto-close）
- GitHub Projects との連携（ステータス管理）
- Milestone 進捗バッジの README 追加（v2.5.0 以降）
```

#### 3. `skills/aidlc/guides/backlog-registration.md`

##### 修正箇所: L46 注記の隣接または出力テンプレート末尾

```markdown
**注**: 発見日/発見フェーズ/発見サイクルはAIが自動補完（現在の日付/フェーズ/`{{CYCLE}}`をそのまま使用。名前付きサイクルの場合は `waf/v1.0.0` のような形式になる）

**Milestone について（v2.4.0 以降）**: 新規 Issue 作成時は Milestone 未割当（empty）を初期状態とする。Milestone への正式紐付けは Inception Phase の `05-completion.md` ステップ 1 で実施し、`02-preparation.md` ステップ 16 では既存 Milestone がある場合のみ先行紐付けする（Unit 005 / #597）。
```

#### 4. `skills/aidlc/guides/glossary.md`

##### 修正箇所: 用語一覧表に 2 エントリ追加（アルファベット順）

```markdown
| Cycle | `cycle/vX.X.X` | 開発の1サイクル。バージョン番号（vX.X.X）で識別される | 全フェーズ | `prompts/common/intro.md` |
| サイクルラベル | `cycle:vX.X.X` | 旧運用での Issue 紐付け方式（**v2.4.0 で deprecated**、Milestone に置換）。物理残置されており過去サイクル追跡用に参照可能 | 全フェーズ | `guides/backlog-management.md` |
| ... |
| Milestone | `vX.X.X`（GitHub Milestone title） | GitHub Milestone を AI-DLC のサイクル管理単位として用いる（v2.4.0 以降）。Inception Phase が自動作成、Operations Phase が自動 close。1 Issue = 1 Milestone 制約 | 全フェーズ | `guides/backlog-management.md` |
| ... |
```

挿入位置: アルファベット順（`Logical Design` の後、`Operations` の前 = `M` 行）。「サイクルラベル」は日本語混在のため `Cycle` の直後に挿入（既存の Cycle 行と隣接させる）。

#### 5. `CHANGELOG.md` `[2.4.0]` 節への `#597` 追記

##### 挿入位置

Keep a Changelog 推奨順（Added → Changed → Deprecated → Removed → Fixed → Security）に従う。本サイクルの `[2.4.0]` 節は現状 `### Changed` / `### Removed` のみで Added セクションがないため、新規 `### Added` を `### Changed` より**前**に挿入し、`### Deprecated` を `### Changed` と `### Removed` の間に挿入する。各 `#597` 節の追記内容は以下の通り:

```markdown
### Added

- Inception Phase に GitHub Milestone 自動作成・関連 Issue 紐付けステップを追加（`skills/aidlc/steps/inception/02-preparation.md` ステップ 16 で先行紐付け / `05-completion.md` ステップ 1 で正式作成・紐付け）。5 ケース判定（`open ≥ 2 / 1 / 0` × `closed ≥ 1 / 0` の組み合わせ）で重複作成・誤再オープンを防止。Issue 紐付けは主経路 `gh issue edit --milestone`、権限/環境差分による失敗時フォールバックで `gh api --method PATCH`。`label-cycle-issues.sh` の awk 抽出ロジック（5 形式対応）を流用（#597 / Unit 005 / Unit 007）
- Operations Phase に Milestone close + 紐付け確認 + fallback 作成手順を追加（`skills/aidlc/steps/operations/01-setup.md` ステップ 11 / `04-completion.md` ステップ 5.5 / `index.md` §2.8 補助契約）。マージ前完結契約準拠（GitHub 側操作のみ）、5 ケース判定で誤再オープン防止、冪等補完原則で 1 Issue = 1 Milestone 制約遵守、LINK_FAILED 集約判定 exit 1 契約、`gh_status != available` 時 exit 1 + REST API 直叩き手動代替手順（#597 / Unit 006 / Unit 007）

### Changed

- サイクル管理を `cycle:vX.X.X` ラベル運用から GitHub Milestone 運用に本採用変更。旧サイクル（v2.3.6 以前）の併記は残さない。過去サイクルの追跡は CHANGELOG / `.aidlc/cycles/v*/` ディレクトリ / 物理残置された `cycle:v*` ラベル（deprecated）で行う。Milestone 進捗バッジの README 追加は v2.5.0 以降のバックログとする（#597 / Unit 007）
- 公開ドキュメント（`skills/aidlc/guides/issue-management.md` / `backlog-management.md` / `backlog-registration.md` / `glossary.md`）のサイクル運用記述を Milestone 参照に書き換え（#597 / Unit 007）

### Deprecated

- `skills/aidlc/scripts/cycle-label.sh` / `skills/aidlc/scripts/label-cycle-issues.sh` を v2.4.0 で deprecated 化（物理残置）。Milestone 運用本採用により Inception Phase ステップ（`02-preparation.md` ステップ 16 / `05-completion.md` ステップ 1）が後継。両スクリプトは将来サイクル（v2.5.0 以降）で物理削除を検討（#597 / Unit 005 / Unit 007）
- `cycle:vX.X.X` ラベル運用を v2.4.0 で deprecated 化。新サイクルでは Milestone を使用。物理残置されたラベルは過去サイクル追跡用にのみ参照可能（#597 / Unit 007）
```

## ファイル変更一覧

| ファイル | 変更内容 | 行数規模 |
|---------|---------|----------|
| `skills/aidlc/guides/issue-management.md` | L52-L58 サイクルラベル付与 → Milestone 紐付け書き換え、L177 関連ファイル deprecation 注記追加 | ±10 行 |
| `skills/aidlc/guides/backlog-management.md` | L22-L23 対応開始時ラベル → Milestone 紐付け、L94-L98 サイクルラベル付与 → Milestone 紐付け、L138-L142 サイクルラベル作成 → Milestone 作成案内、L146-L154 将来検討事項 → 関連機能の現状（v2.4.0） | ±35 行 |
| `skills/aidlc/guides/backlog-registration.md` | L46 注記隣接に Milestone 未割当初期状態の説明追加 | +3 行 |
| `skills/aidlc/guides/glossary.md` | 用語一覧表に「Milestone」「サイクルラベル（deprecated）」の 2 エントリ追加 | +2 行 |
| `CHANGELOG.md` | `[2.4.0]` 節に `### Added` / `### Changed` / `### Deprecated` 各 `#597` 節追加（既存 `### Changed` / `### Removed` には #596 / #595 が既に記載済み、本 Unit は新規節として追加） | +25 行 |

## 動作確認手順

### 検証スコープ限定

本 Unit のスコープは **公開ドキュメントの Markdown 編集のみ** で、Unit 005 / 006 で実装されたスキルステップへの影響はない。実動作確認は v2.5.0 以降のサイクルで Inception/Operations 実行時に自然検証される。

### Markdown 整合性検証

```bash
# Milestone エントリが追加されているか
grep -c "^| Milestone " skills/aidlc/guides/glossary.md  # 期待値: 1
grep -c "^| サイクルラベル " skills/aidlc/guides/glossary.md  # 期待値: 1

# サイクルラベル関連の旧記述が Milestone に置換されているか
grep -c "Milestone 紐付け" skills/aidlc/guides/issue-management.md  # 期待値: 1+
grep -c "v2.4.0 で deprecated" skills/aidlc/guides/issue-management.md  # 期待値: 1+
grep -c "GitHub Milestone" skills/aidlc/guides/backlog-management.md  # 期待値: 3+
grep -c "Milestone 未割当" skills/aidlc/guides/backlog-registration.md  # 期待値: 1

# CHANGELOG #597 節が追加されているか
grep -c "#597 / Unit 005 / Unit 007" CHANGELOG.md  # 期待値: 1+
grep -c "#597 / Unit 006 / Unit 007" CHANGELOG.md  # 期待値: 1+
grep -c "#597 / Unit 007" CHANGELOG.md  # 期待値: 2+ （Changed と Deprecated の cycle:v ラベル）
grep -c "label-cycle-issues.sh" CHANGELOG.md  # 期待値: 1+

# 旧運用の併記がないか（残してはいけない記述）
grep -c "cycle:vX.X.X.*ラベル.*付与" skills/aidlc/guides/backlog-management.md  # 期待値: 0（DEPRECATED 文脈以外で旧運用案内が残っていないか）
```

### 設計レビュー時のガイド照合ルール適用

`.aidlc/rules.md` 「設計レビュー時のガイド照合ルール」（該当ルールが定義されている場合）に従い、過剰な互換記述（旧運用の説明残置）が混入しないよう確認。`glossary.md` の「サイクルラベル」エントリは過去ドキュメントとの参照リンク切れを避ける目的であるため、deprecation 注記付きで例外的に残置可。

## 境界遵守

- Unit 003 所有のファイル（`bin/update-version.sh` / 関連の `.aidlc/rules.md` 段落 / CHANGELOG `#596` 節）には触らない
- Unit 005 所有のファイル（`skills/aidlc/steps/inception/02-preparation.md` / `05-completion.md` / `index.md` / `cycle-label.sh` / `label-cycle-issues.sh`）には触らない
- Unit 006 所有のファイル（`skills/aidlc/steps/operations/01-setup.md` / `04-completion.md` / `index.md` §2.8）には触らない
- 翻訳ドキュメント（`docs/translations/`）は本サイクル対象外
- README.md / docs/configuration.md / .aidlc/rules.md の Milestone 関連書き換え: **実態調査の結果、対象記述が存在しないため触らない**（過剰修正回避）

## リスク評価

### 技術的リスク

- **Low**: Markdown 編集のみで機能変更なし。Unit 005 / 006 の実装と整合する記述に揃えるため、参照誤りリスクは低い

### 運用リスク

- **Low-Medium**: ドキュメントが Milestone 運用前提に切り替わるため、v2.4.0 アップグレード後の利用者が旧 `cycle:v*` ラベル運用を継続しようとして混乱する可能性あり。CHANGELOG `### Deprecated` 節と `glossary.md` 「サイクルラベル」エントリ deprecation 注記で明示することで対応

### 将来的な技術的負債

- `cycle-label.sh` / `label-cycle-issues.sh` の物理残置: 過去サイクル参照のために残すが、v2.5.0 以降のサイクルで物理削除を検討（DEPRECATED 注記済み）

## 関連 Issue

- #597 部分対応（Unit C 担当部分。Unit A は Unit 006、Unit B は Unit 005、Unit D-F は本サイクル対象外）

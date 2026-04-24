# 論理設計: Unit 007 公開ドキュメントのサイクル運用記述を Milestone 参照に書き換え

## 概要

修正対象 5 ファイル（guides 4 ファイル + CHANGELOG 1 ファイル）の挿入・置換内容と動作確認手順を定義する。本 Unit は Markdown 編集のみのため、コンポーネント構成・処理フロー等は採用せず、**挿入内容の正確性 + Unit 005 / 006 実装との整合 + 手動復旧 3 パターン分岐 + 過剰修正回避** を中心に定義する。

**重要**: この論理設計では**コードは書かず**、テキスト挿入・置換位置と内容のみを定義する。具体的なファイル編集は Phase 2 で行う。

## アーキテクチャパターン

ドキュメント追加・置換（Markdown）。Unit 005 / 006 で確定した実装ステップを公開ドキュメントに反映し、Keep a Changelog 順序に準拠した CHANGELOG 構造を維持する。

## ファイル変更一覧

| ファイル | 変更内容 | 行数規模 |
|---------|---------|----------|
| `skills/aidlc/guides/issue-management.md` | L52-L58 サイクルラベル付与 → Milestone 紐付け書き換え（主経路 `gh issue edit --milestone`、フォールバック `gh api PATCH`、`05-completion.md` ステップ 1 を主参照、`02-preparation.md` ステップ 16 は補助動作と明記、手動復旧 3 パターン分岐の cross-reference を `backlog-management.md` 該当節へ）、L177 関連ファイル deprecation 注記追加（`docs/aidlc/` 旧パス → `skills/aidlc/` 実在パスに修正） | ±12 行 |
| `skills/aidlc/guides/backlog-management.md` | L22-L23 ラベル構成 → Milestone 紐付け、L94-L98 Inception Phase サイクルラベル付与 → Milestone 紐付け（手動復旧 3 パターン分岐 A-1 / A-2 / B）、L138-L142 サイクルラベル作成注記 → Milestone 作成案内（`05-completion.md` ステップ 1 主参照）、L146-L154 将来検討事項 → 関連機能の現状（v2.4.0 時点の本採用状況、具体的なステップ番号付き） | ±55 行 |
| `skills/aidlc/guides/backlog-registration.md` | L46 注記隣接に Milestone 未割当初期状態 + 正式紐付け箇所 + 補助動作の説明追加 | +3 行 |
| `skills/aidlc/guides/glossary.md` | 用語一覧表に「Milestone」（`Logical Design` の後）と「サイクルラベル」（`Cycle` の直後、deprecated 注記付き）の 2 エントリ追加 | +2 行 |
| `CHANGELOG.md` `[2.4.0]` 節 | Keep a Changelog 順序に従い、`### Added` を `### Changed` の前に新規挿入、`### Deprecated` を `### Changed` と `### Removed` の間に新規挿入。`#597` 関連 計 6 項目（Added 2 / Changed 2 / Deprecated 2、Deprecated 2 項目は cycle-label 系スクリプトと cycle:vX.X.X ラベルで分割） | +25 行 |

## 修正対象ファイル一覧（実装直前のテキスト挿入・置換内容）

### 1. `skills/aidlc/guides/issue-management.md`

#### 修正箇所 1: L52-L58「サイクルラベル付与」セクション → 「Milestone 紐付け」へ置換

```markdown
2. **Milestone 紐付け**
   - Milestone の正式作成と関連 Issue 紐付けは Inception Phase の `05-completion.md` ステップ 1 で実施（主経路: `gh issue edit --milestone`、権限/環境差分による失敗時フォールバック: `gh api --method PATCH`）
   - `02-preparation.md` ステップ 16 は既存 Milestone がある場合のみ先行紐付けする補助動作（Unit 005 / #597）
   - 補足: 旧サイクル（v2.3.6 以前）で使用していた `cycle:v*` ラベル付与スクリプト（`label-cycle-issues.sh`）は v2.4.0 で deprecated（物理残置）
   - **手動復旧手順**: gh 利用可能時の duplicate/closed 混在復旧（パターン A-1）、gh 利用可能時の LINK_FAILED 復旧（パターン A-2、Issue / PR 双方対応）、gh 利用不可時（パターン B、curl + PAT または GitHub UI）の 3 パターンは [`backlog-management.md` の Inception Phase 節](backlog-management.md#inception-phase) を参照
```

#### 修正箇所 2: L177「関連ファイル」末尾を更新

```markdown
- `skills/aidlc/scripts/issue-ops.sh` - Issue操作スクリプト
- `skills/aidlc/scripts/label-cycle-issues.sh` - サイクルラベル一括付与スクリプト（**v2.4.0 で deprecated**、Milestone 運用本採用により Inception ステップへ移行）
- `skills/aidlc/guides/backlog-management.md` - バックログ管理ガイド
```

**注**: 旧 `docs/aidlc/guides/backlog-management.md` パス（過去構成の遺物）は実在パス `skills/aidlc/guides/backlog-management.md` に修正する。

### 2. `skills/aidlc/guides/backlog-management.md`

#### 修正箇所 1: L22-L23「対応開始時に追加するラベル」 → 「Milestone 紐付け」へ置換

```markdown
**対応開始時の Milestone 紐付け（v2.4.0 以降）**:
- Milestone は Inception Phase の `05-completion.md` ステップ 1 で正式作成する（`vX.X.X` 形式、例: `v1.8.0`）。`02-preparation.md` ステップ 16 は既存 Milestone がある場合のみ先行紐付けする補助動作
- Issue 紐付けも `05-completion.md` ステップ 1 で正式実施（主経路: `gh issue edit --milestone "vX.X.X"`、権限/環境差分による失敗時フォールバック: `gh api --method PATCH`）
- 旧運用の `cycle:vX.X.X` ラベルは v2.4.0 で deprecated（物理残置、新サイクルでは付与しない）
```

#### 修正箇所 2: L94-L98「Inception Phase」サイクルラベル付与 → 「Milestone 紐付け」 + 手動復旧 3 パターン分岐

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

#### 修正箇所 3: L138-L142「サイクルラベル作成」注記 → Milestone 作成案内

```markdown
**注**: サイクル管理は v2.4.0 以降 GitHub Milestone に移行しました。Milestone は Inception Phase の `05-completion.md` ステップ 1 で正式作成・関連 Issue 紐付けを行います。`02-preparation.md` ステップ 16 は既存 Milestone がある場合のみ先行紐付けする補助動作です。旧運用の `cycle:vX.X.X` ラベルは deprecated（物理残置、Operations 担当者の判断で個別対応）:

```text
旧運用（v2.3.6 以前、deprecated）: `gh label create "cycle:v1.8.0" ...` を手動実行していた
新運用（v2.4.0 以降）: Milestone 作成の主経路は Inception Phase の `05-completion.md` ステップ 1。Milestone 不在時は Operations Phase の `01-setup.md` ステップ 11 が fallback 作成する。**Issue/PR の Milestone 紐付け復旧に限れば**、手動対応が必要なのは `gh` 利用不可時、または duplicate/closed 混在・`LINK_FAILED` で自動処理が停止した後の復旧時のみ。なお Milestone close（`04-completion.md` ステップ 5.5）は `gh_status != available` 時 / Milestone close API 失敗時にも手動復旧が必要（REST API 直叩き curl + PAT または GitHub UI）
```
```

#### 修正箇所 4: L146-L154「将来検討事項」 → 「関連機能の現状」へ置換

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

### 3. `skills/aidlc/guides/backlog-registration.md`

#### 修正箇所: L46 注記の隣接に追加

```markdown
**注**: 発見日/発見フェーズ/発見サイクルはAIが自動補完（現在の日付/フェーズ/`{{CYCLE}}`をそのまま使用。名前付きサイクルの場合は `waf/v1.0.0` のような形式になる）

**Milestone について（v2.4.0 以降）**: 新規 Issue 作成時は Milestone 未割当（empty）を初期状態とする。Milestone への正式紐付けは Inception Phase の `05-completion.md` ステップ 1 で実施し、`02-preparation.md` ステップ 16 では既存 Milestone がある場合のみ先行紐付けする（Unit 005 / #597）。
```

### 4. `skills/aidlc/guides/glossary.md`

#### 修正箇所: 用語一覧表に 2 エントリ追加

挿入位置:

- **「サイクルラベル」**: `Cycle` 行（L19）の直後に挿入
- **「Milestone」**: `Logical Design` 行（L24）の後、`Operations` 行（L25）の前に挿入（M 行のアルファベット順）

```markdown
| Cycle | `cycle/vX.X.X` | 開発の1サイクル。バージョン番号（vX.X.X）で識別される | 全フェーズ | `prompts/common/intro.md` |
| サイクルラベル | `cycle:vX.X.X` | 旧運用での Issue 紐付け方式（**v2.4.0 で deprecated**、Milestone に置換）。物理残置されており過去サイクル追跡用に参照可能 | 全フェーズ | `guides/backlog-management.md` |
| ... |
| Logical Design | - | 非機能要件を反映した設計層 | Construction | `prompts/construction/02-design.md` |
| Milestone | `vX.X.X`（GitHub Milestone title） | GitHub Milestone を AI-DLC のサイクル管理単位として用いる（v2.4.0 以降）。Inception Phase が自動作成、Operations Phase が自動 close。1 Issue = 1 Milestone 制約 | 全フェーズ | `guides/backlog-management.md` |
| Operations | - | デプロイ・リリース・運用を行うフェーズ | Operations | `prompts/operations/01-setup.md` |
| ... |
```

### 5. `CHANGELOG.md` `[2.4.0]` 節

#### 挿入位置（Keep a Changelog 順序準拠: Added → Changed → Deprecated → Removed）

現状の `[2.4.0]` 節は `### Changed` (L11) → `### Removed` (L17) のみ。本 Unit で以下のように再構成する:

1. `### Added` を `### Changed` の前に新規挿入
2. `### Changed` の既存項目（#596 関連）はそのまま維持し、本 Unit で `#597` 関連 2 項目を追記
3. `### Deprecated` を `### Changed` と `### Removed` の間に新規挿入
4. `### Removed` の既存項目（#595 関連）はそのまま維持

#### 挿入内容

```markdown
### Added

- Inception Phase に GitHub Milestone 自動作成・関連 Issue 紐付けステップを追加（`skills/aidlc/steps/inception/02-preparation.md` ステップ 16 で先行紐付け / `05-completion.md` ステップ 1 で正式作成・紐付け）。5 ケース判定（`open ≥ 2 / 1 / 0` × `closed ≥ 1 / 0` の組み合わせ）で重複作成・誤再オープンを防止。Issue 紐付けは主経路 `gh issue edit --milestone`、権限/環境差分による失敗時フォールバックで `gh api --method PATCH`。`label-cycle-issues.sh` の awk 抽出ロジック（5 形式対応）を流用（#597 / Unit 005 / Unit 007）
- Operations Phase に Milestone close + 紐付け確認 + fallback 作成手順を追加（`skills/aidlc/steps/operations/01-setup.md` ステップ 11 / `04-completion.md` ステップ 5.5 / `index.md` §2.8 補助契約）。マージ前完結契約準拠（GitHub 側操作のみ）、5 ケース判定で誤再オープン防止、冪等補完原則で 1 Issue = 1 Milestone 制約遵守、LINK_FAILED 集約判定 exit 1 契約、`gh_status != available` 時 exit 1 + REST API 直叩き手動代替手順（#597 / Unit 006 / Unit 007）

### Changed

- ...（既存 #596 関連の Changed 項目はそのまま維持）...
- サイクル管理を `cycle:vX.X.X` ラベル運用から GitHub Milestone 運用に本採用変更。旧サイクル（v2.3.6 以前）の併記は残さない。過去サイクルの追跡は CHANGELOG / `.aidlc/cycles/v*/` ディレクトリ / 物理残置された `cycle:v*` ラベル（deprecated）で行う。Milestone 進捗バッジの README 追加は v2.5.0 以降のバックログとする（#597 / Unit 007）
- 公開ドキュメント（`skills/aidlc/guides/issue-management.md` / `backlog-management.md` / `backlog-registration.md` / `glossary.md`）のサイクル運用記述を Milestone 参照に書き換え（#597 / Unit 007）

### Deprecated

- `skills/aidlc/scripts/cycle-label.sh` / `skills/aidlc/scripts/label-cycle-issues.sh` を v2.4.0 で deprecated 化（物理残置）。Milestone 運用本採用により Inception Phase ステップ（`02-preparation.md` ステップ 16 / `05-completion.md` ステップ 1）が後継。両スクリプトは将来サイクル（v2.5.0 以降）で物理削除を検討（#597 / Unit 005 / Unit 007）
- `cycle:vX.X.X` ラベル運用を v2.4.0 で deprecated 化。新サイクルでは Milestone を使用。物理残置されたラベルは過去サイクル追跡用にのみ参照可能（#597 / Unit 007）

### Removed

- ...（既存 #595 関連の Removed 項目はそのまま維持）...
```

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

# CHANGELOG #597 節（Added 2 / Changed 2 / Deprecated 2）が追加されているか
grep -c "#597 / Unit 005 / Unit 007" CHANGELOG.md  # 期待値: 1+
grep -c "#597 / Unit 006 / Unit 007" CHANGELOG.md  # 期待値: 1+
grep -c "#597 / Unit 007" CHANGELOG.md  # 期待値: 2+
grep -c "label-cycle-issues.sh" CHANGELOG.md  # 期待値: 1+

# Keep a Changelog 順序が維持されているか（Added → Changed → Deprecated → Removed）
awk '/^### / {print NR": "$0}' CHANGELOG.md | head -10
# 期待出力例（v2.4.0 節内）:
# X: ### Added
# Y: ### Changed
# Z: ### Deprecated
# W: ### Removed
```

### 設計レビュー時のガイド照合ルール適用

`.aidlc/rules.md` 「設計レビュー時のガイド照合ルール」（該当ルールが定義されている場合）に従い、過剰な互換記述（旧運用の説明残置）が混入しないよう確認。`glossary.md` の「サイクルラベル」エントリは過去ドキュメントとの参照リンク切れを避ける目的であるため、deprecation 注記付きで例外的に残置可。

## 境界遵守

- Unit 003 所有のファイル（`bin/update-version.sh` / 関連の `.aidlc/rules.md` 段落 / CHANGELOG `#596` 節）には触らない
- Unit 005 所有のファイル（`skills/aidlc/steps/inception/02-preparation.md` / `05-completion.md` / `index.md` / `cycle-label.sh` / `label-cycle-issues.sh`）には触らない
- Unit 006 所有のファイル（`skills/aidlc/steps/operations/01-setup.md` / `04-completion.md` / `index.md` §2.8）には触らない
- 翻訳ドキュメント（`docs/translations/`）は本サイクル対象外
- README.md / docs/configuration.md / .aidlc/rules.md の Milestone 関連書き換え: **実態調査の結果、対象記述が存在しないため触らない**（過剰修正回避）

## 不明点と質問

なし（plan 段階で codex AI レビュー 14 反復を経て手動復旧 3 パターン分岐 / Keep a Changelog 順序 / 過剰修正回避を確定済み）。

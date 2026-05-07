# 論理設計: Operations §7 ステップ7「完了」更新タイミング

## 概要

Unit 001 の docs / template 改訂に必要な **編集箇所（既存文言・改訂後文言）** と **整合性検証 grep クエリ** を確定する。実装フェーズはこの仕様に従い文言マッチで編集箇所を特定する（行番号は改訂直前に再取得）。

**重要**: 本論理設計は docs / template 改訂のため、コードコンポーネント設計は不要。代わりに「文書編集仕様」「整合性検証クエリ仕様」「markdownlint 通過条件」を定義する。

---

## アーキテクチャパターン

**ドキュメンタリ集約 + 単一 SoT 参照パターン**: タイミング契約の主 SoT を `operations-release.md` §7.7 **セクション 1 箇所のみ** に確定し、他レイヤ（§7.2〜§7.6 統合節 / `02-deploy.md` / `03-release.md` / `04-completion.md` / `templates/`）はそれぞれ最小限の SoT 参照（`operations-release.md §7.7` への 1 リンク）と自レイヤ責務に閉じた追記のみを行う【Round 1 設計レビュー指摘 #2 / #7 / #8 対応】。

採用理由:

- 5 ファイルに同タイミング表現を分散すると将来の改訂でドリフトが発生しやすい
- SoT を `operations-release.md §7.7` 1 箇所に集約することで、改訂時の整合性維持コストを最小化
- 各ファイルの改訂後文言から SoT 参照を 1 つに絞り、長文化と参照反復を回避

---

## コンポーネント構成

### 編集対象ファイルレイヤ

```text
operations-release.md (タイミング契約 SoT 単一集約点)
├── §7.2〜§7.6 統合節 line 29 既存段落の冒頭 1 文に「§7.6 書き込み・§7.7 main 反映」「『完了』=『PR準備完了』」を最小追記
└── §7.7 line 51-53（タイミング契約の主表現を 1 文追記）

02-deploy.md (入口手順)
├── line 183（サブステップ列挙の §7.6 行に同義表現補足）
├── line 186（既存 1 文を「PR準備完了 = ステップ7「完了」、§7.7 main 反映」に圧縮改訂）【Round 1 指摘 #3 対応】
└── line 199（ステップ完了時記述を §7.7 確定タイミング表現へ書き換え、SoT 参照は operations-release.md §7.7 のみ）

03-release.md (完了判定)
└── line 28-31（同義性 + main 反映済み補足、SoT 参照は operations-release.md §7.7 のみ）

04-completion.md (整合性ガード)
└── §4 line 484 と line 486 の間に新規段落「**前提（ステップ7「完了」更新タイミング）**」を挿入【Round 1 指摘 #4 対応】

templates/operations_progress_template.md (テンプレート)
└── line 13 直後（推移経路 HTML コメント追加 / lint 失敗時は代替案へ）

.aidlc/cycles/v2.5.4/history/construction_unit01.md (履歴 / 既存)
└── 末尾追記（変更ファイル / レビュー round / 検証結果）
```

---

## 編集仕様

### 1. `skills/aidlc/steps/operations/operations-release.md`（タイミング契約 SoT）

#### 1.1 §7.2〜§7.6 統合節 line 29 既存段落の冒頭最小追記【Round 1 指摘 #2 対応 / SoT 重複回避】

**既存文言**（line 29 冒頭）:

```text
- **progress.md 固定スロット反映【重要 / マージ前完結契約】**: `operations/progress.md` の構造化シグナル 3 スロットを以下のとおり更新し、§7.7 最終コミットに**必ず**含める。スロットの grammar は…
```

**改訂後文言**（既存段落冒頭の太字見出し直後に 1 文を追加）:

```text
- **progress.md 固定スロット反映【重要 / マージ前完結契約】**: **タイミング契約: progress.md ステップ7「完了」(= `02-deploy.md` line 17 の `PR準備完了` と同義 / `03-release.md` line 30 SoT) は §7.6 で書き込み、§7.7 Git コミットで main 反映する**（タイミング契約の正本は §7.7 セクション）。`operations/progress.md` の構造化シグナル 3 スロットを以下のとおり更新し、§7.7 最終コミットに**必ず**含める。スロットの grammar は…
```

**改訂理由**: line 28 直下にサブ箇条書きを挿入すると line 29「**progress.md 固定スロット反映**」段落と意味論が重複（マージ前完結契約・§7.7 反映・マージ後改変禁止が 2 段で並ぶ）。line 29 既存段落の冒頭 1 文として「タイミング契約 + 同義性」を埋め込み、SoT 一意性を維持しつつ最小追記とする【Round 1 指摘 #2 対応】。

#### 1.2 §7.7 セクション line 51-53 への 1 文追記（タイミング契約 SoT 主表現）

**既存文言**（line 51-53）:

```text
## 7.7 Git コミット

コミットなしで 7.8 に進まない。`commit-flow.md` の「Operations Phase 完了コミット」に従い全変更をコミット。本コミットには §7.2〜§7.6 で更新した progress.md 固定スロット（通常系では 3 スロット、エッジケースでは 2 スロット）を**必ず含める**こと（マージ前完結契約の成立条件）。
```

**改訂後文言**（既存段落末尾に 1 文追加 / SoT 主表現）:

```text
## 7.7 Git コミット

コミットなしで 7.8 に進まない。`commit-flow.md` の「Operations Phase 完了コミット」に従い全変更をコミット。本コミットには §7.2〜§7.6 で更新した progress.md 固定スロット（通常系では 3 スロット、エッジケースでは 2 スロット）を**必ず含める**こと（マージ前完結契約の成立条件）。**ステップ7「完了」更新タイミング契約の正本**: progress.md のステップ7「完了」（= `02-deploy.md` line 17 の `PR準備完了` と同義）は §7.6 で書き込み、本 §7.7 Git コミットで main に反映される（マージ前完結契約の成立点）。マージ後（§7.13 後）の `progress.md` 編集は二重更新となるため禁止（`04-completion.md` §4 マージ前完結ルール参照）。
```

### 2. `skills/aidlc/steps/operations/02-deploy.md`（入口手順）

#### 2.1 line 183 サブステップ列挙の §7.6 行補足

**既存文言**（line 183）:

```text
5. 7.6 progress.md更新 ← **PR準備完了**
```

**改訂後文言**:

```text
5. 7.6 progress.md更新 ← **PR準備完了**（= ステップ7「完了」、§7.7 main 反映 / 詳細は `operations-release.md §7.7` 参照）
```

#### 2.2 line 186 圧縮改訂【Round 1 指摘 #3 対応】

**既存文言**（line 186）:

```text
**注**: 7.6でprogress.mdを「PR準備完了」状態に更新し、7.7でコミットしてPRに反映します。以下はレビュー・マージ作業です。
```

**改訂後文言**（同義性 + main 反映タイミングの 1 行表現に圧縮）:

```text
**注**: 7.6 で progress.md を「PR準備完了」（= ステップ7「完了」）に更新し、7.7 で main に反映（マージ前完結契約の成立点 / `operations-release.md §7.7` 参照）。以下はレビュー・マージ作業です。
```

#### 2.3 line 199 ステップ完了時記述の書き換え（SoT 参照を §7.7 単独に絞る）

**既存文言**（line 199）:

```text
- **ステップ完了時**: progress.mdでステップ7を「完了」に更新、完了日を記録
```

**改訂後文言**:

```text
- **ステップ完了時（§7.7 Git コミット時に確定）**: §7.6 で progress.md のステップ7 を「完了」（= `PR準備完了`、line 17 状態ラベル参照）に更新し、完了日を記録、§7.7 のコミットで main に反映する。**マージ後（§7.13 後）の `progress.md` 編集は禁止**（マージ前完結契約 / 詳細は `operations-release.md §7.7` のタイミング契約 SoT 参照）
```

### 3. `skills/aidlc/steps/operations/03-release.md`（完了判定）

#### 3.1 line 28-31 完了時の確認の補足（SoT 参照を §7.7 単独に絞る）

**既存文言**（line 28-31）:

```text
1. **ステップ7（リリース準備）がPR準備完了している**こと
   - バージョン確認、バージョンファイル更新（AI-DLCスターターキットのみ）、CHANGELOG更新（`changelog = true`の場合）、README更新、履歴記録、Markdownlint実行、progress.md更新、Gitコミットが完了
   - progress.mdでステップ7が「完了」（= PR準備完了）になっている
   - **注**: 7.8-7.13はPR準備完了後のレビュー・マージ作業
```

**改訂後文言**:

```text
1. **ステップ7（リリース準備）がPR準備完了している**こと
   - バージョン確認、バージョンファイル更新（AI-DLCスターターキットのみ）、CHANGELOG更新（`changelog = true`の場合）、README更新、履歴記録、Markdownlint実行、progress.md更新（§7.6）、Gitコミット（§7.7）が完了
   - progress.mdでステップ7が「完了」（= PR準備完了）になっている。**この「完了」状態は §7.7 Git コミット時に main へ反映済み**（マージ前完結契約の成立点 / 詳細は `operations-release.md §7.7` のタイミング契約 SoT 参照）
   - **注**: 7.8-7.13はPR準備完了後のレビュー・マージ作業。**マージ後（§7.13 後）の `progress.md` 編集は禁止**（DR-001 / Unit 002 / #583 / `04-completion.md` §4 マージ前完結ルール参照）
```

### 4. `skills/aidlc/steps/operations/04-completion.md`（整合性ガード）

#### 4.1 §4 line 484 と line 486 の間に新規段落を挿入【Round 1 指摘 #4 対応】

**既存構造**（line 484-486）:

```text
**理由**: cycle ブランチは post-merge-sync.sh で削除されるため、マージ後の改変は記録として残らず、未コミット差分として手動破棄が必要になる。マージ完了の事実は GitHub 上の PR・merge commit・自動タグが記録源となる。

**ガード動作**（Unit 002 / DR-001）: マージ後に `write-history.sh --phase operations` を呼び出した場合、…
```

**改訂後構造**（line 484「**理由**」段落の後・line 486「**ガード動作**」段落の前に新規段落を挿入）:

```text
**理由**: cycle ブランチは post-merge-sync.sh で削除されるため、マージ後の改変は記録として残らず、未コミット差分として手動破棄が必要になる。マージ完了の事実は GitHub 上の PR・merge commit・自動タグが記録源となる。

**前提（ステップ7「完了」更新タイミング）**: `operations/progress.md` のステップ7「完了」更新は **§7.7 Git コミット時で main 反映済み**（タイミング契約 SoT: `operations-release.md §7.7`）。マージ後の編集は二重更新となり、本マージ前完結ルールの意図を破る。

**ガード動作**（Unit 002 / DR-001）: マージ後に `write-history.sh --phase operations` を呼び出した場合、…
```

**配置理由**: 既存 line 484「**理由**」段落の末尾追記は段落を 2 文 → 3 文に膨らませ、`**ガード動作**` 段落（line 486）との論理段差が増す。新規段落として独立させることで、line 484「**理由**」（マージ後改変全般の理由）→ line 485（空行）→ 新規「**前提（ステップ7「完了」更新タイミング）**」（ステップ7 固有の前提）→ 空行 → line 486「**ガード動作**」（exit 3 ガード仕様）という論理階段が成立する【Round 1 指摘 #4 対応】。

### 5. `skills/aidlc/templates/operations_progress_template.md`（テンプレート）

#### 5.1 line 13 直後への推移経路コメント追加（lint 失敗時は代替案）

**既存文言**（line 13）:

```text
| 7. リリース準備 | 未着手 | README.md, history.md, PR | - |
```

**改訂後文言（第一案: HTML コメント直接追加）**:

```text
| 7. リリース準備 | 未着手 | README.md, history.md, PR | - |
<!-- ステップ7「完了」状態は §7.6 で書き込み、§7.7 Git コミット時に main へ反映される（タイミング契約 SoT: operations-release.md §7.7）。「完了」と「PR準備完了」は §7.6 で書き込む状態の同義表現（02-deploy.md line 17 の状態ラベル定義参照）。マージ後（§7.13 後）の編集は禁止（DR-001 / Unit 002 / #583）。 -->
```

> **markdownlint 配慮**: 第一案の HTML コメントは Markdown テーブル末尾に直接追加すると MD031 / MD041 系の指摘対象になる可能性がある。実装時に `npx markdownlint-cli2` 結果を確認し、警告 / エラーが出た場合は **第二案: テーブル後の空行を挟んだ別段落** へフォールバックする。

**改訂後文言（第二案: 代替案 / lint 失敗時のフォールバック）**:

```text
| 7. リリース準備 | 未着手 | README.md, history.md, PR | - |

<!-- ステップ7「完了」状態の遷移経路: §7.6 で書き込み、§7.7 Git コミット時に main へ反映（タイミング契約 SoT: operations-release.md §7.7）。「完了」と「PR準備完了」は §7.6 で書き込む状態の同義表現（02-deploy.md line 17 参照）。マージ後（§7.13 後）の編集は禁止（DR-001 / Unit 002 / #583）。 -->
```

実装時の判定手順: 第一案を適用 → `npx markdownlint-cli2 templates/operations_progress_template.md` を実行 → 警告 / エラーがあれば第二案へ切り替え → 再 lint → pass を確認。

---

## 整合性検証クエリ仕様（Step7 Timing Consistency Verifier 実装）

実装直後に以下の grep クエリを順次実行し、全件 期待結果通り（1 行以上ヒット / 5 行不変 / 空 等）を確認する。**全クエリでバッククォートをコマンドラインに含めず、シングルクォートまたはエスケープを使用する**【Round 1 指摘 #1 対応 / zsh OOM クラッシュ回避】。

### V1: タイミング表現の一意性【Round 1 指摘 #5 対応 / 厳密モード】

各ファイルで「§7.7」と「Git コミット時」「main 反映」「コミット」のいずれかを近傍に含む行が **最低 1 件ヒット** すること。

```bash
# 厳密モード: §7.7 を含み、かつ Git/コミット/main のいずれかを近傍に含む行
grep -nE '§7\.7.*(Git|コミット|main)|§7\.7.{0,30}(Git|コミット|main)' skills/aidlc/steps/operations/operations-release.md
grep -nE '§7\.7.*(Git|コミット|main)' skills/aidlc/steps/operations/02-deploy.md
grep -nE '§7\.7.*(Git|コミット|main)' skills/aidlc/steps/operations/03-release.md
grep -nE '§7\.7.*(Git|コミット|main)' skills/aidlc/steps/operations/04-completion.md
grep -nE '§7\.7.*(Git|コミット|main)' skills/aidlc/templates/operations_progress_template.md
```

**期待**: 全 5 ファイルで 1 件以上ヒット。

### V2: 「完了」と「PR準備完了」同義性

```bash
grep -n '完了」（= PR準備完了）' skills/aidlc/steps/operations/03-release.md  # 既存 / 維持
grep -n 'PR準備完了' skills/aidlc/steps/operations/02-deploy.md              # line 17 / 183 / 186 / 199（改訂後も維持）
grep -nE '「完了」.*同義|同義.*「完了」|（= `PR準備完了`|= ステップ7「完了」' skills/aidlc/steps/operations/operations-release.md
grep -n 'PR準備完了' skills/aidlc/templates/operations_progress_template.md   # コメント内
```

**期待**: 全クエリで 1 件以上ヒット。

### V3: マージ後編集禁止の整合

```bash
grep -nE 'マージ後.*progress\.md.*禁止|二重更新' skills/aidlc/steps/operations/04-completion.md
grep -nE 'マージ後.*progress\.md.*禁止' skills/aidlc/steps/operations/02-deploy.md
grep -nE 'マージ後.*progress\.md.*禁止|マージ後.*編集.*禁止' skills/aidlc/steps/operations/03-release.md
grep -nE 'マージ後.*編集.*禁止' skills/aidlc/templates/operations_progress_template.md
```

**期待**: 全クエリで 1 件以上ヒット。

### V4: マージ前完結契約の成立点（SoT 主表現）

```bash
grep -n 'マージ前完結契約の成立点' skills/aidlc/steps/operations/operations-release.md  # 改訂後 §7.7
grep -n 'マージ前完結契約の成立点' skills/aidlc/steps/operations/02-deploy.md           # 改訂後 line 186
grep -n 'マージ前完結契約の成立点' skills/aidlc/steps/operations/03-release.md          # 改訂後 line 28-31
```

**期待**: 全 3 ファイルで 1 件以上ヒット（SoT 主表現が複数箇所で引用されている）。

### V5: 状態ラベル一覧の不変【Round 1 指摘 #1 対応 / バッククォート回避】

```bash
# 02-deploy.md line 11-17 範囲を sed で抽出 → wc -l で 7 行（テーブル含む）不変を確認
sed -n '11,17p' skills/aidlc/steps/operations/02-deploy.md | wc -l   # 期待: 7
# 5 ラベル名が全て存在することを順次確認（バッククォートを含まないキー部分のみ照合）
grep -F '未着手' skills/aidlc/steps/operations/02-deploy.md | head -1
grep -F '進行中' skills/aidlc/steps/operations/02-deploy.md | head -1
grep -F '完了' skills/aidlc/steps/operations/02-deploy.md | head -1
grep -F 'スキップ' skills/aidlc/steps/operations/02-deploy.md | head -1
grep -F 'PR準備完了' skills/aidlc/steps/operations/02-deploy.md | head -1
```

**期待**: `sed | wc -l` の結果が 7（line 11-17 / テーブル + 状態ラベル 5 行 + 終端行）。各 `grep -F` で 1 件以上ヒット。

### V6: スコープ保護（git diff ベース）【Round 1 指摘 #6 対応 / path 完全化】

```bash
# scripts / bin/tests / tests / 既存サイクル progress.md への波及がないこと
git diff --name-only main... -- 'skills/aidlc/scripts/**' 'scripts/**' 'bin/tests/**' 'tests/**'  # 期待: 空
git diff --name-only main... -- '.aidlc/cycles/v1.*' '.aidlc/cycles/v2.0.*' '.aidlc/cycles/v2.1.*' '.aidlc/cycles/v2.2.*' '.aidlc/cycles/v2.3.*' '.aidlc/cycles/v2.4.*' '.aidlc/cycles/v2.5.0' '.aidlc/cycles/v2.5.1' '.aidlc/cycles/v2.5.2' '.aidlc/cycles/v2.5.3'  # 期待: 空（v2.5.4 以前への遡及なし）
```

**期待**: 両クエリで空（exit 0、stdout 0 行）。

> **`bin/tests/` / `tests/` 不在時の挙動**: リポジトリにディレクトリが存在しない場合、`git diff --name-only` は空を返す（exit 0）。これは「波及なし」と整合し、期待値「空」と論理整合する【Round 1 指摘 #6 補足対応】。

---

## 処理フロー概要

### 編集適用フロー（実装順序）

1. SoT 主表現確定: `operations-release.md` §7.7 line 51-53 にタイミング契約 SoT 主表現を 1 文追記
2. SoT 補助点: `operations-release.md` §7.2〜§7.6 統合節 line 29 既存段落の冒頭 1 文に同義性 + タイミング契約参照を埋め込み
3. 入口手順整合: `02-deploy.md` line 183 / line 186 / line 199 を改訂（SoT 参照は `operations-release.md §7.7` のみ）
4. 完了判定整合: `03-release.md` line 28-31 を改訂（SoT 参照は `operations-release.md §7.7` のみ）
5. 整合性ガード: `04-completion.md` §4 line 484 と line 486 の間に新規段落「**前提（ステップ7「完了」更新タイミング）**」を挿入
6. テンプレート: `templates/operations_progress_template.md` line 13 直後にコメント追加（lint 失敗時は第二案へフォールバック）
7. 検証: V1〜V6 grep / sed クエリ + `npx markdownlint-cli2` 5 ファイル
8. 履歴: `construction_unit01.md` に変更ファイル一覧 / 検証結果を追記

**関与するコンポーネント**: 5 docs ファイル + 1 history ファイル

---

## 非機能要件（NFR）への対応

### パフォーマンス

- 要件: ランタイム性能影響なし（docs 改訂のみ）
- 対応策: scripts / バイナリへの変更なし。整合性検証 grep / sed は 1 ファイルあたり数十 ms 以下で完了

### セキュリティ

- 要件: 機密情報の取り扱いに変更なし
- 対応策: 改訂内容は文書整合のみ。秘密鍵 / API トークン / 認証情報を含まない

### 後方互換

- 要件: 既存 Operations Phase の動作（progress.md / history / `operations-release.sh` / `write-history.sh` exit 3 ガード）を破壊しない
- 対応策:
  - `operations-release.md` 既存 line 28-29 の文言は維持し、line 29 段落冒頭の最小追記のみ
  - `02-deploy.md` 既存 line 183 / line 186 / line 199 は文言の補足・改訂で意味論を逸脱しない
  - `03-release.md` line 28-31 「（= PR準備完了）」併記を維持
  - `templates/operations_progress_template.md` 既存テーブル + 固定スロット構造は不変、HTML コメント追加のみ
  - `scripts/write-history.sh` exit 3 ガード（`completion_gate_ready=true` AND PR `MERGED`）の前提（§7.7 で `completion_gate_ready=true` が main 反映される invariant）を強化する方向の改訂のみ
  - 既存サイクル（v2.5.3 以前）の `operations/progress.md` への遡及書き換えなし

---

## 技術選定

- 言語: Markdown（既存ファイル形式）
- 検証ツール: `grep` / `sed` / `git diff` / `npx markdownlint-cli2`
- 編集ツール: Edit / Write（Claude Code 標準）

---

## 実装上の注意事項

- **行番号は文言マッチで再取得**: 改訂直前に `grep -n` で対象行番号を取得し、文言マッチで Edit を実施する。行番号固定での Edit 失敗を回避
- **シェル展開リスク回避**【Round 1 指摘 #1 対応】: 検証クエリでバッククォート（`` ` ``）の使用を回避する。バッククォートを含む文字列照合が必要な場合は `grep -F`（固定文字列モード）+ シングルクォート、または `sed -n` による範囲抽出 + `wc -l` の組み合わせを使用する
- **markdownlint 配慮**: HTML コメントの配置位置（テーブル直後 / 空行を挟むか）は実装時に lint 結果で確認し、必要に応じて第二案（テーブル後の空行 + コメント）に切り替える
- **既存文言の保持**: `operations-release.md` line 28-29 / `02-deploy.md` line 183 / line 199 / `03-release.md` line 28-31 / `04-completion.md` line 484 はいずれも既存文言を維持し、補足追記のみ。`02-deploy.md` line 186 のみ「同義性 + main 反映タイミング」表現に圧縮改訂
- **改訂対象 5 ファイル全てで V1〜V6 検証クエリが期待結果通り** であることを実装完了の必要条件とする
- **SoT 参照の単一化**【Round 1 指摘 #8 対応】: 各レイヤの改訂後文言から SoT 参照は `operations-release.md §7.7` 1 リンクのみとし、長文化と参照反復を回避する

---

## 不明点と質問（設計中に記録）

`[Question]` / `[Answer]` 形式で記録する。

- **[Question]**（Round 1 設計レビュー指摘 #3 起点）: `02-deploy.md` line 186 を改訂対象に含めるか？
  - **[Answer]**: 含める（圧縮改訂）。Round 2 計画レビューでは「line 186 と line 199 の並列性は AI エージェントが SoT を参照することで補完する」と整理したが、Round 1 設計レビュー指摘 #3 で「並列性が将来改訂時のドリフト要因になる」リスクが再提起されたため、line 186 も「同義性 + main 反映タイミング」表現に圧縮改訂する。改訂量は 1 行のため見積もり影響なし。

実装フェーズで発生した質問は本セクションに追記する。

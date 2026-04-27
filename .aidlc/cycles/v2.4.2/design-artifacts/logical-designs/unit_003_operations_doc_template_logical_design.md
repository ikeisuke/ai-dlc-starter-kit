# 論理設計: Unit 003 - Operations 手順書 / template 明文化

## 概要

ドメインモデル（`unit_003_operations_doc_template_domain_model.md`）で定義した「対象 8 件の明文化マッピング」を、3 ファイル（`operations-release.md` / `02-deploy.md` / `operations_progress_template.md`）への追記として実現する論理設計。本 Unit は実装コードを書かず、追記する手順書 / テンプレートのセクション構造・文面例・行範囲を定義する。

**重要**: この論理設計ではコードは書かず、コンポーネント構成（追記セクション構造）と挿入位置仕様のみを行う。具体的な Markdown 文面は Phase 2 で作成する。

## アーキテクチャパターン

- **採用パターン**: **手順書ガイド型ワークフロー（軽量）**（Markdown 手順書 / テンプレートの inline 文章補強）
- **選定理由**: Unit 001 / Unit 002 と同じく、本 Unit はコード追加ではなく Markdown 改訂のため。Unit 001 / Unit 002 で確立したパターンを軽量化（対話 UI なし、コンポーネント分離なし）して流用

## 改訂対象ファイルの追記箇所マトリクス

### `skills/aidlc/steps/operations/operations-release.md`（288 行）

> **挿入位置の精度（Unit 003 設計レビュー反復1 指摘 #1 対応）**: 各エントリの「現行行範囲」に隣接見出しまたは段落アンカーを明記し、Phase 2 実装時の挿入位置揺らぎを排除する。

| # | 改訂対象セクション | 現行行範囲 + 隣接アンカー | 追記内容 | 観測キーワード |
|---|------------------|--------------------------|---------|--------------|
| 1 | §7.2-§7.6（progress.md 固定スロット反映の説明） | line 23-36（line 25「`rules.release.changelog = true` の場合のみ CHANGELOG…」段落〜line 36「値フォーマット検証」段落の範囲） | 固定スロット 3 行の具体例コードブロック inline + grammar v1 準拠（boolean 小文字固定 `true`/`false` / integer `^[1-9][0-9]*$` / HTML コメント `<!-- fixed-slot-grammar: v1 -->` 同梱）（指摘 #7 対応で grammar v1 準拠を本マトリクスに統合） | `## 固定スロット（Operations 復帰判定用）` 見出し + `<!-- fixed-slot-grammar: v1 -->` + `release_gate_ready=true` + `completion_gate_ready=true` + `pr_number=<番号>` |
| 2 | §7.2（CHANGELOG 設定値確認手順、補強1） | line 25「`rules.release.changelog = true` の場合のみ CHANGELOG…」段落直後（line 25 と line 26 の間）/ #3 補強3 の **直前** に挿入 | `scripts/read-config.sh rules.release.changelog` の確認コマンド | `scripts/read-config.sh rules.release.changelog` |
| 3 | §7.2（CHANGELOG 該当なし判定、補強3） | line 25 直後で #2 補強1 の **直後**（同一段落塊として連続記述） | `changelog=false` 時はスキップする旨 | `changelog=false` または「スキップ」文言 |
| 4 | §7.6（既存 progress.md セクション有無判定、補強2） | line 30 「`release_gate_ready=true` に更新…」段落の **直前** に挿入（line 29 末尾と line 30 開始の間） | 「既存 progress.md に `## 固定スロット（Operations 復帰判定用）` セクションが存在するか確認、未存在時は新規セクションを追加してから固定スロットを記載する」手順 | `## 固定スロット` セクション存在確認文言（「セクションが存在」「未存在」「有無」のいずれか） |
| 5 | §7.7（コミット対象ファイル列挙、[P4]） | line 38-40（§7.7 セクション全体） | `operations/progress.md` / `history/operations.md` / `README.md` / `CHANGELOG.md`（条件付き）/ `version.txt` / `.aidlc/config.toml`（条件付き）/ markdownlint 修正ファイル | 上記 7 ファイル名 + 条件付き記述 |
| 6 | §7.7（行区切り規約） | 上記 #5 と同位置（line 38-40 範囲内） | 改行区切り、独立行（`key=value` の Markdown リスト形式ではなく独立行） | 「改行区切り」または「独立行」文言 |
| 7 | §7.7（設定依存判定基準、補強4） | 上記 #5 と同位置（line 38-40 範囲内、コミット対象列挙の文末注記として配置） | `rules.release.changelog` / `bin/update-version.sh` 利用有無の条件分岐記述 | `rules.release.changelog` + `bin/update-version.sh` + 「利用有無」 |

### `skills/aidlc/steps/operations/02-deploy.md`（188 行）

| # | 改訂対象セクション | 現行行範囲 | 追記内容 | 観測キーワード |
|---|------------------|-----------|---------|--------------|
| 8 | §7「ステップ7: リリース準備」冒頭または最初のサブステップ | line 156-186 | 状態ラベル 5 値（`未着手` / `進行中` / `完了` / `スキップ` / `PR準備完了`）の表形式列挙 | 5 値リテラル + 簡潔な説明 |
| 9 | §7.7（誘導注記） | line 175 周辺 | `[必読] operations-release.md §7.7` の独立記述 | `[必読] operations-release.md §7.7` または同等表現 |

### `skills/aidlc/templates/operations_progress_template.md`（37 行）

| # | 改訂対象セクション | 現行行範囲 | 追記内容 | 観測キーワード |
|---|------------------|-----------|---------|--------------|
| 10 | 新規セクション挿入位置 | line 13 と line 14 の間 | `## 固定スロット（Operations 復帰判定用）` セクション + `<!-- fixed-slot-grammar: v1 -->` + 3 スロット（`release_gate_ready=` / `completion_gate_ready=` / `pr_number=`）（初期値は空 / false 推奨） | 上記 4 文字列すべて |

## コンポーネント構成

### 改訂内容の構造図

```text
operations-release.md（既存 288 行）
├── §7.1 バージョン確認（既存、変更なし）
├── §7.2〜§7.6（既存セクション、本 Unit で文章補強）
│   ├── §7.2 CHANGELOG（line 25）← 補強1（read-config.sh）+ 補強3（changelog=false スキップ）追加
│   ├── §7.3 README（変更なし）
│   ├── §7.4 履歴（変更なし）
│   ├── §7.5 lint（変更なし）
│   └── §7.6 progress.md 反映（line 28-36）← [P1] 固定スロット具体例コードブロック + 補強2（セクション有無判定）追加
├── §7.7 Git コミット（line 38-40）← [P4] コミット対象ファイル列挙 + 行区切り規約 + 補強4（設定依存判定）追加
├── §7.8〜§7.13（既存、変更なし）
└── （以降変更なし）

02-deploy.md（既存 188 行）
├── §7 ステップ7: リリース準備（line 156-186）← [P3] 状態ラベル 5 値列挙追加
├── §7 サブステップ一覧 line 175 周辺 ← §7.7 誘導注記（[必読] operations-release.md §7.7）追加
└── （以降変更なし）

operations_progress_template.md（既存 37 行）
├── # Operations Phase 進捗管理（既存、変更なし）
├── ## ステップ一覧（line 5-13、変更なし）
├── ## 固定スロット（Operations 復帰判定用）（line 13-14 間に新規挿入 ★ [P2]/[#585]）
│   ├── <!-- fixed-slot-grammar: v1 -->
│   ├── release_gate_ready=（初期値: 空または false）
│   ├── completion_gate_ready=（初期値: 空または false）
│   └── pr_number=（初期値: 空）
├── ## 現在のステップ（既存、変更なし）
├── ## 完了済みステップ（既存、変更なし）
├── ## 次回実行時の指示（既存、変更なし）
├── ## プロジェクト種別による差異（既存、変更なし）
└── ## 再開時に読み込むファイル（既存、変更なし）
```

### 固定スロット 3 行の Markdown 表現（grammar v1 準拠）

> **HTML コメントの位置仕様（Unit 003 設計レビュー反復1 指摘 #3 対応）**: `<!-- fixed-slot-grammar: v1 -->` HTML コメントは **セクション見出しの直下、3 スロットより前** に配置する。配置順序は「見出し → 空行 → コメント → スロット行群」とする。`ArtifactsStateRepository` のパース工程が見出し → コメント → スロット行の順序で読み取ることを想定し、コメントを末尾に配置すると grammar バージョン判定が遅延するため避ける。

#### `operations-release.md §7.6` への inline 記載例

`operations-release.md` 側では「具体例」として記載する（テンプレートではないため、操作手順の参考例として扱う）。

```markdown
**progress.md への記載例**（grammar v1 準拠）:

\`\`\`text
## 固定スロット（Operations 復帰判定用）

<!-- fixed-slot-grammar: v1 -->
release_gate_ready=true
completion_gate_ready=true
pr_number=123
\`\`\`
```

#### `operations_progress_template.md` への新規セクション

テンプレートはサイクル初期化時に展開されるため、初期値（空 or false）で配置する。

```markdown
## 固定スロット（Operations 復帰判定用）

<!-- fixed-slot-grammar: v1 -->
release_gate_ready=false
completion_gate_ready=false
pr_number=
```

> **初期値の選定**: `release_gate_ready=false` / `completion_gate_ready=false` は §7.6 で `true` に更新される。`pr_number=` は空（未記録）として配置し、§7.6 通常系または §7.8 エッジケースで PR 番号確定時に更新される。boolean 初期値は `false` 明示と空白の 2 案があるが、grammar v1 は明示的な値を期待するため `false` を採用する。

### 行区切り規約の inline 記載

`operations-release.md §7.7` に以下の記述を追加:

```markdown
**行区切り規約**: 各スロットは **独立行** で記述する（Markdown リスト形式 `- key=value` ではなく、独立した 1 行として `key=value` のみ）。改行で区切り、同一行に複数の `key=value` を並べない（grammar v1 のパース挙動上、同一行内のカンマ区切り併記は許容されるが、可読性のため独立行を推奨）。
```

### コミット対象ファイル列挙の inline 記載

`operations-release.md §7.7` に以下のリストを追加:

```markdown
**コミット対象ファイル**:

- `operations/progress.md`（必須、§7.6 の固定スロット更新を含む）
- `history/operations.md`（必須、`/write-history` で §7.4 に記録した内容）
- `README.md`（必須、§7.3 の更新を含む）
- `CHANGELOG.md`（条件付き: `rules.release.changelog=true` の場合のみ。`scripts/read-config.sh rules.release.changelog` で確認）
- `version.txt` / `.aidlc/config.toml`（条件付き: `bin/update-version.sh` でバージョン更新した場合のみ）
- markdownlint で修正したその他ファイル（§7.5 で markdownlint:auto-fix が発生した場合）
```

### 状態ラベル 5 値の inline 記載（02-deploy.md §7）

`02-deploy.md` の §7 冒頭注記に以下を追加:

```markdown
**状態ラベル一覧**: progress.md 内のステップ状態に使用するラベルは以下の 5 値:

| 状態ラベル | 説明 |
|----------|------|
| `未着手` | ステップ未開始 |
| `進行中` | ステップ実行中 |
| `完了` | ステップ正常完了 |
| `スキップ` | ステップ条件によりスキップ（変更なし / プロジェクト種別不該当 等） |
| `PR準備完了` | §7.6 で progress.md 更新完了状態（§7.7 コミット前後を含む段階表現。`02-deploy.md` line 174「7.6 progress.md更新 ← **PR準備完了**」と整合）（指摘 #4 対応） |
```

### §7.7 誘導注記（02-deploy.md）

`02-deploy.md` の line 175 周辺（「7. 7.7 Gitコミット」のサブステップ）に以下を追加:

```markdown
> **[必読] `operations-release.md §7.7`**: コミット対象ファイル / 行区切り規約 / 設定依存判定の詳細は `operations-release.md §7.7` を参照する。本ファイル（02-deploy.md）にはサブステップ番号の列挙のみを残し、詳細手順は集約先で管理する。
```

## 後方互換性の構造的保証

### テンプレート展開ロジックの確認結果（INV-T1 の根拠）

**確認対象**: `skills/aidlc/steps/operations/01-setup.md` §6「進捗管理ファイル確認」（line 46-51）

**確認結果**: line 50-51 で以下の動作が文書化されている:

> - 存在する場合: 完了済みステップを確認、未完了から再開
> - 存在しない場合: 初回実行として作成（`project.type` に応じて配布ステップをスキップ設定）

**結論**: 既存サイクル（v2.4.1 以前）の `operations/progress.md` は **既存ファイル存在時に上書きされない**。テンプレート改訂は新規サイクル（v2.4.2 以降）の Operations Phase 初回開始時にのみ展開される。INV-T1（テンプレート後方互換）は既存仕様で構造的に保証される。

> **INV-T1 の保証レベル（Unit 003 設計レビュー反復1 指摘 #6 対応）**: テンプレート展開主体は **AI エージェント**（`01-setup.md` §6 の手順実行）であり、`bin/setup-aidlc.sh` 等のスクリプトレベルでの上書き防止ではなく、AI プロンプト（手順書）レベルでの分岐により保証される。INV-T1 の根拠は **AI が `01-setup.md` §6「存在する場合 / 存在しない場合」分岐を厳密に従う前提**にあり、`aidlc-setup` スキルや `bin/setup-aidlc.sh` がテンプレートを各サイクルディレクトリに展開する処理は本 Unit のスコープ外（テンプレートディレクトリ自体の配置のみを担当する）。

**確認対象 2**: `skills/aidlc-setup/steps/` のテンプレート展開ロジック

**確認結果**: aidlc-setup スキル側はサイクル固有 `operations/progress.md` の生成を行わず、テンプレートディレクトリ（`skills/aidlc/templates/`）の配置のみを担当する。サイクル別 `operations/progress.md` の生成は `01-setup.md` §6 の責務。

### 既存サイクルでの v2.4.2 リリース後の挙動

既存サイクル（v2.4.1 以前）のユーザーが v2.4.2 にアップグレード後、再度 Operations Phase を実行する場合:

- **既存 `operations/progress.md` に固定スロットセクション不在**: `RecoveryJudgmentService.judge()` および `DecisionCategoryClassifier`（v2.3.6 Unit 005 で実装済み）が legacy_format を自動検出し、`history/operations.md` を判定源としてフォールバックする
- **既存仕様で対応済み**: 本 Unit では追加実装不要。INV-D1（ロジック非変更）が成立

## 観測条件まとめ（Phase 2 完了判定用）

> **観測条件の網羅性（Unit 003 設計レビュー反復1 指摘 #2 対応）**: 計画書 §完了条件チェックリストの各項目に対応する grep コマンドをすべて以下に列挙。8 件すべての完了条件が「単独 grep コマンドで検出可能」であることを担保する。

各完了条件はテキスト検索で発見可能:

```bash
# operations-release.md
grep -n "## 固定スロット（Operations 復帰判定用）" skills/aidlc/steps/operations/operations-release.md  # [P1]
grep -n "<!-- fixed-slot-grammar: v1 -->" skills/aidlc/steps/operations/operations-release.md  # [P1] grammar v1 準拠
grep -n "scripts/read-config.sh rules.release.changelog" skills/aidlc/steps/operations/operations-release.md  # 補強1
grep -nE "changelog=false|スキップ" skills/aidlc/steps/operations/operations-release.md  # 補強3（指摘 #2 対応で追加）
grep -nE "セクションが存在|未存在|有無" skills/aidlc/steps/operations/operations-release.md  # 補強2（指摘 #2 対応で追加）
grep -n "bin/update-version.sh" skills/aidlc/steps/operations/operations-release.md  # 補強4
grep -nE "operations/progress.md|history/operations.md|README.md|CHANGELOG.md" skills/aidlc/steps/operations/operations-release.md  # [P4] コミット対象ファイル列挙
grep -nE "改行区切り|独立行" skills/aidlc/steps/operations/operations-release.md  # 行区切り規約

# 02-deploy.md
grep -nE "未着手|進行中|完了|スキップ|PR準備完了" skills/aidlc/steps/operations/02-deploy.md  # [P3]
grep -n "operations-release.md §7.7" skills/aidlc/steps/operations/02-deploy.md  # §7.7 誘導注記

# operations_progress_template.md
grep -n "## 固定スロット（Operations 復帰判定用）" skills/aidlc/templates/operations_progress_template.md  # [P2]/[#585]
grep -n "<!-- fixed-slot-grammar: v1 -->" skills/aidlc/templates/operations_progress_template.md  # grammar v1 同梱
grep -n "release_gate_ready=" skills/aidlc/templates/operations_progress_template.md
grep -n "completion_gate_ready=" skills/aidlc/templates/operations_progress_template.md
grep -n "pr_number=" skills/aidlc/templates/operations_progress_template.md
```

## 非機能要件（NFR）への対応

### 互換性

- **要件**: 既存サイクルの `operations/progress.md` フォーマットに対する後方互換性を維持
- **対応策**: テンプレート展開はサイクル初期化時のみ（INV-T1）。既存サイクルは legacy_format で自動フォールバック（INV-D1）

### 可用性

- **要件**: テンプレート展開時に既存サイクルの `operations/progress.md` を上書きしない
- **対応策**: `01-setup.md` §6 の既存仕様（「存在する場合 / 存在しない場合」）で構造的に保証

### markdownlint 適合性

- **要件**: 改訂後 3 ファイルが `.markdownlint.yaml` の既存ルール（MD038/MD056 等）に違反しない
- **対応策**: コードフェンス内に `|` を含めず、表形式は適切なヘッダ + 整列で記述。Phase 2b で 3 ファイル 0 error を確認

## 技術選定

- **言語**: Markdown（手順書 / テンプレート）
- **フレームワーク**: なし（既存テンプレート展開ロジックに依存）
- **ライブラリ**: なし
- **対話 UI**: なし（本 Unit はガード / 対話を新規追加しない）

## 実装上の注意事項

### 安全性

- テンプレート改訂後、新規サイクル初回 Operations Phase 開始時の動作確認を Phase 2b の walkthrough で実施
- 既存サイクル（v2.4.1 以前）のユーザーへの影響なしを INV-T1 / INV-D1 で構造的に保証
- 固定スロット具体例の `pr_number=123` 等のリテラル値は手順書側では「例」として明示し、テンプレート側では空（=未記録）で配置

### 保守性

- 改訂対象は 3 ファイルに限定し、既存スクリプト・ロジックに影響を与えない
- 各改訂箇所に「Unit 003 / #591 / #585 対応」コメントを inline で記述するかは Phase 2 実装時に決定（記述する場合は HTML コメント `<!-- Unit 003: ... -->` 形式）
- markdownlint 違反予防（Unit 001/002 で発生した MD038/MD056）に注意し、コードスパン内 `|` を避ける
- **markdownlint dry-run 手順（Unit 003 設計レビュー反復1 指摘 #8 対応）**: Phase 2 実装直後に `npx --no-install markdownlint-cli2 skills/aidlc/steps/operations/operations-release.md skills/aidlc/steps/operations/02-deploy.md skills/aidlc/templates/operations_progress_template.md` を実行し、3 ファイル合計 0 error を確認してから Phase 2b に進む。違反検出時は Self-Healing で修正（最大 3 回、Unit 002 と同じ運用）

### 流用元との差分

- Unit 001 / Unit 002 とは異なり、本 Unit は対話 UI を新規追加しない（軽量設計）
- 本 Unit からの Unit 001 / Unit 002 への影響なし（独立並列実装）

### メタ開発時の検証境界

- 本 Unit は手順書 / テンプレート文書改訂が主体で、実走行検証はスコープ外
- 検証は手順書 / テンプレート walkthrough + markdownlint で間接実施
- 実走行検証は Operations Phase リリース後の運用検証（外部リポジトリでの v2.4.2 サイクル走行）に委ねる

## 不明点と質問（設計中に記録）

[Question] 状態ラベル 5 値の `PR準備完了` は `02-deploy.md` 既存記述（line 174「7.6 progress.md更新 ← **PR準備完了**」）と整合するか？
[Answer] 整合する。`02-deploy.md` line 174 で既に使用されている文言を 5 値リストに追加するのみ。既存記述の意味は変えない。

[Question] テンプレートの `pr_number=` 初期値は空文字か `0` か `null` か？
[Answer] **空文字を採用**。`phase-recovery-spec.md §5.3.5` で `pr_number` の値型は `^[1-9][0-9]*$`（先頭ゼロ禁止）であり `0` は不正値。`null` は grammar に該当値がない。空文字は「未記録状態」として既存仕様で扱われる（`prNumber=null` への変換）。**設計意図（指摘 #5 対応）**: `phase-recovery-spec.md §5.3.5` の checkpoint 別契約により、`pr_number=` 空の状態では `release_done` 検査では `release_gate_ready=true` のみで成立する一方、`completion_done` 検査では `undecidable:<pr_number_missing>` を返す。これは新規サイクル初期状態として **正常**であり、§7.6 通常系または §7.8 エッジケースで PR 番号確定後に解消される。空文字初期値は「未記録 → undecidable → 確定後解消」の自然な遷移を意図的に活用する設計。

[Question] テンプレートの boolean 初期値は `false` 明示か空白か？
[Answer] **`false` 明示を採用**。grammar v1 は明示的な値を期待するため、`release_gate_ready=` の空白よりも `release_gate_ready=false` の明示が望ましい。§7.6 で `true` に更新する手順が手順書側に既に存在する（既存記述）。

[Question] `02-deploy.md` の §7.7 誘導注記の独立記述化は、既存の line 168「各サブステップの詳細手順は `operations-release.md` および `scripts/operations-release.sh` を参照」と重複しないか？
[Answer] **重複を許容**。Unit 定義 §責務「§7.7 誘導注記: 詳細は **[必読] operations-release.md §7.7** を `02-deploy.md §7.7` に残し、本体は operations-release 側に集約」が要請するのは、§7.7 サブステップ自体の独立した目立つ誘導記述。line 168 の包括的記述とは別途、§7.7 サブステップの行に独立した目立つ注記（`[必読]` 付き）を追加することで、利用者が §7.7 を実行する直前に確実に operations-release.md §7.7 を参照する動線を作る。

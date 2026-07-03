# 論理設計: Unit 002 PR 整備 + release.md テンプレート + review ルーティング

## 概要

`steps/release.md` の **Step 2「PR 整備」** 実装（Unit 001 プレースホルダの差し替え）と `templates/release.md` 新規作成の構成・手順契約を定義する。

**重要**: コードは書かず、章構成・手順契約・依存スクリプト/スキルの呼び出し契約のみを定義する。具体的なコマンド文字列の最終整形は実装時に行う。

## アーキテクチャパターン

- **手順ドキュメント + `gh` 直接 + 安全境界スクリプト/スキル委譲**（Unit 001 と同一系統）。PR 操作は `gh`（file-based body）、state 原子書込は `state-write.sh`、review は `review-routing.md`/`review-flow.md` + 既存 reviewing スキルへ委譲。
- **fail-closed**: PR 解決の競合・`gh` 不在・review サマリ欠損は停止/フォールバック。
- **SoT 非再定義**: review perspective（`workflow.md §6`/`review-routing.md §3`）・state schema（`data-model.md §3`）・成果物集約（§8/§10）は参照のみ。

## コンポーネント構成

### ドキュメント構成（差分）

```text
steps/release.md（既存 / Step 2 を実装に差し替え）
└── Step 2: PR 整備 ★ PR ready 確認
    ├── 2-1 PR 解決（fail-closed: update / adopt_and_update / create / conflict_stop / gh pr view 検証）
    ├── 2-2 release.pr_number 書き込み + 検証（作成 / 番号採用時）
    ├── 2-3 release-level review ルーティング（premerge/integration/deploy）+ 結果正規化
    ├── 2-4 release.md 成果物生成（templates/release.md から / 2-3 の review 結果サマリを純 YAML で埋め込み final render）
    └── 2-5 Step 2 ゲート（PR ready 確認 / ready 化は Step 3）

templates/release.md（新規）
├── PR 概要
├── work item 完了一覧
├── review 結果サマリ（固定マーカー純 YAML / Unit 002→003 契約）
├── CI 状態
└── merge 記録（Step 3/4 で追記 / Unit 003）
```

### コンポーネント詳細

#### Step 2-1 PR 解決（PRResolver）

- **責務**: `release.pr_number` + open PR 探索から作成/更新/番号採用/競合停止を導出
- **依存**: `state-read.sh release.pr_number` / `gh pr list`（同一 head branch の open PR 探索）/ `gh pr view`
- **挙動**: ドメインモデル PRResolution の 4 分岐（複数 open PR は fail-closed 停止）

#### Step 2-4 review ルーティング（ReviewRouter）

- **責務**: 実行条件判定 + perspective→caller_context 写像 + 既存スキル委譲 + 結果正規化
- **依存**: work item frontmatter（**`status:done` 件数 / `size:risky` かつ done 件数**の集計 = `work-item-status.sh --read` + `work-item-validate.sh`。`withdrawn` は数えない / 設計レビュー #3）/ `review-routing.md` / `review-flow.md` / 既存 reviewing スキル
- **委譲範囲限定**: review-flow.md の「パス選択・反復・指摘対応・機密マスク」を利用し、commit/`reviews/*.md` 配置は使わない（結果は release.md 集約）

## インターフェース設計

### Step 2 手順契約（評価順）

| 順 | 処理 | 入力 | continue | stop |
|----|------|------|----------|------|
| 2-0 | gh 可用性 | `gh_status` | available | not available → 停止（例外: 手動 PR 番号 + `gh pr view` 確認） |
| 2-1 | PR 解決 | `state-read.sh release.pr_number` / `gh pr view <N> --json ...,baseRefName` / `gh pr list --head <branch> --base <integration-branch> --state open` | pr_number あり + `gh pr view` で state==`OPEN`（draft 含む）かつ headBranch 一致かつ baseRefName==統合先一致=update / null+open PR 1 件=adopt（baseRefName 二重確認）/ null+0 件=create（作成後 number 再取得 + OPEN/head/base 確認） | pr_number あるが `CLOSED`/`MERGED`・別 head・別 base・取得不能 → 停止 / 同一 head+base に open PR 複数 → fail-closed 停止 |
| 2-2 | pr_number 書込 | `state-write.sh release.pr_number <N>` | exit 0=written → `state-validate.sh` status:valid | exit 1=validation 停止 / exit 2=system 停止 |
| 2-3 | review ルーティング | 条件判定（`status:done` 件数 / risky done 件数 / withdrawn 除外）+ 既存スキル委譲 | 全該当 perspective 完了 + 結果正規化 | review-flow フォールバック条件は review-flow に委譲 |
| 2-4 | release.md 生成 | `templates/release.md` + 2-3 の review 結果 | review サマリを純 YAML で埋め込み final render 完了 | テンプレート不在 → 停止 |
| 2-5 | Step 2 ゲート | PR ready 確認 | ready 確認 OK → Step 3 へ | （ready 化は Step 3） |

### 依存スクリプト/スキル契約（既存 / 委譲）

#### state-write.sh release.pr_number（既存）
- **引数**: `release.pr_number <integer|null>`（先頭ゼロ拒否）/ **exit**: 0=`status:written` / 1=値型不正・許可外・書込後 invalid・未知 schema_version 拒否 / 2=jq 不在・依存不備
- **利用**: 2-2。書込後 `state-validate.sh` で `status:valid` 確認

#### review-routing.md / review-flow.md（既存スキル委譲）
- **呼び出し形式**（`review-routing.md §7`）: `skill="reviewing-[stage]", args="[対象] 優先ツール: [tool]"`
- **写像**: premerge→`reviewing-operations-premerge`(code,security) / integration→`reviewing-construction-integration`(code) / deploy→`reviewing-operations-deploy`(architecture)
- **注意**: `routing_review_mode = [rules.reviewing].mode`（config 値）を渡す。perspective 名を `review_mode` に渡さない

### templates/release.md の review 結果サマリ（固定マーカー純 YAML）

マーカー間（`<!-- aidlc-release-review:start -->` の次行〜`<!-- aidlc-release-review:end -->` の前行）は**純 YAML のみ**。Unit 003 はその範囲をそのまま parse する。フィールド: `schema_version` / `reviews[].{perspective,status,unresolved_count,max_severity,merge_blocker,skip_reason}` / `merge_blocker_any`。欠損・parse 不能・enum 外は Unit 003 側で fail-closed。

## スクリプトインターフェース設計

本 Unit では**新規スクリプトを作成しない**（`gh` 直接 + 最小ラッパ方針 / Unit 境界）。新規作成は `templates/release.md`（テンプレート / 実行スクリプトではない）のみ。

## データモデル概要

- 書き込み: `release.pr_number` のみ（既存 `state-write.sh` / schema 不変）。`ready`/`merge_approved` は Unit 003。
- release review 結果: release.md 集約（`reviews/*.md` 不生成 / data-model §8・§10）。

## 処理フロー概要

### Step 2「PR 整備」処理フロー

1. gh 可用性確認 → 不可は停止（例外あり）
2. PR 解決（pr_number + open PR 探索 / 複数は fail-closed 停止）
3. 作成 / 番号採用時に `release.pr_number` 書込 → 検証
4. work item 完了状況から review 実行条件を判定（done 数 / risky done 数）
5. 該当 perspective を caller_context 写像で既存スキルへルーティング、結果を正規化
6. `templates/release.md` から release.md 生成（PR 概要 / 完了一覧 / review サマリ純 YAML / CI 状態 / merge 記録枠）
7. Step 2 ゲート: PR ready 確認 → Step 3（Unit 003）へ

**関与するコンポーネント**: PRPreparation / PRResolver / ReviewRouter / ReleaseDocGenerator / 既存 state-write.sh・gh・reviewing スキル

## 非機能要件（NFR）への対応

### 互換性
- state.json schema 不変（`release.pr_number` のみ）。既存 v3 テスト green 維持（回帰ゼロ / 新規テストは Unit 004）

### 保守性
- review perspective マッピング・成果物集約は `workflow.md §6`/`review-routing.md §3`/`data-model.md §8` を参照（再定義なし）

### セキュリティ
- PR 本文・release.md に機密を含めない（file-based body / review-flow マスク方針準用）

### クロスプラットフォーム
- `gh` / git の POSIX 互換手順。BSD/GNU 差オプション回避

## 実装上の注意事項
- **境界**: ready 化・`release.ready`/`merge_approved` 書込・merge は Unit 003。Step 2 は触れない
- **ドッグフーディング特殊処理の禁止**: 自リポジトリ判定を埋め込まない
- **Bash ツール安全規約**: 手順内コマンド例に `$(...)` / backtick を含めない
- **SKILL.md 非変更**（公開フリップは Unit 004）

## 不明点と質問（設計中に記録）

[Question] 同一 head branch の open PR 探索はどう行うか。
[Answer] `gh pr list --head <branch> --state open` の結果件数で分岐（0=作成 / 1=番号採用 / 複数=fail-closed 停止）。pr_number 既存時はそれを優先。

[Question] review 実行条件の done 数・risky done 数はどう数えるか。
[Answer] work item frontmatter を `work-item-status.sh --read`（status）+ Unit 001 と同じ安全境界で集計し、`size:risky` は work item の size を `work-item-validate.sh` 健全性確認下で参照（生パースしない）。**件数は `status:done` のみで数え `withdrawn` は除外**（release 可能判定とは別レイヤ / 設計レビュー #3）。

[Question] pr_number があるとき PR 解決はどうするか。
[Answer] `gh pr view <N>` で state == `OPEN`（draft も含む / draft は `isDraft` 属性で state ではない）かつ headBranch == current branch を確認できた場合のみ update。`CLOSED`/`MERGED`・別ブランチ・取得不能は conflict_stop で停止（設計レビュー #1 / R2）。

[Question] release.md 生成と review の順序は。
[Answer] 一意化: PR 解決(2-1) → pr_number 書込(2-2) → review 実行/正規化(2-3) → release.md final render(2-4 / review サマリを純 YAML で埋込)。review を先に確定してから release.md を生成し placeholder 残留・マーカー契約破壊を防ぐ（設計レビュー #2）。

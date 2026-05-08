# 論理設計: pr-ops.sh auto-merge エラー分類

## 概要

`skills/aidlc/scripts/pr-ops.sh` の `cmd_merge` 関数末尾、`set-auto-merge` 失敗時 stderr 文字列分類分岐（line 444 周辺）を改修し、auto-merge 無効リポジトリ + CI pending 状態で `error:unknown` に落ちる現象を解消する。本 Unit は分類器（`AutoMergeErrorClassifier`、ドメインモデル参照）の文言バリアント表を 2 種拡張する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的なコード（grep パターン文字列、bash 関数定義）は Phase 2 で作成します。

## アーキテクチャパターン

**インライン手続き型（既存）**を維持。Bash スクリプト言語の特性上、レイヤードアーキテクチャや Clean Architecture の適用は過剰。`pr-ops.sh` 単一ファイル内に「サブコマンド分岐 → ドメインロジック → stdout 出力」の単純フローを保持する。

> **採否決定 — 案 A（インライン拡張）vs 案 B（ヘルパ関数化）**

Round 1 指摘 #1 で提起された分類専用関数化の採否を以下の比較で決定する。

| 観点 | 案 A: インライン拡張 | 案 B: ヘルパ関数化 |
|------|---------------------|-------------------|
| 変更行数 | grep パターン 1 行 + `-E` 付与 | 関数定義 5〜8 行 + 呼び出し側書き換え 4〜6 行 |
| 責務分離 | 分類ルールと実行制御が同一関数内に同居（既存と同等） | 分類ルール（純関数 `_classify_auto_merge_error`）と実行制御（`cmd_merge`）が分離 |
| テスト容易性 | gh モック経由の統合テスト 1 段（既存方式） | 関数単体テスト + 統合テスト（2 段の検証可能） |
| 後方互換 | grep パターン 1 行差分のため副作用最小 | 関数化により呼び出し側の出力形式が変わらないことの追加検証必要 |
| Unit 境界整合 | Unit 定義の責務「grep パターン拡張」に最小準拠 | 同一ファイル内ヘルパ関数化のため Unit 境界内（Intent OUT_OF_SCOPE「全エラーパターン網羅再設計」非該当） |
| 将来拡張性 | パターン追加のたびに `cmd_merge` 内 grep 連鎖が伸長 | パターン追加が `_classify_auto_merge_error` 内で局所化 |
| 設計フェーズ工数 | 0.1 日（パターン文字列のみ確定） | 0.2 日（関数 IF + 移行手順確定） |

**判断基準**:

- 今回追加する文言バリアントは 2 種のみで、`auto_error` 文言バリアント表は中期的に大幅拡張する予定なし（Intent §「除外するもの」: 全エラーパターン網羅再設計 OUT_OF_SCOPE）
- 案 B のメリット（責務分離・関数単体テスト）は将来の拡張頻度に依存し、現時点で投資対効果が見合わない
- 案 A は変更行数最小（grep パターン 1 行 + `-E` 付与）で副作用範囲が局所化される

→ **採用: 案 A（インライン拡張）**。案 B は将来ネタとして残し、本 Unit の範囲外とする。Round 1 指摘 #1 への返答は「案 A / B の比較検討を実施し、変更スコープと将来拡張頻度に照らして案 A を採用」という形で記録する（採用しない案 B はバックログ起票しない。理由: 将来の拡張トリガーが発火した時点で再評価する性質の設計判断であり、現時点で起票しても陳腐化リスクが高いため）。

## コンポーネント構成

### レイヤー / モジュール構成（既存維持）

```text
skills/aidlc/scripts/pr-ops.sh
├── show_help / parse_args                # 入口
├── cmd_find_draft / cmd_ready / cmd_get_related_issues
└── cmd_merge                             # 本 Unit 改修対象
    ├── resolve_check_status              # 既存（CheckStatus 5 分類）
    ├── action 分岐（merge-now / set-auto-merge）
    ├── head_sha 遅延解決
    ├── merge-now 実行 + エラー分類       # 既存（変更なし）
    └── set-auto-merge 実行 + エラー分類  # 本 Unit 改修箇所（line 444）
```

### コンポーネント詳細

#### `cmd_merge` 関数（既存改修）

- **責務**: PR 番号と merge_method を受け取り、CI 状態に応じて `merge-now` / `set-auto-merge` を選択し、結果を stdout に出力する
- **依存**: `gh` CLI（外部依存）、`resolve_check_status`（既存ヘルパ）
- **公開インターフェース**: 既存 stdout 契約 `pr:<N>:merged:<method>` / `pr:<N>:auto-merge-set:<method>` / `pr:<N>:error:<label>` を維持
- **本 Unit の改修範囲**: line 444 の `grep -qi "auto-merge is not allowed\|not enabled\|auto_merge"` を以下に置換
  - 改修後（**案 A 採用**）: `grep -qiE "auto[- ]merge is not allowed|enablePullRequestAutoMerge|not enabled|auto_merge"`
  - 変更点 1: `-qi` → `-qiE`（拡張正規表現有効化、`auto[- ]merge` の文字クラス記法を活用）
  - 変更点 2: 交替セパレータ `\|`（basic regex）→ `|`（extended regex）。`-E` フラグ追加に伴う必須変更
  - 変更点 3: 新規パターン `auto[- ]merge is not allowed` を追加（半角スペース型と既存ハイフン型を 1 表現で統合）
  - 変更点 4: 新規パターン `enablePullRequestAutoMerge` を追加（GraphQL ミューテーション名、case-insensitive で照合）

#### 改修前後の `auto_error` 分類分岐（pseudo）

```text
# 改修前（line 444 周辺）
if echo "$auto_error" | grep -qi "auto-merge is not allowed\|not enabled\|auto_merge"; then
    echo "pr:${pr_number}:error:auto-merge-not-enabled"
elif echo "$auto_error" | grep -qi "permission\|forbidden\|403"; then
    echo "pr:${pr_number}:error:permission-denied"
else
    echo "pr:${pr_number}:error:unknown"
fi

# 改修後
if echo "$auto_error" | grep -qiE "auto[- ]merge is not allowed|enablePullRequestAutoMerge|not enabled|auto_merge"; then
    echo "pr:${pr_number}:error:auto-merge-not-enabled"
elif echo "$auto_error" | grep -qi "permission\|forbidden\|403"; then  # 変更なし（Unit 範囲外）
    echo "pr:${pr_number}:error:permission-denied"
else
    echo "pr:${pr_number}:error:unknown"
fi
```

> **注**: `permission-denied` 分岐は本 Unit のスコープ外のため `grep -qi` のまま変更しない（一貫性 vs 局所変更のトレードオフでは「変更行数最小化」を優先）。

#### 正規表現方言の混在ガード（設計レビュー Round 1 指摘 #2 対応）

本 Unit の改修では `auto-merge-not-enabled` 分岐のみ `grep -qiE`（ERE）に移行し、`permission-denied` 分岐は `grep -qi`（BRE）のまま残る。同一 `cmd_merge` 関数内で正規表現方言が混在することを認識し、以下の保守方針を本論理設計に明記する:

- **方針 1（現行 Unit 範囲）**: `permission-denied` 分岐の grep 形式は変更しない（変更行数最小化を優先）
- **方針 2（次回分類拡張時）**: `permission-denied` カテゴリの文言バリアント追加・変更が発生する Unit では、その時点で `grep -qi` → `grep -qiE` への統一を併せて行う（交替子 `\|` → `|` への置換を含む）。**本方針はバックログ起票せず、次回該当 Unit のレビューで本論理設計を SoT として参照することで担保する**
- **方針 3（誤改修ガード）**: `auto-merge-not-enabled` 分岐の `-qiE` を `-qi`（BRE）に戻す改修は禁止。改修時は本セクションの存在を確認し、ERE 維持を保証する

## インターフェース設計

### スクリプトインターフェース（既存維持）

`pr-ops.sh merge` サブコマンドの引数・stdout 契約・終了コードに変更なし。本 Unit はエラー分類分岐の grep パターンのみを拡張する。

#### 既存 stdout 契約

| 契約行 | 条件 |
|--------|------|
| `pr:<N>:merged:<method>` | 即時マージ成功 |
| `pr:<N>:auto-merge-set:<method>` | auto-merge 設定成功 |
| `pr:<N>:error:auto-merge-not-enabled` | auto-merge が許可されていない（**本 Unit のマッチ範囲拡張対象**） |
| `pr:<N>:error:permission-denied` | 権限不足（変更なし） |
| `pr:<N>:error:checks-failed` 等 | 他のエラー分類（変更なし） |
| `pr:<N>:error:unknown` | 既知パターンに非マッチ（**本 Unit で発生範囲を縮小**） |

## データモデル概要

### テスト fixture（新規ファイル内に定義）

新規テスト `test_pr_ops_auto_merge_error_classification.sh` は gh モック方式で以下 4 fixture を扱う:

| fixture id | 与える stderr | 期待 stdout |
|-----------|--------------|------------|
| (a) space-form | `auto merge is not allowed for this repository` | `pr:123:error:auto-merge-not-enabled` |
| (b) graphql-mutation | `GraphQL: enablePullRequestAutoMerge ...` | `pr:123:error:auto-merge-not-enabled` |
| (c) hyphen-form-bc | `auto-merge is not allowed for this repository` | `pr:123:error:auto-merge-not-enabled`（後方互換） |
| (d) permission-denied | `HTTP 403: Permission denied` | `pr:123:error:permission-denied`（誤分類なし） |

> **注**: 既存テスト `test_pr_ops_merge_skip_checks.sh` の `merge_result=error` 経路（fixture: `some merge error`）は `unknown` に分類される現行挙動を維持する（regression 防止）。

### gh モック構造（既存パターン踏襲）

新規テストは既存 `test_pr_ops_merge_skip_checks.sh` で確立された gh モック方式を踏襲する:

- `GH_STATE_FILE` で fixture 識別子と挙動を切り替え
- `${GH_MOCK_DIR}/gh` のモックスクリプトが PATH に注入され、本物の gh より優先
- `pr merge --auto` 失敗経路（exit != 0、stderr に fixture 文字列）を再現

> **共通ヘルパ層化（`tests/lib/gh_mock.sh`）は本 Unit のスコープ外**（Round 1 指摘 #2 で defer 化、Intent OUT_OF_SCOPE「全エラーパターン網羅再設計」相当として backlog 起票予定）。

## 処理フロー概要

### ユースケース 1: auto-merge 無効リポジトリで `pr-ops.sh merge` 実行

**ステップ**:

1. ユーザーが `pr-ops.sh merge <PR>` 実行
2. `resolve_check_status` が `pending` を返す（CI 実行中）
3. `cmd_merge` が `action="set-auto-merge"` を選択
4. `gh pr merge <PR> --auto` を実行 → stderr に `enablePullRequestAutoMerge ...` を返して exit != 0
5. **改修後の grep -qiE が `enablePullRequestAutoMerge` にマッチ** → stdout `pr:<N>:error:auto-merge-not-enabled` を出力
6. 呼び出し元（Operations Phase）が `auto-merge-not-enabled` を判定し `operations-release.md §7.13` のエラー対処案内を起動

**改修前との差分**: ステップ 5 で改修前は非マッチで `error:unknown` に落ちていた → 改修後は `error:auto-merge-not-enabled` を正しく返す。

**関与するコンポーネント**: `cmd_merge` / `gh` CLI / 既存 `resolve_check_status`

### ユースケース 2: 後方互換テスト（`auto-merge is not allowed` ハイフン型）

既存テストで担保される挙動を新規テストでも明示的に検証する。`auto-merge is not allowed` 文言は改修後の `auto[- ]merge is not allowed` パターンに含まれる（`[- ]` は半角スペースまたはハイフンを許容）ため、後方互換が成立する。

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: Unit 定義 NFR より「grep 1 行追加のため計測対象外」
- **対応策**: `grep -qiE` の交替パターンは O(N) で線形時間。fixture サイズ < 1KB 程度のため実時間影響は無視できる

### セキュリティ

- **要件**: Unit 定義 NFR より「該当なし」
- **対応策**: 実エラー文言は GitHub CLI 公開仕様で機密情報を含まない。fixture / test 内に秘密鍵・トークンを含めない

### スケーラビリティ

- **要件**: Unit 定義 NFR より「該当なし」
- **対応策**: 本 Unit は単発実行用スクリプトの分類ロジック。スケーラビリティ設計の対象外

### 可用性

- **要件**: Unit 定義 NFR より「bats テストでパターン拡張の後方互換性を保証」
- **対応策**: 後方互換テスト（fixture (c) hyphen-form-bc）と既存テスト regression 確認の 2 重防御

## 技術選定

- **言語**: Bash 4+（既存 `pr-ops.sh` 準拠）
- **テストランナー**: `bash` 直接実行（既存 `skills/aidlc/scripts/tests/test_pr_ops_*.sh` の `.sh` テスト形式を踏襲）
- **モック手段**: PATH 差し替え + 状態ファイル（既存 `test_pr_ops_merge_skip_checks.sh` 方式）

## 実装上の注意事項

- **basic regex → extended regex の互換性**: 既存パターン `auto-merge is not allowed` / `not enabled` / `auto_merge` は basic / extended のいずれでも文字列リテラルとして同じ意味を持つ（メタ文字 `.`, `*`, `[`, `]` 以外は同義）。`-E` 付与で挙動が変わるのは交替セパレータ `\|` → `|` のみ
- **case-insensitive 維持**: `-i` フラグを保持。`enablepullrequestautomerge` / `ENABLEPULLREQUESTAUTOMERGE` 等の任意大文字小文字組み合わせがマッチする
- **改行挙動**: `gh` CLI の stderr が複数行の場合、`grep -q` は行ごとに評価する。fixture も実出力を再現するため改行を含む可能性がある。テストでは複数行 fixture でも正しく分類されることを確認する
- **誤マッチ予防**: `permission` 文言を含むエラーが先に `auto-merge-not-enabled` カテゴリにヒットしないよう、`auto-merge-not-enabled` カテゴリのパターンは「auto-merge」「auto_merge」「enablePullRequestAutoMerge」「not enabled」のいずれかに限定（permission との誤マッチ防止）

## 検証クエリ（Phase 2 完了時に実行）

| 検証項目 | コマンド | 期待結果 |
|---------|---------|---------|
| 拡張パターンの存在確認 | `grep -E "grep -qiE.*auto\[- \]merge is not allowed.*enablePullRequestAutoMerge" skills/aidlc/scripts/pr-ops.sh` | 1 行ヒット |
| 既存パターン残存確認（後方互換） | `grep -E "not enabled\|auto_merge" skills/aidlc/scripts/pr-ops.sh` | 1 行ヒット |
| basic regex 残骸非存在確認 | `grep -nE 'grep -qi "auto.*allowed.*not enabled' skills/aidlc/scripts/pr-ops.sh` | 0 行（改修後は `-qiE` のみ） |
| 新規テスト実行 | `bash skills/aidlc/scripts/tests/test_pr_ops_auto_merge_error_classification.sh` | exit 0、FAIL=0 |
| 既存テスト regression 確認 | `bash skills/aidlc/scripts/tests/test_pr_ops_merge_skip_checks.sh` | exit 0、FAIL=0 |

## 不明点と質問（設計中に記録）

[Question] CI ジョブで `skills/aidlc/scripts/tests/test_pr_ops_*.sh` を巡回しているか確認する手段
[Answer] **Phase 2 で確認**。`.github/workflows/*` を grep して `test_pr_ops_` または `skills/aidlc/scripts/tests` への参照を抽出し、glob 巡回 / 個別列挙 / 未接続のいずれかを判定する。未接続時は新規ファイル名の追記で対応する（計画完了条件 (b) で言及済み）。

[Question] 案 A 採用により Round 1 指摘 #1 の「分類ルールと実行制御の密結合」が解消されないが、これは指摘の resolve とみなせるか
[Answer] **resolve とみなす**。Round 2 レビューで「案 A / B 比較を経て案 A を採用」した過程が反映され、Round 2 で codex から「指摘0件」回答を得たため、計画レビュー単位では完了済み。設計レビュー（reviewing-construction-design）でも同等指摘が再発する可能性に備え、本論理設計の「採否決定」セクションで根拠を明示してある。

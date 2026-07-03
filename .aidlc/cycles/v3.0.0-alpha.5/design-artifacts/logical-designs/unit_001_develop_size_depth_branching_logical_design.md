# 論理設計: Unit 001 develop size×depth_level 分岐基盤

## 概要

develop.md Step 1 の `size != tiny` 停止ブロックを size×depth_level 分岐に置換し、`MatrixDecision`（後続 Step が参照する単一の判定結果）を develop フロー内に確立する論理設計。あわせて workflow.md の SoT 整合（§3.2 注記・§6.3 非正本ビュー化）を定義する。

**重要**: 本設計では**コードは書かず**、develop.md（markdown 実行手順）の改訂構造・判定インターフェース・既存スクリプト配線のみを定義する。具体的な手順本文・テストは Phase 2 で作成する。

## アーキテクチャパターン

- **パイプライン + 安全境界スクリプト委譲**: develop フローは Step を直列実行するパイプライン。各 Step の副作用（status 遷移 / commit / journal）と危険なパース（frontmatter / config）は既存安全境界スクリプト（`work-item-next.sh` / `work-item-status.sh` / `state-read.sh` / `read-config.sh`）に委譲し、develop.md 自体は「判定ロジック（§8 写像）と分岐配線」のみを担う。
- **選定理由**: #733 P1/P2（develop.md 内 局所 grep/sed パース起因の不具合）の再発防止。判定の正本（§8）は data-model.md に置き、develop.md は写像規則のビューとして表現する（SoT 二重定義回避）。

## コンポーネント構成

### モジュール構成（develop.md 改訂後の Step 構造）

```text
develop フロー（skills/aidlc-v3/steps/develop.md）
├── Step 0  前提確認（clean-worktree + current_cycle 解決） … 不変
├── Step 1  Work Item 選定 + size×depth_level 判定          … 改訂（本 Unit の主対象）
│   ├── 1-1 work-item-next.sh で選定（next:<id>:<size>:<path>）
│   ├── 1-2 size enum case 検証（tiny/normal/risky / enum 外→副作用なし停止）
│   ├── 1-3 depth_level 解決（read-config.sh / enum 外→standard 正規化）
│   ├── 1-4 §8 写像 → MatrixDecision 構築（matrix_case + 派生要件 + paths）
│   │       └─ risky+minimal → 副作用なし停止
│   └── 1-5 status 読取/遷移（work-item-status.sh / pending→in_progress, resume 継続）
├── Step 2  計画 + 設計      … design_required で分岐（false: スキップ / true: Unit 002）
├── Step 3  実装             … 常に実行
├── Step 4  検証             … 常に実行
├── Step 5  レビュー         … review_required で分岐（false: スキップ / true: Unit 003）
└── Step 6  完了             … status done + journal + reason_record（条件付き）+ commit 集約
```

### コンポーネント詳細

#### Step 1 判定ブロック（SizeDepthDecision の構築点）

- **責務**: work item 選定後に MatrixDecision を構築し、後続 Step の分岐入力を確定する
- **依存**: `work-item-next.sh`（size 供給）/ `read-config.sh`（depth_level 供給）/ data-model.md §8（写像正本）
- **公開インターフェース**: develop.md 後続 Step が参照する MatrixDecision フィールド（§ドメインモデル MatrixDecision 参照）
- **本 Unit のスコープ**: MatrixDecision 構築と分岐配線。design/review の生成・実行は Unit 002/003

#### MatrixResolver（§8 写像テーブル）

- **責務**: 正規化済み (size, depth_level) → §8 セル → 派生要件
- **表現形式**: develop.md Step 1 内の明示マトリクステーブル（ドメインモデル「§8 マトリクス → MatrixDecision 写像表」と同一内容）
- **依存方向**: develop.md → data-model.md §8（参照のみ / 逆依存なし）

## スクリプトインターフェース設計（既存スクリプトの利用配線 / 新規スクリプトなし）

本 Unit は新規スクリプトを作らない。既存スクリプトの出力を develop.md 手順内で組合せる。各スクリプトの利用契約:

### work-item-next.sh（既存 / 利用のみ）

- **出力**: `next:<id>:<size>:<path>` / `next:none`
- **本 Unit での扱い**: `<size>` を取り出し case 検証。`<path>` から成果物ファイル名を導出（下記 path 導出規則）
- **enum ガード**: `<size>` が `tiny|normal|risky` 以外 → `invalid_size` エラー停止（mutation なし）

### designs_path / reviews_path 導出規則

`work-item-next.sh` は slug を直接返さない（出力は `next:<id>:<size>:<path>`）ため、`<path>` から成果物ファイル名を導出する。Unit 002/003 が安定して消費できるよう、以下を develop.md Step 1 の MatrixDecision 構築規則に明記する:

1. `artifact_filename = basename "<path>"`（例: `001-example.md`）
2. `<id>-` prefix を検証（`artifact_filename` が `<id>-` で始まること。`<id>` は同じ next 出力由来）
3. `designs_path = .aidlc/cycles/<cycle>/designs/<artifact_filename>` / `reviews_path = .aidlc/cycles/<cycle>/reviews/<artifact_filename>`
4. prefix 不一致（work item ファイル名規約違反）→ `invalid_artifact_path` として **mutation なし停止**（risky_minimal / invalid_size と同じ副作用なし様式）

> work item ファイル名と成果物ファイル名を同一 basename で対応させることで `<id>-<slug>.md` の再構成（slug の別途パース）を不要にし、局所パース追加を避ける。`<path>` の dirname（work-items/）は使わず designs/ reviews/ に差し替える。

### read-config.sh（既存 / 利用のみ）

- **呼び出し**: `bash skills/aidlc/scripts/read-config.sh rules.depth_level.level`（他スキル経路のためリポジトリルート相対の絶対参照）
- **正規化契約**:
  | read-config.sh 結果 | depth_level 解決 |
  |---------------------|------------------|
  | exit 0 + stdout ∈ {minimal,standard,comprehensive} | その値 |
  | exit 0 + stdout が enum 外 | 警告 + `standard` |
  | exit 1（キー不在） | `standard`（既定） |
  | exit 2（読取失敗） | 警告 + `standard`（停止しない / NFR 可用性） |

### work-item-status.sh（既存 / 利用のみ）

- **本 Unit での扱い**: 現行 Step 1 と同一（`--read` で status 読取 → pending なら in_progress 遷移 / resume は継続）。normal/risky でも同じ status 取り扱い。判定がエラー停止する場合は status 遷移前に終了する（mutation なし保証）

## 処理フロー概要

### Step 1 判定フロー（改訂後）

**ステップ**:
1. `work-item-next.sh` 実行 → `next:none` なら完了後フェーズ導出へ / `next:<id>:<size>:<path>` を取得
2. `<size>` を case 検証 → `tiny|normal|risky` 以外なら `invalid_size` 副作用なし停止
3. `read-config.sh rules.depth_level.level` → 正規化契約で `depth_level` 確定（enum 外は standard）
4. §8 写像テーブル参照 → `matrix_case` と派生要件を確定し MatrixDecision 構築
   - `risky + minimal` → `risky_minimal` 副作用なし停止（status 遷移しない）
   - **Unit 001 スコープ境界ガード**: `design_required = true` または `review_required = true` の組合せ（normal/risky の standard 以上）は、design 生成（Unit 002）/ review 実行（Unit 003）が未実装のため、**status 遷移より前に副作用なし停止**する。これにより本 Unit が status を遷移して進めるのは `design_required = false ∧ review_required = false`（tiny_* / normal_minimal）に限定される。Unit 002/003 実装時に本ガードを解除する
5. （正常 = tiny_* / normal_minimal のみ）`work-item-status.sh --read` → pending なら in_progress 遷移 / in_progress は継続
6. 後続 Step は MatrixDecision の各フィールドで分岐（本 Unit 到達範囲では design_required/review_required は false 確定）

**関与するコンポーネント**: Step 1 判定ブロック / MatrixResolver / 既存 3 スクリプト

### 後続 Step の分岐（配線のみ / 生成・実行は Unit 002/003）

| Step | 分岐キー | false 時 | true 時 |
|------|---------|---------|---------|
| Step 2（設計） | `design_required` | スキップ（**repo への追記なし** / 実行ログ・会話上の通知のみ。normal+minimal はこの経路） | Unit 002 が `designs_path` に design 生成（design_mode / risk_analysis / test_plan / rollback_note を消費） |
| Step 5（レビュー） | `review_required` | スキップ（repo への追記なし） | Unit 003 が `reviews_path` に review 記録（review_mode を消費） |
| Step 6（理由記録） | `reason_record_required` | 追記なし | journal に「短い理由記録」1 行追記（**tiny+comprehensive のみ**） |

> **§8 成果物要件を増やさない**: Step 2/5 の false 時スキップは repo mutation を伴わない（journal / frontmatter / ファイルへの追記をしない）。永続的な「理由記録」は §8 上 `tiny+comprehensive` のみで、`reason_record_required` フィールドで一意に制御する（Step 6）。normal+minimal は「実装 + テスト」のみで repo 追記を増やさない。
>
> 本 Unit では Step 2/5 の実体（design 生成 / review 実行）は実装せず、「分岐して MatrixDecision を渡す配線」と「false 時スキップ（repo 追記なし）」を確立する。normal+minimal は両方 false のため Step 2/5 をスキップし end-to-end 完走する（本 Unit 単体で検証可能）。

### end-to-end 検証対象（本 Unit 単体）

- `normal + minimal`: Step 2/5 スキップ → Step 3 実装 → Step 4 検証 → Step 6 完了（実装 + テストのみ）が完走
- `risky + minimal`: Step 1-4 で副作用なし停止
- `tiny + comprehensive`: Step 6 で理由記録 1 行追加 / `tiny + {minimal,standard}`: Phase 3 と不変

## SoT 整合（workflow.md 編集設計）

| 対象 | 現状 | 改訂 |
|------|------|------|
| `docs/v3/workflow.md` §3.2 Step 2 行 | 「risky: design + risk analysis + test plan」と depth_level 非依存に読める | 「（depth_level により異なる。正本は data-model.md §8）」の注記を付す |
| `docs/v3/workflow.md` §6.3 マトリクス表 | data-model.md §8 と同一表を重複保持 | 見出し直下に「本表は data-model.md §8 の非正本ビュー。正本は §8」と明記（表は参照用に残置可、ただし正本でないことを宣言） |
| `docs/v3/data-model.md` §8 | 「本表が成果物要否の唯一の正本」と既に宣言済み | 変更なし（正本維持） |

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: 既存 tiny フローの実行時間に有意な追加負荷を与えない
- **対応策**: 追加コストは read-config.sh 1 回 + case 検証のみ。tiny 経路は従来通り（depth_level 読取は comprehensive 判定にのみ実質影響）

### セキュリティ
- **要件**: ローカルファイル操作のみ（該当なし）
- **対応策**: 新規外部入力なし。read-config.sh / work-item-* の既存安全境界を利用

### 可用性
- **要件**: depth_level 読取失敗時は停止しない
- **対応策**: read-config.sh exit 1/2 を `standard` フォールバックに正規化（処理継続）

## 実装上の注意事項

- develop.md 内に frontmatter / config の局所 grep/sed パースを足さない（#733 P1/P2 再発防止）。size は work-item-next 出力トークン、depth_level は read-config 出力をそのまま使う
- 「ドッグフーディング特殊処理を本体に埋めない」: 自リポジトリ判定を develop.md / スクリプトに埋め込まない（opt-in シグナル / 既存方針踏襲）
- Bash ツール経由実行時のコマンド置換（`$(...)` / backtick）禁止（リポジトリ規約）— ただし develop.md は手順記述であり、実行例は既存記法（リダイレクト・パイプ）を踏襲
- エラー停止（risky_minimal / invalid_size）は status 遷移・journal・commit より前に判定し mutation なしを保証する

## 技術選定

- **言語**: Markdown（実行手順）+ Bash（既存スクリプト利用 / 新規追加なし）
- **正本**: `docs/v3/data-model.md` §8
- **テスト**: `skills/aidlc-v3/scripts/tests/test-develop-flow.sh`（最小の動作確認 / 全マトリクス回帰は Unit 004）

## 不明点と質問（設計中に記録）

[Question] なし（計画 AI レビュー 3R で確定済み）
[Answer] -

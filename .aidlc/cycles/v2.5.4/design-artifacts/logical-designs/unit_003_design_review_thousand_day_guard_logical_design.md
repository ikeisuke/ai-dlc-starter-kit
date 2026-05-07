# 論理設計: Unit 003 — 設計レビュー特化の早期 defer ガイド

## 概要

`skills/aidlc/steps/common/review-flow.md` に新規 **独立セクション**「`## 設計レビュー特化の早期 defer ガイド`」を追加するための論理設計（配置: 「Round 4 以降の新領域指摘の自動 backlog 化フロー」セクション直後 / 発火タイミング: 各 Round の `is_completed()` 判定直後）。追記文言案、配置位置、数値閾値の根拠、4 系統判定順序ディシジョンテーブル、検証 grep クエリを確定する。

**重要**: この論理設計では **コードは書かず**、review-flow.md に追記する自然言語ガイドの構造とインターフェース（review-summary 記録形式・AskUserQuestion 呼び出し）の定義のみを行う。

## アーキテクチャパターン

**ドキュメント駆動ガイドライン（Documentation-Driven Guideline）**: AI レビュワー / メインエージェントの判断ロジックを自然言語で文書化し、自動判定スクリプトを介さずに運用するパターン。Intent 制約「自動判定スクリプト導入禁止 / 自然言語ルール」と整合。

選定理由:

- 既存 review-flow.md の他ガード（千日手検出 / Round 4+ 新領域 backlog 化）と同じ表現スタイルで統一可能
- 数値閾値変更や検出ロジック調整がドキュメント編集だけで完結し、運用コストが低い
- AI レビュワーの判断責務として表現されるため、過度な機械化による誤検出を避けられる

## コンポーネント構成

### review-flow.md 内の追記位置（Round 1 review 指摘 #1 反映）

**配置の根本見直し**: 当初案では「指摘対応判断フロー」内に追加する案だったが、同フローは review-flow.md L34 で「反復レビュー 5 回後に残指摘（unresolved_count > 0）がある場合に実行」と限定されており、Round 3/4 の早期 defer 判定が発火しない設計矛盾が判明した（Round 1 review 指摘 #1）。

**修正後の配置**: 早期 defer ガイドは「Round 4 以降の新領域指摘の自動 backlog 化フロー」セクションの **直後** に **独立セクション**（`##` 見出し）として追加する。発火タイミングは「各 Round の `is_completed()` 判定直後」であり、5R 後 unresolved 時のみ実行される「指摘対応判断フロー」とは独立に動作する。

```text
review-flow.md
├── 実行手順
├── 完了条件の判定単一仕様（Unit 005 で更新済み）
├── 指摘対応判断フロー（5R 後 unresolved 時のみ実行 / 既存）
│   ├── 千日手検出（既存、過去 5R 中 3R 連続同種）
│   ├── 各指摘への判断（既存）
│   ├── 理由バリデーション（既存）
│   └── スコープ保護確認（既存）
├── defer 判定時の自動 Issue 起票フロー
├── Round 4 以降の新領域指摘の自動 backlog 化フロー（既存、各 Round 終了時実行）
├── 【新規】設計レビュー特化の早期 defer ガイド ← Unit 003 で追加
│   ├── 適用範囲（caller_context = 設計レビュー 限定）
│   ├── 発火タイミング（各 Round の is_completed() 判定直後）
│   ├── Round 別指摘件数閾値
│   ├── 新規仮説追加検出（Round 4 以降）
│   ├── 議論個別点漸進パターン検出
│   ├── 4 系統判定順序ディシジョンテーブル
│   └── 履歴記録形式
├── レビュー完了時の共通処理
├── レビューサマリファイル
├── 履歴記録
├── AI レビュー指摘の却下禁止【絶対遵守】
├── 外部入力検証
├── 推定値検出ガード
└── 分割ファイル参照
```

**配置根拠**:

- 「Round 4 以降の新領域指摘の自動 backlog 化フロー」と発火タイミング（各 Round 終了時）が一致するため、論理的に隣接配置が自然
- 早期 defer ガイドは判定順序 1（Round 別件数閾値）/ 2（既存新領域 backlog 化、本セクションを呼び出し）/ 3（仮説追加）/ 4（漸進パターン）の 4 系統で、優先順位 2 の既存セクションを直前に置くことで参照関係が前方参照のみとなり、循環依存を回避できる

### コンポーネント詳細

#### 設計レビュー特化の早期 defer ガイド（新規追加 独立セクション）

- **責務**: 設計レビューが 5R に到達する前に、**4 系統**（1. Round 別指摘件数閾値 / 2. 既存 Round 4+ 新領域 backlog 化 / 3. 新規仮説追加検出 / 4. 議論個別点漸進パターン検出）の予兆を判定順序通りに検出してユーザー判断を促す
- **依存**: 既存「Round 4 以降の新領域指摘の自動 backlog 化フロー」（判定順序 **2** として呼び出し）、既存「defer 判定時の自動 Issue 起票フロー」（OUT_OF_SCOPE 判定時に合流）、既存「スコープ保護確認」（OUT_OF_SCOPE 判定時に通る）、既存 SoT「`skills/aidlc/steps/common/review-routing.md` §3 CallerContext マッピング」（適用範囲判定の対応表として参照）
- **発火タイミング**: 各 Round の `ReviewSession.is_completed()` 判定直後（既存「指摘対応判断フロー」5R 後限定とは独立）
- **公開インターフェース**:
  - 入力: 各 Round 完了時の review-summary 内容、Round 番号、指摘総件数、指摘対象パス集合、`caller_context`
  - 出力: AskUserQuestion（修正続行 / OUT_OF_SCOPE 化）、警告文（review-summary 末尾セクション追記）、定義済みフロー（既存 defer 起票）への合流、別枠の早期 defer ガード吸収サマリ（複数系統検出時のみ）

## インターフェース設計

### review-flow.md への追記文言案（完全版）

以下を `## Round 4 以降の新領域指摘の自動 backlog 化フロー` セクション全体（既存「計画承認前レビューでの扱い（特例）」サブセクションを含む）の **直後** に、独立した `## 設計レビュー特化の早期 defer ガイド` セクションとして挿入する（`## レビュー完了時の共通処理` セクションの直前）。

````markdown
## 設計レビュー特化の早期 defer ガイド（Unit 003 / #658 / v2.5.4+）

**適用範囲**: 本ガイドは `caller_context = 設計レビュー`（`skills/aidlc/steps/common/review-routing.md` §3 CallerContext マッピング参照、対応する skill_name は `reviewing-construction-design`、focus は architecture）に限定して適用する。`計画承認前` / `コード生成後` / `統合とレビュー` / `Intent 承認前` / `ストーリー承認前` / `Unit 定義承認前` / `デプロイ計画承認前` / `PR マージ前` には適用しない。`caller_context` 列の文言が将来変更された場合は同 PR 内で本ガイドの適用判定も改訂する（変更連動ルール）。

**発火タイミング**: 各 Round の `ReviewSession.is_completed()` 判定直後に評価する（既存「指摘対応判断フロー」セクションは「反復レビュー 5 回後に残指摘がある場合のみ実行」と限定されているため、本ガイドはそれとは独立に Round 1〜5 の各 Round 終了時に動作する）。

設計レビューが 5R 上限に到達する前に、以下 4 系統の予兆を検出してユーザー判断（OUT_OF_SCOPE 化）を促す。本ガイドは既存「千日手検出（過去 5R 中 3R 連続同種）」を **置き換えない**（より前倒しの予兆検出として機能）。

### Round 別指摘件数閾値

| Round | 閾値 | アクション |
|-------|------|----------|
| Round 3 | 指摘 ≥ 5 件（重要度問わず） | review-summary に「OUT_OF_SCOPE 化推奨」アラートを記録し、`AskUserQuestion` で「修正続行 / OUT_OF_SCOPE 化」を選択 |
| Round 4 | 指摘 ≥ 3 件（重要度問わず） | review-summary に「千日手予兆」警告を記録し、`AskUserQuestion` で「修正続行 / OUT_OF_SCOPE 化」を選択 |

数値閾値の根拠: v2.5.3 Unit 004 の実観測（設計レビュー 5R 到達 + Round 1 で 4 件指摘）を参考に設定。Round 3 で 5 件以上は「議論密度過大」、Round 4 で 3 件以上残存は「収束困難」の予兆と判断する。

### 新規仮説追加検出（Round 4 以降）

Round 4 以降に「設計仮説の根本見直し」（ドメインモデル全体の再構成 / 責務境界の引き直し / 主要エンティティの追加削除）が新規で要求された場合、千日手予兆として検出する。

検出手順:

1. Round 1〜3 の review-summary「指摘一覧」テーブル `内容` 列から指摘対象キーワード集合 `H_old` を抽出（パス記法・抽出規則は本ファイル「Round 4 以降の新領域指摘の自動 backlog 化フロー」§「判定手順（再現可能、固定）」 手順 0 / 1 を準用）
2. Round 4 以降の review-summary から指摘対象キーワード集合 `H_new` を抽出（同上、手順 2 を準用）
3. 差分 `H_new - H_old` を計算し、新規キーワードが「設計仮説の根本見直し」（ドメインモデル要素 / 責務境界 / 主要エンティティ追加削除）に該当するかを判定
4. 該当する場合、`AskUserQuestion` で「修正続行 / OUT_OF_SCOPE 化」を選択させる
5. 選択結果を review-summary 末尾「`## Round N 新規仮説追加判定`」セクションに `H_old` / `H_new` / `H_new - H_old` の JSON 配列形式で記録（例: `"H_old": ["責務境界", "Entity"], "H_new": ["集約", "ドメインイベント"], "H_new - H_old": ["集約", "ドメインイベント"]`）

語彙境界（自然言語ルール）:

- **含む**: ドメインモデル要素名（エンティティ / 値オブジェクト / 集約 / ドメインイベント）、責務境界用語（責務 / 境界 / 役割 / レイヤ）、追加削除動詞（追加 / 削除 / 統合 / 分離）、アーキテクチャ用語（依存方向 / インターフェース / 抽象化）
- **含まない**: 形容詞、副詞、一般的な修正動詞（直す / 変える 等）

同義語統合: 表記揺れ（半角/全角・大小文字・送り仮名）はレビュワーが判断時に統合する（明示的な辞書は持たない）。判断根拠は「同義語統合: `<原語>` ≒ `<統合語>`」形式で review-summary 末尾の判定セクションに併記。

**変更連動ルール**: 上記準用元（「Round 4 以降の新領域指摘の自動 backlog 化フロー」§「判定手順（再現可能、固定）」）の見出し名・手順番号・正規表現が変更された場合、本ガイドの抽出仕様も **同 PR 内** で同時改訂すること。改訂時の検証: `grep -E "判定手順（再現可能、固定）|新領域指摘の自動 backlog" skills/aidlc/steps/common/review-flow.md` で準用元アンカーが残存することを確認。

### 議論個別点漸進パターン検出

連続 round で指摘対象パスが同一ディレクトリ内で重複し、修正範囲が漸進的に拡大していくパターンを検出する。

検出条件: Round N → Round N+1 → Round N+2 で 3 round 連続して同一ディレクトリ内（例: `design-artifacts/logical-designs/`）の指摘が発生し、各 round で指摘対象ファイルが追加されていく場合（修正範囲漸進）に「議論個別点漸進」として警告。

警告のみで Issue 起票はせず、ユーザー判断は併発する「Round 別指摘件数閾値」または「新規仮説追加検出」のフローで吸収する。review-summary 末尾「`## Round N 漸進パターン警告`」セクションに対象ディレクトリ・連続 round 番号を記録。

### 4 系統判定順序ディシジョンテーブル

設計レビューに同時適用される **4 系統**（Round 別指摘件数閾値 / 既存 Round 4+ 新領域 backlog 化 / 設計仮説追加検出 / 議論個別点漸進パターン検出）の出力責務を以下のディシジョンテーブルで一意化する:

| 優先順位 | 系統 | 起源 | 判定手段 | 記録先（個別行） | 排他/併記 |
|---------|------|------|---------|----------------|----------|
| 1 | Round 別指摘件数閾値 | 本ガイド | 自然言語判定（件数集計） | `## Round N OUT_OF_SCOPE 推奨アラート`（Round 3）/ `## Round N 千日手予兆警告`（Round 4） | `AskUserQuestion` で「修正続行 / OUT_OF_SCOPE 化」を選択。OUT_OF_SCOPE 選択時は当該 Round の全指摘について後続 2/3/4 を **スキップ** |
| 2 | 既存 Round 4+ 新領域 backlog 化 | 本ファイル「Round 4 以降の新領域指摘の自動 backlog 化フロー」 | 機械判定（K_old / K_new / K_diff） | `## Round 4 新領域判定`（既存セクション） | 自動 Issue 起票実行。後続 3/4 で同一パスを検出した場合は当該パス分を **後続でスキップ** |
| 3 | 設計仮説追加検出 | 本ガイド | 自然言語判定（H_old / H_new） | `## Round N 新規仮説追加判定` | 1/2 で吸収済みパスを除外した残差で `AskUserQuestion`。後続 4 で同一パスを検出した場合は当該パス分を **後続でスキップ** |
| 4 | 議論個別点漸進パターン検出 | 本ガイド | 自然言語判定 | `## Round N 漸進パターン警告` | 1/2/3 でカバー済みのパスは除外。残差を warn 表示のみ（Issue 起票なし） |

**排他/二重記録回避**: 同一指摘について複数系統で検出された場合、**指摘単位の個別行記録は上位優先順位の 1 セクションのみ**で行う。下位系統セクションには当該指摘の個別行を生成せず、別枠の **集計サマリ** `## Round N 早期 defer ガード吸収サマリ` セクションに「優先順位 N で吸収: <件数> 件」を 1 行ずつ記録する（系統別件数は集計し、指摘単位の重複記録は避ける）。

**既存千日手検出との関係**: 本早期 defer ガイドはより前倒しの予兆検出として機能し、既存「千日手検出（過去 5R 中 3R 連続同種）」を置き換えない。本ガイドの判定で defer 化されない場合に、5R 内で既存千日手検出が発動する。

**履歴記録形式**: 本ガイドが反応した round の review-summary 末尾セクション（`## Round N OUT_OF_SCOPE 推奨アラート` / `## Round N 千日手予兆警告` / `## Round N 新規仮説追加判定` / `## Round N 漸進パターン警告` / `## Round N 早期 defer ガード吸収サマリ`）に判定結果・根拠・ユーザー選択結果を記録する。`history/construction_unit{NN}.md` には「設計レビュー早期 defer ガイド発動」イベントとして 1 行記録する。
````

### review-summary 末尾セクションの形式（5 種類、Round 1 review 指摘 #3 反映で吸収サマリ追加）

新サブセクションの判定結果を review-summary 末尾に追記する形式:

````markdown
## Round N OUT_OF_SCOPE 推奨アラート（Round 3 で指摘 ≥ 5 件発動）

- 指摘総件数: <N> 件（Round 3）
- ユーザー選択: 修正続行 | OUT_OF_SCOPE 化
- 選択根拠: <ユーザー回答>

## Round N 千日手予兆警告（Round 4 で指摘 ≥ 3 件発動）

- 指摘総件数: <N> 件（Round 4）
- ユーザー選択: 修正続行 | OUT_OF_SCOPE 化
- 選択根拠: <ユーザー回答>

## Round N 新規仮説追加判定（Round 4 以降）

- H_old: ["<keyword1>", "<keyword2>", ...]
- H_new: ["<keyword1>", "<keyword2>", ...]
- H_new - H_old: ["<keyword1>", ...]
- 設計仮説の根本見直し判定: true | false
- 同義語統合（該当時）: <原語> ≒ <統合語>
- ユーザー選択（true 時）: 修正続行 | OUT_OF_SCOPE 化

## Round N 漸進パターン警告

- 対象ディレクトリ: `design-artifacts/logical-designs/`
- 連続 round 番号: [N-2, N-1, N]
- 修正範囲漸進: true

## Round N 早期 defer ガード吸収サマリ（仕様統一、複数系統検出時のみ生成）

- 優先順位 1 で吸収: <件数> 件
- 優先順位 2 で吸収: <件数> 件
- 優先順位 3 で吸収: <件数> 件
- 優先順位 4 で吸収: <件数> 件
````

**注**: 同一指摘の個別行記録は上位優先順位の 1 セクションのみで行い、下位系統セクションには当該指摘の個別行を生成しない（重複記録回避）。下位系統で検出された件数は「早期 defer ガード吸収サマリ」セクションの集計のみに反映する。

## データモデル概要

本 Unit は新規ファイル形式・新規スキーマを導入しない。review-summary（既存 markdown ファイル）の末尾セクション追加のみ。

## 処理フロー概要

### Round 完了時の早期 defer ガード評価フロー（4 系統、判定順序固定）

**発火タイミング**: 各 Round の `ReviewSession.is_completed()` 判定直後（既存「指摘対応判断フロー」5R 後限定とは独立）

**ステップ**:

1. AI レビュワー / メインエージェントが当該 Round の指摘総件数を集計
2. **優先順位 1**: Round 別指摘件数閾値（Round 3 で 5 件以上 / Round 4 で 3 件以上）を評価し、該当時 AskUserQuestion 発動。OUT_OF_SCOPE 選択時は当該 Round の全指摘について後続 2/3/4 をスキップ
3. **優先順位 2**: 既存 Round 4+ 新領域 backlog 化フロー（review-flow.md 既存セクション）を評価し、該当パスを自動起票。起票済みパスは後続 3/4 評価から除外
4. **優先順位 3**: 新規仮説追加検出（Round 4 以降）を評価し、1/2 で吸収済みパスを除外した残差で該当時 AskUserQuestion 発動。後続 4 で同一パス除外
5. **優先順位 4**: 議論個別点漸進パターン検出を評価し、1/2/3 でカバー済みのパスを除外した残差で該当時 warn 表示（Issue 起票なし）
6. 該当した系統の review-summary 末尾セクションに **指摘単位の個別行記録は上位優先順位の 1 セクションのみ** で記録。複数系統で検出された場合は別枠の `## Round N 早期 defer ガード吸収サマリ` セクションに集計行のみ記録（仕様統一、二重記録回避）
7. ユーザーが OUT_OF_SCOPE 化を選択した場合、既存「defer 判定時の自動 Issue 起票フロー」「スコープ保護確認」に合流

**関与するコンポーネント**: AI レビュワー（Codex CLI / セルフレビュー）、メインエージェント（Claude Code）、review-summary ファイル、AskUserQuestion ツール

## 検証 grep クエリ集（合格判定用）

### 機能要件の検証

```bash
# (a) 設計レビュー特化の defer ガイド記述が 1 箇所以上
grep -E "Round 3.*defer|議論密度|設計レビュー特化の早期 defer ガイド" skills/aidlc/steps/common/review-flow.md

# (b) Round 別指摘件数の閾値が明示的に数値で記載
grep -E "Round 3.*≥ ?5 件|Round 4.*≥ ?3 件" skills/aidlc/steps/common/review-flow.md

# (c) 新規仮説追加検出ロジックが文書化
grep -E "新規仮説追加検出|H_old.*H_new" skills/aidlc/steps/common/review-flow.md

# 適用範囲明示の検証（実装は caller_context ベース）
grep -E "caller_context = 設計レビュー|reviewing-construction-design" skills/aidlc/steps/common/review-flow.md
```

### 既存ガード仕様の維持検証（変更前 HEAD で基準値を記録、変更後で比較）

```bash
# 変更前 HEAD の基準値取得（変更前に 1 度実行）
git show HEAD:skills/aidlc/steps/common/review-flow.md | grep -c "5R"
git show HEAD:skills/aidlc/steps/common/review-flow.md | grep -E -c "5[[:space:]]*round"
git show HEAD:skills/aidlc/steps/common/review-flow.md | grep -c "千日手"
git show HEAD:skills/aidlc/steps/common/review-flow.md | grep -c "new-area-from-round4plus"
git show HEAD:skills/aidlc/steps/common/review-flow.md | grep -c "defer 自動 Issue 起票"
git show HEAD:skills/aidlc/steps/common/review-flow.md | grep -c "last_round_clean"

# 変更後の検証
grep -c "5R" skills/aidlc/steps/common/review-flow.md
grep -E -c "5[[:space:]]*round" skills/aidlc/steps/common/review-flow.md
grep -c "千日手" skills/aidlc/steps/common/review-flow.md   # 既存記述 + 新サブセクション内参照で増加
grep -c "new-area-from-round4plus" skills/aidlc/steps/common/review-flow.md
grep -c "defer 自動 Issue 起票" skills/aidlc/steps/common/review-flow.md
grep -c "last_round_clean" skills/aidlc/steps/common/review-flow.md
```

### 適用範囲の独立性検証

```bash
# 新セクション冒頭に適用範囲明示が含まれているか（実装は caller_context ベース）
grep -A 1 "設計レビュー特化の早期 defer ガイド" skills/aidlc/steps/common/review-flow.md | grep -E "caller_context = 設計レビュー|reviewing-construction-design"

# 変更連動ルールの存在確認
grep -E "変更連動ルール|同 PR 内.*同時改訂" skills/aidlc/steps/common/review-flow.md
```

### スコープ保護検証

```bash
# 変更対象が想定範囲内であることを確認
git diff --name-only HEAD~3..HEAD
# 期待される変更対象（v2.5.4 Unit 003 範囲、計画 + history + design-artifacts + review-flow.md のみ）:
#   .aidlc/cycles/v2.5.4/plans/unit-003-plan.md
#   .aidlc/cycles/v2.5.4/history/construction_unit03.md
#   .aidlc/cycles/v2.5.4/design-artifacts/domain-models/unit_003_design_review_thousand_day_guard_domain_model.md
#   .aidlc/cycles/v2.5.4/design-artifacts/logical-designs/unit_003_design_review_thousand_day_guard_logical_design.md
#   .aidlc/cycles/v2.5.4/construction/units/003-review-summary.md
#   .aidlc/cycles/v2.5.4/construction/progress.md
#   .aidlc/cycles/v2.5.4/story-artifacts/units/003-design-review-thousand-day-guard.md（実装状態のみ）
#   skills/aidlc/steps/common/review-flow.md（追記のみ）
```

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: ランタイム性能影響なし
- **対応策**: docs / 手順改訂のみ。新ガイド適用後は設計レビューが Round 3〜4 で defer 化されるケースが増え、平均所要 round が 0.5〜1 round 削減される見込み（定性的）

### セキュリティ
- **要件**: 機密情報の取り扱いに変更なし
- **対応策**: 既存「機密情報マスク」ルールは変更せず、本ガイドの記録物にも適用される旨は既存セクションが既にカバー

### スケーラビリティ
- **要件**: 影響なし
- **対応策**: -

### 可用性
- **要件**: 影響なし
- **対応策**: -

### 後方互換
- **要件**: 既存千日手検出 / 5R 完了条件 / defer 自動 Issue 起票 / Round 4+ 新領域 backlog 化を破壊しない
- **対応策**: 新サブセクションを追加扱いとし、既存サブセクションへの記述変更を行わない。既存ガード仕様の維持検証 grep で確認

### 適用範囲
- **要件**: Construction Phase 設計レビュー限定
- **対応策**: サブセクション冒頭に適用範囲を明示し、Inception / Operations / Construction コードレビュー / 統合レビューには副次適用しない旨を文言で固定

## 技術選定

- **言語**: Markdown（自然言語ガイド）
- **ツール**: 既存 `gh issue create`（defer 起票合流時のみ。本 Unit 自体では新ツール導入なし）
- **テスト**: markdownlint（既存設定）/ Codex review CLI（既存）

## 実装上の注意事項

- **既存千日手検出記述の保護**: 「**千日手検出**:」段落（既存「指摘対応判断フロー」内）は削除・縮約せず、本ガイド側からは「既存千日手検出との関係」段落で言及するのみとする
- **既存 Round 4+ 新領域 backlog 化フローの保護**: 「## Round 4 以降の新領域指摘の自動 backlog 化フロー」セクション（既存）は削除・縮約せず、新セクションは既存セクションの直後に追加し、本文中で固定アンカー参照する
- **review-flow.md の本文行数制限**: SKILL.md の 500 行制限とは独立だが、review-flow.md 自体の可読性維持のため新セクションは独立セクション化に伴い 100〜120 行程度を見込む（現状 304 行 + 100〜120 行 ≒ 404〜424 行）。500 行を超える場合は「review-summary 末尾セクション形式」を別ファイル参照に切り出す検討余地あり
- **AskUserQuestion 使用ルール**: 本ガイドの「修正続行 / OUT_OF_SCOPE 化」選択は SKILL.md「AskUserQuestion 使用ルール」§「ユーザー選択」に該当（automation_mode に関わらず常に AskUserQuestion を使用）

## 不明点と質問（設計中に記録）

[Question] 「設計仮説の根本見直し」の判定境界は AI レビュワーの自然言語判断に委ねるが、判断のブレを最小化するため何らかの形式的ガイドが必要か
[Answer] 自然言語ガイドの語彙境界（含む / 含まない）と同義語統合ルール（表記揺れ統合 + 根拠併記）で実用上十分。Intent 制約「自動判定スクリプト導入禁止」と整合する範囲では、これ以上の形式化は AI レビュワーの判断負荷を上げるだけで品質向上効果が薄い。

[Question] 議論個別点漸進パターン検出の「修正範囲漸進」を機械判定するか、自然言語判定に委ねるか
[Answer] 自然言語判定に委ねる。「指摘対象ファイルが追加されていく」は連続 round の review-summary 内容を比較すれば AI レビュワー / メインエージェントが容易に判定可能で、機械判定スクリプトを導入すると Intent 制約に反する。

[Question] Round 3 で 5 件以上 / Round 4 で 3 件以上の数値閾値は将来調整可能か
[Answer] 可能。本ガイドはドキュメント駆動のため、運用観測（v2.5.4 以降の設計レビュー数十回分の実績）に基づき次サイクル以降で数値調整できる。本 Unit では v2.5.3 Unit 004 の実観測（5R 到達 + Round 1 で 4 件指摘）を初期値の根拠とする。

[Question] Round 3 で 5 件以上の閾値は「Round 1 で 4 件指摘」の実観測と直接整合しているか
[Answer] 部分的に整合。実観測は Round 1 ベースだが、本ガイドは Round 3 ベース（収束見込みが立たない round 数）で設定。これは「Round 1 で多めの指摘があっても Round 2/3 で収束するケース」を許容するための余白。Round 3 まで来て 5 件以上残存している場合のみアラートする保守的な閾値設定とする。

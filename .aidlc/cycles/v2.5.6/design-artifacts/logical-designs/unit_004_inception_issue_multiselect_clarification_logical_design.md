# 論理設計: Unit 004 - Inception Issue 選択フローで複数選択を前提化

## 概要

`skills/aidlc/steps/inception/02-preparation.md` §16「GitHub Issue 確認」を改訂し、(a)「複数選択可」を明示する文言、(b) `AskUserQuestion(multiSelect: true)` 推奨呼び出し例、の 2 要素を §16 周辺に局所追加する。修正は Markdown 文言のみで、スクリプト・スキーマ・データモデル変更を含まない。

**重要**: 本論理設計では**コードは書かず**、Markdown ガイダンスドキュメントの構造変更点と差分のみを記述する。位置指定は **構造アンカー中心**（見出し / 箇条書き番号 / ブロック種別）で行い、行番号は参考情報に限定する。

## アーキテクチャパターン

**ドキュメント階層型ガイダンス（Documentation-as-Behavior-Spec）**: AI エージェントが読み込むガイダンスドキュメント自体をシステムの「振る舞い仕様」として扱うパターン。ガイダンス改訂が AI 挙動の改訂に直結する。

選定理由:

- 本 Unit の対象は AI エージェントのプロンプト解釈経路（`AskUserQuestion` 構築時の `multiSelect` 推論）のみで、コード/スキーマ層の変更不要
- ガイダンス文書は他層（スクリプト・テスト）と疎結合のため、Markdown 局所修正で完結
- 既存 §16 内の記述ブロック群（対応確認テキスト / 1 を選択時のアクション / Milestone 紐付け処理 / 注釈）を壊さず、新規ブロックを最小挿入する追記的アプローチ

## コンポーネント構成

### §16 内のブロック構成（構造アンカー中心の論理表現）

```text
## 16. GitHub Issue確認
├── イントロ文（§16 冒頭の説明）
├── ブロック A: 実行コマンドフェンス（`scripts/check-open-issues.sh` の bash フェンス）
├── ブロック B: 判定ブロック（3 ケース判定の説明）
├── ブロック C: 対応確認テキストブロック（text フェンス内の対話例）  ★ 改訂対象 1
├── ブロック D: 「1を選択 / 2を選択」アクション説明（箇条書き 2 件）  ★ 改訂対象 2
├── ★ 新規挿入: AskUserQuestion 推奨パターンブロック（ブロック D と E の間）
├── ブロック E: Milestone 機能 opt-in ガード見出し
├── ブロック F: Milestone 紐付け説明
└── ブロック G: 注釈・参照
```

### コンポーネント詳細

#### ブロック C: 対応確認テキストブロック（既存・改訂対象 1）

- **責務**: ユーザーに「Issue を今サイクルに含めるか」の問いかけ文を提示する text フェンス
- **依存**: なし（自然言語）
- **公開インターフェース**: AI エージェントが読み上げる候補テキスト
- **本 Unit での変更点**: ブロック C 内の番号 1 行末「選択したIssue」を「選択したIssue（**複数可**）」に変更（参考行番号: L46）

#### ブロック D: 「1を選択 / 2を選択」アクション説明（既存・改訂対象 2）

- **責務**: AI エージェントへの自然言語ガイダンス（「1 を選択した場合に何をするか」）
- **依存**: なし
- **公開インターフェース**: AI エージェントが解釈する指示テキスト
- **本 Unit での変更点**: ブロック D 内の「1を選択」項目を「対応する Issue を**複数選択可で**選択させ、ユーザーストーリーとUnit定義に追加することを案内」と修正（参考行番号: L50）

#### 新規挿入ブロック: AskUserQuestion 推奨パターンブロック

- **責務**: AI エージェントが `AskUserQuestion` を構築するときの推奨パラメータ・推奨質問文を明示する
- **依存**: なし（自然言語＋擬似コード text フェンス）
- **公開インターフェース**: text フェンスを 1 ブロック追加。`multiSelect: true` の使用、options の制約、推奨質問文を含む
- **挿入位置（構造アンカー中心）**: ブロック D（「1を選択 / 2を選択」アクション説明）の直後、ブロック E（Milestone 機能 opt-in ガード見出し）の直前。間に空行を挟む（参考行番号: L52 と L54 の境界）

## インターフェース設計

### Markdown 改訂仕様（編集対象: `skills/aidlc/steps/inception/02-preparation.md`）

本 Unit の改訂を 3 件の Edit Rule として論理設計する（位置指定は構造アンカー、行番号は参考のみ）。

#### Edit Rule 1: 対応確認テキストブロック内の文言修正

- **target_anchor**: `## 16. GitHub Issue確認` 内 → ブロック C（対応確認テキストブロック）→ 番号 1 行末
- **edit_kind**: `text_replace`
- **before_snippet**: `1. はい - 選択したIssueをユーザーストーリーとUnit定義に追加する`
- **after_snippet**: `1. はい - 選択したIssue（**複数可**）をユーザーストーリーとUnit定義に追加する`
- **multi_select_intent**: `explicit_multi_clarification`
- **意図**: ユーザー対話文に「複数可」を明示し、AI エージェントの読み上げ候補に複数選択前提を含める
- **参考行番号**: L46

#### Edit Rule 2: 「1を選択」アクション説明の文言修正

- **target_anchor**: `## 16. GitHub Issue確認` 内 → ブロック D（アクション説明）→ 「1を選択」箇条書き
- **edit_kind**: `text_replace`
- **before_snippet**: `- **1を選択**: 対応するIssueを選択させ、ユーザーストーリーとUnit定義に追加することを案内`
- **after_snippet**: `- **1を選択**: 対応する Issue を**複数選択可で**選択させ、ユーザーストーリーとUnit定義に追加することを案内`
- **multi_select_intent**: `explicit_multi_clarification`
- **意図**: AI エージェントへのアクション説明にも「複数選択可」を明示
- **参考行番号**: L50

#### Edit Rule 3: AskUserQuestion 推奨パターンブロックの新規追加

- **target_anchor**: `## 16. GitHub Issue確認` 内 → ブロック D（アクション説明）の直後 / ブロック E（`**Milestone 機能 opt-in ガード ...**`）の直前
- **edit_kind**: `block_insert_after`
- **inserted_block**: 下記「挿入ブロック仕様」を参照
- **multi_select_intent**: `recommended_pattern_addition`
- **意図**: AI エージェントが「Issue 選択 → AskUserQuestion 構築」を判断するときに、`multiSelect: true` を選ぶ判断材料を直接提供する
- **参考行番号**: L52 と L54 の境界

##### 挿入ブロック仕様

```text
**`AskUserQuestion` 推奨パターン**（複数 Issue を 1 サイクルにまとめるユースケースが標準的）:

- `multiSelect: true` を使用する（複数 Issue の選択が前提）
- `options` は最大 4 件まで掲載（`AskUserQuestion` API の制約）。**5 件以上ある場合は重要度・関連度の高い 4 件を掲載し、それ以外は Other（自動付与）で受け付ける**
- 推奨質問文: 「これらの Issue のうち本サイクルに含めるものをすべて選択してください（複数可）」
- 各 `option.label` は Issue 番号 + 短いタイトル（例: `#674 Inception §16 複数選択前提化`）
- 各 `option.description` は Issue 概要を 1〜2 文で要約

呼び出し例（擬似コード、`AskUserQuestion` ツール引数の論理表現）:

<text フェンス開始>
AskUserQuestion(
  questions: [{
    question: "これらの Issue のうち本サイクルに含めるものをすべて選択してください（複数可）",
    header: "Issue 選択",
    multiSelect: true,
    options: [
      { label: "#674 Inception §16 複数選択前提化", description: "..." },
      { label: "#671 permissions audit 9 件解消", description: "..." },
      ...
    ]
  }]
)
<text フェンス終了>
```

> 上記のうち `<text フェンス開始>` / `<text フェンス終了>` は本論理設計内のエスケープ表記。Phase 2 の実装では正味の Markdown text フェンス（` ``` text` 〜 ` ``` `）に置き換える。同様に外側の擬似ブロック表記も Phase 2 で実 Markdown に整形する。

### 局所性検証インターフェース（§16 セクション境界チェック）

`Locality Constraint` を直接判定する手順。ブランチ全体差分や `origin/main...HEAD` ではなく、**§16 範囲外の差分ゼロを直接判定**する。

#### 検証手順

1. **対象ファイルの 2 状態を取得**:
   - 変更前スナップショット: `git show <pre-edit-commit>:skills/aidlc/steps/inception/02-preparation.md`
   - 変更後スナップショット: 作業ツリー上の同ファイル
2. **セクション境界の抽出**: 各スナップショットから「`## 16. GitHub Issue確認`」見出し開始から「`## 17. バックログ確認`」見出し開始の直前まで（または最終ファイル末尾まで）を §16 範囲として抽出
3. **§16 範囲内差分検証**: 抽出した 2 区間を `diff` し、Edit Rule 1〜3 由来の差分のみが含まれることを確認
4. **§16 範囲外差分検証**:
   - ファイル先頭〜「`## 16.` 直前」までの 2 区間を `diff` し、差分ゼロを確認
   - 「`## 17.` 開始」〜ファイル末尾までの 2 区間を `diff` し、差分ゼロを確認
5. **対象ファイル唯一性検証**: `git diff --name-only <pre-edit-commit>..HEAD -- 'skills/aidlc/steps/inception/'` の結果が `skills/aidlc/steps/inception/02-preparation.md` の 1 件のみであることを確認

#### 副作用

- なし（読み取り専用検証）

#### 失敗時の挙動

- §16 範囲外に差分検出 → A-3 / B-2 完了条件未達。修正をリバートして該当差分のみを除去
- 対象ファイル以外への変更検出 → 同上
- §16 範囲内差分が Edit Rule 1〜3 と一致しない → 計画と実装の不整合。実装を修正

## スクリプトインターフェース設計

本 Unit ではスクリプト変更なし。既存 `scripts/check-open-issues.sh` の出力フォーマットも変更しない。

## データモデル

本 Unit ではデータベース・外部スキーマの変更なし。

## エラーケース

| ケース | 影響 | 対策 |
|--------|------|------|
| markdownlint エラー（`MD040` 等のフェンス言語タグ規則違反） | C-1 完了条件未達 | 追加するフェンスは `text` を明示、既存 markdownlint 設定（`.markdownlint.json` または既定）に整合させる |
| 既存 §16 のフォーマット崩壊（コードフェンス未閉じ等） | レビュー差し戻し | Edit 適用後に該当ファイルを部分 Read して構造を目視確認 |
| §15 / §17 への意図せぬ波及 | A-3 / B-2 完了条件未達 | 上記「局所性検証インターフェース」の 4. と 5. を必ず実行 |
| プラグインキャッシュとの差分 | 本 Unit 範囲外 | リポジトリソースのみ編集、キャッシュは次回プラグイン更新で同期される旨を計画書に記録済 |

## 完了条件マッピング（plan の `A-*` / `B-*` / `C-*` → 本論理設計の改訂）

| 完了条件 | 本論理設計の対応箇所 | 検証手段 |
|----------|---------------------|----------|
| A-1（複数選択可明示文言） | Edit Rule 1 + Edit Rule 2 | `grep -n "複数" skills/aidlc/steps/inception/02-preparation.md` で 2 件以上ヒット |
| A-2（AskUserQuestion 呼び出し例） | Edit Rule 3（挿入ブロック） | `grep -n "multiSelect: true" skills/aidlc/steps/inception/02-preparation.md` で 1 件以上ヒット |
| A-3（局所性） | 局所性検証インターフェースの 4. / 5. | §16 範囲外差分ゼロ + 対象ファイル唯一性 |
| A-4（Unit 定義 関連Issue） | Unit 定義は Inception 05-completion で `#674` 反映済（既存） | `grep -n "#674" .aidlc/cycles/v2.5.6/story-artifacts/units/004-*.md` で 1 件以上ヒット |
| B-1 | A-1 + A-2 と同等 | 同上 |
| B-2 | A-3 と同等 | 同上 |
| C-1 | 本 Unit 変更ファイルへの markdownlint 0 errors | `markdownlint <変更ファイル>` 実行ログ |
| C-2 | AI レビュー全ラウンド完了 + `004-review-summary.md` 生成 | review-summary ファイル存在確認 |

## 依存関係

- **依存する Unit**: なし
- **依存するスキル/ツール**:
  - `markdownlint`（`rules.linting.enabled = true`）
  - `codex` CLI（review_mode=required, configured_tools=['codex']）
- **外部依存**: GitHub Issue #674（既に Inception 05-completion で起票・採番済み）

## ロールバック手順

万一 §16 改訂後に問題が発覚した場合:

1. `git revert <Phase 2 commit>` で改訂をリバート
2. プラグインキャッシュ側は次回プラグイン更新で自動同期されるため手動操作不要
3. 改訂前の §16（変更前文言）はリポジトリ Git 履歴に保持されているため復元可能

## 不明点と質問（設計中に記録）

[Question] Edit Rule 3 の挿入位置をブロック D（「1を選択 / 2を選択」アクション説明）直後にするか、ブロック C（対応確認テキストブロック）直後にするか？
[Answer] ブロック D 直後を採用する。理由: (a) ブロック C は text フェンス内のユーザー対話で、その内部に推奨パターン擬似コードを差し込むと「対話文 vs AI ガイダンス」のレイヤが混ざる。(b) 「1を選択 / 2を選択」の判定説明（ブロック D）の直後に推奨パターンを置くことで「1 を選択した場合の AskUserQuestion 構築指針」として自然に読める。(c) Milestone opt-in ガード（ブロック E）の前に置くことで、Milestone 紐付けの前提となる「複数 Issue 選択結果」が読者にイメージしやすい。

[Question] 推奨質問文は日本語固定にするか、それとも英語版併記か？
[Answer] 日本語固定。理由: 既存 §16 の他文言・対応確認テキストはすべて日本語であり、ガイダンスの一貫性を保つ。本 Unit のスコープは局所修正のため、多言語対応は範囲外。

[Question] Edit Rule 3 の擬似コードフェンス内で示す `options` の項目数は具体的に何件にするか？
[Answer] 2 件 + `...` で省略表記する。理由: 擬似コードは「最大 4 件」の制約を別途文言で明示済（リスト項目）。具体例で 4 件すべて埋めると見た目が冗長になる。`#674` と `#671` の実例を引用し、残りは `...` で省略する。

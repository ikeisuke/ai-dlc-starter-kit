# 論理設計: Unit 003 事実テーブル先抽出ステップ + 推定値検出ガード

## 概要

`04-completion.md` §1.x に事実テーブル先抽出ステップ追加 + `review-flow.md` に推定値検出ガード追加の論理設計。Unit 001 で確立した §1.0.5 / §1.5 / `retrospective-issue.sh` の不変条件は本 Unit では**触らず**、新規セクションを **追加挿入** する。

**重要**: コードは書かず、構造とインターフェースの定義のみ。

## アーキテクチャパターン

**追加挿入パターン**: 既存セクションを編集せず、新規セクションを既定位置に挿入する。Unit 001 の不変条件（AC-U003-RETRO-GUARD-IMMUTABLE-1〜3）を破壊しないことが最優先。

## コンポーネント構成

```text
Unit 003 事実テーブル + 推定値検出ガード
├── Layer 1: 振り返り手順（既存 + 追加）
│   └── skills/aidlc/steps/operations/04-completion.md
│       ├── §1.0.5 対話必須ガード（Unit 001 / 不変）
│       ├── §1.1 KPT テンプレ（既存 / 不変）
│       ├── §1.x 事実テーブル先抽出ステップ（新規 / Unit 003）
│       │   ├── 目的: KPT 記入後・主因切り分け前の事実構造化
│       │   ├── 読み込み対象 3 source: decisions.md / review-summary.md / history/*.md
│       │   └── 事実テーブル形式: markdown 表（項目 / 値 / 出典）
│       ├── §1.2 主因切り分け（既存 / 不変）
│       └── §1.5 Step 4 起票直前 record_response 呼出（Unit 001 / 不変）
└── Layer 2: レビュー共通フロー（既存 + 追加）
    └── skills/aidlc/steps/common/review-flow.md
        ├── 既存セクション（不変）
        └── 推定値検出ガード（新規 / Unit 003）
            ├── 適用スコープ: 振り返り文脈のみ（retrospective Issue 本文 / KPT / 主因 / Try / mirror 候補）
            ├── 判定原則（独立明記）: 一次情報 Read 済みでも根拠リンク併記がなければ flag
            ├── 検出マーカー: 約 / およそ / approximately / approx. / 推定 / 〜くらい / 〜程度
            ├── 数値隣接判定: 直前/直後 5 文字以内の算用数字 / 日本語数字
            ├── 例外条件: 同一段落内の PR/Commit/Issue リンクまたはファイルパス参照
            ├── flag 出力フォーマット: 「指摘 #N - 推定値混入: `<該当箇所>`」
            ├── 許容例 2 件以上併記
            └── 非許容例 2 件以上併記
```

## インターフェース設計（手順記述レベル）

### §1.x 事実テーブル先抽出ステップ（手順）

```markdown
#### 1.x 事実テーブル先抽出ステップ【必須・KPT 後 / 主因切り分け前】

§1.1 KPT 記入後、§1.2 主因切り分けの前に、以下の 3 source から事実を構造化抽出する:

- (a) `.aidlc/cycles/{{CYCLE}}/inception/decisions.md`
- (b) `.aidlc/cycles/{{CYCLE}}/construction/units/*-review-summary.md`
- (c) `.aidlc/cycles/{{CYCLE}}/history/*.md`

事実テーブル形式（markdown 表）:

| 項目 | 値 | 出典 |
|------|-----|------|
| DR 件数 | （Read 結果からの実数） | `inception/decisions.md` |
| review round 数 | ... | `construction/units/*-review-summary.md` |
| 指摘件数 | ... | 同上 |
| defer 件数 | ... | 同上 |
| 時系列イベント | ... | `history/*.md` |

本ステップは AI 手順として実施。自動抽出ツール化は #652 として別 Unit / 次サイクル候補。
```

### review-flow.md 推定値検出ガード（手順）

```markdown
## 推定値検出ガード

### 適用スコープ

本ガードは**振り返り文脈のみ**に適用する:
- retrospective Issue 本文（`retrospective` ラベル付き Issue）
- 振り返り作業時の KPT / 主因切り分け / Try / mirror 候補本文

それ以外のレビュー文脈（コードレビュー指摘 / Plan / Design / 統合レビューサマリ）は **適用対象外**。

### 判定原則

**一次情報を Read 済みでも、根拠リンクや出典参照が併記されていない近似語付き数値は flag する**。一次情報の有無は flag 判定に使わず、Intent 上で明示された「根拠リンク併記」のみが許容条件。

### 検出マーカー

- `約`, `およそ`, `approximately`, `approx.`, `推定`, `〜くらい`, `〜程度`

### 数値隣接判定

検出マーカーの**直前または直後 5 文字以内**に算用数字（`[0-9]`）または日本語数字（一〜十、百、千、万）が出現する場合のみ flag 候補。

### 例外条件（許容）

同一段落内に以下のいずれかが存在する場合は flag しない:
- PR/Commit/Issue リンク（`#NNN` / `https://github.com/...` / `<sha>` 等）
- 対象ファイルパス参照（`` `path/to/file.md` ``）

### flag 出力フォーマット

ガードが反応した場合、AI レビューワーの応答に **必ず 1 件以上** 以下の形式の文言を含める:

```
指摘 #N - 推定値混入: `<該当箇所>`
```

### 許容例（flag されない / 各例に検証軸タグ付与 / 設計レビュー Round 1 指摘 #4 反映）

- `[AXIS-1: 数値非隣接]` 「約束された動作」「推定エンジン」（数値を伴わない概念用法 / マーカーはあるが数値なし）
- `[AXIS-2: 根拠リンク併記]` 「DR-001〜DR-010（約 10 件、`requirements/decisions.md` 参照）」（同一段落内にファイルパス参照あり）
- `[AXIS-3: スコープ外]` コードブロック内の数値（`approximately = 5` のような変数定義 / コードブロックは振り返り文脈外として扱う）

### 非許容例（flag される / 各例に検証軸タグ付与）

- `[AXIS-1: 数値隣接ヒット]` 「DR-001〜DR-035 の 35 件（推定）」（マーカー「推定」が数値「35 件」と隣接）
- `[AXIS-1: 数値隣接ヒット + AXIS-2: 根拠リンクなし]` 「約 50 round」「approximately 130 件」「推定 35 件」
- `[AXIS-2: 根拠リンクなし]` 「DR-001〜DR-010（**約 10 件**）」（数値隣接 + 段落内に根拠リンク・ファイルパス参照なし）

> **検証軸**: AXIS-1（数値隣接判定）/ AXIS-2（根拠リンク併記の有無）/ AXIS-3（適用スコープ）。各例は最低 1 軸を検証することで、判定仕様とのトレーサビリティを確保。
```

## 不変条件（Unit 001 申し送り保持）

| AC | 検証コマンド | 期待結果 |
|----|-------------|---------|
| AC-U003-RETRO-GUARD-IMMUTABLE-1 | `awk '/^#### 1\.0\.5/,/^#### 1\.1/' skills/aidlc/steps/operations/04-completion.md` | 範囲内に「禁止事項」「必須事項」「抽象操作」「実装マッピング」キーワードが各 1 件以上 |
| AC-U003-RETRO-GUARD-IMMUTABLE-2 | `grep "retrospective_dialog_token_record_response" skills/aidlc/steps/operations/04-completion.md` | 1 件以上 |
| AC-U003-RETRO-GUARD-IMMUTABLE-3 | `grep "retrospective_dialog_token_verify" skills/aidlc/scripts/lib/retrospective-issue.sh` | 関数定義 + `retrospective_issue_create` 内呼出が両方ヒット |

## NFR への対応

- **パフォーマンス**: ドキュメント / 手順改訂のみで影響なし
- **セキュリティ**: 機密情報の扱いに変更なし
- **後方互換**: Unit 001 の §1.0.5 / §1.5 / retrospective-issue.sh を破壊せず、追加挿入のみで実現
- **可用性**: 影響なし

## 実装上の注意

- `04-completion.md` §1.x の挿入位置は **§1.1 と §1.2 の間** で確定（user_stories.md ストーリー 3 受け入れ基準準拠）
- `review-flow.md` 推定値検出ガードは「指摘対応判断フロー」の直後または末尾に追加（既存セクション順序を破壊しない）
- 500 行制限: review-flow.md は現状 247 行、追加分（数十行）で 300 行未満に収まる
- 適用スコープの誤運用予防: AI レビューワーが「対象が振り返り文脈か」を判定するルールを明文化（コードレビュー等での誤適用回避）

## 不明点と質問

[Question] §1.x の節番号

[Answer] 既存節番号体系との整合のため「§1.1.5」または「§1.x」と相対記述。実装時に最終番号を確定（§1.1 と §1.2 の間に挿入する点は不変）。

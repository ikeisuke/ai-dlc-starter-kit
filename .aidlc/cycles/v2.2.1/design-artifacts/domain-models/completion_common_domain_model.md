# ドメインモデル: フェーズ完了処理の共通化

## 概要

3フェーズのcompletion.mdに存在する重複テキストパターンを特定し、インライン圧縮の対象と方法を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（Entity）

### PhaseCompletionFile

各フェーズのcompletion.mdファイルを表す。

- **ID**: ファイルパス（`steps/{phase}/0X-completion.md`）
- **属性**:
  - phase: Phase型 - Inception / Construction / Operations
  - steps: CompletionStep[] - 完了処理ステップの順序付きリスト
  - totalSize: Integer - ファイルサイズ（バイト）
- **振る舞い**:
  - getCompressibleSteps(): 圧縮可能なステップを返す
  - calculateSizeReduction(): 圧縮による削減量を推定

## 値オブジェクト（Value Object）

### CompletionStep

完了処理内の個別ステップ。

- **属性**:
  - name: String - ステップ名
  - phase: Phase - 所属フェーズ
  - category: StepCategory - 分類（delegated / compressible / phase_specific）
  - textSize: Integer - テキストサイズ
  - delegationTarget: String? - 委譲先ファイル（例: commit-flow.md）
- **等価性**: phase + name で判定

### CompressionPattern

圧縮対象のテキストパターン。

- **属性**:
  - patternId: String - パターン識別子
  - occurrences: PhaseRef[] - 出現箇所（フェーズ+ステップ番号）
  - originalText: String - 圧縮前テキスト
  - compressedText: String - 圧縮後テキスト
  - savingsBytes: Integer - 削減バイト数

### StepCategory（列挙型）

| 値 | 説明 |
|----|------|
| `delegated` | 既存共通ファイルに委譲済み（commit-flow.md等） |
| `compressible` | インライン圧縮可能（重複説明文） |
| `phase_specific` | フェーズ固有（圧縮対象外） |

## 集約（Aggregate）

### CompletionCompressionPlan

- **集約ルート**: CompletionCompressionPlan
- **含まれる要素**: PhaseCompletionFile[3], CompressionPattern[]
- **境界**: 3フェーズの完了処理ファイル全体
- **不変条件**:
  - 圧縮後の合計サイズ < 29,722B（元の合計）
  - 各フェーズの完了処理フローが圧縮前と機能等価

## ドメインサービス

### CompressionPatternDetector

- **責務**: 3フェーズ間の重複テキストパターンを検出する
- **操作**:
  - detectDuplicates(files[3]) → CompressionPattern[] - 重複パターンを検出
  - validateEquivalence(original, compressed) → Boolean - 機能等価性を検証

## 圧縮パターン一覧

### CP-001: Squash結果分岐テキスト

- **出現**: Inception(ステップ6), Construction(ステップ7), Inception/エクスプレス(ステップ4)
- **圧縮前**（各箇所で重複、約200B/箇所）:
  ```
  - `squash:success` → ステップNスキップ
  - `squash:skipped` → ステップNへ
  - `squash:error` → エラーリカバリ後ステップNへ
  ```
- **圧縮後**: commit-flow.md への参照に統一し、結果分岐を1行に圧縮
- **推定削減**: ~400B（3箇所 → 共通パターン化）

### CP-002: Gitコミット squash判定テキスト

- **出現**: Inception(ステップ7), Construction(ステップ8), Inception/エクスプレス(ステップ5)
- **圧縮前**（各箇所で重複、約300B/箇所）:
  ```
  squash実行済み（`squash:success`）なら `git status` 確認のみ。
  未実行なら `commit-flow.md` の「XXX完了コミット」に従う。
  ```
- **圧縮後**: 2行に圧縮
- **推定削減**: ~400B

### CP-003: コンテキストリセットのセミオートゲート説明

- **出現**: Inception(ステップ9), Construction(ステップ11)
- **圧縮前**（各箇所で重複、約400B/箇所）:
  セミオートゲート判定の説明 + manual時のメッセージ提示指示
- **圧縮後**: セミオートゲート判定を1行に圧縮し、フェーズ固有の遷移先のみ記載（既存completion内でのインライン圧縮。`context-reset.md` への新規参照は追加しない）
- **推定削減**: ~900B

### CP-004: 完了サマリ出力の説明文

- **出現**: 全3フェーズ
- **圧縮前**: 各フェーズに「AIがXX Phase作業中のコンテキスト情報から動的に生成する」「情報源に存在しない内容を出力しないこと」等の同一説明文（約150B/箇所）
- **圧縮後**: 説明文を1行に圧縮
- **推定削減**: ~300B

### CP-005: エクスプレスモード完了処理の内部重複

- **出現**: Inception内（エクスプレスモード完了処理セクション）
- **圧縮前**: squash/コミット手順が「完了時の必須作業」と重複（約600B）
- **圧縮後**: 重複部分のみ「完了時の必須作業」のステップ番号参照に置換。エクスプレス固有のコミット失敗時エラーハンドリングは保持
- **推定削減**: ~400B

### CP-006: 対応内容サマリのテーブル定義

- **出現**: Construction(ステップ11), Operations(ステップ7)
- **圧縮前**: 同一の4項目テーブル（実施内容・変更対象・未対応事項・次回の着手点）とその説明文が重複（約500B/箇所）
- **圧縮後**: テーブル形式を廃止し、必須項目をインラインリストに圧縮
- **推定削減**: ~800B

## 推定合計削減量

| パターン | 削減量 |
|---------|--------|
| CP-001 | ~300B |
| CP-002 | ~300B |
| CP-003 | ~900B |
| CP-004 | ~300B |
| CP-005 | ~400B |
| CP-006 | ~800B |
| **合計** | **~3,000B** |

目標: 29,722B → ~26,700B

## ユビキタス言語

- **圧縮パターン（CP）**: 複数箇所に出現する重複テキストを特定し、最小テキストに置換する単位
- **機能等価性**: 圧縮前後でAIエージェントの実行フローが同一結果を返すこと
- **委譲**: 詳細手順を別ファイル（commit-flow.md等）に任せ、参照のみ記載すること

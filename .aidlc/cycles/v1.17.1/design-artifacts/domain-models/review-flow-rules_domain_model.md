# ドメインモデル: レビューフロー判定ルール改善

## 概要
review-flow.mdにおける千日手検出の判定基準明文化、ステップ6フォールバック承認強化、スキップ記録のwrite-history.sh統一に関するドメインモデル。本Unitの成果物はプロンプト（Markdown）であり、ソフトウェアコードではない。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## エンティティ（Entity）

### 指摘（ReviewFinding）
- **ID**: `#{index}`（レビュー内の通し番号）
- **属性**:
  - レビュー種別: string - どのレビュー種別で検出されたか（code / architecture / security / inception）
  - 対象ファイル: string? (optional) - 指摘が関連するファイルパス（未指定の場合あり）
  - 指摘内容の要約: string - 指摘の概要（正規化後）
  - 重要度: enum(高/中/低) - 指摘の重要度
- **振る舞い**:
  - 同種判定: 別の指摘と「同種」であるかを判定する（SameIssueJudgmentServiceに委譲）

### フォールバック承認記録（FallbackApprovalRecord）
- **ID**: 履歴記録のタイムスタンプ
- **属性**:
  - スキップ理由: string - ユーザーが入力した理由テキスト
  - 対象成果物: string - レビュー対象の成果物名
  - 承認日時: timestamp - 承認された日時
- **振る舞い**:
  - 理由バリデーション: スキップ理由が妥当かを検証する（ReasonValidationServiceに委譲）

## 値オブジェクト（Value Object）

### 同種判定キー（SameIssueCriteriaKey）
- **属性**:
  - レビュー種別: string
  - 対象ファイル: string? (optional)
  - 指摘内容の要約: string
- **不変性**: 指摘の同種判定に使用するキーは、レビュー結果確定時に固定される
- **等価性**: 3つのキーがすべて実質的に一致する場合に同種とみなす
- **未指定時の扱い**: 対象ファイルが未指定（片方または両方）の場合、対象ファイルキーは常に一致とみなす（ワイルドカード扱い）

### 禁止パターン（ProhibitedReasonPattern）
- **属性**:
  - パターン文字列: string - マッチ対象のテキストパターン
- **不変性**: 定義は「指摘対応判断フロー」セクションの「禁止パターン」箇条書きが唯一の参照元（SoT）。ステップ6ではセクション名で参照する
- **等価性**: パターン文字列の完全一致

### バリデーション結果（ValidationResult）
- **属性**:
  - code: enum(EMPTY / PROHIBITED / OK) - 検証結果コード
  - message: string? (optional) - エラー時のメッセージ
- **不変性**: 検証実行時に生成され変更されない
- **等価性**: codeの一致

## 集約（Aggregate）

### 千日手検出（InfiniteLoopDetection）
- **集約ルート**: 反復レビュー結果（3回分）
- **含まれる要素**: ReviewFinding（各回の指摘リスト）
- **境界**: 直近3回の反復レビュー結果のみ対象
- **不変条件**: 3回分の結果がすべて揃っている場合のみ千日手判定を実行する

### スキップ記録（SkipRecord）
- **集約ルート**: FallbackApprovalRecord
- **含まれる要素**: ProhibitedReasonPattern（バリデーション用参照）
- **境界**: ステップ6の選択肢2（mode=required時）
- **不変条件**: 理由バリデーションを通過した記録のみ保存される

## ドメインサービス

### 同種判定サービス（SameIssueJudgmentService）
- **責務**: 指摘の同種判定と千日手検出を一元的に担う
- **操作**:
  - isSameIssue(findingA, findingB) → boolean: SameIssueCriteriaKeyの3キーで判定（対象ファイル未指定時はワイルドカード扱い）
  - detectInfiniteLoop(round1Findings, round2Findings, round3Findings) → boolean: isSameIssueを使い、3回とも同種の指摘が出現しているか判定

### 理由バリデーションサービス（ReasonValidationService）
- **責務**: スキップ理由が禁止パターンに該当しないか検証する
- **操作**:
  - validate(reason) → ValidationResult: 空チェック(EMPTY) → 禁止パターン(PROHIBITED) → 受理(OK)の順で検証
- **禁止パターン参照**: 「指摘対応判断フロー」セクションの「禁止パターン」箇条書きをSoTとして参照

## ユビキタス言語

- **千日手**: AIレビューの反復で同種の指摘が収束せず繰り返される状態
- **同種の指摘**: レビュー種別・対象ファイル・指摘内容の要約が実質的に一致する指摘（対象ファイル未指定時はワイルドカード扱い）
- **フォールバック承認**: 外部AIレビュー続行不能時にユーザーがレビュースキップを承認すること
- **禁止パターン**: スキップ理由として単独では受け付けない定型表現
- **SoT（Single Source of Truth）**: 禁止パターンの定義が一箇所のみに存在し、他はセクション名で参照する設計原則

## 不明点と質問（設計中に記録）

（なし - Unit定義とIssue内容から要件は明確）

# ドメインモデル: スコープ外バックログ自動登録

## 概要
指摘対応判断フローでOUT_OF_SCOPE選択時にバックログ登録を自動実行するステップのドメインモデル。本Unitの成果物はプロンプト（Markdown）であり、ソフトウェアコードではない。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（Entity）

### スコープ外指摘（OutOfScopeIssue）
- **ID**: 指摘対応判断フロー内の指摘番号
- **属性**:
  - 指摘内容: string - レビュー指摘の概要
  - 先送り理由: string - ユーザーが入力した理由テキスト
  - レビュー種別: string - code / architecture / security / inception
  - 対象成果物: string - レビュー対象のファイル名等
- **振る舞い**:
  - バックログ登録: BacklogRegistrationServiceに委譲

## 値オブジェクト（Value Object）

### バックログモード（BacklogMode）
- **属性**:
  - mode: enum(git / issue / git-only / issue-only)
- **不変性**: `docs/aidlc.toml` の `[rules.backlog].mode` から読み取り、セッション中は固定
- **等価性**: mode値の一致
- **フォールバック**: 設定ファイル未存在・読み取りエラー・構文エラー・値未設定時は `git` として扱う

### バックログ種別（BacklogItemType）
- **属性**:
  - type: enum(chore / security / docs / feature / bugfix / refactor / perf)
- **不変性**: レビュー種別から決定され変更されない
- **等価性**: type値の一致
- **マッピング規則**: security → type:security、その他（code / architecture / inception） → type:chore

### 登録方法（RegistrationMethod）
- **属性**:
  - method: enum(FILE / ISSUE)
- **不変性**: BacklogMode + ghCLI可用性から決定され、変更されない
- **等価性**: method値の一致

### gh CLI可用性（GhCliAvailability）
- **属性**:
  - commandExists: boolean - `gh` コマンドの存在
  - authenticated: boolean - `gh auth status` の結果
- **不変性**: 判定時に固定

### バックログ登録結果（RegistrationResult）
- **属性**:
  - success: boolean - 登録成功/失敗
  - method: RegistrationMethod - 使用した登録方法
  - reference: string? (optional) - Issue番号またはファイルパス
  - fallbackUsed: boolean - フォールバックが適用されたか
  - message: string? (optional) - 警告・エラーメッセージ

## 集約（Aggregate）

### バックログ自動登録（BacklogAutoRegistration）
- **集約ルート**: OutOfScopeIssue
- **含まれる要素**: BacklogMode, BacklogItemType, RegistrationMethod, GhCliAvailability, RegistrationResult
- **境界**: 指摘対応判断フローのステップ5a（OUT_OF_SCOPE判断後のみ）
- **不変条件**: OUT_OF_SCOPEと判断された指摘のみがバックログ登録の対象

## ドメインサービス

### バックログ登録サービス（BacklogRegistrationService）
- **責務**: 種別決定→mode判定→gh CLI可用性判定→登録方法決定→登録実行→履歴記録
- **操作**:
  - determineType(reviewType) → BacklogItemType: レビュー種別からバックログ種別を決定（security → type:security、その他 → type:chore）
  - determineMethod(mode, ghCliAvailability) → RegistrationMethod: mode + gh CLI状態から登録方法を決定
  - register(outOfScopeIssue, method, type) → RegistrationResult: 実際の登録を実行
  - recordHistory(result) → void: write-history.shで履歴を記録

### 登録方法決定ルール

| BacklogMode | gh CLI可用 | 結果 |
|-------------|-----------|------|
| git / git-only | - | FILE |
| issue | 可用 | ISSUE |
| issue | 不可用 | FILE（フォールバック） |
| issue-only | 可用 | ISSUE |
| issue-only | 不可用 | 警告+手動対応依頼（登録スキップ） |

## ユビキタス言語

- **スコープ外（OUT_OF_SCOPE）**: レビュー指摘が現サイクルの対応範囲外であり、次サイクル以降で対応すべきと判断されたもの
- **バックログ自動登録**: OUT_OF_SCOPE判断時にバックログへの登録を自動的に試行するプロセス
- **フォールバック**: Issue作成が不可能な場合にファイルベースの登録に切り替える処理
- **gh CLI可用性**: `gh` コマンドの存在と認証状態の2段階で判定

## 不明点と質問（設計中に記録）

（なし - 計画レビューで要件は明確化済み）

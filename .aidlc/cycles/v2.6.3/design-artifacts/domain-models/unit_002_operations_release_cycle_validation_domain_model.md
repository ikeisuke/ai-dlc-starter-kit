# ドメインモデル: operations-release.sh cmd_squash_712 への --cycle バリデーション導入

## 概要

`cmd_squash_712` サブコマンドの `--cycle` 引数を「信頼できるサイクル識別子」へ昇格させるための
入力検証ドメインを定義する。本 Unit は新規バリデーションロジックを実装せず、既存
`validate_cycle`（`skills/aidlc/scripts/lib/validate.sh`）を検証規則の Single Source of Truth
として再利用する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装は Phase 2（コード生成ステップ）で行います。

## エンティティ（Entity）

本 Unit はシェルスクリプトの引数検証であり、永続化される識別子を持つエンティティは存在しない。
該当なし。

## 値オブジェクト（Value Object）

### CycleIdentifier（サイクル識別子）

- **属性**: `value`: string - `cmd_squash_712` の `--cycle` 引数として渡される文字列
- **不変性**: 検証後は変更されない。検証を通過した時点で「以降のパス解決に使用してよい値」
  という不変条件を保持する
- **等価性**: 文字列値の完全一致で判定
- **検証規則**（`validate_cycle` が定義する受理条件 = SoT）:
  - 非空であること
  - パストラバーサル文字列（`..`）を含まないこと
  - 空白・制御文字を含まないこと
  - 先頭スラッシュを持たないこと
  - 1〜2 セグメントの汎用ラベル形式（`^[a-z0-9v][a-z0-9._-]*(/[a-z0-9v][a-z0-9._-]*)?$`）
  - 末尾ドット・`.lock` 接尾辞を持たないこと（Git ref 予約）
  - `git check-ref-format --branch "cycle/<value>"` を通過すること（最終防衛線・fail-closed）
- **状態**: `unvalidated`（検証前） / `validated`（検証通過） / `rejected`（検証失敗）。
  `rejected` の場合 `cmd_squash_712` は exit 1 で停止し、後続のパス解決に値は渡らない

## 集約（Aggregate）

該当なし（単一値オブジェクトの検証のみで、集約境界を要する複合構造は存在しない）。

## ドメインサービス

### CycleValidationService（サイクル検証サービス）

- **責務**: `CycleIdentifier` を検証規則に照らして `validated` / `rejected` を判定する。
  本 Unit ではこのサービスの実体を新規実装せず、既存 `validate_cycle` 関数がその役割を担う
- **操作**:
  - `validate_cycle(value)` - `value` を検証規則に照合し、受理なら return 0、拒否なら return 1
    を返す（実装は `skills/aidlc/scripts/lib/validate.sh` の既存関数）

### 検証ポイントの責務分離（二層防御）

本 Unit のドメイン上、`CycleIdentifier` の検証は役割の異なる 2 層で行われる:

| 層 | 検証主体 | 責務 | 検証範囲 |
|----|---------|------|---------|
| サブコマンド入口層 | `cmd_squash_712`（本 Unit で追加） | サブコマンド起動時の包括的入力検証 | `validate_cycle` の全規則 |
| 下位関数ローカル層 | `__squash_712_check_history_clean`（既存・維持） | 下位関数が単体で fail-closed を保つためのローカル不変条件チェック | 最小トラバーサル拒否（`..` / 先頭 `/` / 改行） |

両層は重複するが役割が異なるため、下位関数層は除去せず防御的に維持する（計画
「責務境界の確定方針（fixed）」と整合）。

## リポジトリインターフェース

該当なし（永続化対象なし）。

## ファクトリ

該当なし。

## ユビキタス言語

- **サイクル識別子（CycleIdentifier）**: `--cycle` 引数として渡される、`.aidlc/cycles/<value>/...`
  のパスセグメントに展開される文字列
- **検証規則（validation rule）**: `validate_cycle` が定義する受理条件の集合。本リポジトリにおける
  サイクル名検証の Single Source of Truth
- **サブコマンド入口検証**: サブコマンド（`cmd_squash_712`）が引数パース直後に行う包括的検証
- **ローカル不変条件チェック**: 下位関数が、呼び出し元の検証有無に依存せず単体で安全性を保つ
  ための最小限の自己防衛検証
- **fail-closed**: 検証不能・判定不能な入力を「拒否」側に倒す設計方針

## 不明点と質問（設計中に記録）

[Question] なし（要件・実装アプローチともに一意に確定しており、対話による明確化を要する不明点はない）
[Answer] -

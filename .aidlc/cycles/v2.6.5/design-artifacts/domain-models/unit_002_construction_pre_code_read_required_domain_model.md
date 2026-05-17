# ドメインモデル: Unit 002 Construction Phase 1 設計起草前の事前コード Read 工程組み込み

## ステップ 0: 事前コード読込み（本 Unit ドッグフーディング）

### (a) Read 対象ファイル + 目的

| ファイル | 目的 |
|---------|------|
| `skills/aidlc/steps/construction/02-design.md` | 改修対象（主）。既存ステップ 1〜3 構造と `depth_level=minimal` スキップ可記述を確認、ステップ 0 挿入位置を決定 |
| `skills/reviewing-construction-design/SKILL.md` | 改修対象（副）。既存「### 構造」「### パターン」「### API設計」「### 依存関係」セクション構造を確認、新設「### 設計プロセス」セクション挿入位置を決定 |
| `skills/aidlc/steps/construction/index.md` §2.3 | `depth_level` 分岐ロジック SoT を確認、`minimal` 時の Phase 1 スキップ動作と整合する必要性 |

### (b) 設計時に意識すべき挙動

- `02-design.md` の既存ステップ 1〜3 は番号維持必須。新ステップは「ステップ 0」として冒頭に挿入し、既存番号を破壊しない（後方互換）
- `depth_level=minimal` ではドメインモデル設計ステップ自体スキップ可（`index.md §2.3` 参照）。事前コード読込みステップも同条件で skip 可（N/A 判定）
- `reviewing-construction-design/SKILL.md` の `description` フロントマターは architecture focus を含み、観点追加先として整合
- 既存 4 セクション（構造 / パターン / API設計 / 依存関係）は**成果物品質**を扱う。新設「### 設計プロセス」は**実施プロセス検証**を扱うため責務が直交

### (c) 既存実装に基づく代替案検討

- **採用**: 新規セクション「### 設計プロセス」を `reviewing-construction-design/SKILL.md` に追加。既存セクション群と並列配置で責務分離が明確
- **却下**: 既存「### 構造」に sub-bullet として追加 → 「構造=成果物品質」観点と「事前コード読込み=プロセス検証」観点が混在し責務不整合
- **却下**: 別ファイル `reviewing-construction-pre-code-read.md` を新設 → 配置先分散で SoT 探索コスト増、判定経路の重複リスク

## 概要

Construction Phase 1 設計起草前に AI エージェントが既存実装を Read しないまま設計起草を行うのを防ぐドメイン。`02-design.md` のステップ 0 として「事前コード読込み」を必須化し、`reviewing-construction-design` の新設「### 設計プロセス」観点で実施検証する。

**重要**: 本ドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。

## エンティティ（Entity）

### PreCodeReadSession（事前コード読込みセッション）

- **ID**: `(cycle, unit_number)` 複合キー
- **属性**:
  - `cycle`: string - サイクルバージョン
  - `unit_number`: int - Unit 番号
  - `target_files`: list of `TargetFile` - Read 対象ファイル
  - `key_behaviors`: text - 設計時に意識すべき挙動の記述
  - `alternative_evaluation`: text - 既存実装に基づく代替案検討の記述
- **振る舞い**:
  - `is_complete()`: 3 属性（target_files, key_behaviors, alternative_evaluation）すべてに具体記述があるか判定
  - `applies_to(depth_level)`: `depth_level != minimal` のとき true（`minimal` 時は N/A）

## 値オブジェクト（Value Object）

### TargetFile（Read 対象ファイル）

- **属性**:
  - `path`: string - リポジトリ相対パス
  - `purpose`: string - Read 目的（簡潔な 1 文）
- **不変性**: 構築時に path / purpose 両方を要求（どちらか欠落は不正値）

### DepthLevel（depth_level 値）

- **属性**: `level`: enum(`minimal` | `standard` | `comprehensive`)
- **等価性**: `level` 値完全一致

## ドメインサービス

### PreCodeReadSessionValidator（事前コード読込みセッション検証サービス）

- **責務**: ドメインモデル成果物の冒頭に `PreCodeReadSession` 表現（ステップ 0 セクション）が存在し、3 観点すべてに具体記述があるかを検証
- **操作**:
  - `validate(domain_model_path, depth_level)` - `depth_level != minimal` のときのみ実施。ステップ 0 セクション見出し検出 + (a)(b)(c) 3 観点の具体記述存在を判定

## 集約（Aggregate）

### DesignProcessGate（設計プロセスゲート）

- **集約ルート**: `PreCodeReadSession`
- **境界**: 1 つの Unit の設計起草 → 設計レビューに対する事前コード読込み実施検証フロー
- **不変条件**: `depth_level != minimal` の場合、`PreCodeReadSession.is_complete() == true` でなければ設計レビューは承認されない

## ユビキタス言語

- **事前コード読込み (Pre-Code Read)**: Construction Phase 1 設計起草の **前** に、改修予定の既存実装を Read して挙動を理解する工程
- **二段階分離 (Two-Phase Separation)**: 「事前コード Read」と「設計起草」を独立ステップとして分離し、順序制約を付ける設計プロセス原則
- **N/A 判定 (Not Applicable)**: `depth_level=minimal` で設計ステップ自体スキップされる場合、事前コード読込み観点も検証対象外として扱う
- **設計プロセス観点 (Design Process Aspect)**: `reviewing-construction-design` における「成果物品質」（構造 / パターン / API設計 / 依存関係）と並列の新設観点。**実施プロセス検証**を担う

## 不明点と質問

[Question] ステップ 0 セクション見出しは具体的にどの名称にするか
[Answer] `## ステップ 0: 事前コード読込み（本 Unit ドッグフーディング）` 形式（Unit 002 本ドメインモデルでも採用）。`02-design.md` 側では「## ステップ0: 事前コード読込み」セクション名で挿入し、(a)(b)(c) 3 観点を必須サブセクションとする

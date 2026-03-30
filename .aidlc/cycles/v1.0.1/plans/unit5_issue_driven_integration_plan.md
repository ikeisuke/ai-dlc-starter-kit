# Unit 5: Issue駆動統合設計 - 実行計画

> **ステータス: 延期**
> - 延期日: 2025-11-28
> - 延期理由: AI-DLCがもっと成熟してから導入した方が効果的
> - 詳細: `docs/cycles/backlog.md` を参照

## 概要
AI-DLCサイクル全体（Inception → Construction → Operations）にIssue駆動な仕組みを組み込む方法を検討し、設計を完了する。

**重要**: このUnitは**設計のみ**であり、実際の実装は次サイクル以降となる。

---

## 対象ストーリー
- ストーリー 4.1: Issue駆動開発統合の検討と設計
- ストーリー 4.2: Issue駆動開発統合の実装方針決定

---

## Phase 1: 設計【対話形式、コードは書かない】

### ステップ1: ドメインモデル設計
**目的**: Issue駆動開発の概念モデルとAI-DLCサイクルとの対応関係を定義

**成果物**: `docs/cycles/v1.0.1/design-artifacts/domain-models/unit5_issue_driven_domain_model.md`

**内容**:
- Issue駆動開発の基本概念（Epic, Issue, Label, Milestone）
- AI-DLCサイクルとの対応付け
  - Epic ↔ Intent
  - Unit Issue ↔ Unit定義
  - Issue ↔ ユーザーストーリー
- 状態遷移モデル（Open → In Progress → Closed）
- ラベル体系設計（phase:*, type:*, priority:*）
- マイルストーン管理（サイクルバージョンとの対応）

### ステップ2: 論理設計
**目的**: Issue駆動フローの詳細設計とIssueテンプレート仕様の定義

**成果物**: `docs/cycles/v1.0.1/design-artifacts/logical-designs/unit5_issue_driven_logical_design.md`

**内容**:
- Issue駆動フローの詳細（各フェーズでのIssue操作）
- Issueテンプレート仕様（4種類: Epic用、Unit用、バグ用、タスク用）
- フェーズ別Issue活用ガイドライン
- 将来の自動化に向けた拡張ポイント
- オフライン環境での運用方法

### ステップ3: 設計レビュー
ユーザーに設計内容を提示し、承認を得る

---

## Phase 2: 成果物作成【設計を参照してドキュメント生成】

### ステップ4: Issueテンプレート作成
**成果物**: `.github/ISSUE_TEMPLATE/` 配下に4種類のテンプレート
- `epic.md` - Epic用（複数Unitをまとめる）
- `unit.md` - Unit用（1つのUnitに対応）
- `bug.md` - バグ用（単発のバグ修正）
- `task.md` - タスク用（小さな改善）

### ステップ5: フロー定義文書作成
**成果物**: `docs/aidlc/issue-driven-flow.md`
- 各フェーズでのIssue操作手順
- ラベル・マイルストーン運用ガイドライン
- ベストプラクティス

### ステップ6: 統合とレビュー
- 成果物の整合性確認
- `docs/cycles/v1.0.1/construction/units/unit5_implementation.md` に実装記録を作成

---

## 成果物一覧

| フェーズ | 成果物 | パス |
|---------|--------|------|
| 設計 | ドメインモデル | `docs/cycles/v1.0.1/design-artifacts/domain-models/unit5_issue_driven_domain_model.md` |
| 設計 | 論理設計 | `docs/cycles/v1.0.1/design-artifacts/logical-designs/unit5_issue_driven_logical_design.md` |
| 実装 | Issueテンプレート（4種類） | `.github/ISSUE_TEMPLATE/` |
| 実装 | Issue駆動フロー定義 | `docs/aidlc/issue-driven-flow.md` |
| 実装 | 実装記録 | `docs/cycles/v1.0.1/construction/units/unit5_implementation.md` |

---

## 完了基準

- [x] ドメインモデル設計完了
- [x] 論理設計完了
- [x] 設計レビュー承認
- [ ] Issueテンプレート4種類作成
- [ ] Issue駆動フロー定義文書作成
- [ ] 実装記録作成
- [ ] progress.md更新
- [ ] 履歴記録
- [ ] Gitコミット

---

## 備考

- **実装は含まない**: CI/CD統合、自動化スクリプト、API連携などの実装は次サイクル以降
- **オフライン対応**: オフライン環境でもドキュメントベースで運用可能な設計とする
- **シンプルさ優先**: まずは基本的な連携のみ、複雑な自動化は将来の拡張として検討

---

## 作成日時
2025-11-28

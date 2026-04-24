# ドメインモデル: Unit 005 Inception Phase へ Milestone 作成ステップを追加 + cycle-label deprecation

## 概要

GitHub Milestone 運用本採用（#597）の中核 Unit。Inception Phase の Markdown ステップに Milestone 作成・Issue 紐付けの恒久手順を追加し、既存のサイクルラベル付与記述を Milestone 紐付けに置換、`cycle-label.sh` / `label-cycle-issues.sh` を deprecated 化する。本 Unit は Markdown 編集 + シェルスクリプト先頭コメント追記のみのため、**手順の責任分離（02-preparation の先行紐付け vs 05-completion の正式作成・紐付け）と GitHub Milestone API の冪等性確保** を中心に定義する。

**重要**: このドメインモデル設計では**コードは書かず**、責務の定義のみを行う。実装は Phase 2 で行う。

## ドメイン責務

### Unit 005: Inception Phase Milestone 化 + 旧スクリプト deprecation

- **責務**: Inception Phase の各ステップに Milestone 作成・Issue 紐付け手順を追加し、必要なユーザー確認（持ち越し時の付け替え/Backlog 保持選択など）を除き、AI/人間が `gh api` を順次実行できる状態を作る
- **入力**: 既存 Markdown ステップ（`02-preparation.md` / `05-completion.md` / `index.md`）+ 既存スクリプト（`cycle-label.sh` / `label-cycle-issues.sh`）
- **出力**:
  - Markdown 更新後ステップ（Milestone 紐付け手順 + フォールバック手順 + 5 ケース判定マトリクス）
  - スクリプトヘッダ DEPRECATED 注記
  - Unit 007 への CHANGELOG `#597` 節 deprecation 記載依頼

## 手順の責任分離

| ステップ | 責務 | 実行条件 |
|---------|------|---------|
| `02-preparation.md` ステップ16 | **先行紐付け（オプショナル）**: 既存 open Milestone が 1 件のみ存在する場合に `gh issue edit --milestone` で先行紐付け | `gh_status=available` AND `OPEN_COUNT==1 AND CLOSED_COUNT==0` |
| `05-completion.md` ステップ1（完了時の必須作業） | **正式作成・紐付け**: 5 ケース判定 → Milestone 作成（または再利用 / 停止）→ 関連 Issue 一括紐付け（`gh issue edit` 優先 + `gh api PATCH` フォールバック） | `gh_status=available` 必須 |
| `05-completion.md` ステップ2（エクスプレスモード） | ステップ1 を流用 | エクスプレスモード時 |

責任分離の根拠:
- 02-preparation 段階では Milestone 未作成の可能性があり、**Issue 選択と Milestone 作成のタイミング非同期** を許容する設計
- 05-completion ステップ1 で必ず Milestone 作成・紐付けが完了するため、02-preparation の先行紐付けは「速報的な進捗表示」として位置づけられる
- 02-preparation 側の PATCH フォールバック実装は OWNER/REPO 動的解決を必要とするため、責任分離のため 05-completion 側に集約

## 5 ケース判定（Milestone 重複作成防止）

| open 件数 | closed 件数 | 動作 |
|----------|-----------|------|
| ≥ 2 | 0 | 停止（重複作成、手動整理を要求） |
| 1 | 0 | 再利用（既存 open を使用） |
| 0 | 0 | 新規作成 |
| 0 | ≥ 1 | 停止（命名衝突、過去サイクルとの再使用判定を要求） |
| ≥ 1 | ≥ 1 | 停止（混在、運用ミスの可能性として手動確認を要求） |

実装側は `CLOSED_COUNT >= 1` を最優先停止条件としているため、混在ケースも自動的に停止される。

## ファイル所有関係

| ファイル | Unit 005 所有範囲 | 他 Unit との関係 |
|---------|----------------|---------------|
| `skills/aidlc/steps/inception/02-preparation.md` | ステップ16「サイクルラベル付与」→「Milestone 紐付け（先行、open=1 のみ）」置換（**排他所有**） | 他 Unit 所有なし |
| `skills/aidlc/steps/inception/05-completion.md` | ステップ1（完了時の必須作業 L60-L86）+ ステップ2（エクスプレスモード L28-L30）の Milestone 化（**排他所有**） | 他 Unit 所有なし |
| `skills/aidlc/steps/inception/index.md` | L33 / L113 / L208 の「サイクルラベル」→「Milestone（v2.4.0以降）」整合更新（**排他所有**） | 他 Unit 所有なし |
| `skills/aidlc/scripts/cycle-label.sh` | ヘッダ DEPRECATED 注記追加（**排他所有**、機能変更なし） | 他 Unit 所有なし |
| `skills/aidlc/scripts/label-cycle-issues.sh` | 同上 | 他 Unit 所有なし |
| `CHANGELOG.md` | **対象外**（Unit 007 へ委譲） | Unit 007 が `#597` 節に deprecation 記載追加 |
| `skills/aidlc/guides/issue-management.md` / `guides/backlog-management.md` | **対象外**（Unit 007 所有） | Unit 007 が更新 |

## 境界

- **Operations Phase 側 Milestone close**: Unit 006 の責務（並列）
- **ドキュメント側（docs/configuration.md / README.md / guides / rules.md）の更新**: Unit 007 の責務
- **CHANGELOG `#597` 節の deprecation 記載**: Unit 007 の責務（本 Unit の完了報告で依頼明記）
- **`cycle-label.sh` / `label-cycle-issues.sh` の物理削除**: 本サイクル対象外（後続サイクル Unit E）
- **過去 v2 サイクル（v2.0.0〜v2.3.5）の遡及 Milestone 化**: 本サイクル対象外（Unit D）
- **v2.4.0 自身の Milestone 作成・Issue 紐付け**: 運用タスク T1 で実施済み（本 Unit の自動化対象外、Markdown ステップは v2.5.0 以降の恒久手順として記述）

## ユビキタス言語

- **Milestone 紐付け**: GitHub の Issue を特定の Milestone に関連付ける操作。`gh issue edit --milestone` または `gh api --method PATCH /repos/{owner}/{repo}/issues/{number}` で実施
- **5 ケース判定**: Milestone 作成前に同名 Milestone の open/closed 件数を state=all で取得し、5 ケース（open≥2/0, open=1/0, open=0/closed=0, open=0/closed≥1, open≥1/closed≥1）に分類して動作を決定する判定ロジック
- **先行紐付け（02-preparation）**: 05-completion ステップ1 の正式作成・紐付け前に、既存 open Milestone (=1) があれば Issue を先に紐付けるオプショナル動作
- **正式作成・紐付け（05-completion ステップ1）**: 5 ケース判定 → Milestone 作成（または再利用/停止）→ 関連 Issue 一括紐付けの中核手順
- **DEPRECATED 注記**: 旧スクリプトのヘッダコメントに追記する非推奨化通知。物理削除は v2.5.0 以降の Unit E で実施
- **OWNER/REPO 動的解決**: `gh repo view --json owner --jq .owner.login` / `--json name --jq .name` で取得。リポジトリ移管時にも追従

## 不明点と質問

なし（plan 段階で codex AI レビュー 4 反復を経て手順の責任分離・5 ケース判定・OWNER/REPO 解決・棚卸しを確定済み）。

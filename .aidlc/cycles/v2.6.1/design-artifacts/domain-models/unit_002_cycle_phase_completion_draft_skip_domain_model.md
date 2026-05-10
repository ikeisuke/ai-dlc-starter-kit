# Unit 002 ドメインモデル: Cycle Phase Completion Check の draft PR skip

## 概要

GitHub Actions workflow の job レベル `if` 条件追加に閉じる軽量変更のため、複雑なドメインオブジェクトは持たない。本ドキュメントは「PR 状態と CI ジョブ実行可否」のマッピングを整理する軽量モデル。

## 主要概念

### PrJobExecutionPolicy（PR 状態 → workflow ジョブ実行可否のマッピング）

本テーブルは workflow が返すジョブ動作（execute / skip）に責務を限定する。Ruleset 設定側の最終マージ可否評価は本ドメインの責務外（後述「運用前提」セクション参照）。

| PR 状態 | head_ref パターン | draft 状態 | 当ジョブの動作 | GitHub UI 表示 |
|--------|-------------------|----------|---------------|---------------|
| 開発中（中間 push） | `cycle/*` | true | skip | Skipped |
| Review 準備完了 | `cycle/*` | false | execute | Running / Pass / Fail |
| 非 cycle PR | `chore/*` 等 | 任意 | skip（`startsWith` 不一致） | Skipped（既存挙動） |
| 非 main 向け PR | 任意 | 任意 | trigger 未発火（`branches: [main]` 限定） | （ジョブ自体起動しない） |

### 運用前提（Ruleset との分離・workflow ドメイン外）

Repository Ruleset / Branch protection で当ジョブを Required status check として運用する場合の最終マージ可否評価は本 Unit のドメイン外。具体的な確認手順・想定表示は `docs/cycle-phase-completion-check-ruleset.md` の運用ドキュメントで扱う（責務境界の分離）。

### EventTypeContract（pull_request イベントタイプとの対応）

| event type | draft 状態の取得値 | 当 Unit の追加対応 |
|-----------|-------------------|------------------|
| `opened` | 開いた時点の draft 状態（true / false） | 既存挙動維持 |
| `synchronize` | push 時点の draft 状態 | 既存挙動維持（draft なら skip） |
| `reopened` | 再開時点の draft 状態 | 既存挙動維持 |
| `ready_for_review` | 必ず false | 既存挙動維持（execute） |
| `converted_to_draft` | 必ず true | **本 Unit で types に追加**（draft に戻したときに skip 状態へ遷移を可視化） |

## 不変条件

1. **logical AND の二段階フィルタ**: `cycle/*` ブランチ条件（branch filter）と `not draft` 条件（state filter）の両方を満たすときのみジョブ実行。どちらか不一致なら skip
2. **既存挙動の維持**: 非 cycle PR / 非 draft cycle PR の挙動は変更しない（追加された draft skip 経路のみが新規）
3. **Ruleset との分離**: 当 Unit は workflow 側のみを変更し、Repository Ruleset 設定そのものは変更しない（運用者の判断に委ねる）

## 状態遷移

| 遷移元 → 遷移先 | 発火イベント | 当ジョブ動作変化 |
|----------------|------------|-----------------|
| draft → ready | `ready_for_review` | skip → execute |
| ready → draft | `converted_to_draft` | execute → skip |
| draft 状態で commit push | `synchronize` | skip 維持 |
| ready 状態で commit push | `synchronize` | execute 維持 |

## 依存関係

- 上位: GitHub Actions runtime（`if` 式評価エンジン、PR webhook）
- 下位: なし（workflow 単体で完結）

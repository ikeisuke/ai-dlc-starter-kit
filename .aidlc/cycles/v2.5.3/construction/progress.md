# Construction Phase 進捗管理

## Unit一覧

| Unit | タイトル | 状態 | Phase 1（設計） | Phase 2（実装） | 完了日 |
|------|---------|------|-----------------|-----------------|--------|
| 001 | 振り返り対話強制ガード強化（Operations §1） | 完了 | 完了 | 完了 | 2026-05-07 |
| 002 | write-history skill にモード追加（unit-complete-short-note + operations-round） | 完了 | 完了 | 完了 | 2026-05-07 |
| 003 | 事実テーブル先抽出ステップ + 推定値検出ガード（#634 絞込） | 完了 | 完了 | 完了 | 2026-05-07 |
| 004 | predecessor-issue.sh の retrospective-issue.sh 横依存解消（用途別 helper 独立化） | 完了 | 完了 | 完了 | 2026-05-07 |

## 依存関係

- 論理依存: なし（4 Unit すべて独立した価値を提供）
- 実装順依存:
  - Unit 001 → Unit 003（同一ファイル `skills/aidlc/steps/operations/04-completion.md` §1 を改訂するためコンフリクト回避）
  - Unit 002A / 2B（同一スクリプト `skills/aidlc/scripts/write-history.sh` 改修のため、Unit 002 として 1 Unit に統合）
  - Unit 004 は完全独立で並列実装可能

## 実装順序の推奨

1. Unit 004（独立 / 並列実装可 / refactor）
2. Unit 002（独立 / write-history skill 改修 / Must-have）
3. Unit 001（Operations §1 対話強制ガード強化 / Must-have）
4. Unit 003（Unit 001 後 / 04-completion §1 への追記）

または:

- Unit 004 と Unit 002 を並列実装し、その後 Unit 001 → Unit 003 を逐次実装

## 現在のステップ

**全 Unit 完了**（Unit 001 / 002 / 003 / 004 すべて完了）。Construction Phase 終了。次は Operations Phase へ遷移（`/aidlc operations` で開始）。

### 次セッション再開時の必読情報

#### Unit 001 から後続 Unit への申し送り受け入れ条件 (重要)

`.aidlc/cycles/v2.5.3/plans/unit-001-plan.md` の「後続 Unit への申し送り事項」セクションに記載された下記受け入れ条件を Unit 003 / Unit 004 計画ファイルに明記し、統合レビューで回帰チェックすること:

- **AC-U003-RETRO-GUARD-IMMUTABLE-1**: §1.0.5（対話必須ガード）の「禁止事項リスト」「必須事項リスト」「抽象操作レベル禁止表」「実装マッピング表」が改修後も保持
- **AC-U003-RETRO-GUARD-IMMUTABLE-2**: §1.5 Step 4 起票直前の AskUserQuestion 必須化記述および `retrospective_dialog_token_record_response` 呼出手順が改修後も保持
- **AC-U003-RETRO-GUARD-IMMUTABLE-3**: `retrospective_dialog_token_verify` 関数の存在と `retrospective_issue_create` からの呼び出し関係が改修後も保持
- **AC-U004-RETRO-GUARD-IMMUTABLE-1**: `retrospective-issue.sh` の関数移管 / refactor 時、Unit 001 で追加された `retrospective_dialog_token_record_response` / `retrospective_dialog_token_verify` 関数と `retrospective_issue_create` への組み込みが破壊されないこと
- **AC-U004-RETRO-GUARD-IMMUTABLE-2**: 新 helper 群（`aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh`）への関数移管対象に Unit 001 で追加した対話確認トークン関連関数を含めない（`retrospective-issue.sh` 残置）

#### Unit 002 で導入した新機能（Unit 003 / 004 完了処理時に活用推奨）

- `bash skills/aidlc/scripts/write-history.sh --mode unit-complete-short-note --cycle v2.5.3 --phase construction --unit N --unit-slug ... --unit-name ... --step ... --content ... --short-note "..."` で Unit 完了時の short note を記録可能
- mode 制約: `unit-complete-short-note` は `--phase construction` 必須、`operations-round` は `--phase operations` 必須

#### Unit 003 概要（Should-have / 1.5日）

- Issue: #634（絞込）
- 対象ファイル: `skills/aidlc/steps/operations/04-completion.md` §1（Unit 001 で §1.0.5 追加済み、Unit 003 では §1.x 追加） + `skills/aidlc/steps/common/review-flow.md`
- 責務: 事実テーブル先抽出ステップ追加 + 「約 / approximately / 推定値」検出ガード追加
- 受け入れ基準: `.aidlc/cycles/v2.5.3/story-artifacts/user_stories.md` ストーリー 3 参照

#### Unit 004 概要（Should-have / 2日）

- Issue: #643
- 対象ファイル: `skills/aidlc/scripts/lib/predecessor-issue.sh` / `retrospective-issue.sh` + 新規 helper 群
- 責務: `retrospective-issue.sh` への横依存解消、`__retro_validate_cycle` / `__retro_gh_status` / `_spool_extract_entries` を独立 helper（`aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh`）に分離
- 受け入れ基準: `.aidlc/cycles/v2.5.3/story-artifacts/user_stories.md` ストーリー 4 参照

#### コンテキストリセット後の再開コマンド

```text
/aidlc construction
```

または

```text
/aidlc:aidlc c
```

`automation_mode=semi_auto` のため、進行中Unit（なし）→ 実行可能Unit（003 / 004 / 並列可）→ semi_auto 番号順自動選択で Unit 003 が先に着手される想定。

## 再開時に読み込むファイル

コンパクション後やセッション再開時は、以下のコマンドを実行してください：

- `/aidlc construction` （または `/aidlc:aidlc c`）

セッション継続判定で Unit 001/002 完了状態が認識され、次のUnit選定に進む。

## 再開時に読み込むファイル

コンパクション後やセッション再開時は、以下のコマンドを実行してください：

- `/aidlc construction`

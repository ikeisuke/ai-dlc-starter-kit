# Construction Phase Unit 002 履歴

## Unit 概要

- **Unit**: 002 — retrospective-issue.sh の zsh source 互換性復元
- **関連 Issue**: #661（[Backlog] retrospective-issue.sh の zsh source 互換性問題（v2.5.4 Unit 004 OUT_OF_SCOPE））
- **担当**: AI-DLC エージェント
- **着手日**: 2026-05-08
- **完了日**: 2026-05-08

## 概要

`skills/aidlc/scripts/lib/retrospective-issue.sh:43` の SCRIPT_DIR 解決を v2.5.4 Unit 004（#659）で確立された `predecessor-issue.sh:31-40` の `ZSH_VERSION` 分岐パターンに置換し、zsh interactive shell からの source 経路で SCRIPT_DIR が空文字となるバグを解消。`tests/aidlc-helpers-zsh-source.bats:94-105` の zsh 経路 skip マーカー（`skip "OUT_OF_SCOPE: see backlog #661"`）を解除して bash / zsh 両 source 検証を通常実施に戻した。

## 変更ファイル一覧

| ファイル | 操作 | 概要 |
|---------|------|------|
| `skills/aidlc/scripts/lib/retrospective-issue.sh` | 改修（line 42-55 ブロック） | SCRIPT_DIR 解決を `if [[ -n "${ZSH_VERSION:-}" ]]; then ${(%):-%N}; else ${BASH_SOURCE[0]}; fi` 構造へ置換。`predecessor-issue.sh:31-40` 引用コメント・shellcheck disable・前提リファレンスを併記 |
| `tests/aidlc-helpers-zsh-source.bats` | 改修（ヘッダ line 1-9 / retrospective-issue.sh テスト line 94-112） | ヘッダコメントを Unit 002 解消反映に更新。retrospective-issue.sh テストの skip マーカー削除、独立契約 C1〜C4（status 0 / SCRIPT_DIR 非空 / 実在ディレクトリ / HELPER_LIB_DIR 一致）を bash / zsh 両経路で検証する形に書き換え |
| `.aidlc/cycles/v2.5.5/plans/unit-002-plan.md` | 新規作成 | Unit 002 計画（Round 1 指摘反映 + 独立契約 C1〜C4 + フォローアップ事項） |
| `.aidlc/cycles/v2.5.5/design-artifacts/domain-models/unit_002_retrospective_issue_zsh_source_compat_domain_model.md` | 新規作成 | ドメインモデル（ScriptDirResolver / 不変条件 / 分岐前提 P1・P2） |
| `.aidlc/cycles/v2.5.5/design-artifacts/logical-designs/unit_002_retrospective_issue_zsh_source_compat_logical_design.md` | 新規作成 | 論理設計（改修前後 pseudo / bats 構造 / 検証クエリ / 分岐判定の前提と非サポート挙動） |

## レビュー履歴

### 計画レビュー（reviewing-construction-plan）

| Round | 指摘件数 | 対応 |
|-------|---------|------|
| Round 1 | 2 件（低 2） | 全件修正対応（#1: フォローアップ事項として共通 helper 化を技術的負債記録 / #2: 独立契約 C1〜C4 を計画書に明文化） |
| Round 2 | 0 件 | 2R clean、auto_approved |

### 設計レビュー（reviewing-construction-design）

| Round | 指摘件数 | 対応 |
|-------|---------|------|
| Round 1 | 1 件（中） | 全件修正対応（#1: ZSH_VERSION 汚染シナリオの非サポート挙動を分岐前提として明文化、判定強化は predecessor-issue.sh 整合性のため別タスク化） |
| Round 2 | 0 件 | 2R clean、auto_approved |

### コードレビュー（reviewing-construction-code）

| Round | 指摘件数 | 対応 |
|-------|---------|------|
| Round 1 | 0 件 | 1R clean 特例、auto_approved |

### 統合レビュー（reviewing-construction-integration）

| Round | 指摘件数 | 対応 |
|-------|---------|------|
| Round 1 | 1 件（低） | 修正対応（#1: 本ファイル construction_unit02.md を作成） |
| Round 2 | （Round 2 で確認予定） | - |

## 検証結果

### テスト

- `bats tests/aidlc-helpers-zsh-source.bats`: 6 テストすべて PASS（bash + zsh 両経路で C1〜C4 検証）
  - `aidlc-paths.sh` source 動作確認 (PASS)
  - `aidlc-validate.sh` source 動作確認 (PASS)
  - `aidlc-gh.sh` source 動作確認 (PASS)
  - `aidlc-spool.sh` source 動作確認 (PASS)
  - `predecessor-issue.sh` source + SCRIPT_DIR (PASS)
  - `retrospective-issue.sh` source + SCRIPT_DIR (PASS) — 本 Unit 改修対象、zsh 経路の skip 解除後も PASS 維持
- bash 単独 source: `__RETRO_ISSUE_SCRIPT_DIR=<repo>/skills/aidlc/scripts/lib`
- zsh 単独 source: `__RETRO_ISSUE_SCRIPT_DIR=<repo>/skills/aidlc/scripts/lib`（本 Unit で新規担保）
- bash 構文チェック (`bash -n skills/aidlc/scripts/lib/retrospective-issue.sh`): OK

### 整合性検証

| 検証項目 | 結果 |
|---------|------|
| ZSH_VERSION 分岐の存在（line 47） | ✓ |
| zsh 用展開 `${(%):-%N}` の存在（line 50） | ✓ |
| 既存 BASH_SOURCE 残存（line 52、else ブロック） | ✓ |
| skip マーカー削除（tests/aidlc-helpers-zsh-source.bats） | ✓（"OUT_OF_SCOPE: see backlog #661" は削除済み） |
| ヘッダコメント DR-001 注記更新 | ✓（Unit 004 / Unit 002 併記） |

## フォローアップ事項（意図的技術的負債）

`predecessor-issue.sh` と `retrospective-issue.sh` で同一の `ZSH_VERSION` 分岐パターン（5 行ブロック）が 2 箇所に重複している。これは意図的に許容する技術的負債とし、以下の条件で共通化を検討する:

- **トリガー**: 同パターンを必要とする helper が 3 ファイル以上になる、または `${(%):-%N}` の挙動差で別バグが顕在化する
- **対応案**: `aidlc-paths.sh` に `__aidlc_resolve_script_dir()` 関数を追加し、各 helper は関数呼び出しに置換
- **スコープ**: 次サイクル以降の minor / refactor で対応候補
- **記録先**: 計画ファイル `unit-002-plan.md` § フォローアップ事項 + 本履歴ファイル

本 Unit 完了時点では Backlog Issue として起票しない（陳腐化リスク回避、トリガー発火時に再評価）。

## 分岐判定の前提と非サポート挙動

ドメインモデル §「分岐前提」を SoT として参照する:

- **前提 P1**: `ZSH_VERSION` は zsh が起動時に設定する変数であり、bash プロセスでは未設定（事実上の慣習）
- **前提 P2**: bash プロセスへの `ZSH_VERSION` 明示注入は正常運用外
- **汚染シナリオでの挙動**: 非サポート（`${(%):-%N}` の bash 評価エラーが source 失敗で顕在化）
- **判定強化検討**: `predecessor-issue.sh` 整合性のため別タスク化（共通 helper 化フォローアップと一体）

## 完了条件チェックリスト充足状況

| 区分 | 項目 | 状態 |
|------|------|------|
| 機能整合 | retrospective-issue.sh:43 周辺が ZSH_VERSION 分岐構造になっている | ✓（line 47-53） |
| 機能整合 | `__RETRO_ISSUE_SCRIPT_DIR` 変数名は変更されていない | ✓ |
| 機能整合 | predecessor-issue.sh:31-40 同等のコメント併記 | ✓（Unit 004 引用 + ZSH_VERSION 判定理由 + shellcheck disable + ドメインモデル参照） |
| テスト | skip "OUT_OF_SCOPE: see backlog #661" 削除 | ✓ |
| テスト | テスト名「(bash / zsh 両対応)」へ更新 | ✓ |
| テスト | 独立契約 C1〜C4 の bash 経路アサーション | ✓ |
| テスト | 独立契約 C1〜C4 の zsh 経路アサーション | ✓ |
| テスト | ヘッダコメント Unit 002 解消反映 | ✓ |
| テスト | bats 6 テスト全 PASS | ✓ |
| テスト | zsh 環境チェック分岐（既存 bats パターン踏襲） | ✓ |
| 履歴 | 本ファイル新規作成 | ✓ |
| 品質ゲート | AI レビュー 4 種類すべて 2R clean / 1R clean | ✓ |
| 品質ゲート | markdownlint | （完了処理ステップで実施） |

## 備考

- 計画 → 設計 → コード → 統合の各レビューで指摘を全件修正対応し最大 2R clean を達成。defer Issue 起票はなし
- 本 Unit は v2.5.4 Inception DR-001 で OUT_OF_SCOPE 化された対象を計画通りに解消
- `predecessor-issue.sh` パターンとの完全同型のため、汚染シナリオ耐性も同等

# Unit 002 計画: retrospective-issue.sh の zsh source 互換性復元

## 概要

`skills/aidlc/scripts/lib/retrospective-issue.sh:43` の `__RETRO_ISSUE_SCRIPT_DIR` 解決を、v2.5.4 Unit 004（#659）で確立された `predecessor-issue.sh` の `ZSH_VERSION` 分岐パターンに置換する。これにより zsh interactive shell からの `source` 経路で SCRIPT_DIR が空文字となるバグ（Issue #661）を解消し、`tests/aidlc-helpers-zsh-source.bats:94-105` の zsh 経路 skip マーカー（`skip "OUT_OF_SCOPE: see backlog #661"`）を解除して bash / zsh 両 source 検証を通常実施に戻す。

## 関連 Issue

- #661（[Backlog] retrospective-issue.sh の zsh source 互換性問題（v2.5.4 Unit 004 OUT_OF_SCOPE））
- 参考: v2.5.4 Unit 004（#659、`predecessor-issue.sh` で確立されたパターン）

## 責務分離原則

| レイヤ | 役割 | ファイル |
|--------|------|---------|
| 実装 SoT | `__RETRO_ISSUE_SCRIPT_DIR` の zsh / bash 両対応化（既存 API は変更しない） | `skills/aidlc/scripts/lib/retrospective-issue.sh:43` |
| テスト SoT | `retrospective-issue.sh` の独立契約（後述）を bash / zsh 両経路で検証する。既存 skip マーカー削除を含む | `tests/aidlc-helpers-zsh-source.bats:94-105` |
| 履歴 | 実装進捗・参考実装の引用記録 | `.aidlc/cycles/v2.5.5/history/construction_unit02.md` |

**ドリフト防止策**:

- v2.5.4 Unit 004 と同一の修正パターンを踏襲し、独自実装は避ける（実装の冗長性低減 + レビュー観点共通化）。`predecessor-issue.sh:31-40` は **参照実装** であり、本 Unit のテスト・実装の正当性根拠は次節「retrospective-issue.sh の独立契約」に置く

### retrospective-issue.sh の独立契約（Round 1 指摘 #2 対応）

bats テストは以下の独立契約を bash / zsh 両経路で検証する。`predecessor-issue.sh` テストとの構造的同型性は副次的な保守性（参照しやすさ）であり、検証要件の根拠ではない:

| 契約 ID | 内容 |
|--------|------|
| C1 | `source skills/aidlc/scripts/lib/retrospective-issue.sh` の終了ステータスは 0（多重 source ガード経路を含む） |
| C2 | source 後に `${__RETRO_ISSUE_SCRIPT_DIR}` が空文字でない（`-n "$output"`） |
| C3 | `${__RETRO_ISSUE_SCRIPT_DIR}` が実在するディレクトリ（`-d "$output"`） |
| C4 | `${__RETRO_ISSUE_SCRIPT_DIR}` が `${REPO_ROOT}/skills/aidlc/scripts/lib`（=`HELPER_LIB_DIR`）と一致 |

bash / zsh 両経路で C1〜C4 すべてを満たすことを必須要件とする。zsh 環境が CI 上で利用不可の場合は zsh 経路のみ skip（`skip "zsh not available"`）し、bash 経路は常時実行する（既存 bats のパターン踏襲）。

### フォローアップ事項（Round 1 指摘 #1 対応 / 意図的技術的負債）

本 Unit 完了後、`predecessor-issue.sh` と `retrospective-issue.sh` で同一の `ZSH_VERSION` 分岐パターン（5 行ブロック）が 2 箇所に重複する。これは意図的に許容する技術的負債とし、以下の条件で共通化を検討する:

- **トリガー**: 同パターンを必要とする helper が 3 ファイル以上になる、または `${(%):-%N}` の挙動差で別バグが顕在化する
- **対応案**: `aidlc-paths.sh` に `__aidlc_resolve_script_dir()` 関数を追加し、各 helper は関数呼び出しに置換
- **スコープ**: 次サイクル以降の minor / refactor で対応候補。本サイクル v2.5.5 では起票しない（陳腐化リスク回避、トリガー発火時に再評価）
- **記録先**: 本計画ファイル本セクション + Unit 002 完了履歴 `history/construction_unit02.md`

## 変更対象ファイル

| ファイル | 操作 | 概要 |
|---------|------|------|
| `skills/aidlc/scripts/lib/retrospective-issue.sh` | 改修（実装 SoT） | line 43 周辺の `__RETRO_ISSUE_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" ...)` を `predecessor-issue.sh:31-40` と同じ `if [[ -n "${ZSH_VERSION:-}" ]]; then ... ${(%):-%N} ...; else ... ${BASH_SOURCE[0]} ...; fi` 構造に置換。Unit 004 引用コメントを併記 |
| `tests/aidlc-helpers-zsh-source.bats` | 改修（テスト SoT） | line 94-105 の retrospective-issue.sh テストを predecessor-issue.sh テスト（line 74-92）と同じ bash / zsh 両対応構造に書き換え。skip マーカー削除、テスト名から「(bash 必須、zsh は OUT_OF_SCOPE)」を削除 |
| `tests/aidlc-helpers-zsh-source.bats:1-9`（ヘッダコメント） | 改修 | DR-001 OUT_OF_SCOPE 注記の更新（v2.5.5 Unit 002 で解消した旨を反映） |
| `.aidlc/cycles/v2.5.5/history/construction_unit02.md` | 新規作成 | Unit 002 の進捗履歴（変更ファイル / レビュー round / 検証結果） |

## 実装計画

### Phase 1（設計）

設計成果物として以下を作成する:

- ドメインモデル（`design-artifacts/domain-models/unit_002_retrospective_issue_zsh_source_compat_domain_model.md`）: `SCRIPT_DIR 解決ドメイン` の語彙整理（zsh / bash の source パス取得手段差・`ZSH_VERSION` 分岐の不変条件）
- 論理設計（`design-artifacts/logical-designs/unit_002_retrospective_issue_zsh_source_compat_logical_design.md`）: 改修前後の文言、`predecessor-issue.sh` パターンとの一致確認手順、bats テスト書き換え後の構造、検証クエリ

`depth_level=standard` のため Phase 1 はスキップしない。設計レビュー（`reviewing-construction-design`）を 5R 内で実施する。Unit 001 と異なり、本 Unit は「採用パターンが既に確立済み」のため、設計フェーズの判断点は最小限（採否比較不要）。

### Phase 2（実装）

実装順序:

1. `retrospective-issue.sh:43` 改修（`ZSH_VERSION` 分岐構造を採用。`predecessor-issue.sh:31-40` は参照実装として併記コメントで引用。変数名は `__RETRO_ISSUE_SCRIPT_DIR` を維持）
2. `tests/aidlc-helpers-zsh-source.bats:94-105` 改修（独立契約 C1〜C4 を bash / zsh 両経路で検証する形で書き換え。skip マーカー削除）
3. `tests/aidlc-helpers-zsh-source.bats:1-9` ヘッダコメント更新（DR-001 注記の OUT_OF_SCOPE 解消反映）
4. テスト実行（bash + zsh 両経路で C1〜C4 を検証）
5. AI レビュー（`reviewing-construction-code`）→ 統合レビュー（`reviewing-construction-integration`）
6. 履歴記録（変更ファイル / レビュー round / 検証結果 / 共通化フォローアップ事項）

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| zsh が CI 環境で未インストール | bats の既存パターン（`if command -v zsh >/dev/null 2>&1; then ...; else skip "zsh not available"; fi`）を維持。本 Unit は zsh 経路の skip マーカーは削除するが、zsh 環境チェック分岐は predecessor-issue.sh テストと同じ構造で残す |
| `${(%):-%N}` の bash パーサ評価失敗 | predecessor-issue.sh と同じく `ZSH_VERSION` 判定下でのみ評価される独立ブロックに分岐させる。bash パーサが直接当該行を評価する経路は発生しない |
| 既存パス（`__RETRO_ISSUE_SCRIPT_DIR` を参照する `source` 行 line 45-53）への副作用 | 修正は SCRIPT_DIR 解決部分のみで、変数名は `__RETRO_ISSUE_SCRIPT_DIR` のまま維持。下流参照は変更不要 |
| 他 helper（`aidlc-paths.sh` 等）への副作用 | OUT_OF_SCOPE（Unit 定義「境界」に明記）。修正対象は `retrospective-issue.sh` 1 ファイルに限定 |

## NFR

- **パフォーマンス**: shell 判定分岐 1 回追加（`if [[ -n "${ZSH_VERSION:-}" ]]`）のため計測対象外
- **セキュリティ**: 該当なし。SCRIPT_DIR 解決手段の差し替えで挙動変化なし
- **後方互換**: bash 経路は既存ロジック（`${BASH_SOURCE[0]}`）を維持し挙動不変。zsh 経路は新規対応で空文字 SCRIPT_DIR バグを解消

## 完了条件チェックリスト

### 機能整合

- [ ] `retrospective-issue.sh:43` 周辺が `if [[ -n "${ZSH_VERSION:-}" ]]; then ... ${(%):-%N} ...; else ... ${BASH_SOURCE[0]} ...; fi` 構造になっている
- [ ] `__RETRO_ISSUE_SCRIPT_DIR` 変数名は変更されていない（下流 source 行 line 45-53 への影響なし）
- [ ] `predecessor-issue.sh:31-40` と同等のコメント（Unit 004 引用 + ZSH_VERSION 判定理由 + shellcheck disable 指示）が併記されている

### テスト（独立契約 C1〜C4 ベース）

- [ ] `tests/aidlc-helpers-zsh-source.bats:94-105` から `skip "OUT_OF_SCOPE: see backlog #661"` が削除されている
- [ ] テスト名から「(bash 必須、zsh は OUT_OF_SCOPE)」が削除され、「(bash / zsh 両対応)」へ書き換えられている
- [ ] **C1**: bash / zsh 両経路で `source ... retrospective-issue.sh` の status が 0
- [ ] **C2**: bash / zsh 両経路で `${__RETRO_ISSUE_SCRIPT_DIR}` が空文字でない（`-n "$output"`）
- [ ] **C3**: bash / zsh 両経路で `${__RETRO_ISSUE_SCRIPT_DIR}` が実在ディレクトリ（`-d "$output"`）
- [ ] **C4**: bash / zsh 両経路で `${__RETRO_ISSUE_SCRIPT_DIR}` が `${HELPER_LIB_DIR}` と一致
- [ ] ヘッダコメント line 1-9 の DR-001 OUT_OF_SCOPE 注記が「v2.5.5 Unit 002 で解消」へ更新されている
- [ ] `bats tests/aidlc-helpers-zsh-source.bats` が PASS（既存テスト群 + 修正後の retrospective-issue.sh テスト）
- [ ] zsh 未インストール環境では zsh 経路のみ `skip "zsh not available"`（既存 bats パターン踏襲、bash 経路の C1〜C4 は常時検証）

### 履歴

- [ ] `.aidlc/cycles/v2.5.5/history/construction_unit02.md` が新規作成され、変更ファイル / レビュー round / 検証結果が含まれる

### 品質ゲート

- [ ] AI レビュー（`reviewing-construction-design` / `reviewing-construction-code` / `reviewing-construction-integration`）が完了条件（`is_completed()` 単一仕様）を満たす
- [ ] markdownlint（`markdown_lint=true`）が変更対象 markdown ファイルで pass する

## 見積もり

- 設計フェーズ: 0.1 日（パターン踏襲のため判断点最小）
- 実装フェーズ: 0.15 日（コード差分 + bats 書き換え + テスト実行 + レビュー）
- 合計: **0.25 日**（Unit 定義の見積もり「1 時間」と一致）

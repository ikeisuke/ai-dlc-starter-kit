# Unit 002 実装計画: operations-release.sh cmd_squash_712 への --cycle バリデーション導入

## 対象 Unit

- **Unit**: 002 - operations-release.sh cmd_squash_712 への --cycle バリデーション導入
- **関連 Issue**: #701
- **優先度**: High
- **depth_level**: standard（Phase 1 設計を実施）

## 背景・目的

`skills/aidlc/scripts/operations-release.sh` の `cmd_squash_712` は `--cycle` 引数を
`.aidlc/cycles/<cycle>/...` のパス解決（`__operations_release_progress_path` /
`__squash_712_check_history_clean`）に使用するが、引数全体に対する包括的なバリデーションが
存在しない。v2.6.2 Unit 003（#677）で `__squash_712_check_history_clean` 経路には最小限の
トラバーサル拒否（`*..*` / `/*` / 改行）が実装されているが、これは新規ガード経路に閉じた
部分対応であり、`cmd_squash_712` 全体は依然として未保護である。

本 Unit は既存の `validate_cycle`（`skills/aidlc/scripts/lib/validate.sh`）を `cmd_squash_712`
の起動時に適用し、パストラバーサル文字列・空白・制御文字・先頭スラッシュ等による参照先パスの
逸脱を入口で一括拒否する。

## スコープ

### 含まれるもの（責務）

- `operations-release.sh` に `lib/validate.sh` の source を追加（現状 source していない）。
  source は既存スクリプト（`write-history.sh` 等）の慣例どおりファイル全体を取り込むが、
  `operations-release.sh` から実際に**利用するのは `validate_cycle` のみ**とする。
  `validate.sh` は `emit_error` 等の汎用関数も公開するため、source 追加時点で
  `operations-release.sh` 既存関数（23 個）と `validate.sh` 公開関数（6 個）の名前衝突が
  ないことを確認する（現状調査では衝突なしを確認済み）
- `cmd_squash_712` 起動時、`--cycle` パース後・既存処理（squash_enabled 取得）前に
  `validate_cycle "$cycle"` で検証
- 不正値時は exit 1 + tab 区切り stderr `error\tsquash-712:invalid-cycle\t<value>` で停止
  （既存 `__squash_712_check_history_clean` のインライン拒否と同一のエラーフォーマットを踏襲）
- `cmd_squash_712` 配下の `--cycle` 利用経路（`__operations_release_progress_path` /
  `__squash_712_check_history_clean`）が検証後のパスを参照することを保証
- `__squash_712_check_history_clean` の既存インライン・トラバーサル拒否は**防御的に維持する**
  （`cmd_squash_712` 入口の `validate_cycle` と二重防御になるが、下位関数が単体で fail-closed を
  保つことを優先する。詳細は「実装方針」参照）
- 不正 cycle / 正常 cycle の両ケースをカバーする bats テスト追加

### 含まれないもの（境界）

- 新規バリデーションロジックの実装（既存 `validate_cycle` を再利用）
- `record-release-prep-commit` 等の他サブコマンドへの同種検証導入（Phase 1 設計時に
  intent.md「分離判定基準」(a)(b)(c) に照らして要否判断。本サイクル対象外と判断した場合は
  別 Issue 化し decisions.md に記録）
- `pr-ready` サブコマンドの `--cycle` 経路（本 Unit のスコープ外）

## 実装方針

### Phase 1: 設計

- **ドメインモデル**: `--cycle` 引数の検証ドメイン（valid / invalid 判定）と、
  `cmd_squash_712` の起動シーケンスにおける検証ポイントの位置づけを整理
- **論理設計**:
  - `source` 追加位置（`SCRIPT_DIR` 定義後）の確定
  - `validate_cycle` 呼び出し挿入位置の確定（`-z "$cycle"` チェック直後）
  - エラー出力フォーマットの確定（`error\tsquash-712:invalid-cycle\t<value>`）
  - 名前衝突確認手順の確定（`operations-release.sh` 既存関数と `validate.sh` 公開関数の
    名前突き合わせ。`declare -F` または grep ベース）
  - bats テストケース設計（不正 cycle: `..` 含む / 先頭スラッシュ / 空白 / 制御文字、
    正常 cycle: 従来どおり後続処理へ進む）

  **責務境界の確定方針（fixed）**: 既存 `__squash_712_check_history_clean` のインライン・
  トラバーサル拒否は **除去せず防御的に維持する**。`cmd_squash_712` 入口の `validate_cycle` は
  「サブコマンド入口での包括的入力検証」、`__squash_712_check_history_clean` 内のインライン拒否は
  「下位関数が単体で fail-closed を保つためのローカル不変条件チェック」であり、役割が異なる。
  二重防御のコストは小さく、将来 `__squash_712_check_history_clean` に別の呼び出し経路が
  追加された場合の防御漏れを防ぐ。この方針は Phase 1 で再判断せず、decisions.md に
  「採用済み方針」として記録する。

### Phase 2: 実装

1. `operations-release.sh` に `source "${SCRIPT_DIR}/lib/validate.sh"` を追加。
   追加前に既存関数と `validate.sh` 公開関数の名前衝突がないことを確認
2. `cmd_squash_712` に `validate_cycle` 検証を追加（不正値 → exit 1 + tab 区切り stderr）
3. `__squash_712_check_history_clean` のインライン拒否は防御的に維持（変更しない。
   「責務境界の確定方針」参照）
4. bats テスト追加（新規ファイル or 既存 `operations-release-squash712-*.bats` に追記、
   Phase 1 で決定）
5. 既存 bats テスト群の回帰確認

## 完了条件チェックリスト

### #701 受け入れ基準

- [x] `operations-release.sh` が `lib/validate.sh` を source している
- [x] `operations-release.sh` 既存関数と `validate.sh` 公開関数の名前衝突がないことを確認した
- [x] `cmd_squash_712` 起動時に `--cycle` 引数が `validate_cycle` で検証される
- [x] 不正 cycle 値で exit 1 + stderr `error\tsquash-712:invalid-cycle\t<value>` が出力される
- [x] 正常 cycle 値で従来どおり後続処理（squash_enabled 取得以降）に進む（回帰なし）
- [x] `cmd_squash_712` 配下の `--cycle` 利用経路が検証後のパスを参照する
- [x] `__squash_712_check_history_clean` のインライン拒否が防御的に維持されている（除去していない）
- [x] 不正 cycle / 正常 cycle の両ケースをカバーする bats テストが追加されている
- [x] 既存の `operations-release-squash712-*.bats` を含む bats テスト群が引き続き pass する

### 共通

- [x] markdownlint で新規エラー 0 件（ドキュメント変更がある場合）
- [x] AI レビュー（設計 / コード / 統合）が `review_mode=required` に従い実施されている
- [x] 他サブコマンドへの検証導入要否が intent.md「分離判定基準」に照らして判断され、
      decisions.md に記録されている

## リスク・考慮事項

- `operations-release.sh` は現状どの lib も source していないため、source 追加が
  既存サブコマンド（`pr-ready` / `record-release-prep-commit` / `merge-pr` 等）に
  副作用を持たないことを確認する。`validate.sh` はファイル先頭コメントで「トップレベルで
  実行されるコードはない」と明記されており関数定義のみ（副作用なし）。残るリスクは関数名の
  衝突のみで、現状調査では `operations-release.sh` 既存関数と衝突なしを確認済み
- 既存 `__squash_712_check_history_clean` のインライン拒否は防御的に維持する方針で確定済み
  （「実装方針 > 責務境界の確定方針」参照）。二重防御のコストは小さく、下位関数の
  fail-closed 維持を優先する
- `validate_cycle` の許可パターンは「1〜2 セグメントの汎用ラベル」であり、`cycle/v2.6.3` の
  ような 2 セグメント値も許可される。`cmd_squash_712` の `--cycle` に渡される値の実態
  （`v2.6.2` 形式）と整合することを確認する
- 全作業でコマンド置換（`$(...)` / backtick）を Bash ツール引数文字列に含めない（本リポジトリ規約）

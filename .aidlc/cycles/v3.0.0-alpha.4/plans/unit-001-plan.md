# 実装計画: Unit 001 — 共有 frontmatter parser ライブラリ集約 + conformance test（T1 + T2'）

- **サイクル**: v3.0.0-alpha.4
- **対象 Unit**: 001-shared-frontmatter-parser
- **関連 Issue**: #733（部分対応 / T1 + T2' / Relates）
- **depth_level**: standard（Phase 1 設計あり）
- **実装優先度**: High

## 1. 目的

`skills/aidlc-v3/scripts/` の frontmatter パース（スカラー抽出 / dependencies 配列パース / frontmatter ブロック抽出 + malformed guard）を `scripts/lib/` の単一共有ライブラリに集約し、3 consumer（validate / next / status）を移行する。あわせて受理/拒否境界を固定する conformance test suite を整備し、個別構造解釈を禁止する規約を文書化する。**純粋リファクタ + 規約追加**であり、既存の受理/拒否境界は変えない（#733 既知 malformed クラスのみ拒否 fixture として明示固定）。

## 2. 現状（調査結果サマリ）

- `skills/aidlc-v3/scripts/lib/` は**存在しない**。frontmatter パースは 3 consumer にインライン重複実装されている。
- 重複している実装クラス:
  - スカラー抽出: `read_scalar()`（validate, token-atom 厳格）/ `wi_scalar()`（next, 最小）/ `read_status_value()`（status, status 専用）
  - dependencies 配列: validate のインライン検証 / `wi_deps()`（next, fail-closed）
  - frontmatter ブロック抽出 + 閉じ `---` guard: 3 consumer に重複（awk ベース）
- enum 検証の差分は**実在**: validate=厳格（status/size/risk + token-atom + 重複キー検出 + assigned 型 + 依存実在確認）/ next=最小（信頼ベース）/ status=status 専用（status 行一意性ガード）。
- テストは自己完結型 bash ハーネス（`put_wi()` / `assert_rc` / `assert_out` / `assert_stderr_has`）。
- `state-*.sh`（JSON / jq）は**本 Unit の対象外**（#731 で state-validate.sh に集約済み）。整合確認・既存テスト維持のみ。

## 3. スコープ

### 含む（T1 + T2'）

- `skills/aidlc-v3/scripts/lib/frontmatter.sh` 新設（共有 parser API）。**frontmatter ブロック抽出 + body 抽出（`fm_split_file` / `fm_extract_body`）を含む**（validate の必須セクション検証が 2 番目の `---` 以降の body 抽出に依存しており、delimiter 解析を consumer に残すと規約違反になるため共有 API に含める。指摘3 反映）
- `work-item-validate.sh` / `work-item-next.sh` / `work-item-status.sh` の個別パース実装撤去 + 共有ライブラリ source 移行（**既存の受理/拒否挙動を保存**）
- 共有 parser API の責務境界 + 「個別 consumer での frontmatter 構造解釈禁止」規約の文書化（**§4.1 consumer 別 API マッピング表**を成果物化。指摘1 反映）
- `skills/aidlc-v3/scripts/tests/test-frontmatter-parser.sh` conformance suite（受理/拒否 fixture、**3 consumer 別の期待 RC マトリクス検証**。指摘2/5 反映）
- Unit 完了条件「新たな構造データ読取は共有 parser 使用 + conformance fixture 追加必須」の規約組み込み

### 含まない（境界）

- `state-*.sh`（JSON / jq）のパース再設計（整合確認・既存テスト維持のみ）
- 禁止パターンの CI 機械検出（Unit 002 / T4）
- cycle 解決ロジック（Unit 003 / T6）
- 受理/拒否境界の変更（純粋リファクタ。#733 既知 malformed のみ拒否側に固定）

## 4. 実装アプローチ

### Phase 1: 設計

1. **ドメインモデル**: parse 概念（FrontmatterBlock / Body / Scalar / DependencyList / RejectionReason）と責務境界（構造抽出・型/必須キー/範囲検証・拒否理由標準化）を定義。
2. **論理設計**: `frontmatter.sh` の公開 API 関数シグネチャ、**enum 検証は共有 API に含めず consumer 別 API マッピング（§4.1）で呼び出し側責務として確定**、result-out 関数の dynamic scope namespace 化（CLAUDE.md `_local_<fn>_<name>` 規約）、§4.1 consumer 別 API マッピング表、§4.2 namespace 設計方針を定義。

### 4.1 consumer 別 API マッピング表（Phase 1 で成果物化 / 指摘1 反映）

3 consumer は責務が異なる（validate=厳格 schema 検証 + 重複キー検出 + assigned 型 + 依存実在確認 / next=ファイル名由来 id + 最小抽出 + dependencies fail-closed / status=status 行一意性 + status 専用 enum）。**共有化するのは「構造解釈」（delimiter 解析・スカラー抽出・配列パース・malformed guard）に限定**し、consumer 固有の検証責務は consumer 側に残す。Phase 1 でこの境界を表として確定する（暫定方針）:

| 機能 | 帰属 | 備考 |
|------|------|------|
| frontmatter ブロック抽出 + 閉じ `---` guard | 共有 | `fm_extract_block` / malformed は fail-closed |
| body 抽出（2 番目の `---` 以降、本文 `---` で打ち切らない） | 共有 | `fm_split_file` / `fm_extract_body` |
| スカラー抽出（厳格 token-atom / 最小） | 共有 | enum 値の妥当性判定は含めない（抽出のみ） |
| dependencies 配列パース + 要素 token 検証 | 共有 | malformed は fail-closed（return 1） |
| 必須キー重複検出 | 共有（ヘルパ提供） | 呼び出し要否は consumer 判断 |
| enum 検証（status/size/risk 値の妥当性） | **consumer** | validate=全 enum / status=status のみ / next=検証なし |
| 依存実在確認（dep id が実 work item を指すか） | **consumer**（validate のみ） | parser の責務外 |
| status 行一意性・write 遷移・期待 status | **consumer**（status のみ） | parser の責務外 |
| エラーメッセージ文言・exit code | **consumer** | parser は拒否理由コードを返し、文言は consumer |

### 4.2 namespace 設計方針（指摘4 反映）

既存 3 consumer に `err()` / `in_list()` / `STATUS_ENUM`（validate・status 両方で `readonly` 宣言）等の共通名が実在し、共有ライブラリが同名定義すると `readonly` 再代入エラーや source 順依存が起きる。回避方針:

- 公開関数は `fm_` prefix、private 関数・変数は `_fm_` prefix、グローバル定数を定義する場合は `FM_` prefix に限定
- enum は caller から引数で渡す（共有ライブラリは `readonly STATUS_ENUM` 等のグローバル定数を持たない）か、`fm_*` namespaced ヘルパとして提供
- result-out 関数の作業用 local は CLAUDE.md `_local_fm_<fn>_<name>` 規約で namespace 化

### Phase 2: 実装

1. `lib/frontmatter.sh` を実装（既存の構造解釈ロジックを関数として抽出・統合。**enum 検証は共有ライブラリに持たせず consumer 側で実施**。共有は抽出・配列パース・malformed guard・拒否理由標準化に限定）。
2. 3 consumer を共有ライブラリ source に移行（インライン実装撤去、既存の差分挙動を保存）。
3. 規約文書化（共有 parser 境界 + 禁止規約 + Unit 完了条件）。
4. conformance test suite を実装（受理/拒否 fixture、**同一 fixture セット + consumer 別期待 RC マトリクス**、#733 既知 malformed の拒否固定）。
5. v3 全テスト実行 → 回帰緑を確認。

## 5. 完了条件チェックリスト

Unit 定義「責務」+ ストーリー受け入れ基準から抽出:

- [ ] `lib/frontmatter.sh` が新設され、スカラー抽出 / dependencies 配列パース / frontmatter ブロック抽出 + malformed guard / **body 抽出（`fm_split_file` / `fm_extract_body`）** / 拒否理由標準化の関数を公開している
- [ ] 公開 API は `fm_` prefix、private は `_fm_` prefix、定数は `FM_` prefix で namespace 化され、既存 consumer の `err` / `in_list` / `STATUS_ENUM` 等と衝突しない（指摘4）
- [ ] `work-item-validate.sh` / `work-item-next.sh` / `work-item-status.sh` が個別パース実装（`read_scalar` / `wi_scalar` / `read_status_value` / `wi_deps` / body 抽出 awk / frontmatter 抽出 awk）を撤去し、共有ライブラリを source している
- [ ] 共有ライブラリは enum 検証の要否を consumer 側責務に残し（§4.1 マッピング表）、3 consumer の既存受理/拒否挙動を保存している
- [ ] §4.1 consumer 別 API マッピング表（共有 vs consumer 責務境界）が設計成果物に含まれている（指摘1）
- [ ] 共有 parser API の責務境界 + 個別 consumer での frontmatter 構造解釈に `grep`/`sed`/`awk`/permissive `jq` を使うことを禁止する規約が文書化されている
- [ ] `state-*.sh`（JSON / jq 集約済み）は対象外であることが明記されている
- [ ] `skills/aidlc-v3/scripts/tests/test-frontmatter-parser.sh` conformance suite が自己完結型 bash ハーネス形式で追加され、受理ケース（quoted/unquoted id、enum 値、空 dependencies、複数要素 dependencies 等）と拒否ケース（閉じ `---` 不在、不正 enum、malformed 配列、片側引用符、#733 既知 malformed）の双方を fixture 固定している（指摘5: フルパス）
- [ ] conformance test は fixture ごとに **consumer 別の期待 RC（`validate_rc` / `next_rc` / `status_read_rc` / `status_write_rc`）マトリクス**で検証する。consumer 境界に従い期待値を固定する（指摘2 / R2 指摘1）:
  - **validate**: 構造/enum/必須キー/依存実在のいずれか違反で拒否（最も厳格）
  - **next**: id はファイル名由来のため frontmatter id の片側引用符等は素通り。dependencies 欠落/malformed は fail-closed で拒否。enum は種別ごとに挙動が異なる — `status` 不正は `pending`/`in_progress` と一致しないため候補外（exit 0）/ `size` 不正は検証せず選定時にそのまま出力（exit 0）/ `risk` は next が読まないため影響なし
  - **status (read/write)**: status 行に関係する fixture（閉じ `---` 不在 / status 行 0 or 複数 / malformed status 値 / bad status enum / write 時の expected mismatch）のみ拒否。id 片側引用符・dependencies 欠落/malformed・size/risk 不正は status の責務外で**拒否しない**（過剰検証拡張を避け純粋リファクタを維持）
- [ ] Unit 完了条件「新たに構造データを読む場合、共有 parser を使い conformance fixture にケース追加済み」が規約に組み込まれている
- [ ] （異常系）閉じ `---` 不在の malformed frontmatter は共有ライブラリが従来どおり拒否（exit 1）する
- [ ] v3 全テストが緑（既存回帰の維持。互換境界を変えない）
- [ ] dynamic scope namespace 化（`printf -v` result-out 関数は `_local_fm_<fn>_<name>` 規約）を遵守
- [ ] bash 3.2/4.0+ 互換 / `set -euo pipefail` を維持

## 6. リスクと留意点

- **互換崩れリスク**: 3 consumer の検証差分（厳格/最小/専用）を共有化で壊さないこと（enum 検証は共有ライブラリに持たせず consumer 責務に残す / §4.1）。→ conformance test の同一 fixture セット + consumer 別期待 RC マトリクスで保証。
- **dynamic scope shadowing**: `printf -v "$caller_var"` パターンの shadowing バグ（v2.6.2 実例）。→ result-out 関数の local namespace 化を必須化。
- **意図的拒否強化の範囲**: #733 既知 malformed クラスは拒否 fixture で固定。既存が取りこぼしていた場合のみ拒否側に倒す（それ以外の境界は不変）。

## 7. AI レビュー

- `review_mode=required`（tools=codex）。計画 / 設計 / コード / 統合の各承認前に AI レビューを実施（スキップ不可）。

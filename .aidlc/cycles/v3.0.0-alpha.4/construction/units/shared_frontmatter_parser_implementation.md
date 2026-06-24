# 実装記録: Unit 001 — 共有 frontmatter parser ライブラリ集約（T1 + T2'）

## 実装日時
2026-06-22 〜 2026-06-23（v3.0.0-alpha.4 Construction Phase）

## 作成ファイル

### ソースコード
- `skills/aidlc-v3/scripts/lib/frontmatter.sh` - 新設。共有 frontmatter parser（安全境界）。公開 API: `fm_has_closing_frontmatter` / `fm_extract_block`（fail-closed 内包）/ `fm_extract_body`（fail-closed 内包・c>=2 保存）/ `fm_scalar`（strict/loose）/ `fm_scalar_raw`（引用符非剥離・assigned 用）/ `fm_key_count` / `fm_deps`（fail-closed）。private `_fm_valid_key`（key 検証ハードニング）。`fm_`/`_fm_` namespace、グローバル定数なし、stdout 返却（result-out 不使用 = shadowing 原理回避）、bash 3.2 互換、規約コメント（個別 consumer 構造解釈禁止）。
- `skills/aidlc-v3/scripts/work-item-validate.sh` - 移行。`read_scalar` / frontmatter+body 抽出 awk / dependencies 配列パースを撤去し共有 parser へ委譲。enum 検証 / 必須キー一意性 / assigned 型 / 本文セクション / 依存実在 / expected_status は consumer 責務として残置。
- `skills/aidlc-v3/scripts/work-item-next.sh` - 移行。`wi_scalar` / `wi_deps` / 抽出 awk を撤去し共有 parser へ委譲。id ファイル名由来解決 / 依存解決 / resume 選定は残置（enum 非検証維持）。
- `skills/aidlc-v3/scripts/work-item-status.sh` - 移行。`has_closing_frontmatter` / `extract_frontmatter` / `read_status_value` を撤去し共有 parser へ委譲。status 行一意性（`fm_key_count`）/ status enum / 期待現在 status / atomic write は残置。非空ガードは consumer 側に残置。

### テスト
- `skills/aidlc-v3/scripts/tests/test-frontmatter-parser.sh` - 新設。conformance suite（T2'）。consumer 別 RC マトリクス（validate / next / status_read / status_write）で受理 #1/#2/#R3 + assigned quoted/bare、拒否 #3-#11 + assigned array、#733 意図的拒否強化セット #733-a/b/c を fixture 固定。全63 assertion。

### 設計ドキュメント
- `.aidlc/cycles/v3.0.0-alpha.4/design-artifacts/domain-models/unit_001_shared_frontmatter_parser_domain_model.md`
- `.aidlc/cycles/v3.0.0-alpha.4/design-artifacts/logical-designs/unit_001_shared_frontmatter_parser_logical_design.md`

## ビルド結果
成功（shell スクリプトのためビルドは静的検査）

```text
bash -n: 4 ファイル全て ok
shellcheck: 4 ファイル + テスト全てクリーン（rc=0）
```

## テスト結果
成功

- 実行テストスイート数: 6
- 成功: 6
- 失敗: 0

```text
test-frontmatter-parser.sh (新規 conformance) : All tests passed（63 assertion）
test-work-item-next.sh                        : All tests passed
test-develop-flow.sh                          : PASS=49 FAIL=0
test-define-flow.sh                           : All tests passed
test-state-scripts.sh                         : All tests passed
test-activation.sh                            : All tests passed
回帰なし（既存の受理/拒否境界を保存）
```

## コードレビュー結果
- [x] セキュリティ: OK（key 検証ハードニング `_fm_valid_key` 追加 / regex 注入防御 / 非破壊 read-only）
- [x] コーディング規約: OK（fm_ namespace / bash 3.2 互換 / shellcheck クリーン / CLAUDE.md result-out 規約は stdout 返却で原理回避）
- [x] エラーハンドリング: OK（fail-closed / `set -e` 有無両環境で安全 / return 1 シグナル + consumer 文言）
- [x] テストカバレッジ: OK（conformance 63 assertion + 既存 5 スイート緑）
- [x] ドキュメント: OK（lib 冒頭に責務境界 + 禁止規約 + Unit 完了条件を SoT 文書化）

## 技術的な決定事項
- **stdout 返却方式の採用**: 既存全関数が stdout 返却であり、`$()` 捕捉が subshell のため dynamic scope shadowing を原理回避。result-out（printf -v）は導入せず。
- **extract API の fail-closed 内包**: `fm_extract_block`/`fm_extract_body` が閉じ `---` 不在時に return 1 する（安全境界として extract 単体で partial parse を防ぐ）。
- **enum 検証は consumer 責務**: 共有ライブラリは enum 値リスト（`STATUS_ENUM` 等）を持たず、各 consumer が `readonly` 保持（namespace 二重宣言回避）。`in_list` も consumer 維持（汎用 util を frontmatter.sh に入れない）。
- **#733 拒否強化の扱い**: 既知 malformed クラスは alpha.3 premerge（R3-R7）で既に拒否化済みであり、conformance で回帰固定。新たな取りこぼしは観測されず追加強化は不要（before=after=拒否）。consumer が読まない構造は責務どおり拒否しない（status は deps malformed を拒否しない等）。
- **key 検証ハードニング**: 公開 API の key 引数を `^[A-Za-z_][A-Za-z0-9_]*$` に制限（将来の外部入力 key による regex/sed 注入防御）。現 consumer は固定キーのみのため挙動不変。

## 課題・改善点
- 禁止パターンの CI 機械検出は Unit 002（T4）で実装予定。本 Unit は規約の文書化（lib header SoT）まで。
- cycle 解決回帰テストは Unit 003（T6）。

## 状態
**完了**

## 備考
純粋リファクタ + 規約追加 + conformance test。既存の受理/拒否境界を完全保存（conformance の互換保存セット #1-#11 で「移行前実挙動==移行後」を固定）。Self-Healing: shellcheck SC1091（source 非追跡 info）を `disable=SC1091` で解消（attempt 1 / recoverable）。

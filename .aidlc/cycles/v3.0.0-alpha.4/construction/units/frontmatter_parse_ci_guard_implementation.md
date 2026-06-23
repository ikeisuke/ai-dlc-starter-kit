# 実装記録: Unit 002 — 禁止パースパターンの CI 機械検出（T4）

## 実装日時
2026-06-23

## 作成ファイル

### ソースコード
- `bin/check-frontmatter-parse-guard.sh` - frontmatter 構造解釈の禁止パターン（生 grep/sed/awk/permissive jq）検出スクリプト。トークンベース検出 + 論理コマンド単位スキャン（strip_comment lexer / 継続行連結）+ 限定 allow マーカー。終了コード 0/1/2。opt-in シグナル（走査対象不在で exit 0）。
- `skills/aidlc-v3/scripts/work-item-status.sh` - atomic write awk に allow マーカー 1 行を追加（コメントのみ / 実行挙動不変）。
- `.github/workflows/skill-reference-check.yml` - 既存単一ジョブ `skill-reference-check` に検出 step + テスト step を追加、`PATHS_REGEX` に本体 + テストパスを追加（別ジョブ化しない）。

### テスト
- `bin/tests/check-frontmatter-parse-guard.sh` - 自己完結型 bash conformance テスト（33 アサート / T-01〜T-22b）。合格 fixture（C1/C2/C3/B/heredoc）非検出・違反 fixture（①〜⑤/変数経由/複数行/関数経由/汎用キー/permissive jq）全検出・allow マーカー統制・opt-in skip・システムエラー・stale 検出・リポジトリ全体 marker 集合固定。

### 設計ドキュメント
- `.aidlc/cycles/v3.0.0-alpha.4/design-artifacts/domain-models/unit_002_frontmatter_parse_ci_guard_domain_model.md`
- `.aidlc/cycles/v3.0.0-alpha.4/design-artifacts/logical-designs/unit_002_frontmatter_parse_ci_guard_logical_design.md`

## ビルド結果
成功（bash 構文チェック `bash -n` OK / shellcheck -S warning OK）

## テスト結果
成功

- 実行テスト数: 43（conformance / T-01〜T-25e）+ 6（v3 全テスト回帰）+ 3（既存 check スクリプト回帰）
- 成功: 全件
- 失敗: 0

```text
check-frontmatter-parse-guard conformance: PASS=43 FAIL=0
実リポジトリ走査（skills/aidlc-v3/scripts）: no violations, 7 file(s) checked, exit 0
v3 全テスト: 6/6 PASS / 既存 check スクリプト: 3/3 PASS（回帰なし）
```

統合レビュー（5R）で継続判定をスタックベース字句解析（unit_incomplete: 引用符状態を追跡し `$()` ネスト・引用符内括弧を正しく処理）に置換、allow marker 除外を awk atomic write idiom（全行 passthrough + key 書き換えシグネチャ）に厳密化。fixture を T-25e まで拡張。

## コードレビュー結果
- [x] セキュリティ: OK（ローカル CI ガード / NW・認証系 N/A / mktemp + trap cleanup / サンドボックス安全削除確認）
- [x] コーディング規約: OK（既存 bin/check-*.sh 様式準拠 / set -euo pipefail / bash 3.2 互換 / shellcheck warning クリーン）
- [x] エラーハンドリング: OK（終了コード 0/1/2 / find 失敗時 exit 2 / git repo 外 exit 2）
- [x] テストカバレッジ: OK（33 アサート / 合格・違反・境界・システムエラー・stale）
- [x] ドキュメント: OK（設計に実装精緻化を反映 / レビューサマリ Set 1,2）

## 技術的な決定事項
- **検出アルゴリズム = 候補 C（トークン検出 + 限定 allow マーカー）**: 既知 frontmatter キー + 汎用キー（frontmatter 文脈シグナル付き）+ `---` delimiter を参照する生 grep/sed/awk と frontmatter テキストへの permissive jq を検出。C1（`^##` markdown 見出し）/ B（`.json` への jq）/ C3（`tr`）は自然に除外。
- **論理コマンド単位スキャン**: strip_comment 簡易 lexer でクォート外コメントを除去（apostrophe パリティ崩れ防止）、backslash/pipe 継続・awk/sed/jq の単一引用符プログラムを連結。変数経由・複数行・関数経由の取りこぼしを防止（R2 必須）。
- **C2（status.sh atomic write awk）の扱い**: Unit 001 が consumer 責務と明示した atomic write のため、限定 allow マーカー（reason/issue/ref 必須 / 構造解釈 READ には付与不可 / stale 検出 = marker 除去で違反再現）で除外。
- **opt-in シグナル**: 検出スクリプトは consumer 非配布の bin/ ツール。走査対象 `skills/aidlc-v3/scripts/` 不在で exit 0。starter kit 判定分岐を埋めない（CLAUDE.md ドッグフーディング原則）。
- **CI**: 既存単一ジョブへの step 追加（別ジョブ化しない / Detect skip・checkout・permissions 共有）。`PATHS_REGEX` に本体 + テストパス追加。
- **squash internal_ci_checks 非追加**: CI で担保されるため二重化を避ける（設計 §4.3）。

## 課題・改善点
- 検出は heuristic（静的 lexer）であり、極端に難読化された shell（深い `$()` ネストの複数行・複雑な here-string）は best-effort。現行の v3 consumer・想定逸脱パターンは網羅。将来必要なら追加 fixture で拡張。
- allow マーカーは現行 1 件（status.sh）。新規追加時は T-21（集合固定）/ T-17（stale）がレビューゲートで検出。

## 状態
**完了**

## 備考
- 関連 Issue: #733（部分対応 / T4 のみ / Relates、Closes ではない）。
- AI レビュー: 計画（3R）/ 設計（5R）/ コード（5R）を codex で実施、全 resolved。統合レビューは後続。

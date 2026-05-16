# 論理設計: AI エージェント Bash 実行の安全規約整備

## 概要

Issue #706（result-out 関数の local 命名規約整備 + path-guard.sh 予防リファクタ）と Issue #703（codex exec の `</dev/null` 必須運用の明文化）について、具体的な編集対象ファイル・変更箇所・命名規則・検証手段を確定する。

**重要**: この論理設計では**コードは書かず**、変更箇所とインターフェースの定義のみを行う。具体的なコード変更は Phase 2（コード生成ステップ）で作成する。

## アーキテクチャパターン

- **ドキュメント SoT パターン**: 規範文は単一の正本に置き、他ドキュメントは正本への参照 + 最小要約のみを持つ。#706 と #703 で正本が異なる（適用対象が別レイヤ）
- **正本 → 同期コピー伝播パターン**: reviewing-common-base は正本 1 箇所を編集し、`bin/sync-reviewing-common.sh` で 9 コピーへ機械伝播する
- **命名規約による予防パターン**: dynamic scope shadowing は静的解析（shellcheck）で捕捉できないため、命名規約 + 予防リファクタで構造的に防ぐ

## コンポーネント構成

### 変更対象ファイル一覧

```text
#706 規約整備 + 予防リファクタ
├── CLAUDE.md                                         （正本: 命名規約サブセクション追記）
├── skills/aidlc/steps/common/bash-tool-safety.md      （参照: 実装例・運用補助のみ）
└── skills/aidlc-migrate/scripts/lib/path-guard.sh     （予防リファクタ: result-out 関数群）

#703 codex stdin 待ちガード明文化
├── skills/reviewing-common/reviewing-common-base.md   （正本: コマンド例修正 + 新規セクション）
├── skills/reviewing-*/references/reviewing-common-base.md  （9 コピー: 同期スクリプト経由で伝播）
├── CLAUDE.md                                         （参照: 横断ルール簡潔追記）
└── AGENTS.md                                         （参照: 横断ルール簡潔追記）
```

## #706: result-out 関数の local 命名規約

### 規約本文（正本: CLAUDE.md）

`CLAUDE.md`「AI エージェント Bash ツール経由の安全パターン」セクション内に新規サブセクション「printf -v 系 result-out 関数の local 命名規約」を追加する。規約本文の骨子（Issue #706 推奨文に準拠）:

- **対象**: 関数引数で結果書き込み先変数名を受け取り `printf -v "$result_var"` で書き込む関数（result-out 関数）
- **規約**: 関数内部の作業用 local 宣言を必ず関数固有プレフィックス `_local_<関数省略名>_<名>` で namespace 化する。`_result_var` / `_input` / `_base` 等の標準パラメータバインディングは慣例名のまま許容する
- **理由**: caller と同名 local を宣言すると bash dynamic scope により `printf -v` が内部 local を書き換え、caller 変数が空のまま残る致命的バグを引き起こす（v2.6.2 CI 停止の原因 / da212aea で個別修正済）
- **検出困難性**: shellcheck SC2030/SC2031 は本クラスを捕捉しないため、本規約が主防御線

`bash-tool-safety.md` には実装例・運用補助（before/after スニペット等）のみを置き、冒頭で「規約本文の正本は CLAUDE.md 当該節」と参照を明示する（規範文の重複掲載をしない）。

### path-guard.sh 予防リファクタ: 内部 local リネーム表

`skills/aidlc-migrate/scripts/lib/path-guard.sh` の result-out 関数および result-out 関数の caller について、内部の作業用 local を namespace 統一する。**外部公開関数シグネチャ（引数の順序・意味）は不変**。

| 関数 | 種別 | 関数省略名 | リネーム対象 internal local | リネーム後 |
|------|------|-----------|---------------------------|-----------|
| `_aidlc_migrate_path_guard_realpath_m_into` | result-out | `m` | （`_resolved` → `_local_m_resolved` は da212aea で適用済み） | 変更なし（docstring メモは既存 NOTE を規約参照に整える） |
| `_aidlc_migrate_path_guard_realpath_fallback_into` | result-out | `fb` | `_candidate`, `_probe`, `_tail`, `_segment`, `_resolved_parent`, `_normalized`, `_rest` | `_local_fb_<名>` |
| `_aidlc_migrate_realpath` | result-out（公開 shim） | `rp` | `_abs_input` | `_local_rp_abs_input` |
| `_aidlc_migrate_path_guard_normalize_logical_only` | result-out | `nlo` | `_candidate`, `_normalized`, `_rest`, `_segment` | `_local_nlo_<名>` |
| `_aidlc_migrate_path_guard_init` | result-out の caller（公開） | `init` | `_resolved`（`_aidlc_migrate_realpath` へ渡す結果受け取り local） | `_local_init_resolved` |
| `_aidlc_migrate_validate_path` | result-out の caller（公開） | `vp` | `_resolved`, `_root`, `_logical_only` | `_local_vp_<名>` |

**スコープ外（リネームしない）**:

- 標準パラメータバインディング `_result_var` / `_input` / `_base` / `_raw_path` / `_field_name` / `_script_id`（慣例名のまま、関数間で一貫しており shadowing リスクなし）
- `_aidlc_migrate_path_guard_emit_error`（result-out でない / stderr 出力のみ）
- `_aidlc_migrate_path_guard_detect_realpath_m`（result-out でない / グローバル変数へ書き込み）
- `_aidlc_migrate_path_guard_has_parent_segment`（result-out でない / 終了コードで結果を返す、result-out 関数を呼ばない）

### docstring メモ

リネーム対象の各関数（`fb` / `rp` / `nlo` / `init` / `vp`）のヘッダコメントに、result-out 関数（または caller）のため内部 local の namespace 化が必須である旨を 1〜2 行で追記する。`m` 関数は既存 NOTE コメントがあるため、規約名（CLAUDE.md 正本）への参照に整える程度に留める。

### リネーム時の機械的整合性

各関数のリネームは「宣言（`local`）+ 当該関数スコープ内の全参照箇所」を 1:1 で置換する。関数スコープを跨がないため、関数単位で完結する。`printf -v "$_result_var"` の書き込み先は `_result_var`（パラメータ）のまま不変。

## #703: codex exec の stdin 待ちガード

### 正本（reviewing-common-base.md）の変更

`skills/reviewing-common/reviewing-common-base.md` を編集する（正本のみ編集、コピーは同期スクリプトで伝播）。

| 箇所 | 現状 | 変更後 |
|------|------|--------|
| Codex 実行コマンド例（「実行コマンド > Codex」） | `codex exec -s read-only -C . "<レビュー指示>"` | 末尾に `</dev/null` を追加 |
| セッション継続コマンド例（「セッション継続 > Codex」） | `codex exec resume <session-id> "<指示>"` | 末尾に `</dev/null` を追加 |
| ファイル末尾 | （なし） | 新規セクション「stdin 待ちガードルール」を追加 |

**新規セクション「stdin 待ちガードルール」の骨子**（Issue #703 推奨文に準拠）:

- 非対話 subprocess 環境（Claude Code Bash ツール / hooks / CI 等）で `codex exec` / `codex exec resume` を実行する際は、positional 引数で prompt を渡していても stdin が EOF にならない限り `Reading additional input from stdin...` で待ち続ける（codex-cli の設計）
- 必須要件: 非対話環境では `</dev/null` で stdin を閉じる（または stdin にファイルをリダイレクトする）
- 短い prompt では偶然動作することがあるが再現性は prompt 長依存。根本原因は同一のため常に `</dev/null` を付与する
- 本セクションが codex 非対話実行運用の正本（SoT）

### 参照ドキュメントの横断ルール追記

正本ではなく参照として、簡潔な横断ルール + 正本参照を追記する（規範文の重複掲載なし）。

| ファイル | 追記先 | 追記内容 |
|---------|--------|---------|
| `CLAUDE.md` | 「AI エージェント Bash ツール経由の安全パターン」セクション内（file-based 経路の参考表の近傍） | 「`codex exec` / `codex exec resume` は非対話 subprocess 環境で `</dev/null` 必須」の 1 行ルール + 詳細は reviewing-common-base 参照 |
| `AGENTS.md` | 「Bash ツール経由の安全パターン」セクションの「最低限守るべき」リスト | 「`codex exec` 系コマンドは非対話環境で `</dev/null` を付与する」の 1 項目追加 + 詳細は reviewing-common-base 参照 |

### 同期伝播の契約

| 項目 | 内容 |
|------|------|
| 入力（正本） | `skills/reviewing-common/reviewing-common-base.md` |
| 出力（コピー先集合） | `skills/reviewing-construction-code` / `reviewing-construction-design` / `reviewing-construction-integration` / `reviewing-construction-plan` / `reviewing-inception-intent` / `reviewing-inception-stories` / `reviewing-inception-units` / `reviewing-operations-deploy` / `reviewing-operations-premerge` の各 `references/reviewing-common-base.md`（計 9 ファイル） |
| 同期機構 | `bin/sync-reviewing-common.sh`（正本を全コピーへ cp）。コピー先を手動編集しない |
| 検証 | `bin/sync-reviewing-common.sh --verify` で正本と全 9 コピーの一致を検証（exit 0 = 一致）。**注: ドメインモデルの [Answer] のとおり、同期 verify を実行する CI ジョブは存在しないため、検証はローカル/手動実行で行う** |

## スクリプトインターフェース設計

### bin/sync-reviewing-common.sh（既存 / 変更なし）

本 Unit では同期スクリプト自体を変更しない。既存インターフェースを利用するのみ。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| （なし） | 任意 | 正本を全 9 コピーへ同期（sync モード） |
| `--dry-run` | 任意 | 更新対象を表示のみ（コピーしない） |
| `--verify` | 任意 | 正本と全コピーの一致を検証 |

#### 終了コード

- `0`: 成功（sync 完了 / verify 一致）
- `1`: 不一致・コピー失敗・正本不在
- `2`: 引数エラー

## 処理フロー概要

### Phase 2 実装の処理フロー

1. **#706 規約追記**: `CLAUDE.md` に命名規約サブセクションを追記 → `bash-tool-safety.md` に実装例 + 正本参照を追記
2. **#706 予防リファクタ**: `path-guard.sh` の 6 関数の内部 local をリネーム表に従い namespace 統一 + docstring メモ追記
3. **#706 回帰確認**: `tests/migration` の既存 bats 49 件を実行し全 pass を確認
4. **#703 正本修正**: `reviewing-common-base.md`（正本）のコマンド例 2 箇所に `</dev/null` 追加 + 「stdin 待ちガードルール」セクション新設
5. **#703 横断ルール**: `CLAUDE.md` / `AGENTS.md` に横断ルール + 正本参照を追記
6. **#703 同期伝播**: `bin/sync-reviewing-common.sh` で 9 コピーへ伝播 → `--verify` で一致確認
7. **共通**: markdownlint 実行で新規エラー 0 件を確認

**関与するコンポーネント**: `CLAUDE.md`, `AGENTS.md`, `bash-tool-safety.md`, `path-guard.sh`, `reviewing-common-base.md`（正本 + 9 コピー）, `bin/sync-reviewing-common.sh`, `tests/migration` bats 群

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: 性能影響なし（Unit 定義 NFR）
- **対応策**: 規約・ドキュメント追記および内部 local リネームのみ。実行時挙動は等価

### セキュリティ
- **要件**: dynamic scope shadowing による result-out 関数の致命的バグの再発防止（Unit 定義 NFR）
- **対応策**: 命名規約の SoT 明文化 + path-guard.sh 全 result-out 関数への予防適用。caller 同名 local による `printf -v` 書き込み先逸脱を構造的に排除

### スケーラビリティ
- **要件**: 規約は配布物 baseline として全 consumer プロジェクトに適用される（Unit 定義 NFR）
- **対応策**: 規約本文を CLAUDE.md（配布物 baseline）の SoT セクションに置く

### 可用性
- **要件**: 既存挙動の回帰がないこと
- **対応策**: `path-guard.sh` の外部公開シグネチャ不変 + `tests/migration` bats 49 件の回帰確認。reviewing-common-base は正本のみ編集し同期 verify で一致保証

## 実装上の注意事項

- **path-guard.sh のリネーム**: 関数スコープ内で「宣言 + 全参照」を漏れなく 1:1 置換する。リネーム漏れがあると未定義変数（`set -u` 環境では即エラー）またはロジック不整合になるため、関数単位で diff 確認する
- **`_aidlc_migrate_path_guard_realpath_fallback_into` の `_segment`**: 同名 local が `while` ループ内で使われる。宣言は関数冒頭付近の `local _segment=""`。リネーム時はループ内参照も含めて置換する
- **reviewing-common-base は正本のみ編集**: 9 コピーを直接編集しない。編集後は必ず `bin/sync-reviewing-common.sh` で伝播し `--verify` で確認する
- **SoT 規律**: #706 は CLAUDE.md が正本、#703 は reviewing-common-base が正本。CLAUDE.md / AGENTS.md / bash-tool-safety.md の追記は規範文の重複でなく「正本参照 + 最小要約」に留める
- **コマンド置換禁止**: 全作業で Bash ツール引数文字列にコマンド置換（`$(...)` / backtick）を含めない（本リポジトリ規約）

## 不明点と質問（設計中に記録）

[Question] #706 規約の正本は CLAUDE.md と bash-tool-safety.md のどちらか？
[Answer] CLAUDE.md「AI エージェント Bash ツール経由の安全パターン」セクション。既存構造で同セクションが「規約本文の Single Source of Truth」と自己宣言しており、`bash-tool-safety.md` は「詳細運用ガイド」と位置付け済みのため、これに整合させる。

[Question] path-guard.sh の `_aidlc_migrate_path_guard_has_parent_segment` / `_emit_error` / `_detect_realpath_m` も namespace 化対象か？
[Answer] 対象外。これらは result-out 関数（`printf -v "$result_var"` で呼出側へ書き込む関数）でも result-out 関数の caller でもないため、#706 受け入れ基準「result-out 関数すべて」のスコープに含まれない。

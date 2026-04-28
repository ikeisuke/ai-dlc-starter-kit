# Unit 004 実装計画: markdownlint PostToolUse hook 追加と Operations §7.5 削除（#609）

## 対象

- Unit 定義: `.aidlc/cycles/v2.4.3/story-artifacts/units/004-markdownlint-hook-and-ops75-removal.md`
- 対象 Issue: #609（Closes 対象。サイクル PR でクローズ）
- 主対象ファイル:
  - `.claude/settings.json`（PostToolUse hook 追加）
  - `bin/check-markdownlint.sh`（新規 hook スクリプト、命名は本計画で確定）
  - `skills/aidlc/steps/operations/operations-release.md`（§7.5 削除）
  - `skills/aidlc/steps/operations/02-deploy.md`（§7.5 サブステップ列挙削除）
  - `skills/aidlc/scripts/operations-release.sh`（`lint` サブコマンド削除）

## スコープ

Unit 定義「責務」と Issue #609「対応方針候補1（PostToolUse hook 全面採用）」に整合させる:

### A. hook 追加

- `.claude/settings.json` の `hooks.PostToolUse` に `matcher: "Edit|Write"` の hook を追加（既存 `matcher: "Write"` の `check-utf8-corruption.sh` とは独立した別エントリとして並列追加）
- 新規 hook スクリプト `bin/check-markdownlint.sh` を実装:
  - **入力**: PostToolUse の JSON（stdin）
  - **対象判定**: `tool_input.file_path` が `*.md` の場合のみ実行（拡張子で早期 return）
  - **依存ツール**: `markdownlint-cli2` を `command -v` で検出。未インストール時は静かにスキップ（exit 0）
  - **存在しないファイル / 1MB 超**: スキップ（既存 `check-utf8-corruption.sh` と同方針）
  - **違反検出時**: stderr に警告メッセージ表示。exit code は **常に 0**（編集をブロックしない方針、既存 hook と同じ）
  - **既存 `check-utf8-corruption.sh` との独立動作**: matcher が異なる（`Write` 単独 vs `Edit|Write`）ため、PostToolUse 配列の別エントリとして登録、相互依存なし

### B. Operations §7.5 削除

- `skills/aidlc/steps/operations/operations-release.md`:
  - L23 の見出し `## 7.2〜7.6 CHANGELOG / README / 履歴 / lint / progress` から `lint /` を削除（→ `## 7.2〜7.6 CHANGELOG / README / 履歴 / progress`）
  - L28 の bullet `operations-release.sh lint --cycle {{CYCLE}}（...）` を削除
  - L63 の bullet `markdownlint で修正したその他ファイル（§7.5 で markdownlint:auto-fix が発生した場合のみ）` を削除
  - **サブステップ番号は §7.6 / §7.7 / §7.8 / §7.9〜7.11 / §7.12 / §7.13 のまま維持**（外部参照断絶を避けるため renumber しない。§7.5 は欠番として gap 維持）
- `skills/aidlc/steps/operations/02-deploy.md`:
  - L183 のサブステップ列挙 `5. 7.5 Markdownlint実行` を削除
  - 列挙内の連番（1〜13）を残った 12 項目に振り直す（7.X 番号は維持し、ordinal のみ詰める）

### C. operations-release.sh `lint` サブコマンド削除

- `skills/aidlc/scripts/operations-release.sh` から以下を削除:
  - ファイル冒頭コメント L10 の `lint  ステップ 7.5 - run-markdownlint.sh 実行` 行
  - `print_help` 内の `lint` 行（L44）
  - `print_help_lint()` 関数本体（L81-L95）
  - `cmd_lint()` 関数本体（L314-L348）
  - `main()` ディスパッチャの `lint) cmd_lint "$@"` ケース（L695-L697）
- **`run-markdownlint.sh` 本体は削除しない**（直接呼び出しでの利用余地を残す。`scripts/operations-release.sh lint` ラッパー経由のみ廃止）

### スコープ外（Unit 定義「境界」由来）

- CI の `pr-check.yml` `markdown-lint` job（必須 Check として継続）
- markdownlint ルール変更（`.markdownlint.json`）
- 他 lint ツール（shellcheck / yamllint 等）の hook 化
- PreToolUse hook 化
- 過去サイクル（`.aidlc/cycles/v*/history/`）の §7.5 / `operations-release.sh lint` 言及（履歴改変はしない）
- `run-markdownlint.sh` 本体削除（本 Unit のスコープは hook 追加 + ラッパーサブコマンド削除のみ）

## 実装方針

### Phase 1（設計）

#### ドメインモデル設計

markdownlint 検証パイプラインの概念モデルを以下で整理する（小規模）:

- エンティティ:
  - `EditEvent`（Edit / Write ツール実行の発生イベント）
    - 属性: `tool_name` ∈ {Edit, Write}, `file_path`(string)
  - `MarkdownLintHook`（PostToolUse の hook プロセス）
    - 振る舞い: `EditEvent` を受けて拡張子判定 → `markdownlint-cli2` 実行可否判定 → 実行 or スキップ
  - `LintExecutionContext`（実行環境の前提）
    - 属性: `extension`(`.md` / 他), `tool_available`(bool), `file_size`(bytes), `file_exists`(bool)
- ルール:
  - 不変条件1: `extension != .md` の入力では markdownlint を呼ばない（早期 return）
  - 不変条件2: `tool_available=false` の場合はスキップし exit 0
  - 不変条件3: `file_exists=false` または `file_size > 1MB` の場合はスキップ
  - 不変条件4: 違反検出時も exit 0（編集ブロック禁止、警告のみ）
- イベント:
  - `MarkdownLintWarningEmitted`（違反検出 → stderr 警告）
  - `MarkdownLintSkipped`（拡張子不一致・ツール不在・大ファイル等によるスキップ）

#### 論理設計

1. **`bin/check-markdownlint.sh` の I/O 契約**:
   - 入力: stdin の JSON（PostToolUse 仕様）
     ```json
     { "tool_name": "Edit"|"Write", "tool_input": { "file_path": "path/to/file" } }
     ```
   - 出力: stdout は空、stderr に警告（違反時 + jq 不在時）
   - 終了コード: 常に 0（warn-only）
   - 依存コマンド: `jq` / `markdownlint-cli2`（いずれも `command -v` で検出）
   - **依存ツール未インストール時の方針【明示・既存 hook 踏襲】**:
     - `jq` 未インストール時: stderr に `⚠ check-markdownlint: jq が見つかりません。hookが動作不能です。` を出力して exit 0（既存 `bin/check-utf8-corruption.sh` の `for cmd in jq file grep` ループと同方針。hook 機能不全をユーザー / エージェントに通知する責務）
     - `markdownlint-cli2` 未インストール時: 出力なしで exit 0（Issue #609「未インストール時はスキップ」「任意ツール扱い」の方針に従う差分。任意ツール未インストールは正常状態として扱う）

2. **`bin/check-markdownlint.sh` の処理フロー**:
   ```text
   1. command -v jq → 不在なら stderr に「⚠ check-markdownlint: jq が見つかりません」警告を出して exit 0（既存 hook 踏襲、hook 機能不全通知）
   2. jq で tool_name 抽出 → "Edit" / "Write" 以外なら exit 0（出力なし）
   3. tool_input.file_path 抽出 → 空 or 存在しなければ exit 0（出力なし）
   4. 拡張子チェック → *.md 以外なら exit 0（出力なし）
   5. ファイルサイズチェック → 1MB 超なら exit 0（出力なし）
   6. markdownlint-cli2 解決（フォールバックチェーン）:
      6a. command -v markdownlint-cli2 → 利用可能なら直接実行（高速パス）
      6b. 直接バイナリ不在時、command -v npx + npx --no-install markdownlint-cli2 --version → 利用可能なら npx 経由実行（プロジェクト標準 defaults.toml の "npx markdownlint-cli2" と整合）
      6c. どちらも利用不可なら exit 0（出力なし、任意ツールのため通知不要）
   7. 違反有無・lint コマンド失敗に関わらず exit 0
   ```

3. **`.claude/settings.json` 変更内容**:
   ```diff
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          { "type": "command", "command": "bin/check-utf8-corruption.sh" }
        ]
   +  },
   +  {
   +    "matcher": "Edit|Write",
   +    "hooks": [
   +      { "type": "command", "command": "bin/check-markdownlint.sh" }
   +    ]
      }
    ]
   ```

4. **既存 hook との独立動作**:
   - matcher が異なる別エントリで登録するため、`check-utf8-corruption.sh` と `check-markdownlint.sh` は並列実行（Claude Code hook 仕様）
   - 片方の失敗（exit ≠ 0）は他方に影響しない（両者とも `set -euo pipefail` だが exit 0 で終了する設計のため、相互影響なし）

5. **operations-release.md / 02-deploy.md の整合方針**:
   - サブステップ番号 `7.6` 〜 `7.13` は現状維持（renumber しない）
   - `02-deploy.md` の列挙ordinalのみ 1〜13 から 1〜12 に詰める
   - 削除対象行は plan §「Operations §7.5 削除」に明記済み
   - 削除後の grep 検証は **2段階** で実施:
     1. **運用対象**: `grep -rn "§7\.5\|operations-release\.sh lint\|7\.5 Markdownlint" skills/ .claude/` でヒット 0 件
     2. **履歴保護**: `grep -rn "§7\.5\|operations-release\.sh lint\|7\.5 Markdownlint" .aidlc/cycles/` でヒットがある場合、許容は過去サイクル履歴 `.aidlc/cycles/v*/history/` 配下と本サイクル `v2.4.3/plans/` `v2.4.3/history/` 配下のみ（運用ファイル `skills/` `.claude/` への混入がないこと）
   - 検証マトリクス §「テスト生成・regression 検証」の `§7.5 削除整合（運用対象）` / `§7.5 削除整合（履歴保護）` 行と同一方針

6. **operations-release.sh の `lint` 削除影響範囲**:
   - 削除箇所5箇所（plan §「operations-release.sh `lint` サブコマンド削除」明記）
   - dispatcher の case 削除により、未知サブコマンドとして `operations-release:error:unknown-subcommand:lint` が出力される（現状の `*)` ケースで既に正しい挙動）
   - `print_help` 出力からも `lint` が消えるため、ヘルプを見たユーザーが誤って `lint` を呼ぶ余地が消える
   - `run-markdownlint.sh` は不変（直接呼び出し可）

### Phase 2（実装）

#### コード生成

1. `bin/check-markdownlint.sh` 新規作成（実行権限付与: `chmod +x`）
2. `.claude/settings.json` の hooks 配列に `Edit|Write` matcher のエントリを追加
3. `skills/aidlc/steps/operations/operations-release.md` から §7.5 関連3箇所を削除
4. `skills/aidlc/steps/operations/02-deploy.md` から §7.5 サブステップ列挙削除 + ordinal 詰め
5. `skills/aidlc/scripts/operations-release.sh` から `lint` サブコマンド5箇所削除

#### テスト生成・regression 検証

検証-A（手動コマンド実行表）を採用。`bats` テストインフラは本リポジトリ未整備（`find tests/ -name '*.bats'` が 0 件）のため。

| 観点 | 検証手順 | 期待結果 |
|------|----------|----------|
| matcher 起動範囲（Edit） | Edit ツールで `*.md` ファイル編集（テスト用ファイル） | hook 起動・違反検出時 stderr 警告 |
| matcher 起動範囲（Write） | Write ツールで `*.md` ファイル新規作成 | hook 起動・違反検出時 stderr 警告 |
| 拡張子別動作（非 .md） | Edit で `*.sh` / `*.md.sample` を編集 | hook がスキップ（stderr 出力なし） |
| markdownlint-cli2 未インストール環境 | `PATH=/usr/bin` で hook を直接実行（markdownlint-cli2 不在 / jq は存在） | stderr 出力なし、exit 0 |
| jq 未インストール環境 | `PATH=/usr/bin` で hook を直接実行（jq 不在） | stderr に `⚠ check-markdownlint: jq が見つかりません。hookが動作不能です。` 出力、exit 0（既存 `bin/check-utf8-corruption.sh` 踏襲） |
| 既存 hook 連鎖 | Write で `*.md` 編集（U+FFFD 含む内容） | 両 hook が並列実行、片方失敗が他方に波及しない |
| §7.5 削除整合（運用対象） | `grep -rn "§7\.5\|operations-release\.sh lint\|7\.5 Markdownlint" skills/ .claude/` | ヒット 0 件 |
| §7.5 削除整合（履歴保護） | `grep -rn "§7\.5\|operations-release\.sh lint\|7\.5 Markdownlint" .aidlc/cycles/` | ヒットがあった場合、すべて `.aidlc/cycles/v*/history/` 配下のみ（過去サイクル履歴の保護を確認）。本サイクル `v2.4.3/plans/` `v2.4.3/history/` 配下に同文字列を含む計画・履歴記録は許容 |
| dispatcher 削除確認 | `skills/aidlc/scripts/operations-release.sh lint --cycle test` | `operations-release:error:unknown-subcommand:lint` (exit 1) |

検証は手動実行 + 実行ログを `history/construction_unit04.md` に記録する。

#### 設計AIレビュー / コードAIレビュー / 統合AIレビュー

- `review_mode=required`、`tools=['codex']` のため、`steps/common/review-flow.md` および `steps/common/review-routing.md` に従って実施
- 計画承認前 / 設計レビュー（Phase 1 完了時、`depth_level=standard` のため必須）/ コード生成後（コードAIレビュー）/ 統合（テスト完了後）の 4 タイミングで実施
- フォールバック条件（codex usage limit 等）に該当した場合はパス 2（self-review）に降りる（Unit 002 で正式統合された `SelfBackcompatShim` の挙動）

### 完了処理（Phase 3）

`steps/construction/04-completion.md` に従う。

## 完了条件チェックリスト

Unit 定義「責務」セクションと Issue #609 期待動作から抽出。

### Unit 定義「責務」由来

- [ ] `.claude/settings.json` の `hooks.PostToolUse` に `matcher: "Edit|Write"` の hook 追加（既存 hook と独立エントリ）
- [ ] 新規 hook スクリプト `bin/check-markdownlint.sh` 実装（拡張子チェック / `markdownlint-cli2` 存在確認 / 違反時 stderr 警告 / exit 0 維持）
- [ ] `skills/aidlc/steps/operations/operations-release.md` から §7.5 関連3箇所削除（見出し / lint bullet / `markdownlint:auto-fix` bullet）
- [ ] `skills/aidlc/steps/operations/02-deploy.md` の §7.5 サブステップ列挙削除 + ordinal 詰め
- [ ] `skills/aidlc/scripts/operations-release.sh` の `lint` サブコマンド5箇所削除
- [ ] regression 検証4観点（matcher / 拡張子 / 未インストール / 既存 hook 連鎖）実施・記録
- [ ] hook スクリプトのファイルパス（`bin/check-markdownlint.sh`）を design.md に記録し `.claude/settings.json` 参照と一致
- [ ] §7.5 削除整合の grep 検証2段階（運用対象 `skills/ .claude/` ヒット0 + 履歴保護 `.aidlc/cycles/` のヒットが `history/` 配下のみ）を実施・記録
- [ ] hook 命名規約（`check-<domain>.sh` の現行規約 / 将来 PostToolUse 専用が増えた際の `check-<domain>-posttooluse.sh` 拡張案）を design.md に補足記載

### Issue #609 期待動作由来

- [ ] `*.md` ファイル編集後に markdownlint が自動起動する
- [ ] `markdownlint-cli2` 未インストール環境でも編集動作をブロックしない
- [ ] 違反検出時に stderr で警告される

### Construction Phase 共通

- [ ] 設計成果物（domain_model.md / logical_design.md または同等の集約 design.md）が作成されている
- [ ] 計画 AI レビュー / 設計 AI レビュー / コード AI レビュー / 統合 AI レビューの 4 タイミングが実施され、`history/construction_unit04.md` に記録されている
- [ ] 意思決定記録の追加要否を確認し、対象あれば `inception/decisions.md` または同等の記録先に追記している
- [ ] Unit 定義ファイル `004-markdownlint-hook-and-ops75-removal.md` の実装状態を「完了」に更新（開始日 / 完了日記入）
- [ ] markdownlint チェックを通過（`markdown_lint=true`）— **本 Unit で hook を追加するため、編集中も hook 経由で随時検出される**
- [ ] Unit 中間コミットが squash されている（`squash_enabled=true`）

## リスクと注意点

- **既存 hook との競合**: 配列内別エントリで matcher が異なる（`Write` のみ vs `Edit|Write`）ため、Write 編集時は両 hook が並列実行される。両者とも exit 0 維持・stderr 出力のみのため、相互干渉なし。
- **markdownlint-cli2 検出**: フォールバックチェーンで対応する。**設計判断**: 直接バイナリ（`command -v markdownlint-cli2`）→ npx fallback（`command -v npx` + `npx --no-install markdownlint-cli2 --version`）の順に検出。本リポジトリは `skills/aidlc/config/defaults.toml` に `command = "npx markdownlint-cli2"` と定義されており、プロジェクト標準は npx 経由インストール。直接バイナリのみだとプロジェクト標準環境で常にスキップされてしまうため、Phase 2 検証で発見（実環境で違反検出されない問題）し npx fallback を追加した。両方不在の環境では hook が静かにスキップ（安全側挙動）。
- **`jq` 未インストール環境**: `bin/check-markdownlint.sh` は最初に `command -v jq` で検出し、不在なら **stderr に `⚠ check-markdownlint: jq が見つかりません。hookが動作不能です。` を出力して exit 0**（既存 `bin/check-utf8-corruption.sh` 踏襲、hook 機能不全をユーザー / エージェントに通知）。これにより JSON 解析失敗による異常終了を防ぎつつ、機能不全を黙殺せずに通知する。検証観点として `PATH` 制限環境（`jq` 不在）で hook 直接実行 → stderr に警告出力 + exit 0 を確認する。`markdownlint-cli2` 不在時は出力なし（任意ツール扱い）と差分させ、両者の挙動差を意図的に分ける（Issue #609 の「未インストール時はスキップ」を `markdownlint-cli2` のみに適用）。
- **大ファイルでの性能**: 1MB 超ファイルはスキップ。markdown ドキュメントで 1MB 超は通常稀なため影響軽微。
- **renumber しない判断**: `02-deploy.md` 内で §7.6 / §7.7 等への参照が複数あり、また外部（`commit-flow.md` / `phase-recovery-spec.md` 等）からも参照される可能性があるため、§7.5 は欠番として gap を維持する。`02-deploy.md` の列挙 ordinal のみ詰める。
- **`run-markdownlint.sh` の扱い**: 本 Unit のスコープは「`operations-release.sh` の `lint` サブコマンドラッパー削除」のみ。`run-markdownlint.sh` 本体は不変（直接呼び出し可、互換性維持）。
- **設定 JSON の合法性**: `.claude/settings.json` 編集後、`jq . .claude/settings.json` で構文チェック実施。

## 履歴記録方針

- `history/construction_unit04.md` を新規作成し、以下のタイミングで記録:
  - Phase 1 開始 / 設計 AI レビュー完了 / 設計承認
  - Phase 2 開始 / コード AI レビュー完了 / テスト実行完了 / 統合 AI レビュー完了 / 実装承認
  - 完了処理開始 / Unit 完了
- 履歴粒度は `history_level=standard` 準拠

## 参考

- Issue 本文: `gh issue view 609` で取得済み（対応方針候補・期待動作・関連ファイル一覧含む）
- 関連サイクル: v2.4.2（markdownlint 違反 MD038 / MD056 対応経験、変更しない）
- v2.4.3 並列実行 Units: 001 / 002 / 003（完了）/ 004（本 Unit、依存なし）
- 既存 PostToolUse hook: `bin/check-utf8-corruption.sh`（命名規約・I/O 契約のリファレンス）

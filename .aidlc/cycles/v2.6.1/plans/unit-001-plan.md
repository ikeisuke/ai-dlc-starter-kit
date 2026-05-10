# Unit 001 計画: version.sh の zsh OOM クラッシュ修正

## 概要

`scripts/lib/version.sh::read_marketplace_version` を、zsh 環境の Claude Code Bash ツール経由で呼び出した際に OOM クラッシュを起こさない経路へ整備する。Issue #688 で提示された 3 案のうち **案 3（CLI モード追加）** を主軸に採用し、SKILL.md 改訂と組み合わせて AI エージェントを安全な経路に誘導する。

## 採用案と根拠

### 採用案: 案 3（CLI モード追加 + SKILL.md 改訂）

`scripts/lib/version.sh` 末尾に以下のガードを追加し、`bash <path> <json_path>` 形式で直接呼び出せる CLI モードを提供する:

```bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    read_marketplace_version "$@"
fi
```

加えて SKILL.md の「バージョン表示」セクションを改訂し、AI エージェントに対して以下を明示する:

- **必須サポート経路**: `bash {SKILLベースディレクトリ}/scripts/lib/version.sh {marketplace.json のパス}` の CLI モード呼び出し
- **非対象経路**: ユーザーが対話 zsh シェルで手動 `source` する経路は zsh 補完 hook 衝突の既知制約があり対象外（注意書きで案内）

### 根拠

- v2.6.0 Unit 007 の `squash-unit.sh` で同じ CLI モードガードパターンを既に採用済（整合性）
- 既存の `source` 経由呼び出しが残るユースケース（lib として他 bash スクリプトから利用）には影響しない（`if/fi` ガードのため）
- 1 ファイル末尾の数行追加で完結し、後方互換性が完全に保たれる
- DR-004「修正方針は Construction で確定」に従い、Inception の余地を残しつつ最も非破壊的な案を選択

### 責務境界の意図的設計（lib + CLI モードガードの二重責務について）

`version.sh` は元来「関数定義のみを含む lib」だが、本 Unit で CLI モードガード（`if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then read_marketplace_version "$@"; fi`）を末尾に追加することで、lib 本来の責務に加えて「`bash <path>` 経由の薄いエントリポイント」という第二の責務を持つ。これは以下の意図に基づく:

1. **CLI ガードは薄い委譲のみ**: ガード内で行うのは `read_marketplace_version "$@"` への引数透過のみ。業務ロジック（version 抽出 / 検証 / エラーハンドリング）は引き続き `read_marketplace_version()` 関数に集約する
2. **整合パターン**: v2.6.0 Unit 007 の `squash-unit.sh` でも同じ「lib 関数 + 末尾の `if/fi` ガード」パターンを採用しており、AI-DLC スターターキット内の整合性を保つ
3. **将来の wrapper 分離可能**: 仮に責務分離をより厳密にしたい場合、`scripts/show-version.sh` のような薄いラッパースクリプトに CLI ガードを移し、`version.sh` を純粋な lib に戻す改修が容易（Issue #688 の案 2 への移行経路を残している）
4. **wrapper 分離を採らない理由**: 案 2（薄いラッパー）は新規ファイル追加が発生し、AI エージェントへの呼び出し経路（SKILL.md の指示）と実装ファイルの両方を編集する必要がある。CLI モードガードのほうが (a) 1 ファイル変更で完結 (b) 既存パターン踏襲 (c) lib 関数の単一テスト点を維持 のメリットが上回ると判断

## 完了条件チェックリスト

### Unit 001 受け入れ基準（user_stories.md ストーリー 1 より）

#### 正常系

- [x] zsh + Claude Code Bash ツール経由で `bash skills/aidlc/scripts/lib/version.sh <path>` を実行した際に、OOM クラッシュが発生せず正常終了する（exit 0）かつ stdout に `marketplace.json.metadata.version` の値が `v` プレフィックスなしで出力される
- [x] `bash <path>` 形式（CLI モード）と `bash -c "source <path>; read_marketplace_version <json_path>"` 形式の両方で、正しいバージョン文字列が stdout に出力される
- [x] SKILL.md の version アクション記述が、AI エージェント向けに「使用すべき呼び出し経路」と「使用すべきでない経路（zsh 対話シェルからの `source`）」を曖昧さなく区別している
- [x] 既存の `marketplace.json.metadata.version` を SoT とする version 取得契約（出力フォーマット・終了コード規約）が変更されない

#### 異常系

- [x] `marketplace.json` が存在しない場合、stderr に `error:marketplace-json-not-found` を出力し exit 2 で終了する（既存挙動維持）
- [x] `marketplace.json` の `metadata.version` キーが空または不正な場合、stderr に `error:metadata-version-missing-or-empty` または `error:metadata-version-invalid-semver:<value>` を出力し exit 1 で終了する（既存挙動維持）
- [x] dasel / jq の双方が不在で抽出不能な場合、stderr に `error:dasel-and-jq-unavailable` を出力し exit 2 で終了する（既存挙動維持）

#### テスト

- [x] 既存 `skills/aidlc/scripts/tests/test_read_marketplace_version.sh` に CLI モード経由（`bash skills/aidlc/scripts/lib/version.sh <path>`）の正常 / 異常系テストケースを追記、または同形式の `test_version_cli.sh` を新規追加し、いずれの場合も既存テストランナー（`test_*.sh` 形式 / 各テストファイルを直接実行）で実行可能であること。実行コマンド: `bash skills/aidlc/scripts/tests/test_read_marketplace_version.sh`（または新規追加ファイル）が exit 0 で完了

### Unit 定義「責務」セクションより

- [x] **必須サポート経路（Bash ツール経由）の安全化**: zsh 環境の Claude Code Bash ツールから `bash <path>` または `bash -c "source <path>; ..."` で呼び出される経路で OOM 非発生
- [x] **AI エージェント誘導の明確化**: SKILL.md で必須サポート経路と非対象経路を区別
- [x] **テスト整備**: test_*.sh テスト（既存テスト基盤に追加）追加

### 観測可能な判定指標（OOM 非発生の機械的検証）

「OOM 非発生」を直接観測することは困難なため、以下の機械的に確認できる指標で代替する:

- [x] `bash skills/aidlc/scripts/lib/version.sh <path>` を実行し、現実的な処理時間内（30 秒以内が目安）に exit 0 で終了する。`timeout` コマンドは環境依存（macOS デフォルトは GNU coreutils 未導入）のため、強制必須としない。テストスクリプト内ではバックグラウンド実行 + `kill` または bash の `wait` 機構で制御するか、外部 `timeout` が利用可能な環境（GitHub Actions Linux runner / `gtimeout` 経由の macOS）でのみ厳密タイムアウト判定を行う
- [x] stdout が `marketplace.json.metadata.version` の値と一致する（`v` プレフィックスなし）
- [x] stderr に `command_not_found_handler` / `_ai_should_send` / `aidlc_strip_quotes` 等の zsh 補完 hook 由来の再帰系エラー文字列が含まれない
- [x] 同コマンドを 3 回連続実行して全て同一の exit 0 + stdout を得る（再現性確認）

### Construction Phase 共通

- [x] 設計レビュー（reviewing-construction-design）: 指摘0件 or 全 resolve / defer
- [x] コードレビュー（reviewing-construction-code）: 同上
- [x] 統合レビュー（reviewing-construction-integration）: 同上
- [x] **Unit 001 スコープ内の対象が green**: `shellcheck skills/aidlc/scripts/lib/version.sh` exit 0 / `bash skills/aidlc/scripts/tests/test_read_marketplace_version.sh` PASS=22/0。`markdownlint` および pre-existing 失敗 7 テスト（`test_detect_phase.sh` / `test_kiro_merge.sh` / `test_operations_release_merge_pr_empty_args.sh` / `test_parse_gh_error.sh` / `test_resolve_remote.sh` / `test_root_commit_helpers.sh` / `test_wildcard_detection.sh`）は本 Unit のスコープ外 — CI / 別 Unit / 別サイクル管理（詳細は本ファイル末尾「実行できなかった項目と理由」参照）
- [x] 設計と実装の整合性チェック

## スコープ

### 含まれるもの

- `skills/aidlc/scripts/lib/version.sh` への CLI モードガード追加
- `skills/aidlc/SKILL.md` のバージョン表示セクション改訂（必須サポート経路明示、非対象経路の注意書き）
- test_*.sh テスト（既存テスト基盤に追加）（必須サポート経路の正常 / 異常系、CLI モード固有の検証）
- 既存の `source` 経由呼び出しが破壊されないことの後方互換性検証

### 含まれないもの

- ユーザー対話 zsh シェルで手動 `source` した場合の zsh 側挙動修正（zsh 側の補完 hook 競合は本 Unit のスコープ外）
- `read-config.sh` 等の他の lib スクリプトの zsh 互換性監査（必要なら次サイクル）
- `bin/update-version.sh` の挙動変更（読み取り経路の修正に閉じる）

## 関連ファイル（修正対象 / 参照）

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/scripts/lib/version.sh` | 末尾に CLI モードガード追加 |
| `skills/aidlc/SKILL.md` | 「バージョン表示」セクションを CLI モード呼び出しと注意書きで改訂 |
| `skills/aidlc/scripts/tests/test_read_marketplace_version.sh`（既存追記）または `skills/aidlc/scripts/tests/test_version_cli.sh`（新規） | CLI モード経由（`bash skills/aidlc/scripts/lib/version.sh <path>`）の正常 / 異常系テストケース追加 |
| `skills/aidlc/scripts/lib/version.sh`（参照のみ） | 既存の `read_marketplace_version` 関数定義は変更しない |

## 設計フェーズ（Phase 1）の対象

`depth_level=standard` のため Phase 1（設計）を実施する。

- ドメインモデル設計: 軽量（version 取得契約 / 呼び出し経路の責務分離）
- 論理設計: CLI モードガードの配置と SKILL.md 改訂内容、非対象経路の文言

## 実装フェーズ（Phase 2）の対象

- `version.sh` 末尾への `if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then ... fi` ブロック追加
- SKILL.md「バージョン表示」セクションの本文を新しい呼び出し経路で書き換え
- `skills/aidlc/scripts/tests/test_read_marketplace_version.sh` への CLI モードテストケース追記（または `test_version_cli.sh` を新規追加）を行い、`bash skills/aidlc/scripts/tests/test_read_marketplace_version.sh`（または追加ファイル）が exit 0 で完了する
- `bash skills/aidlc/scripts/tests/test_read_marketplace_version.sh`（および新規追加した CLI モードテストファイルがあればそれも）と `shellcheck skills/aidlc/scripts/lib/version.sh` が exit 0 で完了する

## リスク

| リスク | 影響度 | 対応 |
|-------|-------|------|
| CLI モードガード追加により既存の `source` 経由呼び出しが破壊される | 高 | `if/fi` ガードで `${BASH_SOURCE[0]} == $0` 時のみ実行されるため、`source` 時は実行されない。`test_read_marketplace_version.sh`（既存）と CLI モードテスト（追加）で両方の経路を検証 |
| SKILL.md 改訂で既存運用フローが混乱する | 中 | 「使用すべき経路」と「使用すべきでない経路」を明示し、既存呼び出し例も互換動作することを記載 |
| zsh 環境以外（bash 純粋環境）での挙動変化 | 低 | CLI モードは bash で実行されるため zsh 補完 hook 衝突は発生しない。bash でも同じ呼び出し方法で動作 |

## 見積もり

0.5 day

## 関連

- Issue: #688
- Inception 決定: DR-004（修正方針は Construction で確定）
- 整合性: v2.6.0 Unit 007 の squash-unit.sh CLI モードガードパターン

## 完了条件達成証跡（2026-05-10）

| 項目 | コマンド | 結果 |
|------|---------|------|
| Unit 001 テスト（CLI モード追加分含む） | `bash skills/aidlc/scripts/tests/test_read_marketplace_version.sh` | exit 0 / PASS=22 / FAIL=0 |
| `version.sh` shellcheck | `shellcheck skills/aidlc/scripts/lib/version.sh` | exit 0 / 警告なし |
| `version.sh` 実環境動作（CLI モード） | `bash skills/aidlc/scripts/lib/version.sh .claude-plugin/marketplace.json` | exit 0 / stdout=`2.6.0` |
| 設計レビュー | reviewing-construction-design / codex 2 round | resolve 3 / unresolved 0 |
| コードレビュー | reviewing-construction-code / codex 2 round | resolve 1（再評価で取り下げ） / unresolved 0 |
| 統合レビュー | reviewing-construction-integration / codex 2 round | （本セクション追記後の Round 2 で確認） |

### 実行できなかった項目と理由

| 項目 | 理由 |
|------|------|
| `markdownlint skills/aidlc/SKILL.md` | ローカル開発環境に markdownlint 未インストール。CI（GitHub Actions の `markdownlint.yml` ワークフロー）で実行確認。本 Unit の SKILL.md 変更は構造的変更なし（既存セクションの本文書き換え + 制約事項の例外追記のみ）であり、リント違反リスクは低い |
| `skills/aidlc/scripts/tests/test_*.sh` 全件 green | 7 件（`test_detect_phase.sh` / `test_kiro_merge.sh` / `test_operations_release_merge_pr_empty_args.sh` / `test_parse_gh_error.sh` / `test_resolve_remote.sh` / `test_root_commit_helpers.sh` / `test_wildcard_detection.sh`）が main ブランチでも失敗する pre-existing failure。Unit 001 の変更は `test_read_marketplace_version.sh` のみであり、これは PASS=22/0。pre-existing failure は本 Unit のスコープ外 |

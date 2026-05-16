# 論理設計: Unit 003 - /aidlc v 経路の再現性向上

## 概要

`/aidlc v` アクションの実行経路で発生していた「AI エージェントの推測値出力」「base dir → marketplace.json パス組み立てミス」を構造的に解消する。本 Unit はドキュメント改訂（SKILL.md）と既存シェル関数の薄い改修（`version.sh` CLI モードガード）に閉じ、関数本体（`read_marketplace_version`）の契約は不変とする。

## アーキテクチャパターン

**採用パターン**: レイヤード（Documentation / CLI Entrypoint / Function Body）+ 後方互換維持のための test override 経路保持。

**選定理由**:

- 既存責務境界（関数契約・テスト境界・SKILL.md 手順記述）を壊さずに「AI 推測 / パス組み立てミス」の構造的予防を達成するため
- 関数本体に「引数省略時のデフォルト値生成」を持たせると関数契約が暗黙化し、回帰時の障害位置が特定しにくくなるため、CLI モードガード内に閉じる（Codex 指摘 Round 1 #2 を踏まえた設計）

## コンポーネント構成

### レイヤー / モジュール構成

```text
/aidlc v 経路
├── Documentation layer (SKILL.md / version.sh 冒頭コメント)
│   ├── 「バージョン表示」節（手順 SoT）
│   └── 「Bash ツール経由の zsh OOM 回避ルール」節（横断ルール SoT 参照）
├── CLI Entrypoint layer (version.sh 末尾の CLI モードガード)
│   ├── 引数解決（自己解決 / test override）
│   └── read_marketplace_version への委譲
└── Function Body layer (version.sh 内の read_marketplace_version 関数)
    └── 引数必須・SemVer 検証・dasel/jq 二段フォールバック（不変）
```

### コンポーネント詳細

#### SKILL.md「バージョン表示」節

- **責務**: AI エージェント実行手順の Single Source of Truth
- **依存**: SKILL.md 冒頭「Base directory for this skill:」行（base dir 解決の手がかり）
- **公開インターフェース**:
  - 実行手順契約（base dir 取得 → CLI 呼び出し → 表示）
  - 推測禁則（内部知識からの version 出力禁止）
  - フォールバック表示仕様（`(version unknown)`）

#### version.sh CLI モードガード（末尾の `if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then ... fi`）

- **責務**: スクリプト直接実行時の引数解決と関数委譲
- **依存**: `read_marketplace_version`（同一ファイル内の関数）/ `${BASH_SOURCE[0]}` / `$@`
- **公開インターフェース**:
  - 引数なし → 自己解決パスで `read_marketplace_version` 呼び出し
  - 引数あり → 与えられた引数で `read_marketplace_version` 呼び出し（test override）
- **新規分岐ロジック**:
  ```bash
  if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
      if [[ $# -eq 0 ]]; then
          SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
          read_marketplace_version "${SCRIPT_DIR}/../../../../.claude-plugin/marketplace.json"
      else
          read_marketplace_version "$@"
      fi
  fi
  ```

#### read_marketplace_version 関数

- **責務**: marketplace.json から `metadata.version` を抽出し SemVer 検証
- **依存**: dasel / jq（コマンド存在に応じてフォールバック）
- **公開インターフェース**: 既存仕様を**変更しない**
  - 入力: `$1` = marketplace.json パス（空文字 / 未指定は exit 2）
  - 出力: stdout に version 文字列、exit code 0 / 1 / 2
  - stderr エラー: `error:missing-json-path` / `error:marketplace-json-not-found` / `error:metadata-version-missing-or-empty` / `error:metadata-version-invalid-semver:<value>` 等

## インターフェース設計

### スクリプトインターフェース設計

#### `skills/aidlc/scripts/lib/version.sh`（CLI モード）

##### 概要

marketplace.json から `metadata.version` を取得して SemVer 検証付きで返す。引数省略時はスクリプト位置基準で marketplace.json を自己解決する（v2.6.3 Unit 003 で追加）。

##### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `$1` | 任意（v2.6.3 以降） | marketplace.json のパス（test override）。省略時は `<script_dir>/../../../../.claude-plugin/marketplace.json` を自己解決 |
| `$2` 以降 | - | 無視（正式契約）。`read_marketplace_version` は `$1` のみ参照するため `$2` 以降の値は実行結果に影響しない。CLI エントリポイントで明示的なエラーは返さない（既存 v2.6.1 Unit 001 / Issue #688 で確立した挙動を後方互換として維持） |

##### 成功時出力

```text
2.6.3
```

- 終了コード: `0`
- 出力先: stdout

##### エラー時出力

```text
error:marketplace-json-not-found
```

- 終了コード: `1`（コンテンツエラー: version キー不在 / 空 / 非 SemVer）または `2`（実行環境エラー: ファイル不在 / 読取権限なし / dasel・jq 双方不在）
- 出力先: stderr

##### 使用コマンド

```bash
# AI エージェント推奨経路（引数省略 / 自己解決）
bash <skill_base>/scripts/lib/version.sh

# テスト等での test override（引数渡し / 後方互換維持）
bash <skill_base>/scripts/lib/version.sh /path/to/marketplace.json
```

### SKILL.md「バージョン表示」節の構造

改訂後の節は以下の論理構成で書く（500 行制限を満たすため圧縮）:

1. アクション目的（1 行）
2. AI エージェントの実行手順（番号付き 4 ステップ）:
   - SKILL.md 冒頭「Base directory for this skill:」行から base dir を取得
   - `bash <base>/scripts/lib/version.sh` を実行（引数省略可、自己解決される）
   - stdout を trim + 先頭 `v` 除去して `AI-DLC Starter Kit v{version}` 形式で表示
   - exit 非 0 または空文字なら `AI-DLC Starter Kit (version unknown)` を表示
3. 禁則（1 行）: 「Bash を呼ばずに内部知識で version を推測しないこと」
4. 注意（参照のみ、詳細は退避先へ）: zsh OOM 回避ルール（CLAUDE.md / bash-tool-safety.md への横断参照）

### version.sh 冒頭コメントの退避内容

SKILL.md から退避される内容を以下のセクションに集約する。**SoT 関係を明示**: 規約本文の Single Source of Truth は CLAUDE.md（横断ルール）+ `bash-tool-safety.md`（運用例）であり、`version.sh` 冒頭コメントは「運用メモ + Issue リンク」の役割に限定する（仕様の二重管理を避けるため）。

- 自己解決ロジックの存在と動作仕様（CLI モードガード分岐の要点）
- zsh `command_not_found_handler` 無限再帰の経緯**要点のみ**（詳細は CLAUDE.md / Issue #688 を参照）
- CLI モードガードの引数契約（`$1` 任意 / `$2` 以降は無視 / 自己解決経路）

**圧縮方針**: 冒頭コメントは「要点 + Issue #688 リンク + CLAUDE.md 参照」に留め、運用者が一次情報（CLAUDE.md / Issue）へ辿り着ける導線を保ちつつ、本文の二重記載を排除する（Codex 設計レビュー Round 1 指摘 #2 反映）。

## データモデル概要

本 Unit はデータベース・永続データを扱わない。marketplace.json は read-only の Single Source of Truth として参照のみ。

### marketplace.json 参照スキーマ

| キー | 型 | 説明 |
|-----|----|----|
| `metadata.version` | string (SemVer 2.0.0) | プラグインバージョンの正本値 |

## 処理フロー概要

### `/aidlc v` 実行時の処理フロー（改訂後）

**ステップ**:

1. AI エージェントが `/aidlc v` を解釈し、SKILL.md「バージョン表示」節の手順に従う
2. SKILL.md 冒頭「Base directory for this skill:」行から base dir 絶対パスを取得
3. `bash <base>/scripts/lib/version.sh`（引数省略）を Bash ツール経由で実行
4. version.sh の CLI モードガード内で:
   - `$# -eq 0` のため自己解決経路に入る
   - `SCRIPT_DIR` を `${BASH_SOURCE[0]}` から算出
   - `${SCRIPT_DIR}/../../../../.claude-plugin/marketplace.json` を `read_marketplace_version` に渡す
5. `read_marketplace_version` が dasel または jq で `metadata.version` を抽出し SemVer 検証
6. 成功 → stdout に version 文字列、exit 0
7. AI エージェントが stdout を trim + 先頭 `v` 除去して `AI-DLC Starter Kit v{version}` 形式で表示
8. 失敗（exit 非 0 / 空文字） → `AI-DLC Starter Kit (version unknown)` を表示

**関与するコンポーネント**: SKILL.md「バージョン表示」節 / version.sh CLI モードガード / read_marketplace_version / dasel または jq

### テスト処理フロー

#### C3a: CLI モード自己解決成功

**ステップ**:

1. 本物の `version.sh`（`<repo_root>/skills/aidlc/scripts/lib/version.sh`）を引数なしで実行
2. 自己解決で `<repo_root>/.claude-plugin/marketplace.json` を参照
3. exit 0、stdout に SemVer 文字列

#### C3b: CLI モード自己解決失敗

**ステップ**:

1. `mktemp -d` で一時ディレクトリを作成（例: `/tmp/abc/`）
2. 一時ディレクトリ内に `skills/aidlc/scripts/lib/` 階層を mkdir し、本物の `version.sh` をその位置にコピー（`/tmp/abc/skills/aidlc/scripts/lib/version.sh`）
3. 一時ディレクトリには `.claude-plugin/marketplace.json` を作成しない
4. コピーした `version.sh` を引数なしで実行 → 自己解決パスは `/tmp/abc/.claude-plugin/marketplace.json` を指すが存在しない
5. exit 2、stderr に `error:marketplace-json-not-found`

#### C3c: 関数本体引数空契約

**ステップ**:

1. テストスクリプトで `version.sh` を `source` 読み込み（既存テストと同じ手法）
2. `read_marketplace_version ""` を直接呼び出し（CLI モードガードは経由しない）
3. exit 2、stderr に `error:missing-json-path`

#### C9: CLI モード後方互換（引数渡し）

**ステップ**:

1. 一時ファイル（fixture）に正常な marketplace.json を作成
2. 本物の `version.sh` に当該 fixture パスを引数として渡して実行
3. exit 0、stdout に fixture の SemVer 文字列

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: Unit 定義「該当なし」
- **対応策**: 変更なし。CLI モードガードに `cd` 1 回分の overhead が増えるが、`/aidlc v` は対話的単発実行であり性能影響なし

### セキュリティ

- **要件**: Unit 定義「該当なし」
- **対応策**: `cd "$(dirname "${BASH_SOURCE[0]}")"` 経路で外部入力を取らないため、追加の入力検証は不要。marketplace.json への参照は read-only

### スケーラビリティ

- **要件**: 該当なし

### 可用性

- **要件**: `/aidlc v` の既存呼び出し経路で従来と同一のバージョン文字列が出力されること（互換維持）
- **対応策**:
  - 引数渡し経路は test override として保持し、既存テスト C1, C2, C4, C5, C6, C8 を変更なしで pass させる
  - `read_marketplace_version` 関数本体の契約は不変。CLI モードガードのみ拡張

## 技術選定

本 Unit は新規依存を導入しない。

- **言語**: Bash 4+（macOS デフォルトは 3.2 だが、既存 `version.sh` も同前提で動作中）
- **依存ツール**: dasel（推奨） / jq（フォールバック）。既存仕様維持
- **テストフレームワーク**: 既存 `test_read_marketplace_version.sh` の bash 直接実行テスト方式を継承

## 実装上の注意事項

- **パス段数の検証**: Phase 2 実装直前に `skills/aidlc/scripts/lib/` から `..` を 4 段たどると repo root に到達することを実測検証する（計画リスク欄記載）
- **既存 readonly 変数の扱い**: `_SEMVER_PATTERN` は既に `readonly` 宣言済み。多重 source 対応の `if [[ -z "${_SEMVER_PATTERN:-}" ]]` ガードは維持する
- **bash-tool-safety 規約**: AI エージェントが本 Unit の実装作業中も `$(...)` / backtick を Bash ツール引数文字列に含めないこと（リポジトリ規約、Unit 001 SoT）
- **`/aidlc v` 経路固有の zsh 手動 source 注意**: 圧縮対象だが、`source <path>/version.sh; read_marketplace_version <args>` を zsh 対話シェルで手動実行することの OOM リスクは横断ルール（CLAUDE.md）で吸収。SKILL.md からは詳細経緯のみ退避し、横断参照を残す
- **テスト C3b の独立性**: 一時ディレクトリは `mktemp -d` で作成し、`trap 'rm -rf "$TEST_DIR"' EXIT` 等で確実にクリーンアップする（既存テスト手法を踏襲）

## 不明点と質問

[Question] SKILL.md 圧縮で「使用すべきでない呼び出し経路」サブセクションを完全削除するか、横断参照だけ残すか？
[Answer] 横断参照だけ残す。CLAUDE.md / bash-tool-safety.md が SoT として機能している現状を壊さない。`/aidlc v` 固有の経緯は version.sh 冒頭コメントへ「運用メモ要点 + Issue #688 リンク + CLAUDE.md 参照」の形に圧縮して退避（規約本文の二重管理を避けるため）。

[Question] CLI エントリポイントで第2引数以降を渡された場合の挙動（エラー化 vs サイレント無視）の正式契約は？
[Answer] サイレント無視を正式契約として確定する。理由: (1) 既存 v2.6.1 Unit 001 / Issue #688 でこの挙動が確立済み、(2) 引数個数チェック追加は破壊的変更になり後方互換テストが壊れる、(3) 関数本体 `read_marketplace_version` が `$1` のみ参照する設計に整合。論理設計の「引数」表に明示することで契約をドキュメント化（Codex 設計レビュー Round 1 指摘 #1 反映）。

[Question] C3b で `mktemp -d` で作成した一時ディレクトリの `.claude-plugin/` も同時に作成し、その下に空 / 不正な marketplace.json を置くケースは検証すべきか？
[Answer] 本 Unit のスコープでは「自己解決パスが不在」シナリオ（C3b）の単一ケースに限定する。`.claude-plugin/` 自体が存在しても marketplace.json が不在 / 不正 SemVer のケースは既存 C5（metadata.version 不在）/ C6（不正 SemVer）が引数渡し経路で既にカバーしているため、CLI モード経由の重複は追加しない。

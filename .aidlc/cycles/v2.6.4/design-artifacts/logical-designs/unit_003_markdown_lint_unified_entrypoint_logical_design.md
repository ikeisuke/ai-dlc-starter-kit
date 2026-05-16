# 論理設計: markdown lint 統一エントリポイント化

## 概要

`package.json` の `scripts.lint:md` を SoT として、AI レビュー / CI / ローカル開発が同一の npm script 名で markdownlint を起動できる統一エントリポイントを構成する。本設計はコード非生成（Phase 2 で実装）であり、構成物の配置・インターフェース・後方互換確認手順のみを定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

- **パターン**: 「公開エントリポイント + 直接呼び出し経路の併存（opt-in シグナル方式）」
- **選定理由**:
  - 既存 `npx markdownlint-cli2` 直接呼び出し経路（CI / `run-markdownlint.sh` / 散在 docs）を破壊しないため、置換ではなく「並列追加」を採用
  - consumer プロジェクトでは `package.json` の有無自体が opt-in シグナルとして機能し、配布物本体に「starter kit 判定分岐」を持ち込まずに自然 opt-in/out できる（CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」原則準拠）

## コンポーネント構成

### 配置構造（repo ルート起点）

```text
ai-dlc-starter-kit/
├── package.json                                  # 新規（SoT: scripts.lint:md）
├── .gitignore                                    # 更新（node_modules/ 追加）
├── .markdownlint-cli2.jsonc                      # 既存（参照のみ、変更なし）
├── .markdownlint.json                            # 既存（参照のみ、変更なし）
├── .markdownlintignore                           # 既存（参照のみ、変更なし）
├── skills/
│   ├── reviewing-common/
│   │   └── reviewing-common-base.md              # 更新（1 〜 2 行追記、SoT 反映先）
│   └── aidlc/
│       └── scripts/
│           └── run-markdownlint.sh               # 既存（変更なし、smoke 実行で互換確認）
└── .github/
    └── workflows/
        └── pr-check.yml                          # 既存（変更なし、後方互換維持）
```

### コンポーネント詳細

#### package.json（新規）

- **責務**: 統一エントリポイント `scripts.lint:md` の SoT 保持
- **依存**: なし（`devDependencies` 未追加、`npx` 解決に委ねる）
- **公開インターフェース**:
  - `npm run lint:md`: `npx markdownlint-cli2 "docs/translations/**/*.md" "prompts/**/*.md" "*.md"` を起動（既存 CI `markdownlint-cli2-action` の glob と整合）

#### reviewing-common-base.md（更新、1 〜 2 行追記）

- **責務**: AI レビュー外部 CLI 実行基盤の手順書として、markdown lint の標準実行コマンドを 1 箇所だけ明示
- **依存**: `package.json`（SoT への参照）
- **公開インターフェース**: 文章追記（実行 API ではない）。追記内容は「markdown lint の標準実行コマンドは `npm run lint:md` を推奨。`package.json` の `scripts.lint:md` が SoT。本ガイドの適用境界は starter kit 内 AI レビュー導線に限定し、consumer 一般向け導線・上位スキル横断 docs は対象外」

#### .gitignore（更新、`node_modules/` 追加）

- **責務**: `npm install` が将来発生した場合の `node_modules/` 漏洩防止
- **依存**: なし
- **公開インターフェース**: git の挙動（追加分のパターン）

#### 既存コンポーネント（変更なし、後方互換維持）

- `.markdownlint-cli2.jsonc` / `.markdownlint.json` / `.markdownlintignore`: 設定ファイル群。`npm run lint:md` と既存 `npx markdownlint-cli2` 直接呼び出しの両経路から同一参照される
- `skills/aidlc/scripts/run-markdownlint.sh`: 既存ラッパー。本 Unit では smoke 実行で実行互換のみ確認（置換しない）
- `.github/workflows/pr-check.yml`: 既存 CI。`DavidAnson/markdownlint-cli2-action@v18` を維持（差し替えは別 Unit）

## インターフェース設計

### API エンドポイント

該当なし（本 Unit は HTTP API を持たない）

### コマンド

#### `npm run lint:md`

- **パラメータ**: なし（追加引数は想定しないが、`--` 以降は npm の慣例で markdownlint-cli2 に渡される）
- **戻り値**: exit code（`0` = lint 成功、非 0 = lint 違反 / 起動失敗）
- **副作用**: なし（読み取りのみ。`--fix` 等の修正系オプションは本 Unit では推奨しない）
- **想定実行コンテキスト**: starter kit リポジトリ内（`package.json` が存在する文脈）。consumer プロジェクトでは `package.json` 不在で自然に opt-out（呼び出し側で `npm ERR! missing script` 等）

### クエリ

該当なし

## スクリプトインターフェース設計

本 Unit はシェルスクリプトを新規追加しない。`scripts.lint:md` は package.json 内の 1 行定義のみ。

### scripts.lint:md（package.json 内）

#### 概要

統一エントリポイント。`npx markdownlint-cli2 "docs/translations/**/*.md" "prompts/**/*.md" "*.md"` を実行する（既存 CI `.github/workflows/pr-check.yml` の `markdownlint-cli2-action` の glob と整合）。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--` 以降 | 任意 | npm の慣例で markdownlint-cli2 にパススルー（運用上は使用しない想定） |

#### 成功時出力

```text
markdownlint-cli2 v0.x.x (markdownlint v0.x.x)
Finding: docs/translations/**/*.md prompts/**/*.md *.md !docs/aidlc/** !docs/cycles/** !docs/versions/**
Linting: N file(s)
Summary: 0 error(s)
```

- 終了コード: `0`
- 出力先: stdout

#### エラー時出力

```text
markdownlint-cli2 v0.x.x (markdownlint v0.x.x)
...
[lint 違反一覧]
Summary: N error(s)
```

- 終了コード: `1`（lint 違反）/ それ以外（起動失敗時の markdownlint-cli2 由来の値）
- 出力先: stderr / stdout

#### 使用コマンド

```bash
npm run lint:md
```

## データモデル概要

該当なし（本 Unit はファイル形式の SoT 定義のみで、データ永続化を伴わない）

### ファイル形式

#### package.json

- **形式**: JSON（npm 標準）
- **主要フィールド**:
  - `name`: string - `"ai-dlc-starter-kit"`
  - `private`: bool - `true`（npm publish 防止）
  - `scripts.lint:md`: string - 統一エントリポイント定義

## 処理フロー概要

### ユースケース 1: AI レビュー文脈での markdownlint 実行

**ステップ**:

1. AI レビュワー（codex 等）が `npm run lint:md` を実行
2. npm が repo ルートの `package.json` を解決し `scripts.lint:md` を起動
3. `npx markdownlint-cli2 "docs/translations/**/*.md" "prompts/**/*.md" "*.md"` が解決され実行
4. 既存設定ファイル群（`.markdownlint-cli2.jsonc` / `.markdownlint.json` / `.markdownlintignore`）を参照
5. lint 結果を exit code + stdout/stderr で返す

**関与するコンポーネント**: package.json, npm, npx, markdownlint-cli2, 設定ファイル群

### ユースケース 2: 既存 CI 経路での markdownlint 実行（後方互換）

**ステップ**:

1. GitHub Actions が `.github/workflows/pr-check.yml` を起動
2. `DavidAnson/markdownlint-cli2-action@v18` が起動（既存経路、変更なし）
3. 同一設定ファイル群を参照
4. lint 結果を CI ジョブ結果として返す

**関与するコンポーネント**: GitHub Actions, markdownlint-cli2-action, 設定ファイル群

### ユースケース 3: 既存 `run-markdownlint.sh` ラッパー経路（後方互換 smoke）

**ステップ**:

1. AI-DLC Construction Phase 完了処理で `scripts/run-markdownlint.sh {{CYCLE}}` を実行
2. ラッパー内で `npx markdownlint-cli2` を解決
3. 同一設定ファイル群を参照
4. lint 結果を exit code で返す

**関与するコンポーネント**: run-markdownlint.sh, npx, markdownlint-cli2, 設定ファイル群

## 非機能要件（NFR）への対応

### 再現性

- **要件**: AI レビュー（codex）環境で `npm run lint:md` が `command not found` なく動作する
- **対応策**: `package.json` を repo ルートに常設し、`npm` + `node` 既存環境で標準的に解決される構成にする
- **但し書き**: 本 Unit の再現性は **unpinned 前提（`markdownlint-cli2` のバージョン非固定）の範囲**。`npx` 解決はネットワーク状態・解決タイミング・upstream のメジャー更新タイミングに依存する。完全な再現性（同一バイナリ保証）は follow-up Issue #713（版固定 + `devDependencies` 化 + `package-lock.json` 生成 + CI 整合）完了後に再現性要件を引き上げる前提

### 後方互換性

- **要件**: 既存 `npx markdownlint-cli2` 直接呼び出しを破壊しない
- **対応策**:
  - 既存呼び出し箇所を置換せず並列追加に留める
  - 完了条件チェックで grep による残存確認 + `run-markdownlint.sh` 既定経路 smoke 実行 + 設定ファイル参照集合の同一性確認の 3 段検証

#### 3 段検証の実施手順（再現性のための明文化）

1. **grep による残存確認**:
   - 比較対象: 本 Unit 変更前後の `grep -rn "npx markdownlint-cli2"` 一致行数（除外: `.git/`, `node_modules/`, `.aidlc/cycles/*/design-artifacts/`, `.aidlc/cycles/*/plans/`）
   - 証跡: 履歴ファイル `history/construction_unit03.md` に before/after 行数を 1 行記録
   - 合格条件: after 行数 ≥ before 行数（並列追加のため減少は許容しない）
2. **`run-markdownlint.sh` 既定経路 smoke 実行**:
   - 比較対象: `bash skills/aidlc/scripts/run-markdownlint.sh v2.6.4` の exit code
   - 証跡: コマンドの exit code と末尾出力 1〜3 行を履歴ファイルに記録
   - 合格条件: exit code = 0（lint 違反 0 件）
3. **設定ファイル参照集合の同一性確認**:
   - 比較対象: `npm run lint:md` 実行時に markdownlint-cli2 が読み込む設定ファイル集合 vs `npx markdownlint-cli2 "docs/translations/**/*.md" "prompts/**/*.md" "*.md"` 直接実行時（既存 CI 経路 = `markdownlint-cli2-action` と同等 glob）に読み込む設定ファイル集合
   - 検証方法: 両経路を順に実行し、それぞれの stdout/stderr で markdownlint-cli2 が報告する「Linting … files / Config file path」相当の参照ログ（または同等の証跡として両経路の lint 結果（violations 件数 + 内容）の同一性）を比較
   - 証跡: 両経路の exit code と「lint 違反 0 件」を履歴ファイルに 2 行記録（差分があれば差分を併記）
   - 合格条件: 両経路の lint 結果が完全一致（差分 0）。差分が出た場合は本 Unit を未完了として実装承認に進まない

### ドッグフーディング境界保護

- **要件**: 配布物本体に「starter kit 自身か consumer か」を判定する分岐を埋め込まない
- **対応策**:
  - `package.json` の有無自体を opt-in シグナルとして利用
  - docs 反映先を 1 箇所に限定（reviewing-common-base.md / starter kit 内 AI レビュー導線）し、consumer 一般向け導線への波及を防ぐ

### AI エージェント Bash ツール安全パターン

- **要件**: `$(...)` / backtick コマンド置換を Bash ツール引数に含めない（`CLAUDE.md` 規約）
- **対応策**: 本 Unit は npm script 定義のみで、Bash ツール経由のコマンド置換は発生しない

## 技術選定

- **言語**: なし（設定ファイル + docs のみ）
- **フレームワーク**: なし
- **ライブラリ**: `markdownlint-cli2`（既存依存、版固定は Issue #713 で別途）
- **データベース**: なし

## 実装上の注意事項

- **glob パターンの整合**: `scripts.lint:md` の glob は CI ワークフロー `.github/workflows/pr-check.yml` の `markdownlint-cli2-action` の `globs`（`docs/translations/**/*.md` / `prompts/**/*.md` / `*.md`）と同一値を採用。`.markdownlint-cli2.jsonc` の `ignores`（`docs/aidlc/**` / `docs/cycles/**` / `docs/versions/**`）と組み合わせた既存 CI 挙動と整合する。これにより starter kit が長期蓄積する `.aidlc/cycles/*/**/*.md` 等の過去サイクル成果物を `npm run lint:md` の対象外に保ち、unified entrypoint 経由で CI と同一の lint 結果が得られる
- **`name` 最小化**: `package.json` の `name` は `ai-dlc-starter-kit` 固定とし、`version` キーは追加しない（バージョン SoT は `.claude-plugin/marketplace.json` で別管理）
- **`private: true`**: 誤って `npm publish` されないように必須
- **smoke 実行の最小性**: `run-markdownlint.sh` smoke 実行は実行互換確認のみが目的で、サイクル固有引数（{{CYCLE}}）は現サイクル `v2.6.4` を渡せばよい

## 不明点と質問

[Question] なし
[Answer] -

# 論理設計: スキル分離

## 概要

setup/migrate/feedbackを独立スキルに分離し、親スキルのSKILL.mdからルーティング委譲する構造を設計する。

**重要**: この論理設計ではコードは書かず、スキル構成とインターフェース定義のみを行う。

## アーキテクチャパターン

**ファサード + コマンドルーティング**: 親スキルがファサードとしてフェーズ実行とコマンドルーティングの両責務を持ち、独立フローは対応するスキルに委譲する。

## コンポーネント構成

### ディレクトリ構造

```text
skills/
├── aidlc/                        # 親スキル（ファサード）
│   ├── SKILL.md                  # ルータ兼フェーズ実行ファサード
│   ├── CLAUDE.md                 # Claude Code固有設定
│   ├── version.txt               # スターターキットバージョン
│   ├── steps/
│   │   ├── common/               # 共通ステップ（feedback.md除去後）
│   │   ├── inception/
│   │   ├── construction/
│   │   └── operations/
│   ├── scripts/                  # 共有スクリプト（setup/migrate専用除去後）
│   ├── config/
│   ├── templates/
│   └── guides/
├── aidlc-setup/                  # 初期セットアップスキル（新規）
│   ├── SKILL.md
│   ├── version.txt               # read-version.sh用
│   ├── steps/
│   │   ├── 01-detect.md
│   │   ├── 02-generate-config.md
│   │   └── 03-migrate.md
│   ├── scripts/
│   │   ├── init-labels.sh
│   │   ├── setup-ai-tools.sh
│   │   ├── migrate-backlog.sh
│   │   ├── migrate-config.sh
│   │   └── read-version.sh
│   └── templates/
│       ├── config.toml.template   # セットアップ時のconfig生成テンプレート
│       ├── rules_template.md     # .aidlc/rules.md 生成用
│       └── operations_handover_template.md  # .aidlc/operations.md 生成用
├── aidlc-migrate/                # v1→v2移行スキル（新規）
│   ├── SKILL.md
│   ├── steps/
│   │   ├── 01-preflight.md
│   │   ├── 02-execute.md
│   │   └── 03-verify.md
│   └── scripts/
│       ├── migrate-detect.sh
│       ├── migrate-apply-config.sh
│       ├── migrate-apply-data.sh
│       ├── migrate-cleanup.sh
│       └── migrate-verify.sh
└── aidlc-feedback/               # フィードバック送信スキル（新規）
    ├── SKILL.md
    └── steps/
        └── feedback.md
```

### コンポーネント詳細

#### aidlc/SKILL.md（親スキル）
- **責務**: ARGUMENTSパーシング、action検証、フェーズ実行、独立フロー委譲
- **内部依存**: なし（コード・ファイルレベルの直接依存なし）
- **実行時依存**: 子スキルID（`aidlc-setup`, `aidlc-migrate`, `aidlc-feedback`）の存在、AIエージェントのSkillツール委譲機構
- **変更内容**:
  - setup/migrate/feedbackのセクション除去
  - 引数ルーティングテーブルで `setup` → `/aidlc-setup`、`migrate` → `/aidlc-migrate`、`feedback` → `/aidlc-feedback` に委譲
  - フェーズステップ読み込みテーブルから setup/migrate 行を除去
  - フィードバック送信セクションを除去

#### aidlc-setup/SKILL.md
- **責務**: 初期セットアップ（環境検出、設定生成、AIツールセットアップ）
- **内部依存**: なし（親スキルへの依存ゼロ）
- **フロントマター**:
  - name: `aidlc-setup`
  - description: 初期セットアップ
  - argument-hint: `[追加コンテキスト]`

#### aidlc-migrate/SKILL.md
- **責務**: v1→v2移行（プリフライト、移行実行、検証）
- **内部依存**: なし（親スキルへの依存ゼロ）
- **フロントマター**:
  - name: `aidlc-migrate`
  - description: v1→v2移行
  - argument-hint: `[追加コンテキスト]`

#### aidlc-feedback/SKILL.md
- **責務**: フィードバック送信（設定確認、ヒアリング、Issue作成）
- **内部依存**: なし（親スキルへの依存ゼロ）
- **フロントマター**:
  - name: `aidlc-feedback`
  - description: フィードバック送信
  - argument-hint: `[追加コンテキスト]`

## インターフェース設計

### 委譲インターフェース

#### 親スキル → 独立スキル

AI-DLCスキルシステムはプロンプトベースのため、委譲はSKILL.md内のテキスト指示で行う（Skillツール呼び出しが唯一の委譲手段）。

独立フロー系actionが検出された場合の委譲手順:

1. `additional_context` がある場合は引数として付加（単一の生文字列をそのまま透過。パースや変換は行わない）
2. 以下のメッセージを出力して処理を終了:

```text
`/aidlc-{action} {additional_context}` を実行してください。
```

3. AIエージェントがこのメッセージを解釈し、Skillツールで対応するスキルを呼び出す

**制約**: プロンプトベースシステムのため、親スキルは委譲指示の出力のみを行う。呼び出し成功/失敗の検出・エラーハンドリング・再試行はAIエージェント層の責務であり、親スキルの責務範囲外。独立スキルが自身のステップファイル内でドメイン固有のエラーハンドリングを行う。

#### エラーハンドリング

- **無効なaction**（親スキルの責務）: 有効値リストを提示するエラーメッセージ（既存のARGUMENTSパーシングのエラー処理）
- **スキル不在**（AIエージェント層の責務）: Skillツール呼び出し時にスキルが見つからない場合、AIエージェントが一般的なエラーとしてユーザーに報告する。親スキルはこのケースを検知・処理しない

### 各スキルのSKILL.md構造

#### aidlc-setup/SKILL.md

```yaml
---
name: aidlc-setup
description: >
  AI-DLC環境の初期セットアップを実行するスキル。
  プロジェクトの検出、config.toml生成、AIツールセットアップを行う。
  Use when the user says "start setup", "aidlc setup", "セットアップ".
argument-hint: "[追加コンテキスト]"
---
```

本文: ステップファイル `steps/01-detect.md` → `02-generate-config.md` → `03-migrate.md` を順に読み込んで実行する指示。パス解決は自身のベースディレクトリ（SKILL.mdと同じディレクトリ）からの相対パス。

#### aidlc-migrate/SKILL.md

```yaml
---
name: aidlc-migrate
description: >
  v1からv2へのAI-DLC環境移行を実行するスキル。
  プリフライト検証、データ移行、移行後検証を行う。
  Use when the user says "start migrate", "aidlc migrate", "マイグレーション".
argument-hint: "[追加コンテキスト]"
---
```

本文: ステップファイル `steps/01-preflight.md` → `02-execute.md` → `03-verify.md` を順に読み込んで実行する指示。

#### aidlc-feedback/SKILL.md

```yaml
---
name: aidlc-feedback
description: >
  AI-DLCへのフィードバックを送信するスキル。
  フィードバック内容のヒアリングとGitHub Issue作成を案内する。
  Use when the user says "AIDLCフィードバック", "aidlc feedback", "フィードバック送信".
argument-hint: "[追加コンテキスト]"
---
```

本文: `steps/feedback.md` を読み込んで実行する指示。設定確認は `.aidlc/config.toml` を `dasel` で直接読み取る。

## 処理フロー概要

### ユースケース1: `/aidlc setup` の処理フロー

1. ユーザーが `/aidlc setup` を実行
2. 親スキルのSKILL.mdがロードされる
3. ARGUMENTSパーシングで `action=setup` を抽出
4. 引数ルーティングで setup → 独立フロー系と判定
5. 「`/aidlc-setup` を実行してください」と出力
6. AIエージェントが `/aidlc-setup` スキルを呼び出す
7. aidlc-setup/SKILL.mdがロードされ、ステップファイルを順に実行

### ユースケース2: `/aidlc construction` の処理フロー（変更なし）

1. ユーザーが `/aidlc construction` を実行
2. 親スキルのSKILL.mdがロードされる
3. ARGUMENTSパーシングで `action=construction` を抽出
4. フェーズ系actionと判定
5. 共通初期化フロー → Constructionステップを実行（従来と同じ）

## ステップファイル内のパス参照更新

### setup ステップファイル

移動後、`scripts/` への参照を自スキルのベースディレクトリからの相対パスに更新:

| 変更前 | 変更後 |
|--------|--------|
| `scripts/read-version.sh` | `scripts/read-version.sh`（変更なし、自スキル配下） |
| `scripts/migrate-config.sh` | `scripts/migrate-config.sh`（変更なし、自スキル配下） |
| `scripts/init-labels.sh` | `scripts/init-labels.sh`（変更なし、自スキル配下） |
| `scripts/setup-ai-tools.sh` | `scripts/setup-ai-tools.sh`（変更なし、自スキル配下） |
| `scripts/migrate-backlog.sh` | `scripts/migrate-backlog.sh`（変更なし、自スキル配下） |

パスの相対基準がスキルのベースディレクトリであるため、ステップファイル内の `scripts/` 参照はそのまま動作する。

### migrate ステップファイル

同様に、`scripts/` 参照は自スキル配下に移動するため変更不要。

### feedback ステップファイル

`scripts/read-config.sh rules.feedback.enabled` を以下に置換:

```bash
dasel -f .aidlc/config.toml -r toml 'rules.feedback.enabled'
```

**エラーハンドリング**（障害種別ごとにポリシーを分離）:
- `.aidlc/config.toml` 不在: `true`（デフォルト有効）として続行。初回セットアップ前の正常ケース
- `dasel` 未インストール: ユーザーに送信可否を対話確認。設定値を読み取れないため自動判定しない
- TOML破損・キー不在: ユーザーに送信可否を対話確認。設定が意図的に変更されている可能性があるため自動判定しない

## 親スキルSKILL.mdの変更詳細

### 除去するセクション

1. **引数ルーティングテーブル**: `setup`, `migrate`, `feedback` 行を委譲形式に変更
2. **共通初期化フロー**: 「`setup`・`migrate`・`feedback` には適用しない」の注記除去（これらは親スキルで処理しなくなるため）
3. **フェーズステップ読み込みテーブル**: `setup`, `migrate` 行を除去
4. **フィードバック送信セクション**: 全体除去

### 追加するセクション

引数ルーティングテーブルに委譲指示:

```text
| `setup` | `/aidlc-setup` スキルに委譲 |
| `migrate` | `/aidlc-migrate` スキルに委譲 |
| `feedback` | `/aidlc-feedback` スキルに委譲 |
```

## 実装上の注意事項

- **後方互換性は不要**（Intent「制約事項」に明記。利用プロジェクトは次回 `claude install` で最新版が適用される）
- **setup内のmigrate系スクリプトとaidlc-migrateの違い**: `migrate-config.sh`/`migrate-backlog.sh`（setup内）は初回セットアップ時のv1→v2データ移行。`aidlc-migrate` は明示的な移行コマンドによるv1→v2環境移行。同じ「移行」でもユースケースが異なる。移行ロジックの共通化は本Unit（分離）のスコープ外とし、将来のリファクタリングで検討する
- **aidlc-migrateのロールバック**: 既存のmigrateステップファイル（01-preflight.md）でisolatedブランチ（`migrate/v2`）上で作業する設計になっており、失敗時は `git checkout .` でロールバック可能。この既存設計をそのまま移動する
- ステップファイル移動時、gitの履歴追跡のため `git mv` を使用する
- スクリプト内の `SCRIPT_DIR` 変数は相対パスで解決するため、移動後も自動的に正しいパスを参照する
- version.txtは親スキルにも残す（他のスクリプトから参照されるため）。setupスキル用にコピーを配置。バージョン更新時は両箇所の同期が必要（本リポジトリのOperationsで更新処理を追加すること）
- 既存の `skills/aidlc-setup/`（v1用）は先に削除してからsetupスキルを新規作成する

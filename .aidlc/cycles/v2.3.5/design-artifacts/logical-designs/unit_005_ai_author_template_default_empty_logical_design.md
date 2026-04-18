# 論理設計: Unit 005 config.toml.template の ai_author デフォルトを空文字に変更

## 概要

ドメインモデル（`unit_005_ai_author_template_default_empty_domain_model.md`）を具体的な TOML ファイル編集計画として写像する論理設計。対象は 2 つの TOML ファイルに対する数行のテキスト変更のみで、外部スクリプト変更は行わない。

**重要**: この論理設計では**コードは書かず**、TOML ファイル上の編集箇所・編集後の形と、既存仕様との整合観点のみを定義する。

## 責務境界の再確認（3 系統モデルに対応）

ドメインモデルの「正本 / 参照サンプル / フォールバック」の 3 系統に沿って実装対象を整理する（Codex 設計レビュー指摘 #2 対応）。

| 系統 | 実装対象 | 本 Unit での操作 |
|------|---------|----------------|
| 正本（新規生成経路） | `skills/aidlc-setup/templates/config.toml.template` | `ai_author` 行の値 + デフォルト値説明コメントを `""` / 「空なら自動検出」に変更 |
| 参照サンプル（Informational artifact） | `skills/aidlc/config/config.toml.example` | `ai_author` 行の値を `""` に変更（計画の論点 1 で候補 A 確定） |
| フォールバック経路（参考確認のみ） | `skills/aidlc/config/defaults.toml`, `skills/aidlc-setup/config/defaults.toml`, `skills/aidlc-setup/scripts/migrate-config.sh` | **変更なし**（既に `""`）。整合性目視確認のみ実施 |

### 挙動・仕様の依存先（変更なし、参照のみ）

| 論理モデル | 実装対象 | 本 Unit との関係 |
|-----------|---------|----------------|
| `AutoDetectActivation`（挙動マトリクス実装） | `skills/aidlc/steps/common/commit-flow.md` の ai_author 分岐 | **本 Unit のスコープ外**。既存の分岐判定をそのまま利用 |
| 仕様の正本 | `docs/configuration.md:82-83` | 「`ai_author` が空なら自動検出」「`ai_author_auto_detect` が auto-detect の on/off を制御」の規約が明文化済み。本 Unit はこれに依拠 |

### 既知の仕様文言不足（スコープ外、バックログ候補）

`skills/aidlc/steps/common/commit-flow.md:53` には「設定済みなら使用、未設定なら検出」と書かれているが、以下は `docs/configuration.md` 側にのみ明文化されている:

- 空文字 `""` を「未設定」同等に扱う旨
- `ai_author_auto_detect = false` 時の挙動

本 Unit はこの既存仕様に**依拠**するだけで、`commit-flow.md` 側の文言補強はスコープ外（Unit 定義「境界」準拠）。実装レビュー時に別 Issue（バックログ）として文言統一を提案することを推奨する。

## アーキテクチャパターン

**静的既定値宣言の 3 系統別整合性担保**:

- 配布対象のうち**正本**（`config.toml.template`）と**参照サンプル**（`config.toml.example`）の 2 ファイルを静的に書き換える（実行時ロジックは変更しない）
- 書き換え後の整合性は系統別に担保する:
  - 正本: runtime invariant として `ai_author = ""` を保証（setup 時に解釈される値）
  - 参照サンプル: informational integrity として正本と同じ意味（本 Unit ではリテラル同値 `""`）を保証
  - フォールバック・アップグレード経路（`defaults.toml` × 2, `migrate-config.sh`）: 既存の `""` を維持（本 Unit では変更せず、確認のみ）
- `commit-flow.md` の自動検出フローは既存のまま活用する（`空 × true` のパスに入る）

## ファイル別変更設計

### 1. `skills/aidlc-setup/templates/config.toml.template`

setup 時にプロジェクトへ配置される `config.toml` のテンプレート。変更は 2 行。

**現状**（該当部分の構造）:

```toml
# ai_author: Co-Authored-By に使用するAI著者情報
# - 形式: "ツール名 <email>"（推奨）または任意の文字列
# - デフォルト: "Claude <noreply@anthropic.com>"
ai_author = "Claude <noreply@anthropic.com>"
# ai_author_auto_detect: AIツールを自動検出してCo-Authored-Byを付与するか
ai_author_auto_detect = true
```

**変更後**（該当部分の構造）:

```toml
# ai_author: Co-Authored-By に使用するAI著者情報
# - 形式: "ツール名 <email>"（推奨）または任意の文字列
# - デフォルト: ""（空なら自動検出）
ai_author = ""
# ai_author_auto_detect: AIツールを自動検出してCo-Authored-Byを付与するか
ai_author_auto_detect = true
```

**編集点**:

| 行位置 | 現状 | 変更後 |
|-------|------|-------|
| コメント行 | `# - デフォルト: "Claude <noreply@anthropic.com>"` | `# - デフォルト: ""（空なら自動検出）` |
| 値行 | `ai_author = "Claude <noreply@anthropic.com>"` | `ai_author = ""` |

**不変条件**:

- `ai_author_auto_detect = true` には触れない
- 周辺のコメント 2 行（`ai_author: ...`、`形式: ...`）には触れない
- セクション構造（`[rules.git]` 等）には触れない

### 2. `skills/aidlc/config/config.toml.example`

利用者が参照するサンプルファイル。変更は 1 行。

**現状**（該当部分の構造）:

```toml
unit_branch_enabled = false
squash_enabled = true
ai_author = "Claude <noreply@anthropic.com>"
ai_author_auto_detect = true
```

**変更後**（該当部分の構造）:

```toml
unit_branch_enabled = false
squash_enabled = true
ai_author = ""
ai_author_auto_detect = true
```

**編集点**:

| 行位置 | 現状 | 変更後 |
|-------|------|-------|
| 値行 | `ai_author = "Claude <noreply@anthropic.com>"` | `ai_author = ""` |

**不変条件**:

- コメントは追加しない（既存スタイルの「コメントなし 1 行」に合わせる、計画の設計論点 2 で確定）
- 周辺行（`squash_enabled`, `ai_author_auto_detect`）には触れない

## 宣言整合性の確認観点（3 系統別）

`AuthorDeclarationConsistency` を担保するため、以下の 3 系統で `ai_author` の既定値が整合していることを実装レビュー時に目視確認する。役割の違いを保ったまま、それぞれ固有の整合性を担保する。

### 系統 1: 正本（Runtime invariant）

| ファイル | 本 Unit 前 | 本 Unit 後 |
|---------|----------|----------|
| `skills/aidlc-setup/templates/config.toml.template` | `ai_author = "Claude <noreply@anthropic.com>"` | `ai_author = ""` |

- 新規 setup の runtime invariant。この値が利用者の `config.toml` に直接書き込まれる
- コメント行も「空なら自動検出」と整合させる

### 系統 2: 参照サンプル（Informational integrity）

| ファイル | 本 Unit 前 | 本 Unit 後 |
|---------|----------|----------|
| `skills/aidlc/config/config.toml.example` | `ai_author = "Claude <noreply@anthropic.com>"` | `ai_author = ""` |

- 利用者の参照用。リテラル同値を採用（計画の論点 1 で候補 A 確定）
- 同値以外の表現（コメントアウト等）も意味が揃えば可とする設計だが、本 Unit では同値を選択

### 系統 3: フォールバック・アップグレード経路（既存、変更なし）

| ファイル | 値 | 整合性種別 |
|---------|-----|-----------|
| `skills/aidlc/config/defaults.toml` | `ai_author = ""` | Runtime invariant（`read-config.sh` のフォールバック） |
| `skills/aidlc-setup/config/defaults.toml` | `ai_author = ""` | Runtime invariant（setup スキル内のフォールバック） |
| `skills/aidlc-setup/scripts/migrate-config.sh` | `ai_author = ""` | Upgrade-time invariant（v1→v2 マイグレーション時の挿入値） |

- 本 Unit では変更しない（既に `""` で整合済み）
- 目視確認は「3 ファイルで現状維持が確認できること」のみ

## 挙動マトリクスとの整合

本 Unit の既定値変更が有効化する経路を、ドメインモデルの挙動マトリクスに沿って確認する。仕様の正本は `docs/configuration.md:82-83`、実装は既存の `commit-flow.md` 分岐（変更なし）。

| `ai_author` | `ai_author_auto_detect` | 期待される振る舞い | 本 Unit の影響 |
|-------------|------------------------|------------------|----------------|
| `""`（空） | `true` | 自己認識 → 環境変数 → ユーザー確認、ユーザー拒否時は Co-Authored-By なしで続行 | **setup 直後から有効化される**（本 Unit の主目的） |
| `""`（空） | `false` | 自動検出スキップ、Co-Authored-By なしで続行 | 既存仕様のまま |
| `"Name <email>"` | `true` | 明示値 `Name <email>` を採用、自動検出は実行しない | 既存仕様のまま |
| `"Name <email>"` | `false` | 明示値 `Name <email>` を採用、自動検出も実行しない | 既存仕様のまま |

**重要**: 本 Unit は「setup 直後の `config.toml` が 1 行目（`""` × `true`）に入るための**初期条件**」を整えるだけで、`commit-flow.md` の分岐仕様自体は変更しない。

## API 設計

本 Unit は**ファイル内容の静的変更のみ**で、公開インターフェース（コマンド、関数、スクリプト）の追加・変更はない。

- 追加スクリプト: なし
- 変更スクリプト: なし
- 変更設定キー: なし（既存の `ai_author`, `ai_author_auto_detect` は値のみ変更）
- 新規 CLI フラグ: なし

## 検証設計

### 検証項目と検証方法（3 系統別）

| 系統 | 検証項目 | 検証方法 | ドメイン対応 |
|------|---------|---------|------------|
| 正本 | `config.toml.template` の `ai_author` 値が `""` | ファイル grep | `AiAuthorDefault.literal` / 正本 runtime invariant |
| 正本 | `config.toml.template` のコメントが「空なら自動検出」と一致 | ファイル grep | `AiAuthorDefault.comment_description` |
| 参照サンプル | `config.toml.example` の `ai_author` 値が `""` | ファイル grep | `AiAuthorDefault.literal` / informational integrity |
| フォールバック | `defaults.toml` × 2 / `migrate-config.sh` が `""` のまま維持 | 3 ファイルを順に grep（現状維持確認） | `AuthorDeclarationConsistency.fallback_literals` |
| 実行結果 | 新規 setup 後の `config.toml` で `ai_author = ""` | `/tmp` 配下で `aidlc setup` を実行し確認 | 正本 runtime invariant の再確認 |
| 実行結果 | 新規 setup 後 `ai_author_auto_detect = true` | 同上 | `AutoDetectFlagDefault.literal` |
| 挙動 | 自動検出フロー起動経路 | `commit-flow.md` の分岐読解 + 可能ならダミー commit | 挙動マトリクス 1 行目（`""` × `true`） |

### 検証順序

1. **正本の直接検証**: `config.toml.template` を grep で期待値と照合（値 + コメント）
2. **参照サンプルの直接検証**: `config.toml.example` を grep で期待値と照合
3. **フォールバック系統の現状維持確認**: `defaults.toml` × 2 と `migrate-config.sh` を grep し `""` のままであることを確認
4. **setup 実行検証**: 一時ディレクトリで setup を実行し、生成された `config.toml` を grep
5. **commit-flow 分岐読解**: `commit-flow.md` の ai_author 分岐箇所を読み、`空 × true` パスの起動を論理確認
6. **（可能なら）ダミー commit**: 生成プロジェクト内で commit を発生させ、自動検出 or ユーザー確認の分岐が起動することを目視

## スコープ外（論理設計でも明示）

- `commit-flow.md` の自動検出フロー本体の変更
- `ai_author_auto_detect` の既定値（`true`）の見直し
- `defaults.toml`（2 箇所）、`migrate-config.sh` の `ai_author` 値変更（既に `""`）
- 既存プロジェクトの `.aidlc/config.toml` の遡及書き換え
- 旧既定で setup 済みプロジェクトの自動マイグレーション

## 不明点と質問

[Question] `config.toml.template` のコメント行「デフォルト: ""（空なら自動検出）」の文言は `defaults.toml` や `guides/config-merge.md` と表記を統一すべきか？

[Answer] `defaults.toml` はコメントなしで `ai_author = ""` のみ。`guides/config-merge.md` は ai_author を直接言及していない（または参照箇所が薄い）ため、本 Unit では `config.toml.template` 側のコメントを**本質的で簡潔な文言**にとどめる。必要に応じて設計レビュー時に `commit-flow.md` の文言と軽く突き合わせる程度とする。

[Question] `config.toml.example` を `ai_author = "Your Name <you@example.com>"` のようなサンプル値にした方がユーザー向け教育価値が高いのでは？

[Answer] しない。`.example` の主目的は「setup 直後の `config.toml` と同じ状態をコピー参照できるサンプル」であり、サンプル値で教育するのは `guides/` や `rules.md` の役割。本 Unit は既定値整合性を最優先とする（計画の論点 2 と一致）。

[Question] markdownlint は本 Unit の対象外とあるが、TOML コメント内の日本語で既存の lint 規約に抵触しないか？

[Answer] しない。`run-markdownlint.sh` は markdown のみ対象で TOML はスキャン対象外。他 TOML ファイルが既存で日本語コメントを含むため、本 Unit のコメント変更も同様の運用に従い問題なし。

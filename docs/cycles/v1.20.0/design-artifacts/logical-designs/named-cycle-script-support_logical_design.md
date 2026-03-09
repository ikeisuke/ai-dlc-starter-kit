# 論理設計: 名前付きサイクルスクリプト対応

## 概要

5つのスクリプトに名前付きサイクル（`[name]/vX.X.X`）形式の入力を受け付ける変更を加える論理設計。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

既存スクリプトの正規表現・バリデーションを拡張するパターン。各スクリプトは独立しており、共通ライブラリは使用しない（既存設計を維持）。

## コンポーネント構成

### 変更対象

```text
prompts/package/bin/
├── setup-branch.sh         ← バリデーション拡張、worktreeパス正規化
├── aidlc-cycle-info.sh     ← パース拡張、出力キー追加
├── post-merge-cleanup.sh   ← バリデーション拡張
├── init-cycle-dir.sh       ← スラッシュチェック緩和
└── suggest-version.sh      ← パース拡張、ディレクトリスキャン拡張
```

### コンポーネント詳細

#### setup-branch.sh

- **変更箇所**: `validate_version()` 相当の正規表現（L137）、`handle_worktree_mode()` のパス生成（L91）
- **入力**: `$version` - `waf/v1.0.0` or `v1.0.0`
- **出力**: ブランチ `cycle/waf/v1.0.0` or `cycle/v1.0.0`、worktreeパス `.worktree/cycle-waf-v1.0.0` or `.worktree/cycle-v1.0.0`

#### aidlc-cycle-info.sh

- **変更箇所**: `extract_version()`（L42）、main出力セクション（L98-119）
- **入力**: `$branch` - `cycle/waf/v1.0.0` or `cycle/v1.0.0`
- **出力契約**（常時出力、出力順序固定）:

  | キー | 名前付き | 名前なし | 非サイクルブランチ |
  |------|---------|---------|------------------|
  | `current_cycle` | `waf/v1.0.0` | `v1.0.0` | `none` |
  | `cycle_name` | `waf` | `` (空文字) | `none` |
  | `cycle_version` | `v1.0.0` | `v1.0.0` | `none` |
  | `cycle_phase` | (既存) | (既存) | (既存) |
  | `latest_cycle` | (既存) | (既存) | (既存) |
  | `cycle_dir` | `docs/cycles/waf/v1.0.0` | `docs/cycles/v1.0.0` | `none` |

  **規則**: 非サイクルブランチ時は `cycle_name`/`cycle_version` ともに `none` を出力（既存 `current_cycle:none` と同じセンチネル値）。`cycle_name`/`cycle_version` は `current_cycle` の直後に出力

#### post-merge-cleanup.sh

- **変更箇所**: バージョンバリデーション正規表現（L393）
- **入力**: `$CYCLE` - `waf/v1.0.0` or `v1.0.0`
- **出力**: `BRANCH_NAME=cycle/waf/v1.0.0` or `cycle/v1.0.0`（自然生成）

#### init-cycle-dir.sh

- **変更箇所**: `validate_version()` のスラッシュチェック（L99-103）
- **入力**: `$version` - `waf/v1.0.0` or `v1.0.0`
- **出力**: `docs/cycles/waf/v1.0.0/` 配下のディレクトリ構造

#### suggest-version.sh

- **変更箇所**: `get_branch_version()`（L24-25）、`get_latest_cycle()`（L34）
- **入力**: `$branch` - `cycle/waf/v1.0.0` or `cycle/v1.0.0`
- **出力**: `branch_version:v1.0.0`（v付き、後方互換維持）

## 処理フロー概要

### 各スクリプトの名前付きサイクル対応フロー

**共通パターン**: 正規表現にオプショナルな名前プレフィックス `([^/]+/)?` を追加し、キャプチャグループの調整を行う。

1. 入力を受け取る
2. 拡張された正規表現でバリデーション/パース
3. キャプチャグループから名前部分・バージョン部分を抽出
4. 既存のパス生成ロジックで処理（名前部分がスラッシュ付きで自然にパスに含まれる）

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 正規表現変更のみのため影響なし
- **対応策**: 追加のI/Oや外部呼び出しなし

### セキュリティ

- **要件**: パストラバーサル防止
- **対応策**: `init-cycle-dir.sh` がファイルシステム操作前にパス安全性を直接チェック（`..`拒否、スラッシュ制約、先頭/末尾/空セグメント拒否）。`setup-branch.sh`/`post-merge-cleanup.sh` は正規表現でフォーマット検証し、gitがref名の妥当性を担保。パース専用スクリプト（`aidlc-cycle-info.sh`/`suggest-version.sh`）は入力がgit検証済みのブランチ名のため追加チェック不要

### スケーラビリティ

- **要件**: 名前付き・名前なし両方のパターンを1つの正規表現で処理
- **対応策**: オプショナルグループ `([^/]+/)?` で統一的に処理

### 可用性

- **要件**: 既存の `cycle/vX.X.X` ブランチが引き続き正常動作すること
- **対応策**: すべての正規表現変更で名前部分をオプショナル（`?`）にし、従来入力がそのままマッチ

## 実装上の注意事項

- `BASH_REMATCH` インデックスの変更に注意。各スクリプトでキャプチャグループ追加後のインデックスを計画書に明記済み
- `suggest-version.sh` の `get_latest_cycle()` は名前付きブランチの場合に対応するサブディレクトリをスキャンする。名前部分の伝搬方法（グローバル変数 or 関数引数）は実装時に決定
- `aidlc-cycle-info.sh` の `get_latest_cycle()` は名前なし形式のみスキャン（既存動作維持）

## 不明点と質問（設計中に記録）

なし

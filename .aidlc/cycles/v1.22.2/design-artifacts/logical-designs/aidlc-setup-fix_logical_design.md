# 論理設計: aidlc-setupスクリプト修正

## 概要

aidlc-setup.sh のパス解決ロジック改善とエラーメッセージ強化の論理設計。

**重要**: このドキュメントでは**コードは書かず**、コンポーネント構成とインターフェースのみを定義します。

## アーキテクチャパターン

既存のパイプラインパターン（8ステップ直列処理）を維持。変更はパス解決とエラー出力の改善に限定。

## コンポーネント構成

### 変更対象: aidlc-setup.sh

変更箇所は2か所のみ:

#### A. resolve_starter_kit_root() 関数のエラーメッセージ強化

**現状の問題**:
- エラーメッセージが `error:starter-kit-not-found:{簡易メッセージ}` のみ
- 検索したパスや推奨アクションが含まれない

**変更方針**:
- 各フォールバックステージのエラーメッセージに `detail:` 行を追加
- ghq不在時: `AIDLC_STARTER_KIT_PATH` 設定の案内を `detail:` で出力
- ディレクトリ不存在時: 実際に検索したパスを `detail:` で出力

**出力例（ghq不在の場合）**:

```text
error:starter-kit-not-found:ghq not available, set AIDLC_STARTER_KIT_PATH  ← stderr
detail:action:export AIDLC_STARTER_KIT_PATH=/path/to/ai-dlc-starter-kit   ← stderr
detail:searched-pattern:docs/aidlc/skills/*/bin                            ← stderr
detail:project-root:/path/to/project                                       ← stderr
```

#### B. 各依存スクリプト不在時のエラーメッセージ強化

**現状の問題**:
- `warn:check-setup-type-not-found` のみ（パス不明）
- `error:sync-package-not-found` のみ（パス不明）

**変更方針**:
- warn系不在メッセージ: warn行のvalue部にパス情報を含める（stdout統一）
- error系不在メッセージ: 直後に `detail:` 行をstderrに出力（同一ストリーム）

**出力例（check-setup-type.sh不在）**:

```text
warn:check-setup-type-not-found                                                  ← stdout（既存キー、変更なし）
info:searched-path:/path/to/prompts/setup/bin/check-setup-type.sh                ← stdout（新規追加）
```

**出力例（sync-package.sh不在）**:

```text
error:sync-package-not-found                                                     ← stderr
detail:searched-path:/path/to/prompts/package/bin/sync-package.sh                ← stderr
detail:action:verify STARTER_KIT_ROOT is correct                                 ← stderr
```

## インターフェース定義

### 出力ストリーム方針（契約）

| ストリーム | 対象キー | 用途 |
|-----------|---------|------|
| stdout | `mode:*`, `starter_kit_path:*`, `setup_type:*`, `version_*:*`, `warn:*`, `info:*`, `sync:*`, `skip:*` | 正常系出力・警告・補足情報 |
| stderr | `error:*`, `detail:*` | エラー・補足情報 |

**互換性条件**: 既存コンシューマ（AIエージェント）は未知キーを無視可能であることを前提とする。新規 `detail:*` キーは既存パーサーに影響しない。

### 新規追加キー

| キー | 出力先 | 説明 |
|-----|--------|------|
| `detail:searched-path:*` | stderr | 検索した実際のパス |
| `detail:action:*` | stderr | ユーザーへの推奨アクション |
| `detail:searched-pattern:*` | stderr | 検出に使用したパスパターン |
| `detail:project-root:*` | stderr | 検出されたプロジェクトルート |

### 既存インターフェース（変更なし）

以下の既存出力は一切変更しない:
- `mode:dry-run` / `mode:execute`
- `starter_kit_path:{path}`
- `setup_type:{type}`
- `warn:check-setup-type-not-found` → **変更なし**（info:行で補足）
- `error:sync-package-not-found` → **変更なし**（detail行で補足）
- `sync:success` / `sync:dry-run`
- その他全既存キー

**注意**: `warn:check-setup-type-not-found` のvalue部変更は後方互換。既存コンシューマはキー部分（`warn:check-setup-type-not-found`）で判定しており、value部の追加は影響しない。

## 依存関係

### 直接依存（aidlc-setup.sh → 子スクリプト）

```text
aidlc-setup.sh → check-setup-type.sh（任意、-x チェック）
aidlc-setup.sh → migrate-config.sh（任意、-x チェック）
aidlc-setup.sh → sync-package.sh（必須、-x チェック）
aidlc-setup.sh → version.txt（任意、-f チェック）
```

### 環境依存（外部コマンド）

```text
aidlc-setup.sh → dasel（必須、冒頭で -v チェック、不在時 exit 1）
aidlc-setup.sh → ghq（条件付き必須、ユーザーPJモードで環境変数未設定時のみ使用）
aidlc-setup.sh → read-config.sh（条件付き必須、ghq解決時: -x不成立で失敗終了、設定値取得失敗時はデフォルト値フォールバック）
sync-package.sh → rsync（必須、ファイル同期）
```

### 推移依存（sync-package.shの同期対象）

sync-package.sh正常動作時に同期される7ディレクトリ:
`prompts/`, `templates/`, `guides/`, `bin/`, `skills/`, `kiro/`, `lib/`

lib/ の不在（#339）はsync-package.sh不在（#338）の推移的結果。

依存方向は全て一方向（循環なし）。子スクリプトはaidlc-setup.shに依存しない。

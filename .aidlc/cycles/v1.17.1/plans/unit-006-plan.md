# Unit 006 計画: $()コマンドスクリプトファイル化

## 概要

setup-prompt.md内の`$(ghq root)`を使用するスターターキットパス解決ロジックをスクリプトファイル化する。Claude Code等のAIツールで`$()`を含むコマンド実行時の許可確認を不要にする。

## 対象の$()使用箇所

setup-prompt.md内で`$(ghq root)`を使用している箇所:

1. **行119**: `$(ghq root)/github.com/.../check-setup-type.sh` - 通常利用時のcheck-setup-type.sh呼び出し
2. **行530**: `GHQ_ROOT=$(ghq root)` - パス構築の説明例
3. **行865-890**: スターターキットパス解決ブロック（メタ開発/ghq/手動の3段階判定）
4. **行872**: `STARTER_KIT_PATH="$(ghq root)/github.com/ikeisuke/ai-dlc-starter-kit"` - パス解決
5. **行898**: テーブル内の`$(ghq root)/...` - ドキュメント参照

## 変更対象ファイル

1. `prompts/package/bin/resolve-starter-kit-path.sh` - **新規作成**
2. `prompts/setup-prompt.md` - スクリプト呼び出しへの更新

## 実装計画

### 変更1: resolve-starter-kit-path.sh 新規作成

スターターキットのルートパスを解決し、stdoutに出力するスクリプト。

**入力**: なし（環境を自動検出）
**出力（stdout）**: スターターキットのルートパス
**終了コード**: 0=成功, 1=パス解決失敗

**ロジック**（既存の行865-890と同等）:
1. メタ開発モード判定: `prompts/package/` が存在 → `.`（カレントディレクトリ）
2. ghq判定: `command -v ghq` → `$(ghq root)/github.com/ikeisuke/ai-dlc-starter-kit`
3. パス存在確認: `prompts/package` が存在しなければフォールバック
4. 解決失敗: 終了コード1で終了（手動入力が必要な旨をstderrに出力）

### 変更2: setup-prompt.md更新

1. **行119周辺**: 通常利用時の`check-setup-type.sh`呼び出しをスクリプト利用に更新
2. **行865-890**: パス解決ブロックを`resolve-starter-kit-path.sh`呼び出しに置換
3. **行898**: テーブルの`$(ghq root)/...`を更新
4. **行530**: 説明例をスクリプト利用に更新

## 設計方針

1. **後方互換**: 既存の3段階判定ロジック（メタ開発/ghq/手動）を維持
2. **出力形式**: パスのみをstdoutに出力（AIツールが変数に代入しやすい形式）
3. **既存コマンドの置き換えのみ**: 新規機能は追加しない

## 完了条件チェックリスト

- [x] resolve-starter-kit-path.sh を作成（3段階判定、出力・終了コード定義）
- [x] setup-prompt.md の $(ghq root) 使用箇所をスクリプト呼び出しに更新
- [x] スクリプトの実行権限を付与

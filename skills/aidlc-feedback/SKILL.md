---
name: aidlc-feedback
description: >
  AI-DLCへのフィードバックを送信するスキル。
  フィードバック内容のヒアリングとGitHub Issue作成を案内する。
  Use when the user says "AIDLCフィードバック", "aidlc feedback", "フィードバック送信".
argument-hint: "[追加コンテキスト]"
---

# AI-DLC フィードバック送信

フィードバック送信フローを実行する。以下のステップファイルを読み込んで実行すること。

## v2.6.1（Unit 003 / #690）以降の動作

- **デフォルト挙動の変更**: `/aidlc feedback` の Issue 起票デフォルト経路を **直接起票（`gh issue create --body-file`）** に変更（従来は `gh issue create --web` でブラウザ自動起動）
- **opt-in でブラウザ経路**: 従来挙動を維持したい場合は以下のいずれか
  - `.aidlc/config.toml` の `[rules.feedback]` セクションに `open_in_browser = true` を設定
  - 単発実行時は環境変数 `AIDLC_FEEDBACK_WEB=1`（`true` / `yes` も可、大小文字無視）を付けて実行
- **テンプレート構造の SoT**: `.github/ISSUE_TEMPLATE/feedback.yml`（GitHub Issue Form）。両経路でこのファイルを参照する

## 経路判定の優先順位真理値表

優先順位: **TTY 状態 > 設定 > フラグ**（非 TTY / CI 環境では設定・フラグに関わらず常に直接起票）

| # | 設定 `open_in_browser` | 明示フラグ（`AIDLC_FEEDBACK_WEB`） | TTY 状態 | 採用経路 | 警告ログ |
|---|----------------------|---------------------------------|---------|---------|---------|
| 1 | `true` | -    | TTY    | `web`（ブラウザ） | なし |
| 2 | `true` | -    | 非 TTY | `direct`（直接起票） | あり（強制無効化） |
| 3 | `false` / 未設定 | あり | TTY    | `web`（ブラウザ） | なし |
| 4 | `false` / 未設定 | あり | 非 TTY | `direct`（直接起票） | あり（強制無効化） |
| 5 | `false` / 未設定 | なし | TTY    | `direct`（直接起票、デフォルト） | なし |
| 6 | `false` / 未設定 | なし | 非 TTY | `direct`（直接起票、デフォルト） | なし |

判定ロジックは `scripts/lib/resolve-route.sh` の純関数 `resolve_feedback_route` に集約。詳細手順は `steps/feedback.md` 参照。

## ステップ実行

1. `steps/feedback.md` を読み込んで実行 — 設定確認、フィードバック内容ヒアリング、経路判定、Issue 作成案内

## パス解決

- `steps/` で始まるパスはスキルのベースディレクトリ（このSKILL.mdと同じディレクトリ）からの相対パスとして解決する
- `scripts/` で始まるパスも同様にスキルのベースディレクトリからの相対パスとして解決する（例: `scripts/lib/resolve-route.sh`）
- 他スキル（`aidlc` プラグイン等）の `scripts/` を呼び出す場合はリポジトリルート相対の絶対参照を使う（例: `bash skills/aidlc/scripts/read-config.sh ...`）

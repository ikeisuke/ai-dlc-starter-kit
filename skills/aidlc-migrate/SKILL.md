---
name: aidlc-migrate
description: >
  AI-DLC環境の v2→v3 移行を実行するスキル。
  プリフライト検証、config/state 変換、アーカイブ索引生成を行う。
  v1 環境は v2-maintenance branch の aidlc-migrate を案内する。
  Use when the user says "start migrate", "aidlc migrate", "マイグレーション".
argument-hint: "[追加コンテキスト]"
---

# AI-DLC 世代間移行（v2→v3）

環境の世代を検出し、対応する移行フローを実行する。

## 移行対象の判定（バージョンルーティング）

ファイル存在の opt-in シグナルのみで、以下を**評価順**に判定する
（リポジトリ固有の判定は行わない）:

| 順 | 判定シグナル | ルーティング |
|----|------------|------------|
| 1 | `.aidlc/state.json` が存在 | 既に v3 移行済み。その旨を案内して終了（書き込みなし） |
| 2 | `docs/aidlc.toml` が存在（v1 マーカー） | v1→v2 移行の案内のみ（下記「v1 環境の扱い」/ 書き込みなし） |
| 3 | `.aidlc/config.toml` が存在 | v2→v3 フロー（`steps/v3-migrate.md` を読み込んで実行） |
| 4 | いずれも不在 | AI-DLC 未セットアップ。`/aidlc define` での新規開始を案内して終了 |

> v1 と v2 のシグナルが同時に該当する場合は v1 の案内を優先する（評価順のとおり）。
> **1 実行 1 世代**: v1→v2 移行（v2-maintenance 側）完了後に本スキルを再実行すると v2→v3 に進む。

## v1 環境の扱い（v1→v2 は v2-maintenance branch へ移管）

v3.0.0-rc.1 の本流化に伴い、v1→v2 移行フロー（旧 `steps/01-preflight.md` /
`02-execute.md` / `03-verify.md` と関連スクリプト）は main から撤去され、
`v2-maintenance` branch に保全されている。v1 マーカーを検出した場合は以下を案内して
**終了する（書き込みなし）**:

1. `v2-maintenance` branch（`ikeisuke/ai-dlc-starter-kit`）の aidlc-migrate で v1→v2 移行を実施する
2. v2 化完了後、main（v3）の本スキルを再実行して v2→v3 移行に進む

## v2→v3 ステップ実行

`steps/v3-migrate.md` を読み込んで実行する（preflight → 片方向警告 → ★モード選択 →
プラン生成 → ★変換結果確認 → 適用 → サマリ。人間確認ゲート 2 箇所 / commit しない）。
手順方針の正本は `docs/v3/migration.md` §6。

## パス解決

- `steps/` および `scripts/` で始まるパスはスキルのベースディレクトリ（このSKILL.mdと同じディレクトリ）からの相対パスとして解決する
- Bashコマンドで `scripts/` 配下のスクリプトを実行する場合は、解決した絶対パスを使用すること

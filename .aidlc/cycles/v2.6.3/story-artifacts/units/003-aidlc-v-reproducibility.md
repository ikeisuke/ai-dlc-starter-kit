# Unit: /aidlc v 経路の再現性向上

## 概要

`/aidlc v`（バージョン表示）経路で AI エージェントがバージョンを内部知識から誤推測したり marketplace.json のパス組み立てを誤ったりする再現性問題を、SKILL.md「バージョン表示」節の文言追加（A 案）と `version.sh` の自己解決化（C 案）の併用で構造的に解消する（#698）。

## 含まれるユーザーストーリー

- ストーリー 5: /aidlc v 経路の再現性向上（#698）

## 責務

- SKILL.md「バージョン表示」節に base dir 解決手順（`Base directory for this skill:` 行参照）の一文を追加（A 案）
- SKILL.md「バージョン表示」節に「Bash 失敗/不存在の場合のみ `(version unknown)`、内部知識からの推測禁止」の禁則を追加（A 案）
- `skills/aidlc/scripts/lib/version.sh` を引数なし CLI モードでスクリプト自身の位置から marketplace.json を内部解決するよう改修（C 案）
- marketplace.json パス引数渡しを test override として後方互換で残す
- SKILL.md「バージョン表示」節の AI 実行に不要な経緯情報（zsh OOM 経緯 / 関数仕様詳細 / Unit・Issue メタ情報）を退避し本文を圧縮

## 境界

- バージョン算出ロジック自体（semver パース・正規化）の変更は行わない
- `/aidlc v` 以外のアクション経路の改修は行わない
- SKILL.md 本文 500 行制限を超えないこと

## 依存関係

### 依存する Unit

- なし

### 外部依存

- `.claude-plugin/marketplace.json`（version の Single Source of Truth）
- `skills/aidlc/scripts/lib/bootstrap.sh`（スクリプト位置からの相対パス算出ロジックの参考元）

## 非機能要件（NFR）

- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: `/aidlc v` の既存呼び出し経路で従来と同一のバージョン文字列が出力されること（互換維持）

## 技術的考慮事項

- `bootstrap.sh` が既にスクリプト位置からの相対パス算出ロジックを持つため、`version.sh` の自己解決はそれを参考にできる
- marketplace.json はスキルベースディレクトリ外（`{SKILLベース}/../../.claude-plugin/marketplace.json`）にあるため、自己解決ロジックの相対パス基点に注意する
- 退避先候補は `version.sh` 冒頭コメント / `references/` / Issue #688（SKILL.md 本文からの退避）

## 関連Issue

- #698

## 実装優先度

Medium

## 見積もり

中（SKILL.md 改訂 + version.sh 自己解決化 + 後方互換維持 + 本文圧縮・行数確認）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-15
- **完了日**: 2026-05-15
- **担当**: AI Agent (Claude Code Opus 4.7)
- **エクスプレス適格性**: -
- **適格性理由**: -

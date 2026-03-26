# 既存コード分析

## 対象ファイル

### プロンプト・ガイド（prompts/package/配下）

| ファイル | サイズ | 改善内容 |
|----------|--------|----------|
| `prompts/construction.md` | 31KB | AIレビュー実施タイミングの明示化 (#144) |
| `guides/sandbox-environment.md` | 13KB | 認証方式・サンドボックス種類の説明追加 (#141) |
| `guides/ai-agent-allowlist.md` | 18KB | スクリプト化対応の記載追加 (#142) |

### 新規作成が必要

| 対象 | 内容 |
|------|------|
| Construction → Operations引き継ぎ | テンプレート・ガイド作成 (#140) |
| サイクル横断ドキュメント置き場 | ディレクトリ構造・ガイドライン作成 (#104) |
| 定型コマンドスクリプト | `docs/aidlc/bin/` に追加 (#142) |

## 依存関係

- メタ開発のため `prompts/package/` を編集
- Operations Phaseでrsyncにより `docs/aidlc/` に反映
- `docs/cycles/rules.md` にメタ開発ルールが記載済み

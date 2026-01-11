# リリース後の運用記録

## リリース情報

- **バージョン**: v1.7.1
- **リリース予定日**: 2026-01-11
- **リリース内容**: AI-DLCスターターキットの改善（8 Units）

## 主なリリース内容

### 追加機能

1. **Unit 001**: バックログモード修正 - issueモード時のバックログ管理を正常化
2. **Unit 002**: バックログラベル作成 - setup.mdにラベル作成手順を追加
3. **Unit 003**: AskUserQuestion順序ルール - 推奨オプションを一番上に配置するルール
4. **Unit 004**: AIレビューイテレーション改善
5. **Unit 005**: Unitブランチ設定 - `[rules.unit_branch].enabled`設定の統合
6. **Unit 006**: 複合コマンド削減 - 許可リスト運用の改善
7. **Unit 007**: iOSバージョンタイミング - Inception Phaseでのバージョン更新対応
8. **Unit 008**: jjサポート有効化フラグ - `[rules.jj].enabled`設定の追加

### 設定追加

```toml
[rules.unit_branch]
enabled = false  # Unitブランチ作成の提案を無効化

[rules.jj]
enabled = false  # jjコマンド優先案内を無効化（デフォルト）
```

## 残バックログ

### ローカルファイル（docs/cycles/backlog/）

- feature-backlog-single-source-option.md

### GitHub Issues

| # | タイトル | 優先度 |
|---|---------|--------|
| 26 | サンドボックス環境での実行ガイド作成 | 中 |
| 27 | ホームディレクトリにユーザー共通設定を配置可能にする | 低 |
| 28 | Issue駆動統合設計 | 低 |
| 29 | AIエージェント向け許可リスト推奨機能 | 中 |
| 30 | aidlc.toml.local による個人設定サポート | 中 |
| 31 | GitHub Projects連携 | 低 |

## 次期バージョンの計画

### 対象バージョン

v1.8.0（予定）

### 主要な改善・新機能候補

- aidlc.toml.local による個人設定サポート（Issue #30）
- サンドボックス環境での実行ガイド（Issue #26）
- AIエージェント向け許可リスト推奨機能（Issue #29）

## 備考

- メタ開発のため、リリース前にAI-DLC環境アップグレード（rsync同期）を実行

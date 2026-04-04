# Unit: cyclesディレクトリgit管理外オプション

## 概要
.aidlc/cycles/ディレクトリをgit管理外にするオプションを追加し、OSSリポジトリでの利用体験を向上させる。aidlc-setup時に案内メッセージを表示する（自動変更は行わない）。

## 含まれるユーザーストーリー
- ストーリー 7: cyclesディレクトリのgit管理外オプション（#434）

## 責務
- defaults.tomlにrules.cycle.git_tracked設定を追加（デフォルト: true）
- aidlc-setupスキルでread-config.sh経由でgit_tracked値を取得し、false時に案内ロジックを実行
- .gitignoreに既に記載済みの場合の重複案内回避

## 境界
- .gitignoreの自動変更は行わない（案内のみの非破壊方針）
- 既に追跡済みのファイルのuntrackは行わない
- .aidlc/config.tomlのgit管理は変更しない（cyclesのみ対象）
- Gitリポジトリでない場合は案内をスキップする

## 依存関係

### 依存する Unit
- なし（論理的な依存はない。Unit 001とdefaults.tomlを同時編集する場合は競合に注意）

### 外部依存
- なし

## 非機能要件（NFR）
- **後方互換性**: config.tomlにgit_tracked設定がなくてもエラーにならないこと
- **安全性**: 自動でファイルシステムやGit管理を変更しないこと

## 技術的考慮事項
- aidlc-setupスキルのアップグレードフロー内で案内を表示
- .gitignore確認: `grep -q '.aidlc/cycles/' .gitignore 2>/dev/null` で既存記載チェック
- Gitリポジトリ判定: `git rev-parse --is-inside-work-tree 2>/dev/null`

## 関連Issue
- #434

## 実装優先度
Medium

## 見積もり
小規模（defaults.toml、aidlc-setupスキルの修正）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-04-04
- **完了日**: 2026-04-04
- **担当**: AI
- **エクスプレス適格性**: -
- **適格性理由**: -

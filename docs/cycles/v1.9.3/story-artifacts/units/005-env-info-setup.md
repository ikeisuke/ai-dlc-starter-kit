# Unit: env-info.sh セットアップ情報追加

## 概要
env-info.sh に --setup オプションを追加し、セットアップ時に必要な情報を一括出力できるようにする。

## 含まれるユーザーストーリー
- ストーリー 7: env-info.shセットアップ情報追加 (#81)

## 責務
- --setup オプションの追加
- 追加情報の出力（project.name, backlog.mode, current_branch, latest_cycle）
- 既存出力との後方互換性維持

## 境界
- setup.md の変更は最小限（新オプション利用への切り替えのみ）

## 依存関係

### 依存する Unit
なし

### 外部依存
なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
対象ファイル:
- `prompts/package/bin/env-info.sh`
- `prompts/package/prompts/setup.md`（任意）

出力形式:
```
gh:available
dasel:available
jj:available
git:available
project.name:ai-dlc-starter-kit
backlog.mode:issue-only
current_branch:main
latest_cycle:v1.9.2
```

## 実装優先度
Medium

## 見積もり
中

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -

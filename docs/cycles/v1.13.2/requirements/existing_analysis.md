# 既存コード分析

## サイクル: v1.13.2

## 対象ファイル

### 1. #169 init-label処理

**関連ファイル**:
- `prompts/package/bin/init-labels.sh` - ラベル作成スクリプト
- `prompts/setup-prompt.md` - セットアップ・アップグレードプロンプト

**現状**:
- `init-labels.sh` はセットアップ時に呼ばれる（8.2.6節）
- スクリプトは `prompts/package/bin/` → `docs/aidlc/bin/` にrsync同期される

**問題点**:
- アップグレード時にinit-label処理が呼ばれているかの確認が必要
- スクリプトがsync対象になっている設計が適切かの検討

### 2. #162 backlogディレクトリ作成

**関連ファイル**:
- `prompts/package/bin/init-cycle-dir.sh` - サイクルディレクトリ作成スクリプト

**現状**:
- 既に `issue-only` モード時のスキップ処理あり（181-183行目）
- `get_backlog_mode()` 関数でモードを取得

**問題点**:
- Issueの説明では「issue-onlyモード時に不要なbacklogディレクトリが作成される」とあるが、コードには対応済みに見える
- 実際の動作確認が必要（条件分岐が正しく動作しているか）

### 3. #172 operations.md分割

**関連ファイル**:
- `prompts/package/prompts/operations.md` - 1,109行

**現状**:
- 1,000行制限を超過（109行オーバー）
- 分割候補セクション:
  - セルフアップデート処理（スキル化で削減可能）
  - 共通フローの外部化

### 4. #170 コンパクション時のプロンプト読み込み

**関連ファイル**:
- `prompts/package/prompts/inception.md`
- `prompts/package/prompts/construction.md`
- `prompts/package/prompts/operations.md`

**現状**:
- 「コンテキストリセット対応」セクションは存在
- コンパクション時にプロンプトを読み込む明示的な指示なし

**対応方針**:
- 各フェーズに「コンパクション時の対応」セクションを追加
- または progress.md に「再開時に読み込むべきファイル」を記載

### 5. セルフアップデート簡略化

**関連ファイル**:
- `prompts/package/prompts/operations.md`
- `docs/aidlc/skills/aidlc-upgrade/SKILL.md`

**現状**:
- operations.md内にセルフアップデート手順が詳細に記載
- aidlc-upgradeスキルが既に存在

**対応方針**:
- operations.md内の手順を「/aidlc-upgrade スキルを実行」に置き換え
- 行数削減にも寄与

## 依存関係

```
#169 init-label修正
  └── 独立（他に依存なし）

#162 backlogディレクトリ作成
  └── 独立（他に依存なし）

#172 operations.md分割
  ├── セルフアップデート簡略化と同時対応
  └── #170 と一部重複（プロンプトファイル変更）

#170 コンパクション対応
  └── 独立（他に依存なし）
```

## 技術的リスク

- **低**: スクリプト変更は既存機能の改善であり、新規追加ではない
- **低**: プロンプトファイル変更は後方互換性を維持
- **注意**: rsync同期後のスクリプト実行可否（実行権限の確認）

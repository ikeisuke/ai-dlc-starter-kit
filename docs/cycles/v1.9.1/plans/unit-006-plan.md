# Unit 006 計画: プロンプトの圧縮・統合

## 概要

開始プロンプトを圧縮し、コンテキスト消費を削減する。

## 変更対象ファイル

1. `prompts/package/bin/init-cycle-dir.sh`
   - backlogディレクトリ（`docs/cycles/backlog/`, `docs/cycles/backlog-completed/`）の作成を追加

2. `prompts/package/prompts/setup.md`
   - ステップ10のbacklogディレクトリ作成を削除（init-cycle-dir.shに統合）
   - AI-DLC手法の要約は維持（セットアップは単独で使用されるため）

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 変更範囲の影響分析
2. **論理設計**: スクリプト変更の詳細設計

### Phase 2: 実装

1. **init-cycle-dir.sh の拡張**:
   - DIRECTORIESの配列定義は変更せず、新しい関数を追加
   - 共通バックログディレクトリ（サイクル非依存）の作成処理を追加
   - `--dry-run`対応

2. **setup.md の簡略化**:
   - ステップ10の手動backlogディレクトリ作成を削除
   - 完了メッセージの更新

3. **検証**:
   - init-cycle-dir.sh --dry-run でbacklogディレクトリが出力されることを確認
   - 既存機能への影響なし確認

## 完了条件チェックリスト

- [ ] AI-DLC手法の要約の共通化（重複削除）
- [ ] init-cycle-dir.sh でbacklogディレクトリも作成するよう拡張
- [ ] 冗長な説明の削減

## 備考

- AI-DLC手法の要約は、setup.mdとcommon/intro.mdの両方に存在するが、setup.mdはセットアップ専用で単独使用されるため、削除せず維持する（これは「重複」ではなく「必要な参照」）
- 主な圧縮対象は、setup.mdのステップ10にある手動backlogディレクトリ作成の削除

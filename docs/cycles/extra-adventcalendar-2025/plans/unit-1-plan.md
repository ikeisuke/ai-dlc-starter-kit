# Unit-1 実装計画（Lite版）

## Unit情報
- **Unit名**: AI-DLC概念説明セクション
- **依存関係**: なし
- **優先度**: 高

## 対応ユーザーストーリー
- US-1: AI-DLCの概念を理解したい

## 簡易実装先確認

### 1. 対象ファイルの分類
- **成果物側**（`docs/cycles/extra-adventcalendar-2025/`）
- **新規作成**

### 2. 実装先ファイル一覧

| ファイルパス | 種別 | 変更概要 |
|-------------|------|----------|
| `docs/cycles/extra-adventcalendar-2025/article/section-1-aidlc-concept.md` | 新規作成 | AI-DLC概念説明セクションの本文 |
| `docs/cycles/extra-adventcalendar-2025/construction/units/unit-1_implementation.md` | 新規作成 | 簡易実装記録 |
| `docs/cycles/extra-adventcalendar-2025/construction/progress.md` | 更新 | Unit-1完了に更新 |

## 成果物の内容

### section-1-aidlc-concept.md に含める内容

1. **AI-DLCとは**
   - AI-Driven Development Lifecycleの定義
   - AIを開発プロセスの中心に据えるという思想

2. **3つのフェーズ**
   - Inception Phase（要件定義）
   - Construction Phase（実装）
   - Operations Phase（運用）

3. **従来手法との比較**
   - SDLC（人間中心・長期サイクル）
   - Agile（反復・チーム協調）
   - AI-DLC（AI主導・短サイクル）

4. **AI-DLCの主要原則**
   - 会話の反転: AIが計画提示、人間が承認
   - 設計技法の統合: DDD・BDD・TDDのAI自動適用
   - 冪等性の保証

## 実装手順

1. `article/` ディレクトリ作成
2. `section-1-aidlc-concept.md` 執筆
3. 簡易実装記録作成
4. progress.md更新
5. 履歴記録・コミット

## 備考
- 記事執筆プロジェクトのため、ビルド・テストは該当なし
- 後続のUnit-2, Unit-3, Unit-4がこのセクションに依存

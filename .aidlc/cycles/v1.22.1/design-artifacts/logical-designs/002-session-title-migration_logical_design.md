# 論理設計: session-titleスキル移行

## 変更方針

### 1. ファイル削除
- `prompts/package/skills/session-title/` を完全削除（SKILL.md + bin/aidlc-session-title.sh）

### 2. フェーズプロンプト更新パターン
各フェーズの「セッション判別設定」セクションを以下に統一:
- session-titleスキルが利用可能な場合に実行する旨を記述
- 利用不可の場合はスキップ（既存仕様の維持）
- 具体的なスクリプトパスの記述を削除（外部スキル化のため）

### 3. ai-tools.md更新
- activeなスキル一覧テーブルからsession-titleの行を削除
- スキル概要テーブルからsession-titleの行を削除

### 4. skill-usage-guide.md更新
- スターターキット同梱スキルのディレクトリ構成からsession-titleを除外
- 予約名リストからsession-titleを除外
- 外部スキルとしてのインストール案内を追加

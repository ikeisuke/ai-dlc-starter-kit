# 既存コードベース分析

## ディレクトリ構造・ファイル構成

Wave 2の対象は `skills/aidlc/` 配下のプロンプトファイル群。

```
skills/aidlc/
├── SKILL.md (9,703B) — エントリポイント
├── steps/
│   ├── common/ — 全フェーズ共通ステップ
│   │   ├── agents-rules.md (3,841B) ← S3: 統合対象
│   │   ├── rules.md (10,891B) ← S18: 分割対象
│   │   ├── preflight.md (8,774B)
│   │   ├── compaction.md (6,528B) ← S6: 二重ロード解消対象
│   │   ├── review-flow.md (11,945B) ← S10: 圧縮対象
│   │   ├── review-flow-reference.md (7,438B)
│   │   ├── commit-flow.md (3,626B)
│   │   ├── task-management.md (3,885B)
│   │   ├── session-continuity.md (2,274B)
│   │   └── context-reset.md (2,619B)
│   ├── inception/ (43,541B 合計)
│   │   ├── 01-setup.md (10,945B)
│   │   ├── 02-preparation.md (5,738B)
│   │   ├── 03-intent.md (6,704B)
│   │   ├── 04-stories-units.md (8,014B)
│   │   ├── 05-completion.md (11,135B) ← S17: 完了処理共通化対象
│   │   └── 06-backtrack.md (1,005B)
│   ├── construction/ (26,439B 合計)
│   │   ├── 01-setup.md (5,777B)
│   │   ├── 02-design.md (3,513B)
│   │   ├── 03-implementation.md (8,873B)
│   │   └── 04-completion.md (8,276B) ← S17: 完了処理共通化対象
│   └── operations/ (31,488B 合計)
│       ├── 01-setup.md (3,855B)
│       ├── 02-deploy.md (8,879B)
│       ├── 03-release.md (2,002B)
│       ├── 04-completion.md (10,311B) ← S17: 完了処理共通化対象
│       └── operations-release.md (6,441B)
├── templates/ — 外部化済みテンプレート（Wave 1で整理済み）
├── guides/ — ガイドドキュメント（必要時参照）
├── scripts/ — シェルスクリプト
└── config/ — デフォルト設定
```

## アーキテクチャ・パターン

### ロードパターン（現状）

SKILL.md の共通初期化フローで以下の順にファイルをロード:
1. `agents-rules.md` → `rules.md` → `preflight.md`（ステップ1）
2. `session-continuity.md`、必要時 `compaction.md`（ステップ3）
3. フェーズ全ステップファイル一括ロード（ステップ4）

根拠: SKILL.md「ステップ4: フェーズステップ読み込み」で全ステップファイルをReadツールで読み込む指示

### 重複パターン

| 重複箇所 | 重複率 | 根拠 |
|---------|--------|------|
| agents-rules.md ↔ rules.md | ~40% | Issue #519の分析。質問と深掘り・禁止事項・コンテキスト要約の記述が重複 |
| 完了処理（3フェーズ） | 共通要素多数 | 各completion.md に履歴記録・squash・コミット・コンテキストリセットの類似手順 |

### compaction.md二重ロード

- **ロード元1**: 共通初期化フローのステップ3（session-continuity.md経由、コンパクション復帰時のみ）
- **ロード元2**: SKILL.md不変ルール内の「コンパクション復帰時」で`compaction.md`を読み込む指示

根拠: Issue #519「compaction.mdの二重ロード: CLAUDE.mdの@参照 + 01-setup.mdのRead指示」

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| プロンプト形式 | Markdown | 全ステップファイル |
| スクリプト言語 | Bash (POSIX sh互換) | scripts/*.sh |
| 設定形式 | TOML | .aidlc/config.toml, config/defaults.toml |
| 設定パーサー | dasel v3 | scripts/read-config.sh、env-info.sh出力 |

## 依存関係

### Wave 2対象ファイル間の依存関係

```
SKILL.md (不変ルール内でcompaction.md参照)
  ↓
agents-rules.md → rules.md に内容重複（S3で統合）
  ↓
rules.md → 全ステップファイルから参照（S18で3分割）
  ↓
review-flow.md → review-flow-reference.md を参照（S10で圧縮）
  ↓
**/completion.md → commit-flow.md, review-flow.md を参照（S17で共通化）
```

### 循環依存: なし

各ステップファイルは前方参照のみ（Issue #519 Codex分析で確認済み）。

## 特記事項

- Wave 1実施後（v2.2.0）のファイルサイズはIssue #519作成時の計測値と概ね一致（rules.md: 10,891B vs 11,057B、review-flow.md: 11,945B vs 12,375B。微減はWave 1の間接的効果）
- Inception Phase初回ロード推定: ~88KB（SKILL.md + common全ファイル + inception全ファイル）。Issue #519の80KB推定より大きいが、task-management.mdやreview-flow-reference.mdを含むため
- 実際のランタイムロードはステップ4の指示に従うため、review-flow.mdやcommit-flow.mdは必要時のみロードされる。常時ロード分のベースラインはトークン計測で正確に把握する必要がある

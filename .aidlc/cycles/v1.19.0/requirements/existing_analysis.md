# 既存コード分析

## 分析対象

v1.19.0で変更が必要な既存ファイル・機能の特定

---

## 1. jjサポート関連（#276）

### 削除対象ファイル

| パス | 内容 |
|------|------|
| `prompts/package/skills/versioning-with-jj/SKILL.md` | jjスキル定義（101行） |
| `prompts/package/skills/versioning-with-jj/references/jj-support.md` | Git/jjコマンド対照表（559行） |

### 参照除去が必要なプロンプトファイル

| ファイル | 該当行 | 内容 |
|---------|--------|------|
| `prompts/package/prompts/common/rules.md` | L20-21, L86-90, L157 | jjサポート設定セクション、コマンド読み替え指示 |
| `prompts/package/prompts/common/commit-flow.md` | L171-175, L213-217, L309-312, L354-368, L395-409, L421-422, L438-439, L446-449, L489-506, L514, L558 | jj環境での状態確認・コミット・squashフロー |
| `prompts/package/prompts/common/ai-tools.md` | L25 | jjスキル参照テーブル行 |
| `prompts/package/prompts/inception.md` | L149, L935 | env-info出力テーブル、squash注釈 |
| `prompts/package/prompts/construction.md` | L780 | squash注釈 |
| `prompts/package/prompts/operations.md` | L23 | タグ操作のjj制限注釈 |

### 参照除去が必要なスクリプト

| ファイル | 該当箇所 | 内容 |
|---------|---------|------|
| `docs/aidlc/bin/env-info.sh` | L27,46,53,118-126,154,243,246 | jj検出・ブックマーク取得 |
| `docs/aidlc/bin/aidlc-cycle-info.sh` | L17-28 | jj優先のブランチ取得 |
| `docs/aidlc/bin/aidlc-env-check.sh` | L11,46,49 | jjチェック |
| `docs/aidlc/bin/aidlc-git-info.sh` | L3,9,22-26,44-46,73-75,100-104 | VCS判定・jj状態取得 |
| `docs/aidlc/bin/squash-unit.sh` | L5,44,48,103-107,188,370-384,706-707,747-748,807-907,1122-1130,1183-1186,1195-1196,1213-1214,1226-1227 | jj squash全実装 |
| `docs/aidlc/bin/migrate-config.sh` | L206-209 | jjセクション追加処理 |

### 設定ファイル

- `docs/aidlc.toml` L102-107: `[rules.jj]` セクション → 設定は残存、`enabled=true`時に警告

---

## 2. Session Continuity（#218-10）

### 既存のセッション管理機構

| 機構 | ファイル | 内容 |
|------|---------|------|
| compaction対応 | `prompts/package/prompts/common/compaction.md` | 自動要約後のautomation_mode復元（5ステップ） |
| コンテキストリセット | `prompts/package/prompts/common/context-reset.md` | 手動リセット時の継続プロンプト提示 |
| progress.md | 各フェーズ固有 | ステップ状態保持（未着手/進行中/完了） |
| 履歴ファイル | `docs/cycles/{{CYCLE}}/history/` | 中断状態の記録 |
| Unit実装状態 | Unit定義ファイル末尾 | 実装状態セクション |

### 変更対象

- `compaction.md`: session-state.md生成ロジック追加
- `context-reset.md`: session-state.md生成・復元手順追加
- 各フェーズプロンプト: コンテキストリセット提示時にsession-state.md生成を追加
  - `inception.md` L53-82, L939-965
  - `construction.md` L124-126, L912-960
  - `operations.md` L57-59, L566-689

---

## 3. Depth Levels（#218-2）

### 現状

- 成果物の詳細度制御は**未実装**（履歴記録の`[rules.history].level`のみ）
- テンプレートはすべて固定構造
- プロンプトのステップ指示も固定

### 変更対象

| カテゴリ | ファイル | 変更内容 |
|---------|---------|---------|
| 設定 | `docs/aidlc.toml` | `[rules.depth_level]` セクション追加 |
| 共通ルール | `prompts/package/prompts/common/rules.md` | Depth Level判定ロジック追加 |
| Inception | `prompts/package/prompts/inception.md` | ステップ1-5の成果物詳細度調整 |
| Construction | `prompts/package/prompts/construction.md` | Phase 1-2の設計・実装詳細度調整 |
| Operations | `prompts/package/prompts/operations.md` | ステップ1-5の成果物詳細度調整 |
| テンプレート | `docs/aidlc/templates/*.md` | Depth Level別セクション注記追加 |

### テンプレート一覧（主要13個）

Inception: intent, user_stories, unit_definition, prfaq
Construction: domain_model, logical_design, implementation_record
Operations: deployment_checklist, monitoring_strategy, distribution_feedback, post_release_operations
共通: review_summary, backlog_item

---

## 4. Overconfidence Prevention（#218-1）

### 既存の関連機構

- `common/rules.md` L52-80: 「予想禁止・一問一答質問ルール」 → Overconfidence Preventionの一部を既にカバー
- AskUserQuestion機能の活用ルール（CLAUDE.md）

### 変更対象

- `prompts/package/prompts/common/rules.md`: 既存の質問ルールを Overconfidence Prevention原則として体系化・強化

---

## 5. Reverse Engineering（#218-3）

### 既存の関連機構

- `inception.md` L672-679: ステップ2「既存コード分析（brownfieldのみ、greenfieldはスキップ）」
  - 既存コードベースの分析
  - `existing_analysis.md` 作成
  - 最小限の手順のみ（構造解析・パターン検出・技術スタック推定は未定義）

### 変更対象

- `prompts/package/prompts/inception.md`: ステップ2を Reverse Engineeringステージとして拡張（構造解析・パターン検出・技術スタック推定・依存関係マッピングの体系的手順を追加）

# Unit 001: スキル分離 — 実行計画

## 概要

setup/migrate/feedbackを独立スキルに分離し、親スキル（SKILL.md）からのルーティングを委譲形式に変更する。

## 設計上の決定事項

### 命名方針

既存 `skills/aidlc-setup/` はv1用途のアップグレードスキルのため削除する。

- `aidlc-setup`（既存v1用） → 削除
- `aidlc-setup` → 初期セットアップ用（新規作成。既存setupフローを移行）
- `aidlc-migrate` → v1→v2移行用（新規作成）
- `aidlc-feedback` → フィードバック送信用（新規作成）

### 親スキルの責務定義

親スキル（`skills/aidlc/SKILL.md`）はルータ兼フェーズ実行ファサード:

1. ARGUMENTSパーシング（action + additional_context の抽出）
2. actionの有効値検証（無効値時のエラーメッセージ出力）
3. フェーズ系action（inception/construction/operations/express）: 自身が共通初期化フローとフェーズステップを実行
4. 独立フロー系action（setup/migrate/feedback）: 対応する独立スキルへ委譲

**委譲契約表**:

| action | 委譲先スキル | 入力 | 出力 | エラー時 |
|--------|------------|------|------|---------|
| `inception` / `i` | 自身（共通初期化フロー） | additional_context | フェーズ実行 | - |
| `construction` / `c` | 自身（共通初期化フロー） | additional_context | フェーズ実行 | - |
| `operations` / `o` | 自身（共通初期化フロー） | additional_context | フェーズ実行 | - |
| `express` / `e` | 自身（共通初期化フロー） | additional_context | フェーズ実行 | - |
| `setup` | `aidlc-setup` | additional_context | セットアップ完了 | スキル不在時エラー |
| `migrate` | `aidlc-migrate` | additional_context | 移行完了 | スキル不在時エラー |
| `feedback` | `aidlc-feedback` | additional_context | フィードバック送信 | スキル不在時エラー |
| 無効値 | - | - | エラーメッセージ | 有効値リスト提示 |

**委譲方式**: SKILL.md内で「`/aidlc-{action}` を実行してください」と案内する形式（Skillツール呼び出しによる委譲）。

### ステップファイルの所有権（指摘 #3対応: 境界の明確化）

シンボリックリンクは使用しない。各独立スキルが自身のステップファイルを所有する。

- `skills/aidlc/steps/setup/` → `skills/aidlc-setup/steps/` に移動
- `skills/aidlc/steps/migrate/` → `skills/aidlc-migrate/steps/` に移動
- `skills/aidlc/steps/common/feedback.md` → `skills/aidlc-feedback/steps/feedback.md` に移動

**スキル間依存の解決**: 各独立スキルが親スキルへの共有スクリプト依存ゼロで自己完結する。

- **migrate**: 共有スクリプト依存なし。専用スクリプトをそのまま移動
  → `skills/aidlc-migrate/scripts/`: `migrate-detect.sh`, `migrate-apply-config.sh`, `migrate-apply-data.sh`, `migrate-cleanup.sh`, `migrate-verify.sh`
- **setup**: `read-version.sh`（version.txt読むだけ）のみ依存。version.txt + read-version.sh をsetupスキルに同梱して依存を切る
  → `skills/aidlc-setup/scripts/`: `init-labels.sh`, `setup-ai-tools.sh`, `migrate-backlog.sh`, `migrate-config.sh`, `read-version.sh`
  → `skills/aidlc-setup/version.txt`（コピー）
- **feedback**: `read-config.sh`（1キー読むだけ）のみ依存。ステップファイル内でdasel直接呼び出しに置換して依存を切る

## 変更対象ファイル

### 新規作成

- `skills/aidlc-setup/SKILL.md` — 初期セットアップスキル定義
- `skills/aidlc-setup/steps/` — setupステップファイル（移動元: `skills/aidlc/steps/setup/`）
- `skills/aidlc-setup/scripts/` — setup専用スクリプト（移動元: `skills/aidlc/scripts/` の該当ファイル）
- `skills/aidlc-setup/version.txt` — バージョンファイル（コピー）
- `skills/aidlc-migrate/SKILL.md` — v1→v2移行スキル定義
- `skills/aidlc-migrate/steps/` — migrateステップファイル（移動元: `skills/aidlc/steps/migrate/`）
- `skills/aidlc-migrate/scripts/` — migrate専用スクリプト（移動元: `skills/aidlc/scripts/` の該当ファイル）
- `skills/aidlc-feedback/SKILL.md` — フィードバック送信スキル定義
- `skills/aidlc-feedback/steps/feedback.md` — feedbackステップ（移動元、read-config.sh依存をdasel直接呼び出しに置換）

### 変更

- `skills/aidlc/SKILL.md` — setup/migrate/feedbackのロジック除去、委譲ルーティングに変更

### 削除

- `skills/aidlc-setup/`（既存v1用アップグレードスキル） — 全体削除
- `skills/aidlc/steps/setup/` — aidlc-setupに移動済み
- `skills/aidlc/steps/migrate/` — aidlc-migrateに移動済み
- `skills/aidlc/steps/common/feedback.md` — aidlc-feedbackに移動済み
- `skills/aidlc/scripts/` のsetup/migrate専用スクリプト — 各スキルに移動済み

## 実装計画

### Phase 1: 設計

1. ドメインモデル: スキル間の責務・依存関係・共有リソースを定義
2. 論理設計: 各スキルのSKILL.mdフロントマター、ステップファイル配置、パス参照方式
3. 設計レビュー

### Phase 2: 実装

1. 既存 `aidlc-setup`（v1用）を削除し、`skills/aidlc/scripts/` からsetup/migrate専用スクリプトを各スキルに移動
2. 独立スキル作成（aidlc-setup、aidlc-migrate、aidlc-feedback）
3. ステップファイルの移動・パス更新
4. 親スキルSKILL.mdの更新（ロジック除去・委譲ルーティング）
5. テスト（各スキルの呼び出し確認）

## 完了条件チェックリスト

- [ ] setup/migrate/feedbackそれぞれの独立スキルが作成されている
- [ ] 親スキル（skills/aidlc/SKILL.md）からsetup/migrate/feedbackのロジックが除去されている
- [ ] 引数ルーティングテーブルが独立スキルへの委譲形式に更新されている
- [ ] `/aidlc setup`、`/aidlc migrate`、`/aidlc feedback` で各スキルが呼び出せる（Issue #457の成功基準）
- [ ] 親スキルはルータ兼フェーズ実行ファサード（ARGUMENTSパーシング + action検証 + フェーズ実行 + 独立フロー委譲）
- [ ] 独立スキルから親スキル配下のステップファイル・スクリプトへの参照がない（共有スクリプト依存ゼロ）
- [ ] 未知コマンド/不正引数時のエラー応答が定義済み

# リリース後の運用記録

## リリース情報

- **バージョン**: v2.6.0
- **リリース予定日**: 2026-05-10
- **リリース内容**: minor サイクル。バージョン管理 SoT 一本化（`marketplace.json` 確定 + 冗長 version.txt 廃止）、GitHub Projects 移行（バックログ動的管理化）、振り返りフロー独立化（破壊的変更: Operations から `/aidlc-retrospective` へ移転）を主軸に、関連小バグ（migrate-backlog UTF-8 cut / rules.md MD040）と squash-unit.sh の CI 構造チェック opt-in 化（破壊的変更）を統合解消する。

### 含まれる Unit

- Unit 001: rules.md MD040 違反修正（#614）
- Unit 002: migrate-backlog.sh UTF-8 多バイト境界分断バグ修正（#615）
- Unit 003: marketplace.json への version SoT 一本化（#617 / Story 1A〜1D）
- Unit 004: aidlc-setup の starter_kit_version-only 差分 no-op スキップ（#618）
- Unit 005: /aidlc-retrospective 独立スキル化（#667 / **破壊的変更**）
- Unit 006: GitHub Projects (ProjectsV2) フル移行（#673）
- Unit 007: squash-unit.sh CI 構造チェック opt-in 化（**破壊的変更** / Issue なし、ユーザー指示割り込み）

### 自動クローズ対象 Issue（PR #676 マージ時）

- #614, #615, #617, #618, #667, #673

## 運用状況

本プロジェクトは AI-DLC スターターキット（プロンプト・スクリプト集としての OSS リポジトリ）であり、サーバー稼働を伴わない。インシデント追跡・パフォーマンス計測は対象外。

| 項目 | 状態 |
|------|------|
| 稼働率 / ダウンタイム / インシデント数 | N/A（OSS リポジトリのため対象外） |
| パフォーマンス計測 | N/A |
| アクティブユーザー数 | N/A（GitHub stars / fork で間接観測） |

## 破壊的変更と移行影響

- **Unit 005**: Operations Phase 内の振り返りフロー起動を v2.6.0 で廃止。代替は `/aidlc r`（または `/aidlc retrospective`）で `aidlc-retrospective` スキルを起動。Operations 完了メッセージで `/aidlc i` と並列に案内される。
- **Unit 007**: `skills/aidlc/scripts/squash-unit.sh` の CI 構造チェックは consumer プロジェクトでデフォルトスキップに変更（opt-in シグナル化）。starter kit 自身は引き続きチェックされる。

## バグ対応

### 本サイクルで解消した課題

- #614 rules.md MD040 違反 → Unit 001 で fenced code block の言語タグ追加で解消
- #615 migrate-backlog.sh UTF-8 多バイト境界分断 → Unit 002 で `cut -c1-50` を文字単位安全な処理に置換
- #617 version 管理 SoT 多重化 → Unit 003 で marketplace.json に一本化、冗長 version.txt 廃止
- #618 aidlc-setup の starter_kit_version-only 差分 no-op スキップ → Unit 004 で `check-noop-upgrade.sh` 新設
- #667 振り返りフローの Operations 同居 → Unit 005 で `/aidlc-retrospective` 独立スキルへ移転（破壊的変更）
- #673 GitHub Projects 移行 → Unit 006 で ProjectsV2 ベースのバックログ動的管理基盤を整備

### 未修正のバックログ（次サイクル候補 / `backlog` ラベル / open）

| 優先度 | Issue | 概要 |
|--------|-------|------|
| high | #680 | aidlc-migrate: manifest 由来パスのトラバーサル検証（type:security） |
| medium | #687 | squash-unit.sh CI 構造チェック設定駆動化（Unit 007 後続） |
| medium | #686 | Cycle Phase Completion check を draft PR でスキップ |
| medium | #685 | Consumer プロジェクト向け GitHub Projects セットアップ助け |
| medium | #683 | Unit 006 副作用 bats テスト整備（gh API モック） |
| medium | #682 | gh-project-cli.sh ensure-fields の options 差分同期 |
| medium | #681 | Unit 005 retrospective 独立化に伴う旧 step-integration.bats クリーンアップ |
| medium | #666 #664 #663 #662 #655 #652 #649 #646 #645 #641 #633 #630 #629 #624 #623 #622 #621 | 振り返り由来 / feedback 由来 / 機能拡張バックログ多数 |
| low | #684 #669 #640 | 拡張・整理系（priority:low） |

## ユーザーフィードバック

`feedback` ラベル付き Issue を継続的に集約。本サイクル統合分は #614/#615/#617/#618/#667/#673 + Unit 007 (interrupt-driven)。その他 feedback (`feedback` ラベル付き open Issue) は次サイクル以降で扱う。

## 次期バージョンの計画

### 対象バージョン

v2.6.1 (patch) もしくは v2.7.0 (minor) — priority:high バックログ #680（aidlc-migrate トラバーサル検証）の対応可否と、`feedback` Issue 群の整理結果で確定する。

### 主要候補

- #680 aidlc-migrate トラバーサル検証（priority:high / type:security）
- #687 squash-unit.sh CI 構造チェック設定駆動化（Unit 007 後続）
- #685 Consumer プロジェクト向け GitHub Projects セットアップ助け（v2.6.0 で導入した基盤の consumer 適用）
- `feedback` ラベル付き Issue の Inception 取り込み判定

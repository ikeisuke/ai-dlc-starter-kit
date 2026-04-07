# ベースライン計測結果（Wave 1実施後）

計測日: 2026-04-06
計測方法: `wc -c`（バイト数）
パス表記: `skills/aidlc/` を基準とした相対パス（スキルベースディレクトリ基準）

## 共通初期化ファイル（全フェーズ共通）

SKILL.mdの共通初期化フロー（ステップ1〜3）で読み込まれるファイル。

| ファイルパス | バイト数 | ロードタイミング |
|------------|---------|--------------|
| SKILL.md | 9,703 | エントリポイント |
| steps/common/agents-rules.md | 3,841 | ステップ1 |
| steps/common/rules.md | 10,891 | ステップ1 |
| steps/common/preflight.md | 8,774 | ステップ1 |
| steps/common/session-continuity.md | 2,274 | ステップ3 |
| .aidlc/rules.md（プロジェクトルート） | 27,977 | ステップ2（存在する場合のみ） |
| **共通合計** | **63,460** | |

注: `.aidlc/rules.md` はプロジェクト固有の追加ルール。存在しない場合はロードされない。本リポジトリでは存在するためベースラインに含める。
注: `compaction.md`(6,528B)はコンパクション復帰時のみロード（通常起動時は除外）。
注: `review-flow.md`(11,945B)、`commit-flow.md`(3,626B)、`context-reset.md`(2,619B)、`task-management.md`(3,885B)は必要時のみロード（ベースラインには含めない）。

## Inception Phase

| ファイルパス | バイト数 |
|------------|---------|
| steps/inception/01-setup.md | 10,945 |
| steps/inception/02-preparation.md | 5,738 |
| steps/inception/03-intent.md | 6,704 |
| steps/inception/04-stories-units.md | 8,014 |
| steps/inception/05-completion.md | 11,135 |
| **Inceptionステップ合計** | **42,536** |
| **Inception初回ロード合計（共通 + ステップ）** | **105,996** |

## Construction Phase

| ファイルパス | バイト数 |
|------------|---------|
| steps/construction/01-setup.md | 5,777 |
| steps/construction/02-design.md | 3,513 |
| steps/construction/03-implementation.md | 8,873 |
| steps/construction/04-completion.md | 8,276 |
| **Constructionステップ合計** | **26,439** |
| **Construction初回ロード合計（共通 + ステップ）** | **89,899** |

## Operations Phase

| ファイルパス | バイト数 |
|------------|---------|
| steps/operations/01-setup.md | 3,855 |
| steps/operations/02-deploy.md | 8,879 |
| steps/operations/03-release.md | 2,002 |
| steps/operations/04-completion.md | 10,311 |
| **Operationsステップ合計** | **25,047** |
| **Operations初回ロード合計（共通 + ステップ）** | **88,507** |

## サマリ

| フェーズ | 共通(B) | ステップ(B) | 合計(B) |
|---------|---------|-----------|---------|
| Inception | 63,460 | 42,536 | 105,996 |
| Construction | 63,460 | 26,439 | 89,899 |
| Operations | 63,460 | 25,047 | 88,507 |

**Wave 2の成功基準**: 上記ベースラインから12,500B以上の削減。

---

## 事後計測（Wave 2実施後）

計測日: 2026-04-07
計測方法: `wc -c`（バイト数）
計測対象: プロジェクトソース（`skills/aidlc/`）— Wave 2の変更はプロジェクトソースに適用済み

### 構成変更

Wave 2により共通初期化の読み込みファイル構成が変更された:

| 変更 | 旧ファイル | 新ファイル | 備考 |
|------|-----------|-----------|------|
| 統合・分割 | agents-rules.md (3,841B) + rules.md (10,891B) | rules-core.md (10,049B) | rules-automation.md, rules-reference.mdは必要時のみロード |
| 削除 | agents-rules.md | - | rules-core.mdに統合 |
| 削除 | rules.md | - | 3分割（core/automation/reference） |

### 共通初期化ファイル

| ファイルパス | ベースライン(B) | 事後(B) | 差分(B) |
|------------|---------------|---------|---------|
| SKILL.md | 9,703 | 9,559 | -144 |
| steps/common/agents-rules.md | 3,841 | 0 (削除) | -3,841 |
| steps/common/rules.md | 10,891 | 0 (削除) | -10,891 |
| steps/common/rules-core.md | - | 10,049 | +10,049 |
| steps/common/preflight.md | 8,774 | 8,774 | 0 |
| steps/common/session-continuity.md | 2,274 | 2,410 | +136 |
| .aidlc/rules.md（プロジェクトルート） | 27,977 | 27,977 | 0 |
| **共通合計** | **63,460** | **58,769** | **-4,691** |

### Inception Phase

| ファイルパス | ベースライン(B) | 事後(B) | 差分(B) |
|------------|---------------|---------|---------|
| steps/inception/01-setup.md | 10,945 | 10,950 | +5 |
| steps/inception/02-preparation.md | 5,738 | 5,749 | +11 |
| steps/inception/03-intent.md | 6,704 | 6,719 | +15 |
| steps/inception/04-stories-units.md | 8,014 | 8,083 | +69 |
| steps/inception/05-completion.md | 11,135 | 9,210 | -1,925 |
| **Inceptionステップ合計** | **42,536** | **40,711** | **-1,825** |
| **Inception初回ロード合計** | **105,996** | **99,480** | **-6,516** |

### Construction Phase

| ファイルパス | ベースライン(B) | 事後(B) | 差分(B) |
|------------|---------------|---------|---------|
| steps/construction/01-setup.md | 5,777 | 5,785 | +8 |
| steps/construction/02-design.md | 3,513 | 3,532 | +19 |
| steps/construction/03-implementation.md | 8,873 | 8,899 | +26 |
| steps/construction/04-completion.md | 8,276 | 7,509 | -767 |
| **Constructionステップ合計** | **26,439** | **25,725** | **-714** |
| **Construction初回ロード合計** | **89,899** | **84,494** | **-5,405** |

### Operations Phase

| ファイルパス | ベースライン(B) | 事後(B) | 差分(B) |
|------------|---------------|---------|---------|
| steps/operations/01-setup.md | 3,855 | 3,860 | +5 |
| steps/operations/02-deploy.md | 8,879 | 8,894 | +15 |
| steps/operations/03-release.md | 2,002 | 2,013 | +11 |
| steps/operations/04-completion.md | 10,311 | 9,153 | -1,158 |
| **Operationsステップ合計** | **25,047** | **23,920** | **-1,127** |
| **Operations初回ロード合計** | **88,507** | **82,689** | **-5,818** |

### 差分サマリ

| フェーズ | ベースライン(B) | 事後(B) | 削減量(B) | 成功基準(12,500B) | 判定 |
|---------|---------------|---------|----------|-----------------|------|
| Inception | 105,996 | 99,480 | 6,516 | 未達 | ❌ |
| Construction | 89,899 | 84,494 | 5,405 | 未達 | ❌ |
| Operations | 88,507 | 82,689 | 5,818 | 未達 | ❌ |

### 判定結果

**未達成**: 全フェーズで成功基準（12,500B以上削減）を満たしていない。

**主な削減要因**:
- 共通ファイルの統合・分割（agents-rules.md + rules.md → rules-core.md）: -4,691B
- 05-completion.md の完了処理共通化: -1,925B（Inception）
- 04-completion.md の完了処理共通化: -767B（Construction）/ -1,158B（Operations）

**未達の分析**:
- Wave 2の削減量見込み（12.5-26.5KB）はWave 2の5施策（S18, S6, S3, S17, S10）すべての効果を前提としたが、実際の削減は共通ファイル統合と完了処理共通化が主体
- rules.md 3階層分割は共通部分を rules-core.md(10,049B) に集約したが、元の2ファイル合計(14,732B)との差は4,683Bに留まった
- 一部ステップファイルのバイト数が微増（+5〜+69B）しており、Wave 2施策以外の変更が影響した可能性がある

**注**: 成功基準未達の場合の追加施策実施はこのUnitの責務外（Unit定義の境界に記載）

### 統合検証（スモークテスト）結果

検証日: 2026-04-07
検証方法: 共通初期化フローで読み込まれる全ファイルの存在確認

| フェーズ | 対象ファイル数 | 結果 |
|---------|-------------|------|
| 共通（SKILL.md + rules-core.md + preflight.md + session-continuity.md） | 4 | OK（全ファイル存在） |
| Inception（01-setup.md 〜 05-completion.md） | 5 | OK（全ファイル存在） |
| Construction（01-setup.md 〜 04-completion.md） | 4 | OK（全ファイル存在） |
| Operations（01-setup.md 〜 04-completion.md） | 4 | OK（全ファイル存在） |

**判定**: 全フェーズの共通初期化フロー対象ファイルが存在し、正常にロード可能であることを確認。

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

（Unit 006で記録予定）

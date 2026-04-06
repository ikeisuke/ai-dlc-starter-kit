# Unit 002: rules.md 3階層分割 - 実装計画

## 背景

現在、共通初期化フロー（SKILL.mdステップ1）で `agents-rules.md`(3,841B) と `rules.md`(10,891B) の計14,732Bをロードしている。両ファイルには質問・バックログ管理に関する重複内容がある。

## 設計方針

rules.mdを用途別に3ファイルに分割し、agents-rules.mdの全セクションをrules-core.mdに統合する（Unit定義の技術的考慮事項で代表セクションのみ例示されているが、agents-rules.mdは全体をrules-core.mdに統合する方針）。常時ロードはrules-core.mdのみとし、rules-automation.mdとrules-reference.mdは各ステップファイルから必要時に参照する形に変更する。

### サイズ推計

| ファイル | 推定サイズ | 根拠 |
|---------|----------|------|
| rules-core.md | ~9,700B | rules.md残部(6,565B) + agents-rules.md(3,841B) - 重複除去(~700B) |
| rules-automation.md | ~2,813B | セミオートゲート仕様 + エクスプレスモード仕様 |
| rules-reference.md | ~1,512B | Depth Level仕様(1,162B) + 設定仕様リファレンス(350B) |
| **合計** | **~14,025B** | < 14,732B（NFR達成見込み） |

**常時ロード削減**: 14,732B → ~9,700B（約5,000B削減）

### 分割構成

| ファイル | 内容 | ロードタイミング |
|---------|------|----------------|
| `rules-core.md` | 質問判断基準、承認プロセス、AskUserQuestion使用ルール、スコープ保護ルール、改善提案ルール、Gitコミットルール、コード品質基準、設定読み込み + agents-rules.md全セクション（質問と深掘り、バックログ管理、禁止事項、コンテキスト要約時の情報保持、実行前の検証、フェーズ固有ルール） | 常時（SKILL.mdステップ1） |
| `rules-automation.md` | セミオートゲート仕様、エクスプレスモード仕様 | 必要時（ステップファイルからの参照） |
| `rules-reference.md` | Depth Level仕様（テーブル含む）、設定仕様リファレンス | 必要時（ステップファイルからの参照） |

### 変更対象ファイル

1. **新規作成**: `steps/common/rules-core.md`, `steps/common/rules-automation.md`, `steps/common/rules-reference.md`
2. **削除**: `steps/common/rules.md`, `steps/common/agents-rules.md`
3. **SKILL.md ステップ1変更**: `agents-rules.md` と `rules.md` の2エントリを `rules-core.md` の1エントリに置換
4. **参照パス更新**: AGENTS.md、各フェーズのステップファイル

### 参照パス更新方針

実装時に `grep -r "rules\.md\|agents-rules\.md"` で全参照箇所を特定し、以下のルールで更新する:

- `common/rules.md` への参照 → 参照先セクションに応じて適切な新ファイルに更新
  - セミオートゲート仕様 → `rules-automation.md`
  - Depth Level → `rules-reference.md`
  - エクスプレスモード仕様 → `rules-automation.md`
  - その他 → `rules-core.md`
- `agents-rules.md` への参照 → `rules-core.md` に更新
- `.aidlc/rules.md`（プロジェクト固有）は変更対象外

### 主要な更新対象ステップファイル（grep結果ベース）

| ステップファイル | 参照セクション | 更新先 |
|----------------|--------------|--------|
| `construction/01-setup.md` | 共通ルール参照 | rules-core.md |
| `construction/02-design.md` | Depth Level、セミオートゲート | rules-reference.md、rules-automation.md |
| `construction/03-implementation.md` | Depth Level、セミオートゲート、フォールバック | rules-reference.md、rules-automation.md |
| `operations/01-setup.md` | 共通ルール参照 | rules-core.md |
| `operations/02-deploy.md` | セミオートゲート、Depth Level | rules-automation.md、rules-reference.md |
| `operations/03-release.md` | セミオートゲート | rules-automation.md |
| `inception/01-setup.md` | 共通ルール参照 | rules-core.md |
| `inception/02-preparation.md` | エクスプレスモード | rules-automation.md |
| `inception/03-intent.md` | Depth Level、セミオートゲート | rules-reference.md、rules-automation.md |
| `inception/04-stories-units.md` | セミオートゲート、Depth Level、エクスプレス | rules-automation.md、rules-reference.md |
| `inception/05-completion.md` | セミオートゲート | rules-automation.md |
| `common/compaction.md` | セミオートゲート | rules-automation.md |
| `common/review-flow.md` | スコープ保護ルール | rules-core.md |
| `SKILL.md` | ステップ1ロード指示 | rules-core.md（1エントリに統合） |
| `AGENTS.md` | agents-rules.md参照 | rules-core.md |

## NFR

- rules-core.md + rules-automation.md + rules-reference.md 合計 < 14,732B（元の合計）
- 常時ロードサイズ: rules-core.md のみで ~9,700B（元の14,732Bから約34%削減）

## 完了条件チェックリスト

- [ ] rules-core.md が作成され、agents-rules.mdの全内容が統合されている
- [ ] rules-automation.md が作成され、セミオートゲート仕様とエクスプレスモード仕様を含む
- [ ] rules-reference.md が作成され、Depth Level仕様と設定仕様リファレンスを含む
- [ ] 3ファイル合計 < 14,732B
- [ ] SKILL.md ステップ1が agents-rules.md + rules.md → rules-core.md の1エントリに更新
- [ ] 全ステップファイルの参照パスが正しい新ファイルを指している（grep検証済み）
- [ ] 元ファイル（rules.md、agents-rules.md）が削除されている
- [ ] セミオートゲート仕様・Depth Level仕様等の内容が分割前と等価

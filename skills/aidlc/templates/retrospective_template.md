# Retrospective: {{CYCLE}}

## 概要

本サイクルで発生したプロセス上の問題を振り返り、次サイクルに引き継ぐ。

## メトリクスサマリ

| 項目 | 値 |
|------|-----|
| Unit 数 | |
| Decision Records | |
| マージ前レビューラウンド | |
| Test 純増 | |
| CI 失敗回数 | |
| Auto-close Issue | |
| 派生バックログ | |

## Keep（次サイクルでも継続）

<!-- 次サイクル以降も継続したい良いプラクティス・成果を箇条書きで記載。なしの場合は「特になし」と明示 -->

1.

## Try（次サイクル以降で試す）

| 優先度 | 施策 | 反映先 |
|--------|------|-------|
| | | |

<!-- Problem への対策として次サイクル以降で試す施策を優先度付きで記載。なしの場合は「特になし」と明示 -->

## 問題項目（Problem）

<!-- 各 Problem には主因の切り分け（プロダクト固有 / AI-DLC Starter Kit 固有 / 両方）を skill 起因判定 YAML フロントマターで明示すること。

問題項目が 0 件の場合、以下のような明示行を 1 つ残すこと（空ファイル禁止）:

### 問題なし

本サイクルでは特筆すべきプロセス問題は発生しなかった。

-->

### 問題 1: {{タイトル}}

**何が起きたか**: {{記述}}

**なぜ起きたか**: {{記述}}

**損失と影響**: {{記述}}

**主因切り分け**:

| 主因分類 | 該当 | 反映先（GitHub Issue 番号 / 次サイクル Intent / `/aidlc feedback`） |
|----------|------|------------------------------------------------------------------|
| プロダクト固有（プロダクトリポジトリ側で対応） | yes/no | |
| AI-DLC Starter Kit 固有（`/aidlc feedback` で起票） | yes/no | |
| 両方に責任（プロダクト側は短期保険、AI-DLC 側は構造改善） | yes/no | |

**skill 起因判定**:

<!-- 質問文（retrospective-schema.yml の questions と一字一句一致）:
q1: skill 内の具体的な箇所を引用できるか?
q2: 別の skill ファイルとの矛盾を示せるか?
q3: 「どう読んでも複数解釈できる」と示せるか?
-->

```yaml
skill_caused_judgment:
  q1_answer: "no"
  q1_quote: ""
  q2_answer: "no"
  q2_quote: ""
  q3_answer: "no"
  q3_quote: ""
mirror_state:
  state: ""
  issue_url: ""
  recorded_at: ""
```

## 反映先一覧

<!-- 振り返り output の反映先を集約表示する。各 Try / Problem の対応先（GitHub Issue 番号 / `/aidlc feedback` Issue / 次サイクル Intent 反映予定）を一覧化 -->

- プロダクト GitHub Issue: #
- AI-DLC feedback Issue: #
- 次サイクル Intent 反映事項:

## 次サイクルへの引き継ぎ事項

{{引き継ぎ事項。なしの場合は「なし」と明示}}

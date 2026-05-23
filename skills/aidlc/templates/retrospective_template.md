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

<!--
Unit 004 (v2.6.6 / SC-02 / SC-03 / #710): Try セクションは `aggregate_issue_enabled` 設定で
2 つの表現形式に分岐する。以下 2 ブロックを HTML コメントマーカーで明示分離する。
ブロック選択は §1.5 Step 4 が `retrospective_api_aggregate_enabled` 解決値で行う:
  - false (既定 / v2.6.6+): try_loop_block を採用（1 Try = 1 Issue, 5 必須見出し）
  - true (opt-in / v2.6.5 互換): aggregate_block を採用（単一表、既存 v2.6.5 構造維持）
両ブロックは常時共存（マーカー文字列は固定 / 改名禁止 / 設計レビュー R1 指摘 #4 対応）。
-->

<!-- BEGIN: try_loop_block -->
<!--
1 Try = 1 GitHub Issue の単位で起票する形式（既定）。
各 Try について以下 5 必須見出しすべてに非空本文を記載する（空ブロックは禁止 /
明示的に「該当なし」と書けば非空扱い）。
Try 件数分このセクションを複製する（### Try N: ... を増やして並べる）。
-->

### Try 1: {{Try 内容を 1 行で記載 / Issue タイトル 1 行要約に使用される}}

**優先度**: {{高 | 中 | 低}}

**反映先**: {{プロダクト GitHub Issue / AI-DLC feedback Issue / 次サイクル Intent}}

#### 背景

<!-- 該当する Keep または Problem の要旨 / 関連 K-N / P-N の番号を明記 -->

#### 主因切り分け

<!-- §1.2 の 3 分類（プロダクト固有 / AI-DLC Starter Kit 固有 / 両方）のいずれか + 根拠 -->

#### 構造課題昇格根拠

<!-- §1.2.5 セルフレビューで「個別チェック追加で逃げていない」と判定した根拠
     (再発性 / 対象レイヤ / 再入余地 3 観点の選択肢ラベルから自動転記される) -->

#### 想定対策

<!-- Try の具体内容（実施手順 / 影響範囲 / 完了条件） -->

#### 関連

<!-- サイクル番号: {{CYCLE}} / 関連 Issue 番号 / Milestone リンク
     aggregate_issue_enabled=true 時のみ Relates: #<集約 Issue 番号> を追加 -->

<!-- END: try_loop_block -->

<!-- BEGIN: aggregate_block -->
<!--
集約 retrospective Issue 1 件に Try 表を内包する形式（opt-in / aggregate_issue_enabled=true）。
v2.6.5 以前のフォーマットを完全互換維持（同等性 fixture と diff 0）。
-->

| 優先度 | 施策 | 反映先 |
|--------|------|-------|
| | | |

<!-- Problem への対策として次サイクル以降で試す施策を優先度付きで記載。なしの場合は「特になし」と明示 -->

<!-- END: aggregate_block -->

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

# Retrospective: v2.5.0

## 概要

Unit 006 cap テスト用: 5 件の skill_caused=true 候補（重複なし / cap=3 で 2 件超過）。

## 問題項目

### 問題 1: 課題 alpha の説明不足

**何が起きたか**: alpha 関連の skill 説明が不足

**なぜ起きたか**: 章立てが未整備

**損失と影響**: 実装に時間を要した

```yaml
skill_caused_judgment:
  q1_answer: "yes"
  q1_quote: "alpha skill の手順説明が不足している箇所"
  q2_answer: "no"
  q2_quote: ""
  q3_answer: "no"
  q3_quote: ""
mirror_state:
  state: ""
  issue_url: ""
  recorded_at: ""
```

### 問題 2: 課題 bravo の例示不足

**何が起きたか**: bravo 関連 skill の例示不足

**なぜ起きたか**: 例示テンプレ不在

**損失と影響**: 解釈ぶれ

```yaml
skill_caused_judgment:
  q1_answer: "yes"
  q1_quote: "bravo skill の例示が不足している箇所"
  q2_answer: "no"
  q2_quote: ""
  q3_answer: "no"
  q3_quote: ""
mirror_state:
  state: ""
  issue_url: ""
  recorded_at: ""
```

### 問題 3: 課題 charlie の手順誤り

**何が起きたか**: charlie の手順が誤っていた

**なぜ起きたか**: skill 改修漏れ

**損失と影響**: 再作業発生

```yaml
skill_caused_judgment:
  q1_answer: "yes"
  q1_quote: "charlie skill の手順記述に誤りがある箇所"
  q2_answer: "no"
  q2_quote: ""
  q3_answer: "no"
  q3_quote: ""
mirror_state:
  state: ""
  issue_url: ""
  recorded_at: ""
```

### 問題 4: 課題 delta の参照欠落

**何が起きたか**: delta 関連 skill の参照リンク欠落

**なぜ起きたか**: 参照管理ルール不在

**損失と影響**: 探索コスト増

```yaml
skill_caused_judgment:
  q1_answer: "yes"
  q1_quote: "delta skill の参照リンクが欠落している箇所"
  q2_answer: "no"
  q2_quote: ""
  q3_answer: "no"
  q3_quote: ""
mirror_state:
  state: ""
  issue_url: ""
  recorded_at: ""
```

### 問題 5: 課題 echo の用語ぶれ

**何が起きたか**: echo 関連 skill の用語ぶれ

**なぜ起きたか**: 用語集不在

**損失と影響**: 認識齟齬

```yaml
skill_caused_judgment:
  q1_answer: "yes"
  q1_quote: "echo skill の用語ぶれが残っている箇所"
  q2_answer: "no"
  q2_quote: ""
  q3_answer: "no"
  q3_quote: ""
mirror_state:
  state: ""
  issue_url: ""
  recorded_at: ""
```

## 次サイクルへの引き継ぎ事項

cap-exceeded 動作確認用。

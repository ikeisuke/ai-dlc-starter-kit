# Retrospective: v2.5.0

## 概要

mirror_state 状態が混在するテスト用。

## 問題項目

### 問題 1: 既に sent された問題

**何が起きたか**: a

**なぜ起きたか**: skill が曖昧

**損失と影響**: a

```yaml
skill_caused_judgment:
  q1_answer: "yes"
  q1_quote: "skill 内の §A.B の記述が曖昧で複数解釈できる過去送信"
  q2_answer: "no"
  q2_quote: ""
  q3_answer: "no"
  q3_quote: ""
mirror_state:
  state: "sent"
  issue_url: "https://github.com/ikeisuke/ai-dlc-starter-kit/issues/999"
  recorded_at: "2026-04-29T10:00:00Z"
```

### 問題 2: skipped にされた問題

**何が起きたか**: b

**なぜ起きたか**: skill 矛盾

**損失と影響**: b

```yaml
skill_caused_judgment:
  q1_answer: "no"
  q1_quote: ""
  q2_answer: "yes"
  q2_quote: "skill A と skill B の記述が矛盾している過去判断"
  q3_answer: "no"
  q3_quote: ""
mirror_state:
  state: "skipped"
  issue_url: ""
  recorded_at: "2026-04-29T11:00:00Z"
```

### 問題 3: 未処理 skill 起因（candidate 対象）

**何が起きたか**: c

**なぜ起きたか**: skill 解釈ぶれ

**損失と影響**: c

```yaml
skill_caused_judgment:
  q1_answer: "no"
  q1_quote: ""
  q2_answer: "no"
  q2_quote: ""
  q3_answer: "yes"
  q3_quote: "skill のどう読んでも複数解釈できる重要記述"
mirror_state:
  state: ""
  issue_url: ""
  recorded_at: ""
```

### 問題 4: pending にされた問題

**何が起きたか**: d

**なぜ起きたか**: skill 不明瞭

**損失と影響**: d

```yaml
skill_caused_judgment:
  q1_answer: "yes"
  q1_quote: "skill 内の §C.D の引用箇所が複数解釈できる保留中"
  q2_answer: "no"
  q2_quote: ""
  q3_answer: "no"
  q3_quote: ""
mirror_state:
  state: "pending"
  issue_url: ""
  recorded_at: "2026-04-29T12:00:00Z"
```

## 次サイクルへの引き継ぎ事項

なし

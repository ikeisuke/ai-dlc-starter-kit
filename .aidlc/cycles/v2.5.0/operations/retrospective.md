# Retrospective: v2.5.0

## 概要

本サイクルで発生したプロセス上の問題を振り返り、次サイクルに引き継ぐ。

## 問題項目

### 問題 1: Operations Phase の retrospective 自動生成ステップが PR マージ実行へ直行する経路で skip される余地がある

**何が起きたか**: Operations Phase 実行中、`operations-release.md` の §7.1〜§7.13（リリース準備〜 PR マージ実行）を順次実行する流れで、`04-completion.md §3.5`（retrospective 自動生成）を skip して §7.13 PR マージ実行確認まで進行してしまった。ユーザーから「振り返りっていつやるの？」と指摘を受けて気付き、PR マージ前にやり直した。

**なぜ起きたか**: `operations-release.md`（ステップ 7 リリース準備）と `04-completion.md`（Operations Phase 完了処理 / retrospective 生成を含む）の実行順序が両ドキュメント間で明示されていない。`operations-release.md §7.13` は「PR マージ実行」、`04-completion.md §3.5` は「マージ前完結契約準拠」と書かれているが、`§7.13 の前に 04-completion.md §3.5 を実行する」という順序を明示する文がない。エージェントは §7 を完了マークした時点でそのまま §7.13 マージに進めてしまう。

**損失と影響**: 本サイクルではユーザー指摘により発覚し、マージ前にやり直せた。ただし指摘がなければ、本サイクルで初めて投入する自動振り返り機能を、リリースサイクル自身では実行しないままマージしていた可能性がある。マージ後は cycle ブランチが post-merge-sync で削除されるため、retrospective.md がローカルにすら残らない事象が起きうる。

**skill 起因判定**:

<!-- 質問文（retrospective-schema.yml の questions と一字一句一致）:
q1: skill 内の具体的な箇所を引用できるか?
q2: 別の skill ファイルとの矛盾を示せるか?
q3: 「どう読んでも複数解釈できる」と示せるか?
-->

```yaml
skill_caused_judgment:
  q1_answer: "yes"
  q1_quote: "operations-release.md §7.13「PR マージ【重要】PR 本文の `Closes #XX` を最終確認」の節に、§7.13 実行前に 04-completion.md §3.5 retrospective 自動生成を完結させる必要がある旨の言及がない。04-completion.md §3.5 側にのみ「マージ前完結契約準拠: 本サブステップは 5. PR マージ後の手順より前に完結させる必要がある」と書かれており、両者の順序整合が片側ドキュメントのみに記述されている。"
  q2_answer: "yes"
  q2_quote: "operations-release.md と 04-completion.md の双方が「マージ前」のステップを保持しており、両者の実行順序（リリース準備 §7.1-§7.13 vs Operations Phase 完了処理 §1-§5）の関係が operations index.md / 02-deploy.md / どちらの個別ファイルにも明示されていない。エージェントはどちらを先に実行するか判断材料が不足する。"
  q3_answer: "yes"
  q3_quote: "「マージ前完結契約準拠」という制約は満たされる順序が複数ある（例: §7.7 commit 前 / §7.8 PR Ready 前 / §7.13 マージ前のいずれでも「マージ前」を満たす）。`04-completion.md §3.5` を `operations-release.md §7.x` のどこに挿入すべきかが指定されておらず、複数解釈の余地がある。"
mirror_state:
  state: ""
  issue_url: ""
  recorded_at: ""
```

### 問題 2: skills 内ドキュメントで `bash skills/aidlc/scripts/...` 形式の参照を書いてしまい CI Skill Reference Check が失敗

**何が起きたか**: Unit 004 / Unit 005 / Unit 006 で追加した `04-completion.md` ステップ 3.5 / Step 5 の bash 実行例で、`bash skills/aidlc/scripts/retrospective-mirror.sh` のようなプロジェクトルート相対パスを記載した。CI の `bin/check-skill-references.sh` が違反検知し、PR Ready 化後に Skill Reference Check が FAILURE になった。

**なぜ起きたか**: `SKILL.md` の「パス解決」節に `scripts/` で始まるパスはスキルベース相対と明記されているが、bash 実行コマンド内では `bash <path>` の形式を使うため、エージェントがプロジェクトルート相対の方が「動作する」と誤認した（実際は両方動作するが規約違反）。

**損失と影響**: 軽微。リリース直前の CI 失敗で 1 commit 追加修正と再 push が必要になった。マージブロックは免れた（fix commit でリカバ）。

**skill 起因判定**:

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

## 次サイクルへの引き継ぎ事項

- **問題 1**: `operations-release.md §7.x` と `04-completion.md §1-§5` の実行順序を `operations/index.md` または専用の execution-order ドキュメントに明記する。特に「§7.13 PR マージ実行の直前に `04-completion.md §3.5` retrospective 自動生成 + (mirror モード時) §3.5 Step 5 mirror フローを必ず完結させる」順序契約を明文化する。次サイクルで個別 Issue 化を推奨（mirror Issue 起票候補）。
- **問題 2**: 軽微なため CHANGELOG / 設計修正は不要。今回の fix commit で完了。
- 本サイクル成果物（retrospective 自動生成 + mirror フロー + 氾濫緩和）は v2.5.0 リリース後に各プロジェクトで段階的に有効化される。`feedback_mode = "mirror"` への切替は upstream（ikeisuke/ai-dlc-starter-kit）開発者を主対象とし、ダウンストリーム消費プロジェクトは silent 既定のままで運用。

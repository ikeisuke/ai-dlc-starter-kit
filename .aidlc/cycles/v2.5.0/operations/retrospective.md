# Retrospective: v2.5.0

## 概要

本サイクルで発生したプロセス上の問題を振り返り、次サイクルに引き継ぐ。本サイクル v2.5.0 は自己改善ループ機能（#590）を導入したサイクルであり、本振り返りは Unit 007（#625）で導入した KPT + 主因切り分け + 3 分岐ガイドの初適用例となる。

## メトリクスサマリ

| 項目 | 値 |
|------|-----|
| Unit 数 | 7（Unit 001-007） |
| Decision Records | DR-001〜DR-008（Unit 001-006 由来） |
| マージ前レビューラウンド | 計 11 ラウンド（Inception 2 / Construction 9 / Operations 1） |
| Test 純増 | +88（migration 含まず）、203/203 → 206/206 + α |
| CI 失敗回数 | 1（Skill Reference Check / fix commit でリカバ） |
| Auto-close Issue | #590, #592, #625 |
| 派生バックログ | #621（retrospective mirror Issue 自動重複統合 / GitHub Models 駆動）、#619, #618, #617, #616, #615, #614, #586 等は次サイクル持ち越し |

## Keep（次サイクルでも継続）

1. **Strict Step-Script Separation Pattern**: 04-completion.md ステップが「呼び出し順序と分岐のみ」、bash スクリプトが「決定論的判定ロジック」を担う完全責務分離型ハイブリッド構成。Unit 004-006 で確立し、テスタビリティ + マージ前完結契約整合に大きく寄与
2. **codex review --base main の高速イテレーション**: 各 Unit で 3 ラウンド以内に指摘 0 件まで収束。レビューラウンド毎の課題発見が早く、Construction 完了後の手戻りが最小化された
3. **マージ前完結契約**: PR マージ前に retrospective / mirror / Milestone close まで完結させる契約により、cycle ブランチ削除後の post-merge 改変リスクをゼロにできた
4. **テンプレ + ガード 2 段構成**: defaults.toml 集約 + retrospective-schema.yml + cycle-version-check.sh の 3 層で「設定変更」と「ロジック変更」を分離し、後方互換性を保ちながら新機能を導入できた

## Try（次サイクル以降で試す）

| 優先度 | 施策 | 反映先 |
|--------|------|-------|
| 高 | retrospective mirror Issue の自動重複統合 workflow（GitHub Models 駆動） | #621 |
| 中 | version 管理を marketplace.json に一本化 | #617 |
| 中 | 7.12 PR マージ前レビュー後の write-history 追加コミット漏れ修正 | #616 |
| 低 | retrospective.md の主因切り分け（プロダクト固有 / AI-DLC 固有 / 両方）の機械判定（v2.6.x 以降） | 新規 Issue 起票検討 |
| 低 | predecessor_retrospective.md の自動配置（次サイクル Inception 開始時に前サイクル output から生成） | 新規 Issue 起票検討 |

## 問題項目（Problem）

### 問題 1: Operations Phase の §1-2 振り返りステップが構造未整備で暗黙スキップされる構造的問題（Unit 007 で対応 / Issue #625）

**何が起きたか**: Operations Phase 実行中、`operations-release.md §7.1〜§7.13` を順次実行する流れで、`04-completion.md §3.5 retrospective 自動生成`（Unit 004）が暗黙スキップされ §7.13 PR マージ実行確認まで進行してしまった。ユーザーから「振り返りっていつやるの？」と指摘を受けて気付き、PR マージ前にやり直した。

**なぜ起きたか**: 旧構造では §1「フィードバック収集」/ §2「分析と改善点洗い出し」が項目立てだけで具体的手順・テンプレ・出力先が規定されていなかった。Unit 004 で §3.5 retrospective 自動生成を追加したが、§1-2 と §3.5 の関係 + マージ前完結契約 + write-history.sh exit 3 ガードの整合が片側ドキュメント（04-completion.md §3.5）にのみ記述されており、エージェント / ユーザーが暗黙スキップする余地が残った。visitory v1.14.1 でも実例発生（同様のスキップ問題）。

**損失と影響**: 本サイクルではユーザー指摘により発覚し、マージ前にやり直せた。指摘がなければ、本サイクルで初めて投入する自動振り返り機能を、リリースサイクル自身では実行しないままマージしていた可能性がある。マージ後は cycle ブランチが post-merge-sync で削除されるため、retrospective.md がローカルにすら残らない事象が起きうる。

**主因切り分け**:

| 主因分類 | 該当 | 反映先 |
|----------|------|-------|
| プロダクト固有（プロダクトリポジトリ側で対応） | no | （該当なし） |
| AI-DLC Starter Kit 固有（`/aidlc feedback` で起票） | yes | Issue #625（本サイクル Unit 007 で対応） |
| 両方に責任 | no | （該当なし） |

**skill 起因判定**:

```yaml
skill_caused_judgment:
  q1_answer: "yes"
  q1_quote: "v2.4.x 以前の 04-completion.md §1「フィードバック収集」/ §2「分析と改善点洗い出し」が項目立てだけで具体的な実施手順・テンプレ・出力先が規定されていない構造を引用できる。"
  q2_answer: "yes"
  q2_quote: "operations-release.md §7.x（リリース準備サブステップ）と 04-completion.md §1-§5（Operations Phase 完了処理）の双方が「マージ前」のステップを保持しており、両者の実行順序が両ドキュメント間 / operations index.md / 02-deploy.md のいずれにも明示されていない。"
  q3_answer: "yes"
  q3_quote: "「マージ前完結契約準拠」という制約は満たされる順序が複数あり（例: §7.7 commit 前 / §7.8 PR Ready 前 / §7.13 マージ前のいずれでも「マージ前」を満たす）、§3.5 retrospective を §7.x のどこに挿入すべきかが指定されておらず、複数解釈の余地がある。"
mirror_state:
  state: ""
  issue_url: ""
  recorded_at: ""
```

### 問題 2: skills 内ドキュメントで `bash skills/aidlc/scripts/...` 形式の参照を書いてしまい CI Skill Reference Check が失敗

**何が起きたか**: Unit 004 / Unit 005 / Unit 006 で追加した `04-completion.md` ステップ 3.5 / Step 5 の bash 実行例で、`bash skills/aidlc/scripts/retrospective-mirror.sh` のようなプロジェクトルート相対パスを記載した。CI の `bin/check-skill-references.sh` が違反検知し、PR Ready 化後に Skill Reference Check が FAILURE になった。

**なぜ起きたか**: `SKILL.md` の「パス解決」節に `scripts/` で始まるパスはスキルベース相対と明記されているが、bash 実行コマンド内では `bash <path>` の形式を使うため、エージェントがプロジェクトルート相対の方が「動作する」と誤認した（実際は両方動作するが規約違反）。

**損失と影響**: 軽微。リリース直前の CI 失敗で 1 commit 追加修正と再 push が必要になった。マージブロックは免れた（fix commit でリカバ）。

**主因切り分け**:

| 主因分類 | 該当 | 反映先 |
|----------|------|-------|
| プロダクト固有 | no | （該当なし） |
| AI-DLC Starter Kit 固有 | no | （該当なし、SKILL.md にパス解決ルールは明記済み） |
| 両方に責任 | no | （人間ミス / エージェントミス） |

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

### 問題 3: cycle-version-check.sh が「プロダクトサイクル番号」と「starter kit バージョン」を直接 SemVer 比較する名前空間混同バグ（visitory v1.14.2 報告）

**何が起きたか**: Unit 004 で実装した `scripts/lib/cycle-version-check.sh` の `aidlc_is_cycle_v25_or_later <cycle>` が、引数として渡された **プロダクト側のサイクル識別子**（例: visitory の `v1.14.2`）を **starter kit 側の機能導入バージョン** `v2.5.0` と直接 SemVer 比較していた。これにより v2 系サイクル番号を使うプロダクト以外（visitory v1.x / 日付サイクル `2024-12` 等）では永久に `cycle-too-old` と判定され、`04-completion.md §1.5` 自動生成フローが永久 skip される事象が発生。visitory v1.14.2 サイクルで `Operations Phase 04-completion §1` を実行しようとした際に skip されたとの報告で発覚（PR #620 マージ直前）。

**なぜ起きたか**: Unit 004 設計時、「v2.5.0+ で導入された機能を v2.4.x 以前の skill では呼ばない」という意図のガードを実装したが、判定対象として「skill 自身のバージョン」ではなく **誤って「サイクル番号」を引数で渡す** 設計にしてしまった。プロダクトサイクル識別子と starter kit 内部バージョンは独立した名前空間で比較可能性がないため、判定結果が無意味になっていた。設計レビュー / 各 Unit のレビューラウンド（codex 2-3 回）でも本バグは見落とされた（テストは `v2.5.0` / `v2.4.3` 等 starter kit と一致する番号付けで動作確認していたため、ダウンストリームでの実利用ケースをカバーしていなかった）。

**損失と影響**: PR #620 のマージ前に visitory プロジェクトからの実利用報告で発覚し修正可能だったため、ダウンストリームへの実害は出なかった。修正なしでマージしていた場合、v2.5.0 の目玉機能（自動振り返り）がほとんどのプロダクトで永久に動作しないリリース事故になっていた。本サイクルで実装した自己改善ループ機能が、本サイクルの問題発見にそのまま貢献した（visitory が手動で振り返りを書き Issue 起票 → PR にフィードバック反映）。

**主因切り分け**:

| 主因分類 | 該当 | 反映先 |
|----------|------|-------|
| プロダクト固有 | no | （該当なし） |
| AI-DLC Starter Kit 固有（`/aidlc feedback` で起票） | yes | visitory v1.14.2 から起票された feedback（Issue #625 fix で取り込み完了） |
| 両方に責任 | no | （該当なし） |

**skill 起因判定**:

```yaml
skill_caused_judgment:
  q1_answer: "yes"
  q1_quote: "scripts/lib/cycle-version-check.sh の aidlc_is_cycle_v25_or_later <cycle> が、引数として受け取ったプロダクト側のサイクル識別子（例: v1.14.2）を starter kit 側の機能導入バージョン v2.5.0 と直接 SemVer 比較する設計を引用できる。"
  q2_answer: "yes"
  q2_quote: "04-completion.md §1.5 Step 1 で `bash scripts/lib/cycle-version-check.sh \"{{CYCLE}}\"` を呼ぶ仕様と、関数内で `[[ ! \"$cycle\" =~ ^v[0-9]+\\.[0-9]+\\.[0-9]+$ ]]` 形式チェックを行う実装は、テンプレ {{CYCLE}} に「サイクル番号」が入る前提と「v2.5.0 比較」の意図が両立しない（プロダクトサイクル番号は v2.5.0 とは独立名前空間）。"
  q3_answer: "yes"
  q3_quote: "「v2.5.0 以降のサイクルでは生成する」という関数 doc コメントは、プロダクトサイクル番号が v2.5.0 以降を意味するのか、starter kit が v2.5.0 以降を意味するのかが複数解釈可能（テスト `cycle-version-check.bats` でも v2.5.0/v2.4.3 を比較しているがどちら向けの判定かが暗黙）。"
mirror_state:
  state: ""
  issue_url: ""
  recorded_at: ""
```

## 反映先一覧

- プロダクト GitHub Issue: なし（本サイクル成果物は AI-DLC Starter Kit 自身の改善のため、プロダクト Issue は発生しない）
- AI-DLC feedback Issue: #625（本サイクル Unit 007 で取り込み完了 / 問題 1 + 問題 3 の両方をカバー）
- 次サイクル Intent 反映事項:
  - 派生バックログ #621 / #617 / #616 等の優先度判定
  - 主因切り分け機械判定の検討
  - predecessor_retrospective.md 自動配置の検討

## 次サイクルへの引き継ぎ事項

- **問題 1（Issue #625 / Unit 007 で対応済み）**: §1-2 を §1 振り返りに統合し、KPT + 主因切り分け + 3 分岐 + write-history.sh ガード整合 + `feedback_mode` ベースの opt-out スイッチ（§1.0 実施判定）を組み込んだ。本 retrospective.md 自体が新構造の初適用例である
- **問題 2（軽微 / 対応済み）**: fix commit でリカバ済み。CHANGELOG / 設計修正は不要
- **次サイクル開始時の action**: `cycles/v2.5.0/operations/retrospective.md`（本ファイル）を `steps/inception/01-setup.md §4a` の手順で読み込み、次サイクル Intent 前提として参照する
- **本サイクル成果物の段階的有効化**: retrospective 自動生成 + mirror フロー + 氾濫緩和 + KPT 構造化 は v2.5.0 リリース後に各プロジェクトで段階的に有効化される。`feedback_mode = "mirror"` への切替は upstream（ikeisuke/ai-dlc-starter-kit）開発者を主対象とし、ダウンストリーム消費プロジェクトは silent 既定のままで運用

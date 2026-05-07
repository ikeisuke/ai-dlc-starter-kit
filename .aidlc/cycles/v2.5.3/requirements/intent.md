# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit v2.5.3 — 振り返り機能の信頼性向上

## 開発の目的

v2.5.2 振り返り（[Issue #651](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/651)）で顕在化した、振り返り機能（retrospective）まわりの 4 件の構造的脆弱性を統合解消する patch リリース。AI-DLC を採用する全プロジェクト（jailrun 等）にとって振り返りシステムは「メタプロセス品質保証」の中核となるため、本サイクルで以下の信頼性課題を解消する：

1. **auto mode 下での独断起票バグ**（[#647](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/647)）— jailrun v0.3.4 で実証済み。AI エージェントが対話を経ずに振り返り Issue を起票する運用ミスが起きやすい構造を改善する
2. **履歴記録の構造的欠落**（[#637](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/637)）— v2.5.1 で Unit 完了時の short note が漏れ、Operations PR マージ前レビュー round 1 のエントリが構造的に欠落していた問題を改修
3. **推測値混入バグ**（[#634](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/634) の取り込み範囲）— 振り返り作成時に一次情報を Read してもセッション内記憶からの推測値が混入する構造的問題を、事実テーブル先抽出ステップと推測値検出ガードで予防
4. **retrospective 系スクリプトの横依存**（[#643](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/643)）— `predecessor-issue.sh` が `retrospective-issue.sh` を直接 source して関数を借用する構造を解消し、責務別 helper に分離

## ターゲットユーザー

- AI-DLC Starter Kit を採用しているプロジェクト開発者（特に auto mode を多用するユーザー）
- AI-DLC のメタプロセス（振り返り）を信頼して継続的にサイクルを回すメンテナ
- jailrun のように AI-DLC を活用した別プロジェクトの保守者

## ビジネス価値

- **AI が auto mode で独断起票するバグの再発防止** — AI-DLC を採用する全プロジェクトで効果（jailrun で観測済の実害を予防）
- **履歴記録の網羅性向上** — 次サイクル振り返りの一次情報精度を底上げ（write-history マージ前ガード #616 と組み合わせて記録漏れリスクを抑制）
- **推測値混入ガード** — メタ振り返り（数サイクルに 1 度実施される高インパクト振り返り）の信頼性向上
- **スクリプト保守性向上** — 将来の retrospective 関連改修における障害伝播リスクを低減

## 含まれるもの（Unit 想定 4 件）

| Unit 候補 | 対象 Issue | 概要 |
|----------|-----------|------|
| Unit 001 | [#647](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/647) | Operations §1 振り返り対話強制ガード強化 — `steps/operations/04-completion.md` §1 冒頭に「対話必須」明記 / SKILL.md「AskUserQuestion 使用ルール」テーブルへの「振り返り内容の決定」種別追加 / `feedback_mode=silent` でも対話必須を §1.0 表に補足 |
| Unit 002 | [#637](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/637) | 履歴記録の構造改善 — `aidlc:write-history` skill に「Unit 完了 short note」モードと「Operations round エントリ」モードを追加。round 1 から指摘件数・重要度・対応判定を必ず記録 |
| Unit 003 | [#634](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/634)（絞込み） | 振り返りプロセスの構造的改善 — 事実テーブル先抽出ステップを `steps/operations/04-completion.md` §1 に追加 + `steps/common/review-flow.md` に「約 / approximately / 推定値」検出ガード追加 |
| Unit 004 | [#643](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/643) | predecessor-issue.sh の横依存解消 — path/validation/gh/spool-parse 関数群を `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` に独立 helper として分離。`predecessor-issue.sh` から `retrospective-issue.sh` への直接 source を撤去 |

## 除外するもの（OUT_OF_SCOPE）

- **#634 の 3層検証 skill 化（jsonl 解析 helper 含む）** → [#652](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/652) として切り出し済（次サイクル以降）
- **[#644](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/644)**（retrospective-resend.sh AIDLC_PROJECT_ROOT 対応）— priority:low、本サイクルテーマ「振り返り信頼性」の主軸ではない
- **[#621](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/621)**（mirror Issue 自動重複統合 workflow）— minor 規模の新機能、別サイクル
- **その他 Operations / review-flow 系 [Feedback]**（#641 / #650 など）— 関連はするが今サイクルの主軸ではない

### #634 取り込み対象 / OUT_OF_SCOPE 対比表（指摘 #1 対応）

| 項目 | v2.5.3 で実施（Unit 003） | OUT_OF_SCOPE → #652 |
|------|--------------------------|---------------------|
| 対象ファイル | `steps/operations/04-completion.md` §1 / `steps/common/review-flow.md` | `skills/aidlc/scripts/lib/aidlc-fact-extract.sh`（新規）/ `aidlc-jsonl-parse.sh`（新規）/ 新 skill `aidlc:retrospective-fact-extract` |
| 実装粒度 | docs / steps の改訂のみ。新規 helper・skill 追加なし | helper 群 + skill エントリポイント新規作成 |
| 完了条件 | 04-completion §1 内に「事実テーブル先抽出ステップ」が §1.x として明示されること / review-flow に「約 / approximately / 推定値」検出が記述され、許容例・非許容例が併記されていること | 3 source（decisions.md / history/*.md / jsonl）を統合する skill が動作し、出力される事実テーブル JSON を 04-completion §1 から呼び出せる構造になること |
| 検証方法 | docs grep で該当文言の存在確認 + review-flow をレビュー実行した結果でガードが発動すること | skill 単体テスト + 04-completion §1 結合テスト |

## 成功基準

| Unit | 検証方法 | 合格条件（定量） |
|------|---------|----------------|
| Unit 001 | (a) `grep -E "対話必須\|AskUserQuestion" steps/operations/04-completion.md` で §1 冒頭 / §1.0 表に該当文言が **2箇所以上** ヒット<br>(b) `grep "振り返り内容の決定" skills/aidlc/SKILL.md` で **1件以上** ヒット<br>(c) **本リポジトリ内ドライラン**: `feedback_mode=mirror` × `automation_mode=semi_auto` を想定した fixture を `.aidlc/cycles/v2.5.3/construction/fixtures/operations-mirror-autodialog.md` 等に作成し、04-completion §1 改訂後の手順を擬似実行 → `gh issue create` 直前で AskUserQuestion 呼び出しが必須化されていることを fixture 上で確認<br>(d) **参考検証（non-blocking）**: jailrun #70 と同型シナリオで再発しないことを参考事例として記録 | 上記 (a)(b)(c) すべて合格（必須）。(d) は参考検証（non-blocking）。**対話なしの起票パスが本リポ内 fixture 上で存在しない** |
| Unit 002 | (a) `/write-history --mode unit-complete-short-note --short-note "テスト" --cycle X --unit N` が exit 0 で、history/construction_unitNN.md に「補足（short note）」セクションが追記される<br>(b) `/write-history --mode operations-round --round 1 --findings 3 --critical 1 ...` が exit 0 で、history/operations.md に round 1 エントリ（指摘件数 / 重要度 / 対応判定）が追記される<br>(c) round 1 エントリが round 2-5 と同じテンプレ構造を持つ | 上記 (a)(b)(c) すべて合格 |
| Unit 003 | (a) `grep -E "事実テーブル\|fact[- _]table" steps/operations/04-completion.md` で §1.x として **1箇所以上** 明示<br>(b) review-flow による Round 1 ドライランで、入力例 A「DR-001〜DR-035 の **35 件**（推定）」が「推定値混入」として flag される<br>(c1) **flag される入力例 B-flag**: 「DR-001〜DR-010（**約 10 件**）」（近似語あり / 根拠リンク併記なし） → flag される<br>(c2) **flag されない入力例 B-allow**: 「DR-001〜DR-010（約 10 件、`requirements/decisions.md` 参照）」（近似語あり / 根拠リンク併記あり） → flag されない（例外条件として境界条件セクションに沿う）<br>(d) `steps/common/review-flow.md` に許容例・非許容例が **2件以上** 併記される | 上記 (a)(b)(c1)(c2)(d) すべて合格。入力例 B は flag/non-flag のペアで例外ロジックの回帰検知が成立する |
| Unit 004 | (a) `grep -c "source.*retrospective-issue.sh" skills/aidlc/scripts/lib/predecessor-issue.sh` が **0**<br>(b) **責務分離（機械判定）**: `aidlc-validate.sh` に `__retro_validate_cycle` 系（cycle 命名・存在チェック）/ `aidlc-gh.sh` に `__retro_gh_status` 系（gh CLI 可用性）/ `aidlc-spool.sh` に `_spool_extract_entries` 系（NDJSON spool パース）が移管され、`grep -E "^(__retro_validate_cycle\|__retro_gh_status\|_spool_extract_entries)" skills/aidlc/scripts/lib/retrospective-issue.sh` で **元ファイルから移管対象関数定義が削除されている**（grep 0 件）<br>(c) **相互 source 禁止**: 新 helper ファイル（`aidlc-{validate,gh,spool}.sh`）が `retrospective-issue.sh` / `predecessor-issue.sh` をいずれの記法（`source` または `.` (dot source)）でも読み込まないこと。下記コマンド (Markdown テーブル外で正規表現を提示) で **0 件** 確認。<br>(d) 既存呼び出し（`predecessor_resolve_issue` / `retrospective_collect_candidates`）の **CLI 引数互換性**: 入力引数列・引数名・必須／任意フラグが破壊変更されていない<br>(e) **exit code 互換性**: 既存ケース（success / not-found / gh-unavailable）の exit code が一致する<br>(f) **stderr 文言互換性**: 既存テストケースで stderr 文言の主要行（`predecessor_candidates_emitted` / `info` / `warn` プレフィックス等）が一致する | 上記 (a)(b)(c)(d)(e)(f) すべて合格。**回帰テストとして v2.5.2 サイクルの predecessor-issue.sh 呼び出しを再生して同等の出力を得る** |

## 期限とマイルストーン

- patch リリース v2.5.3 として 1 サイクル内で完了
- 全 Unit を Inception → Construction → Operations 一気通貫で実施

## 制約事項

- **後方互換**: 既存 mirror cycle / Issue / retrospective.md / history/*.md の読み込みは継続動作する
- **skill 構成ルール**: SKILL.md の本文 500 行制限を遵守（`aidlc:write-history` skill の改修もこの制限内で）
- **patch スコープ**: 破壊的変更なし。設定ファイル（config.toml）のキー追加・名称変更は行わない（必要時は別 minor で）
- **review-flow 5R 化**: v2.5.2 で導入された 5R 完了条件（最後 2R 連続ゼロ or defer）を本サイクルでも継続適用

## Unit 004(c) 検証コマンド（Markdown テーブル外で正規表現を提示）

Markdown テーブル内では `|` がセル区切りとぶつかるため、検証コマンドを以下のコードブロックで提示する：

```bash
grep -EHn "^(source|\.)[[:space:]]+.*(retrospective-issue|predecessor-issue)\.sh" \
  skills/aidlc/scripts/lib/aidlc-validate.sh \
  skills/aidlc/scripts/lib/aidlc-gh.sh \
  skills/aidlc/scripts/lib/aidlc-spool.sh
```

このコマンドの出力が **0 件**（exit code 1 = no match）であることを Unit 004(c) の合格条件とする。`source` と `.` (dot source) の両記法を alternation として検出する。

## 推定値検出ガードの境界条件（指摘 #3 対応 / Unit 003 補足）

`review-flow.md` に追加する「約 / approximately / 推定値」検出ガードは、誤検知を抑えるため以下のスコープに限定する：

**検出対象**: 「数値表現と隣接する」近似/推定マーカー
- 検出マーカー: `約`, `およそ`, `approximately`, `approx.`, `推定`, `〜くらい`, `〜程度` など
- ただし**直前または直後 5 文字以内に算用数字（`[0-9]`）または日本語数字（一〜十、百、千、万）が現れる場合のみ flag**

**許容例（flag されない）**:
- 「約束された動作」「推定エンジン」のような数値を伴わない概念用法
- 「十分な検証」のような数量を意味しない数字表記
- コードブロック内の数値（`approximately = 5` のような変数定義）
- **根拠リンク併記時の例外**: 同一段落内に PR/Commit/Issue リンク（`#NNN` / `https://github.com/...` / `<sha>` 等）または対象ファイルパス参照（`` `path/to/file.md` ``）があり、その数値の出典が明示されている場合（例: 「DR-001〜DR-010（約 10 件、`requirements/decisions.md` 参照）」）

**非許容例（flag される）**:
- 「約 50 round」「approximately 130 件」「推定 35 件」「DR-001〜DR-010（**約 10 件**）」（根拠リンク併記なし）
- 一次情報を Read していないことが明らかな数値推定表現
- **重要**: 一次情報を Read 済みでも、根拠リンクや出典参照が併記されていない近似語付き数値は flag する（一次情報の有無は flag 判定に使わず、Intent 上で明示された「根拠リンク併記」のみが許容条件）

詳細な regex / 実装方針は Construction Phase Unit 003 の設計で確定する。

## 不明点と質問（Inception Phase 中に記録）

（現時点で未解決の Question なし。Stories / Unit 定義段階で発生したものをここに追記する）

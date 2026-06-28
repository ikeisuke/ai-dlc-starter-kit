# PRFAQ: AI-DLC v3 — Phase 6（reflect + doctor + status 拡充）

## Press Release（プレスリリース）

**見出し**: AI-DLC v3、振り返りと自己診断を獲得し「単独フルサイクル完走」へ

**副見出し**: `/aidlc-v3 reflect` で学びを Issue に変え、`/aidlc-v3 doctor` で着手前に環境・状態を診断できるようになりました（v3.0.0-alpha.7）。

**発表日**: 2026-06-28（サイクル v3.0.0-alpha.7）

**本文**:

[背景] AI-DLC v3 はここまで `define → develop → release` を v3 単独の手順で回せるようになりました（Phase 5 / alpha.6）。しかし、サイクルを閉じる「振り返り」と、作業前に問題を見つける「診断」が未実装で、フルサイクルを完走できる状態には一歩届いていませんでした。v2 では振り返りに upstream mirror / cap 管理など starter kit 固有の重い仕組みが、診断は preflight と recovery 仕様に分散しており、認知コストが高い課題がありました。

[プロダクト] 本サイクル（Phase 6）で 3 つを提供します。(1) **reflect**: journal と release 結果から KPT を抽出し、必要な改善だけを Issue 化、`reflect.md` に記録して次の define に渡します（承認ゲートなし・人間が編集）。(2) **doctor**: config / state / cycle / work-items / git / gh / pr / scripts を着手前に診断し、禁止パースパターンも検出します（診断と推奨のみ・自動修正しない）。(3) **status 拡充**: 残作業と次の推奨コマンドを含む現在地表示。あわせて、ドッグフーディングで踏んだ `squash-unit.sh` の複数 `--message` footgun を修正しました。

[顧客の声] 「reflect で振り返りが反省文でなく次の Issue に変わる」「doctor を最初に打てば壊れた state で作業を始めずに済む」「status で次に打つコマンドが分かる」——v3 を使う開発者と、本キットを自分自身で開発するドッグフーディング開発者の双方が、より少ない読み込み量で運用できます。

[今後の展開] Phase 6 完了で「v3 をスキルとして使える」状態に到達します。続く Phase 7 で v3 を本流化し（`aidlc-v3 → aidlc` 置換）、v3.0.0 RC→GA を目指します。doctor の `[phase]` 導出・`[trace]` 整合は alpha.8 の必須 follow-up として段階実装します。

## FAQ（よくある質問）

### Q1: なぜ doctor は config/git/gh/state など 8 領域だけで、phase/trace は入らないのですか？
A: 実装コストの大半が `[phase]` 導出 code 化と `[trace]` 整合に集中しており、両者は機能確定待ちです。本サイクルは既存スクリプト（state-validate.sh / work-item-validate.sh 等）を再利用できる shallow 8 領域 + parse-guard に絞り、phase/trace は alpha.8 の必須 follow-up として SoT（workflow.md / renewal-plan / Epic #736）に段階注記します。「やり過ぎ」を避け、Phase 6 完了条件「v3 単独フルサイクル完走可能」を満たすための判断です。

### Q2: #733（v3系通し振り返り）は実装しないのですか？
A: #733 の Try（T1 共有 parser ライブラリ / T2' conformance test / T4 機械検出 / T6 CycleResolver 明示優先）は、すべて alpha.4（Phase 番外）で実装・CI ガード済みです。本サイクルでは再実装せず、完了証跡をコメントしてクローズします（実装作業ゼロ）。

### Q3: reflect は v2 の Retrospective と何が違いますか？
A: v3 の reflect は core を軽量化し、upstream mirror（starter kit 固有）/ cap 管理 / dialog token / aggregate retrospective issue を実装しません。材料収集 → KPT 抽出（人間編集）→ Try の Issue 化（人間確認・必要分のみ）→ journal 追記の 4 ステップに集約し、明示の承認ゲートを持ちません。

### Q4: doctor は問題を自動で直してくれますか？
A: いいえ。doctor は**診断と推奨のみ**で、state.json や work item が壊れていても自動修正しません。修正は利用者の判断に委ねます。

### Q5: なぜ v2 ツールの #735 修正がこの v3 サイクルに含まれるのですか？
A: `squash-unit.sh` はドッグフーディングで各 Unit 完了時の squash に使われ、複数 `--message` で subject が失われる footgun があります。本サイクルでも先行 Unit の完了 squash が影響を受けるため、修正 Unit を実行順の先頭（Unit 001）に置き、以降の Unit が修正後のツールで安全に squash できるようにしました。

### Q6: 本サイクル自体のリリースは v3 で行いますか？
A: いいえ。alpha.7 自身の Inception → Construction → Operations は通常どおり v2（`/aidlc`）で進めます。v3 を実リリースに使う dogfooding は Phase 7 で行います。

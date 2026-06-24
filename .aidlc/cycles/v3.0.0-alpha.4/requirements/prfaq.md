# PRFAQ: AI-DLC v3 frontmatter パース安全境界の共有ライブラリ集約（v3.0.0-alpha.4）

## Press Release（プレスリリース）

**見出し**: AI-DLC v3、frontmatter パースを単一の共有ライブラリに集約 — 「寛容なパースが malformed を通す」バグクラスを構造的に根絶

**副見出し**: work item の frontmatter 解釈を 1 箇所に集め、禁止規約・conformance テスト・CI 機械検出で再発を断つ v3.0.0 GA 仕上げの一歩

**発表日**: v3.0.0-alpha.4 リリース時

**本文**:

[背景] AI-DLC v3 では、work item の frontmatter を各スクリプトが個別に `grep`/`sed`/`awk` の行指向 regex で解釈してきた。この「寛容なパース」が malformed な YAML を通してしまうバリデーションクラスのバグが alpha.2（state 系）→ alpha.3（work-item 系）で反復再発し、per-Unit のレビューをすり抜けて Operations の全差分レビューで 8 件まとめて発覚した（振り返り #733）。同じパースロジックが 3 クラス（スカラー抽出 / 配列 / ブロック抽出）にわたり 2〜3 箇所ずつ重複しており、1 箇所の修正が兄弟スクリプトに横展開されない構造的弱点があった。

[プロダクト] 本サイクルは frontmatter パースを `skills/aidlc-v3/scripts/lib/` の単一共有ライブラリへ集約する。`work-item-validate.sh` / `work-item-next.sh` / `work-item-status.sh` は個別実装を撤去してこのライブラリを source する。加えて (1) 個別スクリプトでの構造解釈を禁止する規約の明文化、(2) 受理/拒否ケースを固定する conformance test suite、(3) 禁止パターンの CI 機械検出、(4) cycle 解決が明示指定を最優先する回帰テスト、を整備し、「共有する」だけでなく逸脱を自動で弾くガードレールまで含めて締める。

[顧客の声] v3 本体の保守者は「パース境界が 1 箇所に集まり、拒否理由と受理仕様が中央化されたので、release / reflect / doctor を実装してもパース面で同じ轍を踏まない」と評価する。

[今後の展開] 本構造改善を alpha.4 で検証した上で、v3.0.0 GA に進む。共有ライブラリは将来の v3 consumer（release / reflect / doctor フロー）が同一境界を source する基盤となる。

## FAQ（よくある質問）

### Q1: なぜ JSON（state-*.sh）は対象外なのか？

A: JSON のパースは既に `jq` に一本化され、schema 検証も `state-validate.sh` に集約済み（#731）だから。本サイクルの主対象は未集約の frontmatter 側であり、JSON は現状維持（整合確認のみ）とする。

### Q2: 「純粋リファクタ」と言いつつ malformed を確実に拒否するのは挙動変更では？

A: 既存で正しく受理/拒否されているケースの境界は変えない（互換維持）。一方、#733 で検出された既知の malformed / partial-parse クラスは拒否 fixture として明示的に固定する（意図的な拒否強化）。両者を conformance test 上で区別する。

### Q3: T4 の CI 機械検出は state-*.sh の正当な jq まで弾かないか？

A: 弾かない。検出は frontmatter 構造解釈の文脈に限定し、`lib/`（共有 parser 本体）と `tests/`（fixture）を allowlist 除外する。`state-*.sh` の JSON 用途の jq は対象外。

### Q4: T6 の CycleResolver は v3 で何を直すのか？

A: v3 本体は既に cycle を `state.json.current_cycle`（明示指定）に一本化済みで、#733 P4 のような gitlog 推定ロジックは存在しない。本サイクルではその「明示指定最優先」仕様を回帰テストで固定し、再発を防ぐ（framework 側 `skills/aidlc/` の修正はスコープ外）。

### Q5: なぜ GA ではなく alpha.4 なのか？

A: #733 の主因（パース安全境界の反復再発）は GA 品質に直結するため、構造改善を alpha でもう一段検証してから GA（v3.0.0）に進む方が安全と判断した。

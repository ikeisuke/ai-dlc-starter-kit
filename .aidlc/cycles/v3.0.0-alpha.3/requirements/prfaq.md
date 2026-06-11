# PRFAQ: AI-DLC v3 alpha.3（define + develop tiny フロー実行実装）

## Press Release（プレスリリース）

**見出し**: AI-DLC v3 が初めて「動く」 — define で cycle を作り、develop で tiny work item を完了する

**副見出し**: alpha.2 で「読める手順」だった `skills/aidlc-v3/` が実行可能に。`/aidlc-v3 define` で新しい cycle・intent・work-items・state.json を実生成し、`/aidlc-v3 develop` で tiny work item を design / review なしで完了できる。

**発表日**: 未定（v3.0.0 alpha 段階的開発の一部）

**本文**:

[背景] alpha.2 の skeleton は define / status を「読める手順」として固定したが、フローを実際には実行できなかった。Phase 4 以降（develop normal/risky、release、reflect/doctor）はこの実行基盤を土台とするため、まず define + develop tiny を「動く」状態にする必要がある。

[プロダクト] alpha.3 は `skills/aidlc-v3/` の define フローを実行実装にし（cycle ディレクトリ作成・intent.md / work-items/*.md / journal.md 生成・`.aidlc/state.json` 初期化・branch / commit）、`steps/develop.md` の tiny フロー（status を pending → in_progress → done と遷移、work item 単位 commit、journal 追記）を新設する。依存解決スクリプト `work-item-next.sh`（pending かつ依存が全 done の work item を選定）を追加し、`marketplace.json` に `aidlc-v3` を登録して `/aidlc-v3` 起動を有効化する。あわせて alpha.2 レビューで defer した #731（未知 schema_version の state を validator が WARN 化し、writer が更新しない最小ガード）を解消する。すべて v2 `skills/aidlc` には一切触れない（クリーンカット共存）。

[顧客の声] 「v3 を読むだけでなく、実際に `/aidlc-v3 define` で cycle を起こして tiny work item を回せるようになった」「未知の schema_version を持つ state が誤って上書きされなくなり、安心して state を触れる」。

[今後の展開] alpha.3（define + develop tiny）→ alpha.4（develop normal/risky）→ alpha.5（release）→ alpha.6（reflect + doctor）→ alpha.7〜（ドッグフーディング + 本流化）と段階構築を継続し、v3.0.0 として本流化する。

## FAQ（よくある質問）

### Q1: alpha.3 で v3 は実際に使えるようになりますか？
A: define と develop の tiny フローは実際に動きます。`/aidlc-v3 define` で cycle を作成し、`/aidlc-v3 develop` で tiny work item を完了できます。ただし develop の normal / risky、release、reflect / doctor は未実装（予約）で、これらは後続フェーズです。

### Q2: develop で normal / risky の work item を選んだらどうなりますか？
A: tiny フローのみが対象です。次候補が normal / risky の場合は未サポート案内を出して停止し、frontmatter / journal / commit を一切変更しません（副作用なし）。normal / risky フローは Phase 4 で実装します。

### Q3: v2（既存の skills/aidlc）に影響はありますか？
A: ありません。成果物は `skills/aidlc-v3/` と `marketplace.json` の plugins 追加 1 行に隔離されます。v3 の state は `.aidlc/state.json`（cycle レベル）で、v2 の `.aidlc/config.toml` / `cycles/` とは location が異なるため共存できます。検証は v2 ドッグフーディング用の `.aidlc/` を破壊しないサンドボックス／テストハーネスで行います。

### Q4: #731 はどう解消しますか？
A: `state-validate.sh` がサポート対象 `schema_version`（初版 `"3.0"`）と未知バージョンを区別し、未知バージョンは invalid（exit 1）ではなく WARN + migration・手動対応案内として扱います（data-model §6 準拠）。あわせて `state-write.sh` が未知 schema_version の既存 state.json を更新しない最小ガードを入れ、非互換 state の誤更新・保持を防ぎます。recovery / migration レイヤーの本格実装は後続フェーズです。

### Q5: なぜ起動有効化（marketplace 登録）を alpha.3 で行うのですか？
A: 実行実装が入るため、`/aidlc-v3 define` / `develop` を実際に起動してドッグフーディングでき、設計（docs/v3/*.md）と実装の乖離を早期に検出できるからです。本流化（skills/aidlc-v3 → skills/aidlc、marketplace version の v3.0.0 化）は Phase 7 へ defer します。

# PRFAQ: AI-DLC v3 alpha.2（aidlc-v3 skeleton）

## Press Release（プレスリリース）

**見出し**: AI-DLC v3 の骨組みが立ち上がる — `skills/aidlc-v3/` skeleton

**副見出し**: alpha.1 で確定した設計（RFC / data model）を、v2 と共存する最初の実体に。define 手順・status 出力仕様・state 操作スクリプト・成果物テンプレートが「読めて検証できる」形で揃う。

**発表日**: 未定（v3.0.0 alpha 段階的開発の一部）

**本文**:

[背景] alpha.1 で v3 の設計判断は `docs/v3/*.md`（rfc / workflow / data-model / migration）に固定されたが、まだ実体（skill ファイル）が存在しなかった。Phase 3（define + develop flow 実装）に進むには、土台となる skill 構造・state 操作 API・テンプレートを先に確定する必要がある。

[プロダクト] alpha.2 は `skills/aidlc-v3/` に最初の骨組みを構築する。SKILL.md（define / develop / release / reflect / status / doctor + express + 旧名エイリアス + 引数なし実行のルーティング）、`steps/define.md`（define フロー手順書）、`steps/status.md`（status 出力仕様）、state スクリプト 3 本（read / write / validate）、テンプレート 3 種（intent / work-item / journal）を置く。すべて v2 `skills/aidlc` には一切触れず（クリーンカット共存）、フローの実行実装は Phase 3 以降に委ねる。

[顧客の声] 「v3 がどんな構造で、define で何を作り status で何が見えるのかが、実ファイルとして読めるようになった」「state.json の作成仕様が validate スクリプトで機械的に確認できる」。

[今後の展開] alpha.2（skeleton）→ alpha.3（define + develop tiny flow 実装）→ alpha.4（develop normal/risky）と段階構築を継続し、ドッグフーディング完走後に v3.0.0 として本流化する。

## FAQ（よくある質問）

### Q1: alpha.2 で v3 は動くようになりますか？
A: まだ「動く」段階ではありません。alpha.2 の完了条件は「define 手順が読める / state.json 作成仕様がある / status 出力仕様がある / v2 に影響しない」であり、ドキュメント中心の skeleton です。実際に `/aidlc-v3 define` が機能するのは Phase 3（alpha.3）からです。

### Q2: v2（既存の skills/aidlc）に影響はありますか？
A: ありません。成果物は `skills/aidlc-v3/` に隔離され、v2 のファイル・runtime には一切変更を加えません（`git diff` で検証します）。`marketplace.json` への `aidlc-v3` 登録（起動有効化）も本サイクルでは行わず、Phase 3 以降へ defer します。

### Q3: なぜ state スクリプトを 3 本（read/write/validate）入れるのですか？
A: 「試せる skeleton」には state.json の読み取り（status が参照）と書き込み（define が更新）と検証（doctor が利用）の最小 API が必要なためです。計画書の恒久スクリプトリストとも一致します。ただし状態遷移ルールの詳細化は Phase 3 へ defer します。

### Q4: コマンド名は build ですか develop ですか？
A: `develop` です。確定 RFC（DG-1）が `define / develop / release / reflect` を正式名と定め、`build` / `implement` はエイリアスにもしません。renewal plan 上の `build` 表記は確定 RFC の `develop` に読み替えます。

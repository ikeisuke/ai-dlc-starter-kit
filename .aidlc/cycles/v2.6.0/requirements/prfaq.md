# PRFAQ: AI-DLC Starter Kit v2.6.0

## Press Release（プレスリリース）

**見出し**: AI-DLC Starter Kit v2.6.0 リリース — バージョン管理 SoT 一本化、GitHub Projects 移行、振り返りフロー独立化

**副見出し**: Plugin Marketplace 表示乖離の根絶、バックログ動的管理化、Operations と振り返りの責務分離を一括で実現する minor リリース

**発表日**: 2026-05-XX（v2.6.0 マージ完了日）

**本文**:

**[背景]** AI-DLC Starter Kit は、`marketplace.json`・複数の `version.txt`・`config.toml` の `starter_kit_version` という多重ソースでバージョン情報を管理してきた結果、Plugin Marketplace 表示と実体バージョンが乖離する事象（v2.4.3 時点で `marketplace.json = 2.0.4` のまま残存）が発生した。同時に、バックログ管理は GitHub Issue #524 の手動チェックリストに依存しており、サイクル完了ごとに本文編集コストが発生していた。さらに振り返りフローは Operations Phase §1 に組み込まれており、サイクル完了直後でしか実施できない構造的制約があった。

**[プロダクト]** v2.6.0 では以下の 3 系統を一括で解決する:

1. **バージョン管理 SoT 一本化**: `.claude-plugin/marketplace.json.metadata.version` を唯一の SoT に確定し、冗長な `version.txt` 系 3 ファイルを廃止。`bin/update-version.sh` を `marketplace.json` 主体に再構築し、pre-release / CI ガードで同期漏れを構造的に防止。`aidlc-setup` のアップグレードでは `starter_kit_version` のみ差分の場合に no-op スキップ。
2. **GitHub Projects 移行**: ProjectsV2 でバックログを動的管理化。Status / Priority / Cycle / Type の 4 軸でフィルタ可能、`Item closed` ワークフローで Issue Close 時の Done 自動遷移を実現。Issue #524 は Project URL へリダイレクト化。
3. **振り返りフロー独立化（破壊的変更）**: `/aidlc r`（短縮: `r`）で起動可能な独立スキル `aidlc-retrospective` を新設。Operations Phase §1 から振り返りロジックを完全移転。Operations 完了時に `/aidlc i` と並列で `/aidlc r` を案内。

加えて、`migrate-backlog.sh` の UTF-8 多バイト境界分断バグ（#615）と `rules.md` の MD040 違反（#614）を修正する。

**[顧客の声]** AI-DLC スターターキットを利用するメンテナ・コントリビュータからは、「Plugin Marketplace 表示が常に最新と一致する安心感が得られた」「バックログを動的に絞り込めて次サイクル候補の意思決定が早くなった」「振り返りを後日まとめて実施できるようになり、Operations 完了直後のプレッシャーが減った」というフィードバックを想定している。

**[今後の展開]** 次のサイクル以降では、本サイクルで残した課題（`priority:*` ラベルと Project `Priority` フィールドの双方向同期 workflow、振り返り Issue の自動重複統合 #621、振り返り 3 層検証手順の skill 化 #652、`[rules.backlog]` DEPRECATED 削除 #646）に取り組む。GitHub Projects 上で動的フィルタを使った優先度判断が標準ワークフローになる予定。

---

## FAQ（よくある質問）

### Q1: v2.6.0 は破壊的変更を含みますか？

A: はい。**振り返りフロー独立化（#667）** が破壊的変更です。v2.6.0 以降、Operations Phase 内から振り返りは一切起動されません。代わりに `/aidlc r`（または `/aidlc retrospective`）で `aidlc-retrospective` スキルを起動してください。Operations 完了メッセージで案内されます。

`aidlc-migrate` を v2.5.x → v2.6.0 で実行すると「振り返り起動方法が変わりました（`/aidlc r` を使用してください）」のメッセージが表示されます。

### Q2: `version.txt` ファイルが消えるとローカルスクリプトが壊れませんか？

A: 削除前に参照側コード（`SKILL.md` / `01-setup.md` / `env-info.sh` / `lib/version.sh`）をすべて `marketplace.json` 参照に書き換えてから削除します。順序は厳守され、`bin/update-version.sh` も `marketplace.json` 主体に再構築されるため、リリースワークフローは継続して動作します。

外部スクリプトで `version.txt` を直接参照していた場合は、`dasel -i json '.metadata.version' < .claude-plugin/marketplace.json` または `jq -r '.metadata.version' .claude-plugin/marketplace.json` への置換が必要です。

### Q3: GitHub Projects への移行は手動作業が必要ですか？

A: はい、**gh CLI のトークンスコープ拡張**は手動作業が必要です。利用前に `gh auth refresh -s project,read:project` を実行してください。手順は README.md / `docs/` に記載されます。

その後の Project 作成・フィールド/ビュー定義・Item 一括投入は AI-DLC スクリプト経由で実施可能です。トークンスコープ不足が検出された場合、AI-DLC スクリプトは Project 操作をスキップして警告のみで続行するため、既存のバックログ確認フローは阻害されません。

### Q4: `/aidlc r` で振り返りを後日実施するとき、対象サイクルはどう特定されますか？

A: `/aidlc r` はデフォルトで直近完了サイクルを自動検出します。明示指定したい場合は `/aidlc r v2.5.6` のように引数で指定可能です。対象サイクルが特定できない場合（`.aidlc/cycles/` 不在等）は `error:cycle-not-found` を表示して exit 1 となるため、黙って間違ったサイクルが選ばれる事故を防ぎます。

### Q5: マージ前完結契約（DR-001）は `/aidlc r` 経由でも維持されますか？

A: はい。`/aidlc-retrospective` から呼び出される `write-history.sh` も既存の `--operations-stage post-merge` ガード経路を継承します。post-merge での `cycles/.../**` 改変は引き続き exit 3 で拒否されるため、マージ前完結契約は破壊的変更の影響を受けません。

### Q6: Story 1 が 4 サブストーリー（1A/1B/1C/1D）に分割されているのに Unit が 1 つ（Unit 003）なのはなぜですか？

A: ストーリー粒度はレビュー観点（INVEST 原則）に基づき、各サブストーリーが独立に検証可能であることを担保するための分割です。Unit 粒度は実装の凝集性に基づく単位で、SoT 一本化作業は段階的に進める必要があるため 1 Unit でまとめて管理する方が依存関係が明確になります。詳細は `.aidlc/cycles/v2.6.0/inception/decisions.md` DR-005 を参照してください。

### Q7: 過去の `version.txt` 参照が CHANGELOG や history に残っているのはどうなりますか？

A: 過去サイクルの履歴・CHANGELOG・ドキュメント言及は **削除対象外** です。本サイクルの目的は「規範的な参照（スクリプト・SKILL・設定ファイルでの実行参照）の SoT を一本化する」ことであり、過去の記録に手を加えることではありません。`git grep` 検証時も履歴系ファイルは除外します。

### Q8: GitHub Projects と Milestone はどう使い分けるのですか？

A: 役割が異なるため両立します:

- **Milestone**: サイクル単位の出荷スコープ（`v2.6.0` 等の固定スコープ）
- **GitHub Projects**: バックログ全体の動的管理（Status / Priority / Cycle 等の動的フィルタ）

`Cycle` フィールドは Milestone 値（`v2.6.0` 等）と連動させ、Project 上で Milestone を SoT として参照します。詳細は `requirements/intent.md` の「含まれるもの #673」を参照してください。

### Q9: `aidlc-retrospective` 独立スキルの実装規模が大きい場合の進め方は？

A: Construction Phase で Unit 005 を sub-Unit に分割します（例: Phase 1 スキル骨格 + parser 拡張 / Phase 2 ロジック移転 / Phase 3 Operations 側削除 / Phase 4 ドキュメント更新）。各 sub-Unit は独立 commit として履歴に残り、進捗が可視化されます。詳細は `story-artifacts/units/005-aidlc-retrospective-skill-extraction.md` を参照してください。

### Q10: 本サイクルに含まれない関連 Issue（#646 / #640 / #669 / #664 / #652 / #621）はどうなりますか？

A: いずれも次サイクル以降で個別または統合的に対応予定です。`requirements/intent.md` の「含まれないもの」に記載の通り、本サイクルではスコープ外として扱います。GitHub Projects 移行（Story 3 完了）後は、これらの Issue を Project 上で Status / Priority で動的に絞り込んで次サイクル候補を決定できるようになります。

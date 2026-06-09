# PRFAQ: AI-DLC v3

## Press Release（プレスリリース）

**見出し**: AI-DLC v3 — モダン AI モデル前提のゼロから再設計

**副見出し**: 防御ロジックを削ぎ落とし、明示状態と最小ワークフローで「Intent からリリースまで」を一気通貫にする AI-DLC の次世代版。

**発表日**: 未定（v3.0.0 / alpha 段階的開発を経て確定）

**本文**:

[背景] AI-DLC v2 はステップ Markdown 6,436 行の約 60% が Claude 3.5 時代向けの防御的指示で占められ、推論ベースの復帰仕様（819 行）と 10 個の重複したレビュースキルが保守を圧迫していた。モダン AI モデル（Opus 4.x 等）には「何をすべきか」を簡潔に書けば十分であり、過剰な防御は不要になった。

[プロダクト] v3 は方法論（会話の逆転・Unit 概念・3 フェーズ・レビュー品質ゲート）を維持したまま実装を再設計する。コマンドは define / build / release / reflect の 4 フェーズ + status / doctor の補助 2 つ。状態は state.json（cycle）と work item frontmatter（分散）で明示管理し、復帰は推論ではなくフェーズ導出で行う。レビューは 1 スキル + perspective に統合。スキル 17→5、ステップ 6,436→約 730 行、設定キー 34→8 を目標とする。

[顧客の声] 「読み込むファイルが減り、AI がどのフェーズで何をするかが一目で分かる」「tiny な変更が儀式なしで終わる一方、risky な変更はちゃんと重く扱われる」。

[今後の展開] alpha.1（RFC / data model 固定）→ alpha.2（skeleton）→ alpha.3（define + build tiny）と段階的に構築し、ドッグフーディングで 1 サイクル完走後に v3.0.0 として本流化する。v2 からは migration スキルで移行を支援する。

## FAQ（よくある質問）

### Q1: v3 は v2 と互換性がありますか？
A: runtime 互換は維持しません（クリーンカット）。v2 の config.toml / progress / history は v3 形式へ migration スキルで変換します。推奨移行モードは new-cycle-only（過去資産を触らず v3 cycle を開始）です。

### Q2: AI-DLC の方法論は薄まりませんか？
A: いいえ。削減対象は「実装の複雑さ（旧モデル向け防御ロジック）」であり、「方法論の深さ」ではありません。承認ゲート・レビュー上限・Defer 戦略・Unit 依存解決・Depth Level 分岐はすべて維持します。

### Q3: 本サイクル（alpha.1）で何が手に入りますか？
A: 設計文書（docs/v3/rfc.md / workflow.md / data-model.md / migration.md）と state.json schema 初版・work item template 初版です。実行可能な v3 ツールは alpha.3 以降で動き始めます。

### Q4: なぜコマンド名を変えるのですか？
A: define / build / release / reflect はフェーズの実際の行為を直接表現し、新規ユーザーの理解コストを下げます。ただし最終決定は RFC の設計判断として改めて検討し、旧名称（inception 等）はエイリアスとして維持する方針を含めて結論を出します。

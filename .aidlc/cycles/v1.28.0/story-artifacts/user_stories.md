# ユーザーストーリー

## Epic: AI-DLC品質保証・レビュー体制の強化

### ストーリー 1: アーキテクチャスタイル宣言と違反検出（#405）
**優先順位**: Must-have

As a AI-DLCを使用する開発者
I want to プロジェクトのアーキテクチャスタイル（レイヤー構成、依存方向）をtoml設定で宣言し、レビュー時に違反を自動検出したい
So that サイクルを重ねてもアーキテクチャスタイルの崩れを早期に検出・防止できる

**受け入れ基準**:
- [ ] `docs/aidlc.toml` に `[rules.architecture]` セクションを追加でき、`style`（レイヤード/クリーンアーキテクチャ等）、`layers`（レイヤー定義リスト）、`dependency_direction`（依存方向ルール）を宣言できる
- [ ] `docs/aidlc/config/defaults.toml` に `[rules.architecture]` のデフォルト値が定義され、未設定時はデフォルト値が適用される
- [ ] `read-config.sh` で `rules.architecture.*` のキーが正常に読み取れる
- [ ] reviewing-architectureスキルのSKILL.mdに、toml設定の `[rules.architecture]` を参照してレイヤー分離・依存方向の違反を検出する観点が追加される
- [ ] `[rules.architecture]` が未設定の場合、reviewing-architectureスキルは従来の汎用レビューのみ実行し、エラーにならない
- [ ] 設定したレイヤー違反（上位レイヤーから下位レイヤーへの依存方向違反等）がレビュー結果で指摘として検出される
- [ ] `style` に未知の値が設定された場合、警告メッセージ「未知のアーキテクチャスタイル: [値]。汎用レビューのみ実行します」が表示され、エラーにならない

**技術的考慮事項**:
- 設定は `prompts/package/config/defaults.toml` を編集し、`docs/aidlc/config/defaults.toml` はrsync同期で反映
- daselでTOML配列・ネストテーブルの読み取りが可能か事前確認が必要

---

### ストーリー 2: Inception Phase意思決定プロセスの記録（#404）
**優先順位**: Must-have

As a AI-DLCでInception Phaseを進める開発者
I want to 複数の選択肢があった場合に、選択理由と却下理由を構造的に記録したい
So that 後続サイクルで過去の意思決定を追跡・参照でき、判断の一貫性を維持できる

**受け入れ基準**:
- [ ] `prompts/package/templates/` に意思決定記録テンプレート（`decision_record_template.md`）が追加される
- [ ] テンプレートには「選択肢一覧」「選択した選択肢」「選択理由」「却下理由」の4項目が必須フィールドとして含まれる
- [ ] Inception Phaseプロンプト（`prompts/package/prompts/inception.md`）に、Intent承認・ユーザーストーリー承認・Unit定義承認の各ゲートで意思決定記録を `docs/cycles/{{CYCLE}}/inception/decisions.md` に追記するフローが追加される
- [ ] 意思決定が1つもない場合（単一選択肢のみ）、記録フローはスキップされる
- [ ] 記録された意思決定は `docs/cycles/{{CYCLE}}/inception/decisions.md` にファイルとして永続化され、後続サイクルのInception Phase開始時にステップ19（既存成果物確認）で読み取り可能
- [ ] 意思決定記録の必須フィールド（選択肢一覧、選択した選択肢、選択理由、却下理由）のいずれかが欠落している場合、記録時に警告メッセージが表示される

**技術的考慮事項**:
- 記録対象は「AIが複数選択肢を提示してユーザーが選択した場面」に限定
- 自動記録と手動記録のバランス（過度な記録は作業効率を下げる）

---

### ストーリー 3: reviewing-inception AIDLC固有観点の追加（#299）
**優先順位**: Should-have
**依存**: ストーリー 2（意思決定記録の構造・保存先が確定していること）

As a AI-DLCでInception Phaseの成果物をレビューする開発者
I want to AIDLC固有のレビュー観点（Intent-Unit整合性、意思決定記録の充足性）でレビューしたい
So that Inception Phase成果物の欠落や不整合を早期に発見し、Construction Phaseへの持ち越し問題を防止できる

**受け入れ基準**:
- [ ] reviewing-inceptionスキルのSKILL.mdに、AIDLC固有のレビュー観点として「Intent-Unit整合性チェック」（IntentのスコープとUnit定義の対応関係が正しいか）が追加される
- [ ] reviewing-inceptionスキルのSKILL.mdに、「意思決定記録の充足性チェック」（`decisions.md` に記録があり、必須4項目が埋まっているか）が追加される
- [ ] セルフレビューモードの指示テンプレートにも新規観点が反映される
- [ ] 既存のreviewing-inceptionの3つのレビュー観点（Intent品質、ユーザーストーリー品質、Unit定義品質）は維持され、破壊的変更がない

**技術的考慮事項**:
- reviewing-inceptionの既存デュアルモード構造（外部CLI + セルフレビュー）を維持
- 新規観点追加時は、セルフレビューモードの指示テンプレートも同時に更新が必要

---

### ストーリー 4: フェーズ別レビュー観点定義ドキュメント（#299）
**優先順位**: Could-have

As a AI-DLCスターターキットの保守担当者
I want to Construction/Operations Phase向けのAIDLC固有レビュー観点を定義ドキュメントとして整備したい
So that 後続サイクルでフェーズ別レビュースキルを実装する際の設計基盤として活用できる

**受け入れ基準**:
- [ ] `prompts/package/guides/phase-review-perspectives.md` が作成され、Inception/Construction/Operations各フェーズのAIDLC固有レビュー観点が定義される
- [ ] 各フェーズの観点は「チェック対象」「チェック項目」「重要度」の3列テーブル形式で記載される
- [ ] Inception Phase の観点はストーリー3で追加された観点と整合する

**技術的考慮事項**:
- 本ストーリーはドキュメント作成のみ。スキル実装は後続サイクル

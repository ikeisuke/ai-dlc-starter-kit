# ユーザーストーリー

## Epic 1: エクスプレスモード

### ストーリー 1a: エクスプレスモード判定とフォールバック（#359）
**優先順位**: Must-have
**適用モード**: minimal のみ（standard/comprehensive は影響なし）

As a AI-DLC利用者
I want to `depth_level=minimal` 時にエクスプレスモードの適用可否が自動判定されるようにしたい
So that 適切な場合のみ高速パスが適用され、不適切な場合は通常フローに安全にフォールバックできる

**受け入れ基準**:
- [ ] `rules.depth_level.level = "minimal"` 設定時にエクスプレスモード判定が実行される
- [ ] Unit定義が1つ以下の場合、エクスプレスモードが有効になる
- [ ] Unit定義が2つ以上の場合、「エクスプレスモード適用不可: Unit数が2以上のため通常フローに切り替えます」とメッセージが表示され、通常フローに遷移する
- [ ] `depth_level` が `standard` または `comprehensive` の場合、エクスプレスモード判定自体がスキップされ、既存フローが変更なしで動作する
- [ ] `depth_level` 設定値が不正な場合、既存のバリデーション仕様（rules.md）に従い `standard` にフォールバックされる

**技術的考慮事項**:
- rules.mdのDepth Levelテーブルにエクスプレスモードの適用条件セクションを追加
- inception.mdのDepth Level読み込み後に判定分岐を挿入

---

### ストーリー 1b: Inception+Construction統合フロー（#359）
**優先順位**: Must-have
**適用モード**: minimal（エクスプレスモード有効時のみ）

As a AI-DLC利用者
I want to エクスプレスモード有効時にInceptionとConstructionが1つのフローで完結するようにしたい
So that コンテキストリセットなしで、Intent作成から実装完了まで連続して進められる

**受け入れ基準**:
- [ ] エクスプレスモード時、Inception完了後にコンテキストリセット提示をスキップし、Construction Phaseの実装ステップに自動遷移する
- [ ] Intentは1-2文の簡潔な記述（minimalの既存仕様通り）
- [ ] ユーザーストーリーの受け入れ基準は主要ケースのみ（minimalの既存仕様通り）
- [ ] PRFAQ作成はスキップ（minimalの既存仕様通り）
- [ ] 設計フェーズ（ドメインモデル・論理設計）はスキップ（minimalの既存仕様通り）
- [ ] Construction Phase完了時にコミットが作成される（commit-flow.mdの完了コミット手順に従う）
- [ ] コミット作成失敗時、エラーメッセージが表示され、ユーザーに手動コミットが案内される

**技術的考慮事項**:
- inception.mdにエクスプレスモード用のフロー分岐を追加
- construction.mdにエクスプレスモード用の簡略フローを追加
- semi_autoモードとの整合性を維持

---

## Epic 2: Inception Phase初期セットアップ改善

### ストーリー 2: rules.md確認タイミング前倒し（#357）
**優先順位**: Should-have
**適用モード**: 全モード共通（minimal/standard/comprehensive）

As a AI-DLC利用者
I want to Inception Phase初期セットアップ（Part 1）でプロジェクト固有ルール（rules.md）が読み込まれるようにしたい
So that セットアップ段階からルールを意識した判断が可能になり、設定ミスを早期に検出できる

**受け入れ基準**:
- [ ] `docs/cycles/rules.md` の読み込みがPart 1の依存コマンド確認（env-info.sh実行）直後に実行される
- [ ] Part 2の「追加ルール確認」ステップが削除され、後続ステップの番号が調整される
- [ ] rules.mdが存在しない場合、警告なくスキップして次の処理に進む
- [ ] construction.mdの追加ルール確認タイミング（序盤で実行）は変更なし

**技術的考慮事項**:
- inception.md Part 1のステップ番号の振り直しが必要
- Part 2のステップ削除と後続ステップの番号調整

---

### ストーリー 3: バージョン確認デフォルト無効化（#354）
**優先順位**: Should-have
**適用モード**: 全モード共通（minimal/standard/comprehensive）

As a AI-DLC利用者
I want to Inception Phase開始時のバージョン確認がデフォルトでスキップされるようにしたい
So that 毎回の煩わしいバージョンチェックを回避でき、必要時のみ有効化できる

**受け入れ基準**:
- [ ] rules.mdの「アップグレードチェック設定」セクション内のデフォルト値が `"false"` に変更される
- [ ] inception.mdの「スターターキットバージョン確認」ステップ内のread-config.shコードブロックのデフォルト値が `"false"` に変更される
- [ ] `docs/aidlc.toml` で `rules.upgrade_check.enabled = true` を設定した場合、従来通りバージョン確認が実行される
- [ ] 非boolean値が設定された場合、警告が表示され `"false"` にフォールバックする（フォールバック先の変更）
- [ ] 設定読み取り失敗時（終了コード2）、警告が表示され `"false"` にフォールバックする

**技術的考慮事項**:
- rules.mdが定義源（Single Source of Truth）のため、まずrules.mdを修正
- inception.mdのコードブロックも同期して修正
- バリデーション仕様の「フォールバック先」を `"true"` → `"false"` に変更

---

### ストーリー 4: aidlc-setup同期タイミング最適化（#352）
**優先順位**: Should-have
**適用モード**: メタ開発時のみ（スターターキット以外のプロジェクトには影響なし）

As a スターターキット開発者（メタ開発者）
I want to aidlc-setup同期をOperations Phaseの「リリース準備」ステップ内でCHANGELOG更新・バージョン更新の完了後、PRステータス変更（Ready for Review）の直前に実行するようにしたい
So that 同期後の追加変更による整合性問題を防止し、同期漏れリスクを低減できる。これにより一般利用者にも正確に同期された最新プロンプトが配布される

**受け入れ基準**:
- [ ] `docs/cycles/rules.md` のカスタムワークフローセクションが更新される
- [ ] aidlc-setup実行タイミングが「CHANGELOG更新・バージョン更新完了後、PRステータス変更直前」と明記される
- [ ] aidlc-setup実行後にコミットが作成される手順が記載される
- [ ] スターターキット以外のプロジェクトには影響しない（docs/cycles/rules.mdはプロジェクト固有ファイル）
- [ ] aidlc-setup実行失敗時、エラーメッセージが表示され、ユーザーに手動対応が案内される

**技術的考慮事項**:
- docs/cycles/rules.mdのみの変更（rsync対象外）
- 具体的なステップ位置はOperations Phaseプロンプトのリリース準備フロー内で特定

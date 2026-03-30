# ユーザーストーリー

## Epic: Operations Phaseリリース品質保証の強化

### ストーリー 1: ローカルレビュー手順の標準化
**優先順位**: Must-have
**関連Issue**: #372

As a AI-DLC利用開発者
I want to Operations Phaseにローカルレビュー手順が標準ステップとして組み込まれている
So that 外部レビューツール（Codex GitHub連携等）がrate limit等で利用できない場合でも品質チェックが確実に実行される

**受け入れ基準**:
- [ ] operations-release.mdのPRマージ前レビューセクションにローカルレビュー手順が追加されている
- [ ] `codex review --base main` によるローカルCodexレビューの手順が記載されている
- [ ] reviewingスキル（reviewing-code等）によるローカルレビューの手順が記載されている
- [ ] レビュー指摘への対応フロー（修正→再レビュー）が記載されている
- [ ] 外部PRレビューが利用不可の場合のフォールバックとして明確に位置づけられている
- [ ] ローカルレビューコマンド実行失敗時のエラーハンドリング（エラー表示→手動レビューへの誘導）が記載されている
- [ ] レビュー指摘が0件の場合は「指摘なし」と表示してマージに進む旨が記載されている

**技術的考慮事項**:
operations-release.mdの既存のPRマージ前レビュー構造を拡張する形で追加。rules.mdの「ローカルレビュー必須ルール」との整合性を維持。ステップ番号は#374（Bash Substitution Check移動）による繰り上げ後を使用。

---

### ストーリー 2: パーミッション管理ステップの追加
**優先順位**: Must-have
**関連Issue**: #375, #373

As a AI-DLCスターターキット開発者
I want to リリース前にパーミッション設定のセッション分析と監査がカスタムワークフローとして定義されている
So that 新たな自動承認パターンの検討と危険な設定の検出をリリースごとに実施できる

**受け入れ基準**:
- [ ] rules.mdのカスタムワークフローセクションに「パーミッション管理」ステップが追加されている
- [ ] PR Ready化前に以下の2ステップを順に実行する手順が記載されている:
  1. `/tools:suggest-permissions` でセッション履歴を分析し改善候補を抽出
  2. `/tools:suggest-permissions --review all` で既存設定を監査
- [ ] suggest-permissions: 新規ルール提案がある場合の設定反映手順が記載されている
- [ ] suggest-permissions: 新規ルール提案がない場合は「変更なし」と表示して次へ進む旨が記載されている
- [ ] --review all: HIGH/CRITICAL指摘がある場合の対応フロー（ask/denyガード追加等）が記載されている
- [ ] --review all: 指摘なしの場合は「監査合格」と表示して次へ進む旨が記載されている
- [ ] コマンド実行失敗時は警告を表示し、手動確認を案内して続行する旨が記載されている
- [ ] 設定変更がある場合はコミットに含める旨が記載されている

**技術的考慮事項**:
rules.mdのカスタムワークフローとして追加。ステップ番号は#374（Bash Substitution Check移動）による繰り上げ後を使用。

---

## Epic: リポジトリ固有処理の適切な配置

### ストーリー 3: Bash Substitution Checkのプロジェクト固有ルールへの移動
**優先順位**: Must-have
**関連Issue**: #374

As a AI-DLC利用開発者（他プロジェクト）
I want to operations-release.mdにリポジトリ固有のスクリプト依存がない
So that 他プロジェクトでOperations Phaseを実行する際にcheck-bash-substitution.shの不在でエラーにならない

**受け入れ基準**:
- [ ] operations-release.mdから7.6 Bash Substitution Checkが削除されている
- [ ] 削除後の後続ステップ番号が正しく繰り上げられている（7.7→7.6, 7.8→7.7, ..., 7.14→7.13）
- [ ] rules.mdのカスタムワークフローにBash Substitution Checkが追加されている
- [ ] rules.md内の既存カスタムワークフロー（バージョンファイル更新、aidlc-setup同期）のステップ番号参照が更新されている
- [ ] operations-release.mdのステップ番号を参照する他ドキュメント（rules.md等）が更新されている

**技術的考慮事項**:
ステップ番号繰り上げの影響範囲が広い。rules.mdの「7.8後、7.9前」→「7.7後、7.8前」等の参照更新が必要。他ストーリー（#1, #2）のステップ番号参照はこのストーリー完了後の番号体系を使用する。

---

## Epic: ツール基盤のリファクタリング

### ストーリー 4: defaults.tomlへのデフォルト値集約
**優先順位**: Must-have
**関連Issue**: #376

As a AI-DLCフレームワーク保守者
I want to 全デフォルト値がdefaults.tomlに一元管理されている
So that デフォルト値の定義箇所が統一され、新規設定追加時にdefaults.tomlだけを更新すればよい

**受け入れ基準**:
- [ ] defaults.tomlに未登録の5キー（rules.depth_level.level, rules.automation.mode, rules.construction.max_retry, rules.preflight.enabled, rules.preflight.checks）が追加されている
- [ ] 追加後、read-config.shで各キーを--defaultなしで取得してもdefaults.tomlの値が返される

**技術的考慮事項**:
read-config.shの4層マージ（defaults.toml→user→project→local）により、defaults.tomlに値を追加すればキー不在時のフォールバックとして機能する。

---

### ストーリー 5: read-config.sh --default廃止
**優先順位**: Must-have
**関連Issue**: #376

As a AI-DLCフレームワーク保守者
I want to read-config.shから--defaultオプションが廃止され、全プロンプトから使用箇所が除去されている
So that デフォルト値の二重管理が解消され、プロンプトの可読性が向上する

**受け入れ基準**:
- [ ] read-config.shから--defaultオプションの実装（HAS_DEFAULT, DEFAULT_VALUE変数、関連分岐）が削除されている
- [ ] 全プロンプト・ドキュメント（inception.md, rules.md, commit-flow.md, feedback.md, compaction.md, aidlc-setup SKILL.md等）から--default使用箇所が除去されている
- [ ] --default削除後も終了コード（0=値あり, 1=キー不在, 2=エラー）の動作が維持されている
- [ ] `grep -r "\-\-default" prompts/package/` の結果が0件である

**技術的考慮事項**:
ストーリー4（defaults.toml集約）の完了が前提。影響範囲は20箇所以上。ロールバックはgit revertで可能。

---

### ストーリー 6: プリフライト設定取得のバッチモード化
**優先順位**: Must-have
**関連Issue**: #376

As a AI-DLCフレームワーク保守者
I want to preflight.mdの設定取得が--keysバッチモード1回に集約されている
So that プリフライトチェックの実行効率とプロンプトの可読性が向上する

**受け入れ基準**:
- [ ] preflight.mdの11回の個別read-config.sh呼び出しが--keysバッチモード1回に集約されている
- [ ] バッチモードの出力（key:value形式）をパースしてコンテキスト変数に格納する手順が記載されている
- [ ] バッチモード実行失敗時（exit code 2）のエラーハンドリングが記載されている
- [ ] 結果提示フォーマット（主要設定値セクション）に変更がない

**技術的考慮事項**:
ストーリー5（--default廃止）の完了が前提。バッチモード（--keys）は既にread-config.shに実装済みのため、preflight.mdの記述変更が主な作業。

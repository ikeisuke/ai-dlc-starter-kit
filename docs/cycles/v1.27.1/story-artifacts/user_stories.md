# ユーザーストーリー

## Epic: 開発支援ツール基盤の堅牢性向上

### ストーリー 1: post-merge-cleanup.sh マルチリモート対応（#390 + #389）
**優先順位**: Must-have

As a マルチリモート環境で開発するAI-DLCユーザー
I want to post-merge-cleanup.shがローカルブランチ削除済みでも正しいリモートを特定してほしい
So that 誤ったリモートのブランチを削除してしまうリスクを回避できる

**受け入れ基準**:
- [ ] ローカルブランチが存在しない場合、`git ls-remote` 等で各リモートを走査し、該当ブランチを持つリモートを特定する
- [ ] 該当ブランチが単一リモートに存在する場合、そのリモートが自動選択される
- [ ] 該当ブランチが複数リモートに存在する場合、originを優先する（従来互換）
- [ ] 該当ブランチがどのリモートにも存在しない場合、リモート削除ステップをスキップし警告を出力する
- [ ] シングルリモート環境（origin のみ）での既存動作に変更がない
- [ ] `--dry-run` モードで新しいリモート解決ロジックの結果が確認できる

**技術的考慮事項**:
- `resolve_remote()` 関数内でブランチ名が空の場合のフォールバックロジックを改善
- `git ls-remote` はネットワークアクセスを伴うため、既にfetch済みの `refs/remotes/` を先に確認するアプローチも検討

---

### ストーリー 2: setup_kiro_agent 実ファイルマージ対応（#388）
**優先順位**: Must-have

As a Kiro CLIを使用しaidlc.jsonをカスタマイズしているAI-DLCユーザー
I want to setup_kiro_agentがカスタマイズ済みファイルにテンプレートの新規コマンドを差分マージしてほしい
So that スターターキットの更新時に手動でallowedCommandsを追加する手間がなくなる

**受け入れ基準**:
- [ ] `.kiro/agents/aidlc.json` が実ファイル（非symlink）の場合、テンプレートとのallowedCommands差分マージが実行される
- [ ] 既存のユーザーカスタマイズ（追加コマンド等）が保持される
- [ ] テンプレートにのみ存在する新規コマンドが追加される
- [ ] ワイルドカードパターンに包含される具体的パターンは重複追加しない
- [ ] jq利用可能時はjqで実行、不可時はPython3でフォールバックする
- [ ] マージ結果（追加件数）がコンソールに出力される
- [ ] symlink状態のファイルは従来通りの動作（マージなし）

**技術的考慮事項**:
- setup_claude_permissions()の`_merge_permissions_jq()`/`_merge_permissions_python()`を参考に実装
- Kiro側はallowedCommandsのみが対象（Claude側のpermissions.allow/askとは構造が異なる）

---

### ストーリー 3: defaults.toml フルパス明記（ドキュメント改善）
**優先順位**: Should-have

As a AI-DLCスターターキットを使用するプロジェクトのAIエージェント
I want to プロンプト・ガイド文書でdefaults.tomlのフルパスが明記されていてほしい
So that ユーザーに正確なパスを案内でき、`docs/aidlc/defaults.toml` のような誤案内を防止できる

**受け入れ基準**:
- [ ] `config-merge.md` の設定ファイル階層テーブルで `defaults.toml` のパスが `docs/aidlc/config/defaults.toml`（デプロイ先）として明記されている
- [ ] `rules.md` の設定読み込みセクションでdefaults.tomlの配置パスに言及がある
- [ ] 正本（`prompts/package/`）と同期先（`docs/aidlc/`）の両方でdefaults.tomlのフルパス表記が一致している

**技術的考慮事項**:
- read-config.shは相対パス解決（`${SCRIPT_DIR}/../config/defaults.toml`）のため、スクリプト動作には影響なし
- ドキュメント上の記載改善のみ
- 正本（`prompts/package/`）を編集し、`docs/aidlc/` にはrsync同期で反映する

---

### ストーリー 4: defaults.toml 不在時の耐障害性強化
**優先順位**: Must-have

As a 古いバージョンからアップグレードしたAI-DLCユーザー
I want to defaults.tomlが存在しない場合でもread-config.shが適切に動作してほしい
So that アップグレード手順の不備やファイル欠落時にも設定値取得が失敗しない

**受け入れ基準**:
- [ ] defaults.toml不在時にread-config.shが終了コード0を返し、defaults.tomlなしでも設定値取得が正常動作する
- [ ] defaults.toml不在時にread-config.shが標準エラーに「aidlc-setupを実行してください」を含む診断メッセージを出力する
- [ ] プリフライトチェックのconfig-validationがdefaults.toml不在をwarningとして報告する
**技術的考慮事項**:
- v1.26.3以前のバージョンでセットアップしたプロジェクトがaidlc-setupを実行していない場合に発生
- read-config.shは既に `[ -f "$DEFAULTS_CONFIG_FILE" ]` チェックがある可能性があるため、既存動作を確認してから対応方針を決定
- aidlc-setupのSYNC_DIRSに `config` が含まれており、実行すればdefaults.tomlは正常に同期される（既存動作で対応済み、本Unitのスコープ外）

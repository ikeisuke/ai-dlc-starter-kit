# ユーザーストーリー

## Epic: コンテキスト圧縮・最適化

### ストーリー 1: review-flow追加圧縮（#519 S10残り）

**優先順位**: Should-have

As a AI-DLC利用者
I want to review-flow-reference.mdの冗長な記述が圧縮されている
So that review-flow関連ファイルのUTF-8バイト数が削減され、セッション中のコンテキスト消費が減る

**受け入れ基準**:
- [ ] review-flow.md + review-flow-reference.md の合計UTF-8バイト数が現行比20%以上削減される
- [ ] ツール別制約（Codex/Claude/Gemini）の重複記述が統合される
- [ ] 圧縮後のファイルに、review-flow.mdの全必須セクション（処理パス分岐、指摘対応判断フロー、レビューサマリ、外部入力検証）が保持されている
- [ ] 品質劣化リスクマトリクス記載セクション（指摘対応判断フロー全体、却下禁止ルール）のテキストが変更されていない

**技術的考慮事項**:
- 測定方法: `wc -c` でUTF-8バイト数を比較

---

### ストーリー 2: AGENTS.md活用・ルール移行（#533 + #541）

**優先順位**: Must-have

As a AI-DLC利用者
I want to フェーズステップ読み込み前に必要なルールがプラグインAGENTS.mdから自動注入される
So that rules-core.mdの初期ロードバイト数が削減される

**移行対象セクション（確定）**:
- 承認プロセス（rules-core.md 78-83行）
- 質問と実行の判断基準（rules-core.md 30-67行）
- AskUserQuestion使用ルール（rules-core.md 85-110行）

**受け入れ基準**:
- [ ] 上記3セクションがプラグインルートAGENTS.mdに配置される
- [ ] rules-core.mdから移行済みセクションが削除され、UTF-8バイト数が削減される
- [ ] メタ開発リポジトリでフェーズ開始時に移行済みルールが参照可能で、既存フローが正常完了する
- [ ] プラグインとしてインストールされた外部プロジェクトで、rules-core.mdの明示Readなしにフェーズ開始が可能である（AGENTS.md自動注入による）

**技術的考慮事項**:
- AGENTS.mdは全スキル呼び出し時に自動注入されるため、配置するルールは真に全スキル共通で必要なもののみ
- rules-core.md内でステップ読み込み後に参照すれば十分なルール（バックログ管理、スコープ保護等）は移行しない

---

## Epic: バグ修正・微調整

### ストーリー 3: バージョンチェック一貫性修正（#539）

**優先順位**: Must-have

As a AI-DLC利用者
I want to STARTER_KIT_DEVリポジトリでもバージョン不一致時に他プロジェクトと同一の警告が表示される
So that 全プロジェクトで一貫した体験が得られ、バージョン不一致を見逃さない

**受け入れ基準**:
- [ ] バージョン不一致時にSTARTER_KIT_DEV判定による「開発中は想定内の差異」注記が出力されない
- [ ] STARTER_KIT_DEVでもUSER_PROJECTと同一のバージョン不一致警告フロー（警告表示→ユーザーに継続確認）が実行される
- [ ] guides/version-check.md内のSTARTER_KIT_DEV分岐が削除される

---

### ストーリー 4: Construction Phaseバックログステップ削除（#542）

**優先順位**: Should-have

As a AI-DLC利用者
I want to Construction Phase開始時の不要なバックログ確認ステップが省略される
So that Unit開始までの手順数が削減され、必要な受け入れ基準確認はステップ12（計画作成）で維持される

**受け入れ基準**:
- [ ] Construction Phase 01-setup.mdからステップ8（バックログ確認）が削除される
- [ ] 後続ステップの番号が整合する
- [ ] ステップ12（計画作成）に関連Issueの受け入れ基準確認が含まれている（既存で確認済み、追加不要）
- [ ] task-management.mdのConstructionタスクテンプレートが更新される（該当する場合）

---

### ストーリー 5: PRマージ方法設定化（#538）

**優先順位**: Should-have

As a AI-DLC利用者
I want to PRマージ方法をconfig.tomlで事前設定できる
So that Operations Phase毎回のマージ方法確認が省略される

**受け入れ基準**:
- [ ] config.tomlに `rules.git.merge_method` キーが追加される（"merge" | "squash" | "rebase" | "ask"）
- [ ] defaults.tomlのデフォルト値が "ask"（従来動作維持）
- [ ] "ask"以外の設定時、AskUserQuestion確認なしで指定方法でマージが実行される
- [ ] 無効値の場合は "ask" にフォールバックし、警告メッセージを表示する
- [ ] 指定方式でのマージが失敗した場合（リポジトリ設定で禁止等）、エラーメッセージを表示しユーザーにマージ方法の選択を求める

**技術的考慮事項**:
- Operations Phase operations-release.mdのPRマージ箇所を修正
- preflight.mdの設定値取得にmerge_methodを追加

---

### ストーリー 6: UTF-8文字化け自動検知（#537）

**優先順位**: Could-have

As a AI-DLC利用者
I want to Writeツールで書き込んだファイルにUTF-8文字化け（U+FFFD）が含まれる場合に警告される
So that 文字化けに早期に気付き、手動修正できる

**受け入れ基準**:
- [ ] PostToolUse hookでWriteツール実行後に対象ファイルのU+FFFD（置換文字）をチェックする
- [ ] U+FFFD検出時に警告メッセージを表示する
- [ ] 書き込み自体は阻害しない（警告のみ、hookの終了コードは0）
- [ ] 正常なテキストファイルでは誤検知しない
- [ ] バイナリファイル（画像等）はチェック対象外とする
- [ ] Writeツールが失敗した場合（ファイルが存在しない等）はhookをスキップする

**技術的考慮事項**:
- `LC_ALL=C grep -c '�'` でU+FFFDを検出可能
- .claude/settings.json のhooks設定に追加
- 対象はWriteツールで書き込まれたファイルパスのみ（hookのコンテキストから取得）

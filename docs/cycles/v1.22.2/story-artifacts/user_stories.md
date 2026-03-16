# ユーザーストーリー

## Epic: セットアップ・デプロイの信頼性向上

### ストーリー 1: aidlc-setup.shスクリプト不在エラーの修正
**優先順位**: Must-have
**関連Issue**: #338

As a AI-DLCを導入したプロジェクトの開発者
I want to aidlc-setupスキルでアップグレードを正常に実行したい
So that バージョンアップ時にエラーで中断されない

**受け入れ基準**:
- [ ] aidlc-setup.sh --dry-run 実行時に check-setup-type.sh 不在エラーが発生しない
- [ ] aidlc-setup.sh --dry-run 実行時に sync-package.sh 不在エラーが発生しない
- [ ] メタ開発環境（スターターキット内）と外部プロジェクト環境の両方で動作する
- [ ] スクリプト不在時に具体的なエラーメッセージ（パスと対処法）が表示される

**技術的考慮事項**:
- check-setup-type.sh は prompts/setup/bin/ に配置されており、package/ 配下ではない
- パス解決ロジックの修正が必要

---

### ストーリー 2: lib/ディレクトリのユーザープロジェクトへのデプロイ
**優先順位**: Must-have
**関連Issue**: #339

As a AI-DLCを導入したプロジェクトの開発者
I want to read-config.sh等のスクリプトがlib/validate.shを正常に読み込めるようにしたい
So that 設定読み込みやバリデーションが正常に動作する

**受け入れ基準**:
- [ ] aidlc-setup実行後、docs/aidlc/lib/validate.sh がユーザープロジェクトに存在する
- [ ] read-config.sh がlib/validate.shをsourceしてエラーなく動作する
- [ ] 既存のSYNC_DIRS配列にlibが含まれていることを確認し、同期が実際に実行されることを検証

**技術的考慮事項**:
- SYNC_DIRS配列にlibは含まれている → 問題はsync-package.sh自体が見つからないこと（#338と連動）
- #338の修正が前提条件（sync-package.shが実行されなければlibも同期されない）

---

## Epic: 開発体験の改善

### ストーリー 3: アップグレード用ブランチ名の改善
**優先順位**: Should-have
**関連Issue**: #337

As a AI-DLCを利用する開発者
I want to アップグレード用ブランチとサイクル用ブランチを明確に区別したい
So that ブランチの目的が一目で分かり、混同によるミスを防げる

**受け入れ基準**:
- [ ] setup-prompt.mdでアップグレード用ブランチが `upgrade/vX.X.X` プレフィックスで案内される
- [ ] aidlc-setupスキルのSKILL.mdでも同様の命名が案内される
- [ ] post-merge-sync.sh が upgrade/ プレフィックスのブランチを削除対象として正しく処理できる

**技術的考慮事項**:
- post-merge-sync.sh の cycle/ プレフィックスチェックとの整合性確認

---

### ストーリー 4: セットアップ時のデフォルト許可パターン追加
**優先順位**: Should-have
**関連Issue**: #335

As a AI-DLCを新規導入する開発者
I want to セットアップ時にAI-DLCスクリプトの実行許可が自動設定されるようにしたい
So that 頻繁な承認プロンプトに煩わされずに作業できる

**受け入れ基準**:
- [ ] セットアップ完了後、docs/aidlc/bin/ 配下のスクリプト実行が自動承認される許可パターンが設定される
- [ ] 既存の .claude/settings.json がある場合、上書きではなくマージされる
- [ ] 許可対象は `Bash(docs/aidlc/bin/*.sh *)` パターンに限定される

**技術的考慮事項**:
- .claude/settings.json の allowedTools 形式を確認
- 既存設定との競合回避が必要

---

### ストーリー 5: AI-DLCフェーズ手順の明文化
**優先順位**: Should-have
**関連Issue**: #314

As a AI-DLCを利用する開発者
I want to CLAUDE.mdだけでフェーズ開始手順を確認したい
So that AGENTS.mdを辿らなくても基本操作が分かる

**受け入れ基準**:
- [ ] CLAUDE.md（prompts/package/prompts/CLAUDE.md）にフェーズ簡略指示表が追記されている
- [ ] 「インセプション進めて」「コンストラクション進めて」「オペレーション進めて」の簡略指示が記載されている
- [ ] AGENTS.mdとの重複は最小限に保ち、詳細はAGENTS.mdへの参照で補う

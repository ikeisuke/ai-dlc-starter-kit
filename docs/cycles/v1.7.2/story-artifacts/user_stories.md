# ユーザーストーリー

## Epic 1: セットアップフロー最適化

### ストーリー 1-1: 不要な確認の省略
**優先順位**: Should-have
**関連Issue**: #35

As a AI-DLC開発者
I want to セットアップ中の不要な確認ダイアログがスキップされる
So that セットアップがスムーズに進行する

**受け入れ基準**:
- [ ] サイクルディレクトリ作成時に確認が不要になる
- [ ] セットアップ時のコミットが確認なしで実行される
- [ ] プロンプトに「確認なしで実行」が明示されている

---

### ストーリー 1-2: 依存コマンドの事前確認
**優先順位**: Should-have
**関連Issue**: #36

As a AI-DLC開発者
I want to セットアップ冒頭で依存コマンドの存在が確認される
So that 必要なツールがない場合に早期に対処できる

**受け入れ基準**:
- [ ] セットアップ冒頭で `gh` (GitHub CLI) の存在確認が行われる
- [ ] セットアップ冒頭で `dasel` の存在確認が行われる（オプション）
- [ ] 存在しない場合の代替手段が明示される

---

### ストーリー 1-3: ステップ番号の整理
**優先順位**: Could-have
**関連Issue**: #36

As a AI-DLC開発者
I want to プロンプトのステップ番号が連番で整理されている
So that ステップの順序が明確になる

**受け入れ基準**:
- [ ] inception.md のステップ番号が連番（0.5, 2.5, 2.7 → 整数）に変更
- [ ] ステップの内容は維持されている

---

## Epic 2: jjサポート強化

### ストーリー 2-1: setup-prompt.mdへの[rules.jj]追加
**優先順位**: Should-have
**関連Issue**: #40

As a jjを使用したいAI-DLC開発者
I want to 新規セットアップ時にaidlc.tomlに[rules.jj]セクションが含まれる
So that jjサポートを有効化できる

**受け入れ基準**:
- [ ] setup-prompt.md内のaidlc.tomlテンプレートに[rules.jj]セクションがある
- [ ] デフォルト値は `enabled = false`

---

### ストーリー 2-2: 許可リストへのjjコマンド追加
**優先順位**: Should-have
**関連Issue**: #42

As a jjを使用するAI-DLC開発者
I want to jjコマンドが許可リストに含まれている
So that jjコマンドも承認なしで実行できる

**受け入れ基準**:
- [ ] ai-agent-allowlist.md にjj読み取り系コマンドが追加されている
- [ ] ai-agent-allowlist.md にjj作成系コマンドが追加されている
- [ ] ai-agent-allowlist.md にjj操作系コマンドが追加されている
- [ ] Claude Code設定例にjjコマンドが追加されている

---

### ストーリー 2-3: jj-support.mdへの説明追加
**優先順位**: Should-have
**関連Issue**: #43

As a jj初心者のAI-DLC開発者
I want to gitとjjの考え方の違いが説明されている
So that jjのワークフローを理解しやすくなる

**受け入れ基準**:
- [ ] jj-support.md に「gitとjjの考え方の違い」セクションがある
- [ ] コミットタイミングの違いが説明されている
- [ ] 変更追跡の違いが説明されている
- [ ] フローの比較が図示されている

---

## Epic 3: バックログ管理改善

### ストーリー 3-1: バックログ移行処理のモード対応
**優先順位**: Should-have
**関連Issue**: #38

As a AI-DLC開発者
I want to バックログ移行時にmodeに応じた適切な移行先が提案される
So that 設定に合った方法でバックログを管理できる

**受け入れ基準**:
- [ ] mode=git の場合、`docs/cycles/backlog/` への移行が提案される
- [ ] mode=issue の場合、GitHub Issues への移行が提案される
- [ ] 旧形式（backlog.md）からの移行が正しく動作する

---

### ストーリー 3-2: AGENTS.mdへのバックログ管理方針追加
**優先順位**: Could-have
**関連Issue**: #41

As a AI-DLC開発者
I want to AGENTS.mdにバックログ管理方針が記載されている
So that バックログの保存先が明確になる

**受け入れ基準**:
- [ ] AGENTS.md にbacklog.modeの説明がある
- [ ] 保存先の対応表がある（git/issue）
- [ ] バックログ追加手順が記載されている

---

### ストーリー 3-3: backlog.single_sourceオプション追加
**優先順位**: Could-have
**関連Issue**: ローカルバックログ

As a AI-DLC開発者
I want to バックログ確認時に片方のみ確認するオプションがある
So that 必要な確認範囲を制御できる

**受け入れ基準**:
- [ ] aidlc.toml に `backlog.single_source` オプションが定義されている
- [ ] 各フェーズプロンプトでこの設定が参照されている
- [ ] デフォルトは `false`（両方確認）

---

## Epic 4: iOSプロジェクト対応強化

### ストーリー 4-1: Operations Phaseでのビルド番号確認
**優先順位**: Should-have
**関連Issue**: (新規)

As a iOSアプリを開発するAI-DLC開発者
I want to Operations PhaseでCURRENT_PROJECT_VERSION（ビルド番号）のインクリメント確認が行われる
So that App Storeへの提出時にビルド番号重複エラーを防げる

**受け入れ基準**:
- [ ] Operations Phase ステップ1でMARKETING_VERSIONの確認が行われる
- [ ] CURRENT_PROJECT_VERSIONが前バージョンからインクリメントされているか確認される
- [ ] 同じ場合はインクリメントを提案する
- [ ] project.type = "ios" の場合のみ該当する

**技術的考慮事項**:
- `grep -E "MARKETING_VERSION|CURRENT_PROJECT_VERSION" *.xcodeproj/project.pbxproj`
- `git show main:*.xcodeproj/project.pbxproj` で前バージョンと比較
- App Storeは同一ビルド番号での再提出を許可しない

---

## Epic 5: 将来検討

### ストーリー 5-1: プランモード活用の検討
**優先順位**: Won't-have (このサイクルでは検討のみ)
**関連Issue**: #39

As a AI-DLC開発者
I want to プランモード活用の検討結果がドキュメント化されている
So that 次回以降のサイクルで実装できる

**受け入れ基準**:
- [ ] プランモード活用の検討結果がドキュメント化されている
- [ ] Construction Phaseでの活用案が記載されている
- [ ] 期待される効果が記載されている

**備考**: このサイクルでは検討・方針策定のみ、実装は次回以降

---

## v1.8.0へ延期したストーリー

### 延期: 複合コマンドの廃止
**関連Issue**: #34
**延期理由**: 約26箇所の大規模変更。4ファイル（inception.md, construction.md, operations.md, setup.md）に影響。

### 延期: フェーズ間の情報引き継ぎ
**関連Issue**: #37
**延期理由**: 新機能の設計が必要。セットアップ→インセプション間の引き継ぎファイル形式の設計を要する。

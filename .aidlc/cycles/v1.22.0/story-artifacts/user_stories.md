# ユーザーストーリー

## Epic: AI-DLCフレームワークの堅牢性改善

### ストーリー 1: フェーズ内操作順序の明示化
**優先順位**: Must-have
**関連Issue**: #317

As a AIエージェント
I want to 操作の正しい実行順序がcommit-flow.mdに明文化されている
So that コミット前のPR作成やスカッシュ前のUnit完了マークなどの順序違反を自律的に検知・防止できる

**受け入れ基準**:
- [ ] commit-flow.mdに「操作順序ルール」セクションが追加されている
- [ ] 以下の順序制約が明記されている: コミット→PR作成、スカッシュ→Unit完了マーク、全Unit完了→Operations Phase移行、AIレビュー完了→ユーザーレビュー依頼
- [ ] 順序違反を検知した場合の自己修正フロー（正しい手順の提示）が記載されている
- [ ] 追加した順序ルールが既存の`コミットタイミング`セクションの各ルールと矛盾しないことをAIレビューで確認する

**技術的考慮事項**:
- 対象ファイル: `prompts/package/prompts/common/commit-flow.md`
- `## コミットポリシー` セクション配下に新規セクションを追加

---

### ストーリー 2: Self-Healingテストループの導入
**優先順位**: Must-have
**関連Issue**: #318

As a AIエージェント
I want to テスト失敗時に自動で原因分析・修正・再実行を最大3回試行する
So that テスト失敗のたびにユーザーの介入を求めることなく、自律的に問題を解決できる

**受け入れ基準**:
- [ ] Construction Phase Step 6でビルド/テスト失敗時に自動修正ループが実行される
- [ ] ループは最大3回まで実行される
- [ ] 各ループで: エラー出力の分析→原因特定→修正実施→再実行の手順が明記され、各試行でattempt番号と失敗要因の要約が出力される
- [ ] 成功した場合は即座にループを終了し、次のステップ（AIレビュー）に進む
- [ ] 3回失敗した場合はユーザーに判断を求める（バックログ登録提案を含む）。このストーリーはビルド/テスト実行失敗の自動修正が対象であり、レビューツール実行不可はストーリー3の範囲
- [ ] 既存のバックログ登録フローとの整合性が維持される

**技術的考慮事項**:
- 対象ファイル: `prompts/package/prompts/construction.md` Step 6（L545-587付近）
- 既存の「エラー修正→再実行」ループに最大回数制限を追加する形

---

### ストーリー 3: 外部レビューツール制約のドキュメント化
**優先順位**: Must-have
**関連Issue**: #319

As a AIエージェント
I want to 外部レビューツール（Codex等）の既知制約と対処法がreview-flow.mdに記載されている
So that ツール固有の制約に遭遇した際にフリーズせず、適切なフォールバック手順を実行できる

**受け入れ基準**:
- [ ] review-flow.mdに「外部レビューツールの既知制約」セクションが追加されている
- [ ] Codexの制約が記載されている: read-onlyモード制約、ファイル読み取り制限、`--skip-git-repo-check`オプション
- [ ] 認証失効時のフォールバック手順が記載されている（再ログイン依頼→リトライ→次ツールへフォールバック）
- [ ] インタラクティブモードでのフリーズ対策が記載されている
- [ ] 既存のフォールバック処理フロー（L233-277）との整合性が維持される。既存のエラー分類表（CLI不在、CLI実行エラー、出力解析不能）を参照・補完する形で制約情報を追加する

**技術的考慮事項**:
- 対象ファイル: `prompts/package/prompts/common/review-flow.md`
- 既存の「種別単位のフォールバック処理」セクション付近に追加

---

### ストーリー 4: validate_cycle()のGit ref安全性修正
**優先順位**: Must-have
**関連Issue**: #326

As a 開発者
I want to validate_cycle()がGit refとして無効なサイクル名を拒否する
So that ブランチ作成時にgitエラーが発生せず、安全にサイクルを開始できる

**受け入れ基準**:
- [ ] 末尾ドット（例: `foo.`）が拒否される
- [ ] `.lock`接尾辞（例: `foo.lock`）が拒否される
- [ ] 既存の正当なサイクル名（`v1.22.0`、`feature/v1.0.0`等）は引き続き受け入れられる
- [ ] 拒否時に具体的なエラーメッセージが表示され（どのルールに違反したか）、終了コードが0以外を返す
- [ ] 既存のバリデーション（空文字、パストラバーサル、空白、制御文字、先頭スラッシュ、正規表現）は維持される

**技術的考慮事項**:
- 対象ファイル: `prompts/package/lib/validate.sh` L39-73
- `git check-ref-format --branch "cycle/${cycle}"` によるチェック追加、またはパターンマッチによる拒否

---

### ストーリー 5: アップグレードパスの堅牢性改善
**優先順位**: Must-have

As a 古いバージョンのAI-DLCユーザー
I want to setup-prompt.md経由のアップグレードが`docs/aidlc/bin/`にスクリプトが存在しない環境でもエラーなく完了する
So that アップグレード時にエラーが多発して中断することなく、最新バージョンに移行できる

**受け入れ基準**:
- [ ] setup-prompt.mdの以下のスクリプト参照で、`docs/aidlc/bin/`に存在しない場合にスターターキット側にフォールバックする: `resolve-starter-kit-path.sh`、`sync-package.sh`、`migrate-config.sh`、`setup-ai-tools.sh`
- [ ] `check-setup-type.sh`が既存プロジェクト（`docs/aidlc.toml`が存在）を`initial`ではなく`upgrade`として正しく検出する
- [ ] `setup-ai-tools.sh`のハードコードパス（`docs/aidlc/bin/setup-ai-tools.sh`）が、sync完了前でもエラーにならない
- [ ] `check-version.sh`が`v`プレフィックス付きバージョン（`v1.21.2`等）を正規化して内部比較する（入力`v1.21.2` → 内部`1.21.2`として処理）
- [ ] アップグレード完了後に`docs/aidlc/`配下のファイル同期が正常終了し、`docs/aidlc.toml`のバージョンが更新される

**技術的考慮事項**:
- 対象ファイル: `prompts/setup-prompt.md`、`prompts/setup/bin/check-setup-type.sh`、`prompts/setup/bin/check-version.sh`、`prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh`
- 鶏と卵問題: sync前に`docs/aidlc/bin/`のスクリプトを使えない → スターターキット側のスクリプトを優先使用
- **Unit分割候補**: (1) アップグレード判定修正（check-setup-type.sh/check-version.sh）、(2) スクリプトパスフォールバック（setup-prompt.md/aidlc-setup.sh）

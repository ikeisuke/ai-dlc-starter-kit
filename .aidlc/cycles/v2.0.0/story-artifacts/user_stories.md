# ユーザーストーリー

## Epic 1: スキル化・プラグイン基盤

### ストーリー 1: スキル機能の技術検証
**優先順位**: Must-have

As a AI-DLC開発者
I want to スキルからのオンデマンドRead とスキル間呼び出しの実現可能性を検証する
So that v2.0.0の実装方針を確定できる

**受け入れ基準**:
- [ ] テストスキルからsteps/ファイルをRead指示で読み込める、または@参照フォールバックの必要性が判明する
- [ ] テストスキルAからSkillツールでテストスキルBを呼び出せる、またはフォールバック方式が確定する
- [ ] 検証結果に基づく実装方針がドキュメント化されている

**技術的考慮事項**:
テストスキルをプラグインとしてインストールし、スキルディレクトリからの相対パス解決を確認

---

### ストーリー 2: リポジトリ構造のスキル配置移行
**優先順位**: Must-have

As a AI-DLC開発者
I want to 既存スキルを`skills/`ディレクトリに移動し、marketplace.jsonを更新する
So that プラグイン配布に適したリポジトリ構造になる

**受け入れ基準**:
- [ ] `skills/` ディレクトリに全スキル（aidlc, reviewing-*, squash-unit）が配置されている
- [ ] `marketplace.json` が新しいスキルパスを参照している
- [ ] 既存の `.claude/skills/` シンボリックリンクが不要になっている

---

### ストーリー 3: シェルスクリプトのパス移行
**優先順位**: Must-have

As a AI-DLC利用者
I want to シェルスクリプトが `.aidlc/config.toml` と `.aidlc/cycles/` を参照する
So that プロジェクト側のAI-DLCファイルフットプリントが最小化される

**受け入れ基準**:
- [ ] 全スクリプトが `AIDLC_PROJECT_ROOT`（プロジェクトルート）と `AIDLC_PLUGIN_ROOT`（プラグインルート）を解決できる
- [ ] `read-config.sh` が `.aidlc/config.toml` を読み込める
- [ ] `write-history.sh` が `.aidlc/cycles/` 配下に履歴を書き込める
- [ ] `init-cycle-dir.sh` が `.aidlc/cycles/` 配下にディレクトリを作成する

---

## Epic 2: フェーズスキル実装

### ストーリー 4: 統合オーケストレータースキル
**優先順位**: Must-have

As a AI-DLC利用者
I want to `/aidlc inception` のようなコマンドで各フェーズを開始できる
So that 統一的なインターフェースで全フェーズにアクセスできる

**受け入れ基準**:
- [ ] SKILL.md が引数解析でinception/construction/operations/setup/express/feedbackを正しくルーティングする
- [ ] 共通初期化（プロジェクトルート検出、config.toml確認、preflight、設定読み込み）が全フェーズで動作する
- [ ] `steps/common/` の全共通ステップ（preflight, rules, compaction, commit-flow, review-flow, session-continuity）が読み込み可能

---

### ストーリー 5: Inception Phaseスキル化
**優先順位**: Must-have

As a AI-DLC利用者
I want to Inception Phaseがスキルのステップ群として動作する
So that 1,436行の巨大プロンプトが分割管理され、保守性が向上する

**受け入れ基準**:
- [ ] `steps/inception/01-setup.md` 〜 `06-completion.md` が順次実行される
- [ ] Intent作成、ユーザーストーリー作成、Unit定義がv1と同等に動作する
- [ ] エクスプレスモード判定が正常に動作する

---

### ストーリー 6: Construction Phaseスキル化
**優先順位**: Must-have

As a AI-DLC利用者
I want to Construction Phaseがスキルのステップ群として動作する
So that 設計・実装フローが分割管理される

**受け入れ基準**:
- [ ] `steps/construction/01-setup.md` 〜 `04-completion.md` が順次実行される
- [ ] ドメイン設計、論理設計、実装、テストがv1と同等に動作する
- [ ] Self-Healingループが正常に動作する

---

### ストーリー 7: Operations Phaseスキル化
**優先順位**: Must-have

As a AI-DLC利用者
I want to Operations Phaseがスキルのステップ群として動作する
So that デプロイ・リリースフローが分割管理される

**受け入れ基準**:
- [ ] `steps/operations/01-setup.md` 〜 `04-completion.md` が順次実行される
- [ ] デプロイ、リリース準備、PR管理がv1と同等に動作する

---

### ストーリー 8: Setup Phaseスキル化
**優先順位**: Must-have

As a AI-DLC利用者
I want to `/aidlc setup` で初期セットアップとv1→v2移行ができる
So that setup-prompt.mdとaidlc-setupスキルが統合される

**受け入れ基準**:
- [ ] `steps/setup/01-detect.md` 〜 `03-migrate.md` が順次実行される
- [ ] 新規プロジェクトで `.aidlc/config.toml` が生成される
- [ ] v1プロジェクト（`docs/aidlc.toml` + `docs/cycles/`）からの移行が可能

---

## Epic 3: 仕上げ・移行

### ストーリー 9: プラグインレベルCLAUDE.md/AGENTS.md
**優先順位**: Must-have

As a AI-DLC利用者
I want to プラグインレベルのCLAUDE.md/AGENTS.mdがフェーズルーティングを提供する
So that 簡略指示（「インセプション進めて」等）が `/aidlc` スキルに正しくマッピングされる

**受け入れ基準**:
- [ ] フェーズ簡略指示が `/aidlc` スキル呼び出しにマッピングされる
- [ ] AskUserQuestion使用ルール、gitコミットルールが記載されている
- [ ] 非AIDLCプロジェクトガード（`.aidlc/config.toml` 未存在時のsetup提案）が動作する

---

### ストーリー 10: 旧構造クリーンアップ
**優先順位**: Must-have

As a AI-DLC開発者
I want to 旧構造（docs/aidlc/, prompts/）を削除し、移行ガイドを提供する
So that リポジトリがv2.0.0のクリーンな構造になる

**受け入れ基準**:
- [ ] `docs/aidlc/prompts/`, `docs/aidlc/bin/`, `docs/aidlc/skills/` 等の旧ディレクトリが削除されている
- [ ] `prompts/package/` の二重構造が解消されている
- [ ] `docs/guides/migration-v1-to-v2.md` が作成されている

---

### ストーリー 11: 統合テスト
**優先順位**: Must-have

As a AI-DLC開発者
I want to 全フェーズの動作確認とプラグインインストール確認を行う
So that v2.0.0のリリース品質が保証される

**受け入れ基準**:
- [ ] 全フェーズ（Inception/Construction/Operations/Setup）がスキルとして正常動作する
- [ ] プラグインインストールから別プロジェクトで `/aidlc inception` が実行できる
- [ ] v1プロジェクトからの移行テストが成功する
- [ ] `skill-lint` による全スキルのベストプラクティスチェックがパスする

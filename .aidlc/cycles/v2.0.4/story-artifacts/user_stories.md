# ユーザーストーリー

## Epic: プラグインリポジトリ化

### ストーリー 1: プラグインインストール
**優先順位**: Must-have

As a Claude Codeユーザー
I want to `claude install` でAI-DLCをインストールする
So that プロジェクトにファイルをコピーせずにAI-DLCを利用できる

**受け入れ基準**:
- [ ] `skills/` ディレクトリにプラグイン構造が配置されている
- [ ] `skills/aidlc/SKILL.md` が存在し `/aidlc` コマンドとして動作する
- [ ] 全スキル（aidlc, aidlc-setup, reviewing-*, squash-unit）が `skills/` 配下にある
- [ ] CLAUDE.md がプラグインのルートに存在する

### ストーリー 2: ステップファイルのパス解決
**優先順位**: Must-have

As a `/aidlc` スキルの利用者
I want to `steps/` パスが正しく解決される
So that Inception/Construction/Operations Phaseのステップが読み込みエラーなく実行される

**受け入れ基準**:
- [ ] SKILL.md の `steps/` 参照がスキルのベースディレクトリからの相対パスで解決される
- [ ] `steps/common/`, `steps/inception/`, `steps/construction/`, `steps/operations/` が存在する
- [ ] 現在の `docs/aidlc/prompts/` の内容が `steps/` に移行されている

### ストーリー 3: 追加コンテキスト渡し
**優先順位**: Must-have

As a `/aidlc` スキルの利用者
I want to `/aidlc inception プラグイン化を進めて` のように追加コンテキストを渡す
So that セッション開始時にテーマや追加指示を伝えられる

**受け入れ基準**:
- [ ] `/aidlc <action> <追加テキスト>` で action 以降が ARGUMENTS に含まれる
- [ ] SKILL.md のオーケストレーターが追加コンテキストを認識し、セッション中参照できる

### ストーリー 4: v1残存コードの削除
**優先順位**: Must-have

As a 開発者
I want to v1のrsyncコピー処理とパス設定の残存を削除する
So that コードベースがv2のプラグイン構造と整合する

**受け入れ基準**:
- [ ] #429: スターターキットパス判定がスキル構造に合わせて更新されている
- [ ] #430: defaults.tomlのパス設定がv2構造と整合している
- [ ] #431: rsyncコピー処理が削除されている
- [ ] #433: 同期マニフェスト関連が整理されている（コピー方式廃止に伴い不要部分を削除）

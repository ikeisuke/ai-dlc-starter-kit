# ユーザーストーリー

## Epic: aidlc-setup.sh のパス解決バグ修正

### ストーリー 1: resolve_starter_kit_root の warn メッセージ修正
**優先順位**: Must-have

As a AI-DLCスターターキットの利用者
I want to `project.starter_kit_repo` が未設定でも `aidlc-setup.sh` が正常にパスを解決できること
So that 初回セットアップやフォールバック時にエラーが発生しない

**受け入れ基準**:
- [ ] `resolve_starter_kit_root` 関数の 226行目の warn メッセージが stderr に出力される
- [ ] `STARTER_KIT_ROOT` 変数に純粋なパスのみが格納される（warn メッセージが混入しない）
- [ ] `project.starter_kit_repo` 未設定時に `aidlc-setup.sh --dry-run` を実行しても正常にパス解決できる
- [ ] 既存の正常系（環境変数指定、メタ開発モード、設定値あり）の動作に影響がない

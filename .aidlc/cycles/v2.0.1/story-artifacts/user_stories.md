# ユーザーストーリー

## Epic: v2.0.0安定化 - 旧構造の完全移行とリファクタリング

### ストーリー 1: サイクルデータの統一パス化
**優先順位**: Must-have

As a AI-DLC利用者
I want to すべてのサイクルデータが `.aidlc/cycles/` に統一されている
So that サイクル参照時に `docs/cycles/` と `.aidlc/cycles/` の2箇所を探す必要がなくなる

**受け入れ基準**:
- [ ] `docs/cycles/` 配下の全サイクルデータが `.aidlc/cycles/` に移動されている
- [ ] `suggest-version.sh` 等のスクリプトが `.aidlc/cycles/` のみを参照している
- [ ] `docs/cycles/` ディレクトリが削除されている

---

### ストーリー 2: 旧ディレクトリの移行・削除
**優先順位**: Must-have

As a AI-DLC利用者
I want to `docs/aidlc/` 配下の旧ディレクトリ（templates, bin, config, skills）が削除されている
So that v2の構造（`skills/aidlc/`）だけを参照すればよくなる

**受け入れ基準**:
- [ ] ステップファイル内の `docs/aidlc/templates/` 参照が `skills/aidlc/templates/` に更新されている
- [ ] `docs/aidlc/bin/`、`docs/aidlc/config/`、`docs/aidlc/skills/` が削除されている
- [ ] エントリポイントファイル（`docs/aidlc/prompts/inception.md` 等）はリダイレクト用として残存
- [ ] `docs/aidlc/guides/` と `docs/aidlc/kiro/` は維持されている

---

### ストーリー 3: 旧パス参照の一掃
**優先順位**: Must-have

As a AI-DLC開発者
I want to スキルファイル内のv1パス参照が全て更新されている
So that v2環境で混乱なく動作する

**受け入れ基準**:
- [ ] `skills/aidlc/` 配下で `docs/aidlc.toml` への参照が0件（v1フォールバック以外）
- [ ] `skills/aidlc/` 配下で `docs/cycles/` への参照が0件
- [ ] `prompts/setup-prompt.md` への参照が `/aidlc setup` に更新されている
- [ ] CLAUDE.md/AGENTS.md のスタイルが統一されている

---

### ストーリー 4: ステップファイル構造改善
**優先順位**: Should-have

As a AI-DLC開発者
I want to 大規模なステップファイルが適切に分割されている
So that 保守性と可読性が向上する

**受け入れ基準**:
- [ ] `operations-release.md` の統合先が整理されている
- [ ] `02-generate-config.md` の責務が適切に分離されている
- [ ] コンテキスト変数の一覧が文書化されている

---

### ストーリー 5: シェルスクリプトバグ修正
**優先順位**: Should-have

As a AI-DLC利用者
I want to シェルスクリプトの既知バグが修正されている
So that セットアップやフェーズ実行が正しく動作する

**受け入れ基準**:
- [ ] `aidlc-cycle-info.sh` の `detect_phase()` が正しいフェーズを返す
- [ ] 重複関数（`get_backlog_mode()`, `get_current_branch()`）が共通ライブラリに統合されている
- [ ] クォート除去ロジックが統一されている
- [ ] UUOC パターンが修正されている

# ユーザーストーリー

## Epic: 設定整合性・UX改善

### ストーリー 1: 未使用設定キーの掃除 (#506)
**優先順位**: Must-have

As a AI-DLCスターターキットの開発者
I want to 使われていない `[paths].cycles_dir` 設定キーが除去されている
So that 設定ファイルの見通しが良くなり、未使用キーによる混乱が防げる

**受け入れ基準**:
- [ ] `.aidlc/config.toml` から `[paths]` セクションの `cycles_dir` が削除されていること
- [ ] `skills/aidlc-setup/templates/config.toml.template` から `cycles_dir` が削除されていること
- [ ] `defaults.toml` に `[paths].cycles_dir` が存在しないこと（現状も存在しないが確認）
- [ ] 既存の `config.toml` に `cycles_dir` が残った状態で `read-config.sh` によるセットアップフローが正常に動作すること

---

### ストーリー 2: 名前付きサイクル機能の制御 (#507)
**優先順位**: Must-have

As a AI-DLCスターターキットの利用者
I want to 名前付きサイクル機能をconfig設定でon/offできる
So that 不要な選択肢が表示されず、シンプルなワークフローで作業できる

**受け入れ基準**:
- [ ] `defaults.toml` に `rules.cycle.named_enabled = false` が追加されていること
- [ ] `named_enabled=false`（デフォルト）の場合、ステップ7でmode=namedの分岐がスキップされること
- [ ] `named_enabled=false`（デフォルト）の場合、ステップ8の名前付きサイクル継続確認がスキップされること
- [ ] `named_enabled=true` の場合、従来通りの動作が維持されること
- [ ] `config.toml` にキー未設定の既存環境では `defaults.toml` のデフォルト値 `false` が適用され、名前付きサイクル機能が無効になること（意図的な仕様変更）
- [ ] `read-config.sh` で `rules.cycle.named_enabled` が読み取れること

**技術的考慮事項**:
デフォルト `false` は意図的な仕様変更であり、後方互換ではない。既存ユーザーで名前付きサイクルを利用していた場合は `config.toml` に `named_enabled = true` を追加する必要がある。

---

### ストーリー 3: AskUserQuestionツール使用ルール (#505)
**優先順位**: Must-have

As a AI-DLCフレームワークを使うAIエージェント
I want to ゲート承認とユーザー選択・情報収集の区別が明文化されている
So that semi_autoモードでもユーザーの明示的判断が必要な場面でAskUserQuestionを適切に使用できる

**受け入れ基準**:
- [ ] `steps/common/rules.md` にAskUserQuestion使用ルールが追加されていること
- [ ] ゲート承認（semi_autoで自動化可）とユーザー選択（AskUserQuestion必須）の区別が表形式で明記されていること
- [ ] 情報収集（AskUserQuestion必須）の区別も含まれていること
- [ ] 代表的な具体例（ゲート承認の例、ユーザー選択の例、情報収集の例）が含まれていること
- [ ] 既存のセミオートゲート仕様との矛盾がないこと

---

### ストーリー 4: versionアクション追加 (#508)
**優先順位**: Must-have

As a AI-DLCスターターキットの開発者
I want to `/aidlc version` でスキルのバージョンを確認できる
So that 現在どのバージョンのスキルで処理しているかが即座にわかる

**受け入れ基準**:
- [ ] `/aidlc version` で `starter_kit_version` の値が1行で表示されること
- [ ] 短縮形 `/aidlc v` でも同じ結果が得られること
- [ ] SKILL.mdの引数ルーティングに `version`（短縮形: `v`）が追加されていること
- [ ] ヘルプ表示に `version` アクションが含まれていること
- [ ] 共通初期化フローは実行されないこと（version表示のみで終了）
- [ ] `v` エイリアスが既存アクション短縮形（`i`/`c`/`o`/`e`/`h`）と競合しないこと

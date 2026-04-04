# ユーザーストーリー

## Epic: 設定キー整理・簡素化

### 共通移行ポリシー

本エピックで設定キーの削除・改名を行う際は、以下の統一ポリシーに従う:

- **削除済みキー**: config.tomlに残存していても無視される（read-config.shはTOML内の未知キーをエラーにしない）
- **改名キー**: 新キー優先、旧キーのみ設定時はフォールバックとして読み取る。新旧同時指定時は新キーが優先される
- **旧キー維持期間**: 少なくとも次のメジャーバージョンまで維持する（Intentの制約事項に準拠）
- **旧キー使用時の警告**: Construction Phaseで設計判断（任意）
- **read-config.shの終了コード契約**: exit 0=値あり、exit 1=キー不在（optional-missing、異常ではない）、exit 2=エラー。呼び出し元はexit 1を「未設定」として正常にハンドリングすること

---

### ストーリー 1: 不要なpreflight設定の削除（#520-1）
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to プリフライトチェックが設定不要で常時実行される
So that 不要な設定項目を管理する手間が省け、設定ファイルが簡潔になる

**受け入れ基準**:
- [ ] `/aidlc inception` 実行時にプリフライトチェック（環境チェック・オプションチェック）が設定なしで完走する
- [ ] 旧config.tomlにpreflight設定（enabled/checks）が残っていても正常に起動する（共通移行ポリシー: 削除済みキー無視）
- [ ] defaults.toml・config.tomlテンプレートからpreflight関連設定が削除されている

**技術的考慮事項**:
preflight.mdの手順5の分岐ロジック簡素化が必要。オプションチェック（gh, review-tools, config-validation）は常時全項目実行に変更。

---

### ストーリー 2: named_enabledとcycle.modeの統合（#520-2）
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to サイクルモードをcycle.modeの1つのキーで制御できる
So that 重複設定による混乱がなくなり、設定の意図が明確になる

**受け入れ基準**:
- [ ] `cycle.mode=default` で従来の通常フロー、`cycle.mode=named` で名前付きサイクル、`cycle.mode=ask` でユーザー選択が動作する
- [ ] 旧config.tomlにnamed_enabledが残っていても正常に動作する（共通移行ポリシー: 削除済みキー無視）
- [ ] defaults.tomlからrules.cycle.named_enabledが削除されている

**技術的考慮事項**:
01-setup.mdのステップ7のnamed_enabledチェック（L187-199）を除去し、cycle.mode直接参照に変更。

---

### ストーリー 3: size_checkのスコープ見直し（#520-3）
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to メタ開発専用のsize_check設定がデフォルトに含まれない
So that 一般プロジェクトの設定ファイルに不要な項目が含まれなくなる

**受け入れ基準**:
- [ ] size_check設定がないconfig.tomlで `/aidlc inception` が正常に起動する（size_checkは未設定時に無効扱い）
- [ ] メタ開発リポジトリのconfig.tomlにはsize_check設定が直接記載され、bin/check-size.shで読み取り可能である
- [ ] defaults.toml・setupテンプレートからrules.size_check関連キーが削除されている

**技術的考慮事項**:
defaults.tomlから除外後、read-config.shでsize_checkキーが不在の場合はexit 1（キー不在）を返す。呼び出し元（bin/check-size.sh）がexit 1をハンドリングしてsize_checkを無効として扱う。

---

### ストーリー 4: 旧キー名の更新（#520-4）
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to ドキュメントの設定仕様リファレンスが最新のキー名で記載されている
So that ドキュメントとコードの不整合による混乱が防止される

**受け入れ基準**:
- [ ] common/rules.mdの設定仕様リファレンスでrules.upgrade_check.enabledがrules.version_check.enabledに更新されている

---

### ストーリー 5: history.levelとdepth_levelの統合（#522）
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to 履歴記録レベルがdepth_levelから自動導出され、設定不要で一貫した詳細度制御ができる
So that 既定では追加設定なしで適切な履歴レベルが適用され、必要な場合のみ上書きできる

**受け入れ基準**:
- [ ] depth_level=standardのconfig.tomlで、history_levelを未設定のまま `/aidlc inception` を実行すると、プリフライト結果の主要設定値にhistory_level: standardと表示される
- [ ] depth_level=comprehensiveで未指定時、プリフライト結果の主要設定値にhistory_level: detailedと表示される
- [ ] rules.depth_level.history_levelを明示指定した場合、自動導出より明示値が優先される
- [ ] 旧キーrules.history.levelのみ設定されたconfig.tomlでも正常に読み取れる（共通移行ポリシー: 改名キーフォールバック）
- [ ] 同一depth_levelなら全フェーズで同一のhistory_levelが導出される
- [ ] 自動導出ロジックはプリフライトチェック（手順4）で一元的に実行される

**技術的考慮事項**:
defaults.tomlにrules.depth_level.history_levelを追加（デフォルト: 空=自動導出）。read-config.sh内で新キー → 旧キーのフォールバックチェーン実装。

---

### ストーリー 6: lintingカスタムコマンド対応（#523）
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to Markdown lintに使用するコマンドをカスタマイズできる
So that プロジェクト固有のlinterやオプションを利用できる

**受け入れ基準**:
- [ ] rules.linting.command="custom-lint"を設定した状態でlint実行時、指定コマンドが実行される（コマンドは単一実行ファイル名として扱い、引数は固定で対象パスを付与する。シェル展開・パイプ・リダイレクトは非対応）
- [ ] 旧キーmarkdown_lint=trueのみ設定されたconfig.tomlでもenabled=trueとして動作する（共通移行ポリシー: 改名キーフォールバック）
- [ ] enabled=falseでlintがスキップされる
- [ ] defaults.tomlにrules.linting.enabledとrules.linting.commandが追加されている（commandデフォルト: "npx markdownlint-cli2"）
- [ ] commandで指定したコマンドが存在しない・失敗した場合、lint失敗として終了コード非0を返す（evalは使用しない）

**技術的考慮事項**:
run-markdownlint.sh内でのコマンド実行はevalを使わず、設定値を単一コマンド名として実行する（引数は固定で対象パスを付与）。旧キーフォールバック実装。

---

### ストーリー 7: cyclesディレクトリのgit管理外オプション（#434）
**優先順位**: Must-have

As a OSSリポジトリでAI-DLCを利用する開発者
I want to .aidlc/cycles/ディレクトリをgit管理外にできるオプションがある
So that リポジトリに中間成果物がコミットされず、クリーンな状態を維持できる

**受け入れ基準**:
- [ ] git_tracked=falseを設定し `/aidlc setup` を実行すると、.gitignoreへの`.aidlc/cycles/`追記を案内するメッセージが表示される
- [ ] 案内のみで自動変更は行わない（非破壊方針）
- [ ] 既に追跡済みのファイルのuntrackは行わない
- [ ] .gitignoreに既に`.aidlc/cycles/`が記載済みの場合、重複案内しない
- [ ] defaults.tomlにrules.cycle.git_tracked設定が追加されている（デフォルト: true。`rules.cycle.*` 名前空間に統一）
- [ ] config.tomlにgit_tracked設定がなくてもエラーにならない

**技術的考慮事項**:
aidlc-setupスキルでの案内ロジック追加が必要。.aidlc/config.tomlはgit管理を維持（cyclesのみ対象）。Gitリポジトリでない場合は案内をスキップする。

# ユーザーストーリー

## Epic 1: 名前付きサイクル

### ストーリー 1: 名前付きサイクルの設定
**優先順位**: Must-have

As a AI-DLC利用者
I want to サイクルの命名モード（`default` / `named` / `ask`）を設定できる
So that プロジェクトの特性に応じたサイクル管理方式を選択できる

**受け入れ基準**:
- [ ] `rules.cycle.mode` に `default`、`named`、`ask` の3値が設定可能
- [ ] `read-config.sh rules.cycle.mode --default "default"` で設定値を取得できる
- [ ] 未設定時は `default` が返り、既存の `cycles/vX.X.X` 形式で動作する
- [ ] 無効な値（例: `invalid`）設定時、警告メッセージ「【警告】rules.cycle.mode の値 "..." は無効です」を出力し `default` にフォールバックする

---

### ストーリー 2: 名前付きサイクルのディレクトリ作成
**優先順位**: Must-have

As a AI-DLC利用者
I want to `mode=named` 時に `docs/cycles/[name]/vX.X.X/` 構造でサイクルディレクトリが作成される
So that 機能ドメイン別（例: WAF、CDN）の独立したバージョン系列を管理できる

**受け入れ基準**:
- [ ] `init-cycle-dir.sh` に組み立て済みのサイクルパス（例: `waf/v1.0.0`）を渡すと `docs/cycles/waf/v1.0.0/` 配下に全サブディレクトリが作成される。入力はパス文字列1つ（名前とバージョンの分離は呼び出し元の責務）
- [ ] プロンプト側バリデーション（ストーリー4の責務）: 名前部分が `^[a-z0-9][a-z0-9-]{0,63}$` に合致しない場合、再入力を求める
- [ ] スクリプト側バリデーション: `init-cycle-dir.sh` は既存の検証（空文字・不正パス区切り）のみ実施し、不正時は終了コード1を返す
- [ ] 既存ディレクトリと衝突する場合（`docs/cycles/waf/v1.0.0/` が既に存在）、エラーメッセージを返し上書きしない
- [ ] `mode=default` 時は従来通り `docs/cycles/vX.X.X/` にディレクトリが作成される（後方互換）

**技術的考慮事項**:
- サイクル名入力フローの責務はストーリー4（Inceptionプロンプト）側。本ストーリーはスクリプトの対応のみ
- `init-cycle-dir.sh` は既に任意の識別子を受容するため、呼び出し元でパスを組み立てて渡す

---

### ストーリー 3: 名前付きサイクルのブランチ対応
**優先順位**: Must-have

As a AI-DLC利用者
I want to 名前付きサイクル時にブランチが `cycle/[name]/vX.X.X` 形式で作成・検出・削除される
So that ブランチ名からサイクル名とバージョンの両方を識別できる

**受け入れ基準**:
- [ ] ブランチ作成: `setup-branch.sh waf/v1.0.0 branch` を実行すると `cycle/waf/v1.0.0` ブランチが作成され、`status:success` `branch:cycle/waf/v1.0.0` が出力される
- [ ] サイクル検出: `aidlc-cycle-info.sh` がブランチ `cycle/waf/v1.0.0` から `cycle_name:waf` `cycle_version:v1.0.0` を抽出して出力する
- [ ] マージ後削除: `post-merge-cleanup.sh` がマージ済みの `cycle/waf/v1.0.0` ブランチを検出し削除対象に含める
- [ ] 従来形式（`cycle/v1.20.0`）のブランチも引き続き動作する（後方互換）
- [ ] 名前付きサイクルのブランチが既に存在する場合、`setup-branch.sh` がエラーメッセージを返す

---

### ストーリー 4: Inception Phaseプロンプトの名前付きサイクル対応
**優先順位**: Must-have

As a AI-DLC利用者
I want to Inception Phaseで名前付きサイクルの作成フローが統合される
So that 名前付きサイクルでもスムーズにインセプションを進められる

**受け入れ基準**:
- [ ] `mode=named` 時: ステップ6でサイクル名入力プロンプトが表示され、バリデーション失敗時は再入力を求める
- [ ] `mode=ask` 時: ステップ6で「名前付き」or「名前なし」の選択肢が表示される。「名前付き」選択時は名前入力へ、「名前なし」選択時は従来フローへ
- [ ] `mode=default` 時: 従来フロー（名前入力なし）で動作する
- [ ] バージョン提案: `suggest-version.sh` が名前付きサイクル内のバージョン系列（例: `docs/cycles/waf/v*/`）から提案する。該当名前の既存バージョンがない場合は `v1.0.0` を提案する
- [ ] 重複チェック: 入力された `[name]/[version]` の完全一致が `all_cycles` に含まれる場合、「同名同バージョンのサイクルが既に存在します」エラーを表示して再選択を求める（同じ名前の別バージョンは許可: 例 `waf/v1.0.0` 存在時に `waf/v1.1.0` は作成可能）
- [ ] progress.md・履歴ファイルの参照パスが `docs/cycles/[name]/vX.X.X/` を指す

---

## Epic 2: squash-unit.sh スキル化

### ストーリー 5: squash-unit スキル定義
**優先順位**: Must-have

As a AI-DLC利用者
I want to Unit完了時のsquash操作をスキル呼び出しで実行できる
So that `--cycle`、`--vcs`、`--base` 等の引数を手動で組み立てる必要がなくなる

**受け入れ基準**:
- [ ] 正本: `prompts/package/skills/squash-unit/SKILL.md` が作成されている
- [ ] 配布先: `docs/aidlc/skills/squash-unit/SKILL.md` にrsync同期される（Operations Phaseのupgrading-aidlcで自動実行）
- [ ] シンボリックリンク: `.claude/skills/squash-unit` → `../../docs/aidlc/skills/squash-unit` が作成される
- [ ] SKILL.mdにスキルのメタデータ（name: `squash-unit`, description, argument-hint）が定義されている
- [ ] 引数自動解決: スキルがブランチ名から `--cycle` を、設定から `--vcs` を、コミット履歴から `--base` を解決する手順を記述している
- [ ] dry-run: squash実行前に `--dry-run` で対象コミット一覧を表示し、続行確認を求めるフローが記述されている
- [ ] メッセージファイル: Writeツールで一時ファイル作成 → `--message-file` で渡す → 削除のフローが記述されている
- [ ] スキル呼び出し失敗時: エラーメッセージとともにcommit-flow.mdの手動フローを案内する
- [ ] retroactiveモードもスキルから呼び出し可能

**技術的考慮事項**:
- squash-unit.sh本体のロジック変更は不要（スキル定義のみ）
- commit-flow.mdでスキル呼び出しを推奨として追記（従来の直接呼び出しも動作を維持）
- 実装時はUnit内で「SKILL.md作成・配布・リンク整備」と「実行フロー記述」をサブタスクに分割して段階的に完了する

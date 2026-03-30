# 既存コード分析 - v1.18.3

## #262: セミオートモードでレビューサマリが生成されない

### 原因
`prompts/package/prompts/common/review-flow.md` の構造的問題:
1. AIレビュー完了（指摘0件）→ 履歴記録 → レビューサマリ更新参照（Line 251）
2. セミオートゲート判定（Line 667-670）→ ユーザー承認スキップ
3. レビューサマリ更新がセミオートゲート後の文脈に含まれ、スキップされる

### 修正対象
- `prompts/package/prompts/common/review-flow.md`

### 修正方針
レビューサマリ更新をセミオートゲート判定の**前**に独立ステップとして明示的に配置する。

---

## #261: プロンプト内Bashコードブロックの$()使用をCI自動検出

### 現状
- CI: `.github/workflows/pr-check.yml` にmarkdown-lintジョブが存在
- 対象: `prompts/package/prompts/**/*.md` 内のBashコードブロック
- 現行のmarkdownlintでは$()検出不可

### 修正対象
- `bin/check-bash-substitution.sh`（新規作成）
- `.github/workflows/pr-check.yml`（ジョブ追加）
- `prompts/package/prompts/common/rules.md` でルール既に明文化済み

### 修正方針
- `bin/check-size.sh` のパターンに倣ったスクリプトを新規作成
- ` ```bash ` ～ ` ``` ` ブロック内の `$()` を検出
- 説明文中・.shスクリプト内の `$()` は対象外
- 終了コード: 0=合格, 1=違反検出, 2=スクリプトエラー

---

## #263: upgrade-aidlc.sh daselを必須依存に変更

### 現状
- `upgrade-aidlc.sh`: dasel不在時のフォールバックが複雑（grep, デフォルト値等）
- `check-setup-type.sh`: dasel不在時に空のsetup_typeを返す
- `read-config.sh`: dasel不在時にexit 2（既にエラー終了）

### 修正対象
- `prompts/package/skills/upgrading-aidlc/bin/upgrade-aidlc.sh`

### 修正方針
- スクリプト冒頭で `command -v dasel` を確認
- 未インストール時: `error:dasel-required` + インストール手順を表示してexit 1
- フォールバック処理を削除してコードを簡素化

---

## #264: upgrade-aidlc.sh --configオプション廃止

### 現状
- `upgrade-aidlc.sh` Line 61-68: `--config PATH` を解析し `CONFIG_PATH` に格納
- 下流スクリプトに透過されない（`check-setup-type.sh` はハードコード `docs/aidlc.toml`）
- 全ユーザーがデフォルトパス使用、実害ゼロ

### 修正対象
- `prompts/package/skills/upgrading-aidlc/bin/upgrade-aidlc.sh`

### 修正方針
- `--config` オプションの解析を削除
- `CONFIG_PATH` 変数を `docs/aidlc.toml` にハードコード化
- 下流スクリプトへの透過ロジックも削除（不要になるため）
- リリースノートに廃止を明記

---

## #217: サイクルバージョン決定時にバックログ・過去サイクル状況提示 + 非SemVer対応

### 現状
- `suggest-version.sh` の `get_latest_cycle()`: `v[0-9].*` パターンのみ（SemVer限定）
- Inception Phase ステップ6: バージョン候補を表示するだけでコンテキスト情報なし
- `init-cycle-dir.sh`, `setup-branch.sh`: 非SemVer名も受け付ける

### 修正対象
- `docs/aidlc/bin/suggest-version.sh`（`prompts/package/bin/suggest-version.sh` を編集）
- `prompts/package/prompts/inception.md`（ステップ6）

### 修正方針

**suggest-version.sh**:
- 既存の `get_latest_cycle()`（SemVerのみ）は維持
- 新関数 `get_all_cycles()` を追加（全サイクルディレクトリを列挙）
- 出力に `all_cycles:` 行を追加

**inception.md ステップ6**:
- バージョン提案前にバックログ一覧と直近サイクル概要を表示
- 非SemVerサイクルが存在する場合は自由入力フローを追加
- 既存のSemVerフローは維持（後方互換）

---

## #211: マージ後のmain pull + worktree同期自動化

### 現状
- `docs/cycles/rules.md` にworktree運用ルールを手動手順として記載
- マージ後に手動で: (1) 親リポジトリでmain pull、(2) worktreeのブランチ切り替え、(3) ブランチ削除

### 修正対象
- `bin/post-merge-sync.sh`（新規作成、リポジトリ固有）
- `docs/cycles/rules.md`（運用手順を自動化スクリプトに置換）

### 修正方針
- スクリプトが以下を実行: (1) 親リポジトリのmain pull、(2) worktreeのdetached HEAD化、(3) マージ済みサイクルブランチの削除
- 失敗時のフォールバック: 従来の手動手順を表示
- リポジトリ固有のため、共通プロンプトには含めない

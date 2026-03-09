# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.20.0

## 開発の目的
AI-DLCのワークフロー拡張と利便性向上を行う。具体的には、名前付きサイクル機能の導入により機能ドメイン別の並行開発を可能にし、squash-unit.shのスキル化によりUnit完了時の操作をシームレスにする。

## ターゲットユーザー
AI-DLCスターターキットを利用する開発者（特に複数機能ドメインを持つプロジェクト）

## ビジネス価値
- 名前付きサイクルにより、1つのリポジトリ内で機能ドメイン別（例: WAF、CDN等）の独立したバージョン系列を管理できるようになる
- squash-unit.shのスキル化により、引数の手動組み立てが不要になり、Construction Phaseのフローがよりスムーズになる

## 成功基準

### 名前付きサイクル
- `docs/aidlc.toml` に `rules.cycle.mode` 設定を追加し、`default` / `named` / `ask` の3値が設定可能
- `mode=named` 時: Inception Phase開始時に名前を入力し、`docs/cycles/[name]/vX.X.X/` 構造でディレクトリが作成される
- `mode=ask` 時: Inception Phase開始時に「名前付き」or「名前なし」を選択できる。「名前付き」選択時は名前入力を求め、`mode=named` と同じ動作になる。「名前なし」選択時は `mode=default` と同じ動作になる。名前のバリデーション失敗時は再入力を求める
- `mode=default` 時（未設定時含む）: 既存の `docs/cycles/vX.X.X/` 形式で動作する（後方互換）
- ブランチ名が `cycle/[name]/vX.X.X` にネストされる（`setup-branch.sh` が対応）
- サイクル名の命名規則: `^[a-z0-9][a-z0-9-]{0,63}$`（小文字英数字・ハイフン、先頭は英数字、最大64文字）
- `suggest-version.sh`、`init-cycle-dir.sh` 等の既存スクリプトが名前付きサイクルに対応する

### squash-unit.sh スキル化
- `.claude/skills/squash-unit/SKILL.md` が作成されている
- スキルから `squash-unit.sh` を適切な引数で呼び出せる
- `--cycle`、`--vcs`、`--base`、`--message-file` がコンテキストから自動解決される
- dry-runモードでの事前確認がスキルフローに組み込まれている

## スコープ

### 含まれるもの
- 名前付きサイクルの設定・ディレクトリ構造・ブランチ命名の実装
- 関連スクリプト（`suggest-version.sh`、`init-cycle-dir.sh`、`setup-branch.sh` 等）の名前付きサイクル対応
- Inception Phaseプロンプトの名前付きサイクル対応
- squash-unit.shのスキル定義作成

### 含まれないもの（Out of Scope）
- 既存サイクル（`cycles/vX.X.X`）の名前付き形式への自動移行
- 名前付きサイクル間のクロスリファレンス・依存管理
- Operations Phase・Construction Phaseプロンプトの名前付きサイクル対応（影響箇所の洗い出しのみ実施し、対応は次サイクル以降）
- squash-unit.sh 本体のロジック変更（スキル定義のみ）

## 影響分析

### 既存機能への影響
- **ディレクトリ探索**: `ls -d docs/cycles/v*/` 等の既存パターンは `mode=default` 時にそのまま動作する。`mode=named` 時は `docs/cycles/[name]/v*/` パターンが必要になるため、関連スクリプトの対応が必要
- **ブランチ検出**: `cycle/vX.X.X` パターンの検出ロジック（`post-merge-sync.sh` 等）が `cycle/[name]/vX.X.X` にも対応する必要がある
- **バージョン提案**: `suggest-version.sh` が名前付きサイクル内のバージョン系列を正しく認識する必要がある
- **CI/CD**: 本リポジトリではCI/CDパイプラインへの直接影響はない（GitHub Actions未使用）

## 期限とマイルストーン
特になし

## 制約事項
- 既存のサイクル構造（`cycles/vX.X.X`）との後方互換を維持すること
- メタ開発のため、変更は `prompts/package/` に対して行い、`docs/aidlc/` は直接編集しないこと

## 不明点と質問（Inception Phase中に記録）

[Question] 名前付きサイクルの「名前」はどういうケースで使う想定か？
[Answer] プロジェクト機能単位。例: AWSインフラ管理リポジトリでWAF用のライン管理

[Question] 名前付きサイクルの設定方式は？
[Answer] `default`（現行動作）/ `named`（常に名前付き）/ `ask`（インセプション時に選択）の3値

[Question] ブランチ名はネストする想定か？
[Answer] はい。`cycle/[name]/vX.X.X` 形式

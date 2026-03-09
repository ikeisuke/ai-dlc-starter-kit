# Unit: 名前付きサイクルスクリプト対応

## 概要
名前付きサイクルの `[name]/vX.X.X` 形式に対応するため、関連スクリプト群（`setup-branch.sh`、`aidlc-cycle-info.sh`、`post-merge-cleanup.sh`、`init-cycle-dir.sh`、`suggest-version.sh`）を修正する。ブランチ作成・検出・削除・ディレクトリ初期化・バージョン提案の一貫した動作を実現する。

## 含まれるユーザーストーリー
- ストーリー 2: 名前付きサイクルのディレクトリ作成（スクリプト側バリデーション確認）
- ストーリー 3: 名前付きサイクルのブランチ対応

## 責務
- `setup-branch.sh`: `waf/v1.0.0` 形式の入力を受け付け、`cycle/waf/v1.0.0` ブランチを作成。既に同名ブランチが存在する場合は `status:already_exists` を返す（ストーリー3の「エラーメッセージを返す」要件。呼び出し元が `already_exists` をエラーとして扱う）
- `aidlc-cycle-info.sh`: `cycle/waf/v1.0.0` ブランチから `cycle_name:waf` と `cycle_version:v1.0.0` を抽出
- `post-merge-cleanup.sh`: マージ済みの `cycle/[name]/vX.X.X` ブランチを検出・削除対象に含める
- `init-cycle-dir.sh`: スラッシュ含有チェック（L99-103）を緩和し、`[name]/vX.X.X` 形式（1レベルのスラッシュ）を受容する。`docs/cycles/waf/v1.0.0/` 配下にサブディレクトリが正しく作成されること。既存ディレクトリ衝突時のエラー動作を維持
- `suggest-version.sh`: ブランチ名パース（L24: `^cycle/v(...)`）を名前付き形式にも対応。ディレクトリスキャン（L34: `docs/cycles/v*/`）を `docs/cycles/[name]/v*/` パターンにも対応。名前付きサイクル内のバージョン系列から提案可能にする
- 従来形式（`cycle/vX.X.X`、`docs/cycles/vX.X.X/`）の後方互換維持

## 境界
- スクリプトのパス・正規表現修正のみ。設定値の読み取り（Unit 001）やプロンプト側のフロー制御（Unit 003）は含まない
- サイクル名のバリデーション（正規表現チェック）はプロンプト側（Unit 003）の責務。スクリプトは入力値をそのまま使用

## 依存関係

### 依存する Unit
- なし（スクリプトは設定値に依存せず、渡されたパス/ブランチ名を処理するのみ）

### 外部依存
- `prompts/package/bin/setup-branch.sh`（L137付近: SemVerバリデーション正規表現）
- `prompts/package/bin/aidlc-cycle-info.sh`（L42, L57: ブランチ名パース正規表現）
- `prompts/package/bin/post-merge-cleanup.sh`（L393付近: ブランチ名フィルタ正規表現）
- `prompts/package/bin/init-cycle-dir.sh`（L99-103: スラッシュ含有チェックの緩和）
- `prompts/package/bin/suggest-version.sh`（L24: ブランチパース、L34: ディレクトリスキャンパターン）

## 非機能要件（NFR）
- **パフォーマンス**: 正規表現変更のみのため影響なし
- **セキュリティ**: パストラバーサル防止（既存のバリデーションを維持）
- **スケーラビリティ**: 名前付き・名前なし両方のパターンを1つの正規表現で処理
- **可用性**: 既存の `cycle/vX.X.X` ブランチが引き続き正常動作すること

## 技術的考慮事項
- `setup-branch.sh` L137: `^v[0-9]+\.[0-9]+\.[0-9]+` を `^([a-z0-9][a-z0-9-]*/)?v[0-9]+\.[0-9]+\.[0-9]+` 等に拡張
- `aidlc-cycle-info.sh` L42: `^cycle/(v[0-9]+...)$` を名前部分のオプショナルキャプチャに拡張
- `aidlc-cycle-info.sh`: 新しい出力キー `cycle_name` の追加（名前なし時は空文字）
- `post-merge-cleanup.sh` L393: ブランチフィルタの正規表現を拡張
- `init-cycle-dir.sh` L99-103: スラッシュ含有チェックを「2レベル以上のスラッシュ」のみ拒否に緩和（`[name]/vX.X.X` は許可、`a/b/c` は拒否）。パストラバーサル防止（`..` を含むパス拒否）は維持
- `suggest-version.sh` L24: `^cycle/v(...)` を `^cycle/(([a-z0-9][a-z0-9-]*/)?v(...))` に拡張。L34: `docs/cycles/v*/` に加え `docs/cycles/[name]/v*/` も走査
- 全変更は `prompts/package/` に対して行う（メタ開発ルール）

## 実装優先度
High

## 見積もり
中〜大（5スクリプトの正規表現修正・出力契約追加・後方互換テスト）

## 関連Issue
- #293 名前付きサイクル

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -

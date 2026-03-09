# Unit: Inceptionプロンプト名前付きサイクル統合

## 概要
Inception Phaseプロンプトに名前付きサイクルの作成フローを統合する。`mode` に応じた名前入力・バリデーション・バージョン提案・重複チェックの一連のフローを実装する。

## 含まれるユーザーストーリー
- ストーリー 2: 名前付きサイクルのディレクトリ作成（プロンプト側フロー）
- ストーリー 4: Inception Phaseプロンプトの名前付きサイクル対応

## 責務
- `mode=named` 時: 名前入力プロンプト表示、バリデーション（`^[a-z0-9][a-z0-9-]{0,63}$`）、失敗時の再入力
- `mode=ask` 時: 「名前付き」or「名前なし」選択肢表示、選択に応じたフロー分岐
- `mode=default` 時: 従来フローで動作（名前入力なし）
- バージョン提案: `suggest-version.sh` 出力の `all_cycles` を用いてAI側で名前付きサイクル内のバージョン系列を抽出・再計算して提案（スクリプト改修不要）
- 重複チェック: `[name]/[version]` 完全一致での既存サイクル検出
- progress.md・履歴ファイルの参照パスが `docs/cycles/[name]/vX.X.X/` を指す
- `init-cycle-dir.sh` への組み立て済みパス渡し（例: `waf/v1.0.0`）

## 境界
- プロンプト（`prompts/package/prompts/inception.md`）の変更のみ。スクリプト本体の修正はUnit 002の責務
- Construction Phase・Operations Phaseプロンプトの対応は含まない（スコープ外）

## 依存関係

### 依存する Unit
- Unit 001: 名前付きサイクル設定（依存理由: `rules.cycle.mode` の読み取りが必要）
- Unit 002: 名前付きサイクルスクリプト対応（依存理由: `setup-branch.sh` が名前付きブランチを作成できる必要がある）

### 外部依存
- `prompts/package/bin/suggest-version.sh`（`all_cycles` 汎用取得に使用。名前付き系列の抽出・再計算はAI側で実施）
- `prompts/package/bin/init-cycle-dir.sh`（ディレクトリ作成、Unit 002でスラッシュ緩和対応）
- `prompts/package/bin/setup-branch.sh`（ブランチ作成、Unit 002で名前付き対応）

## 非機能要件（NFR）
- **パフォーマンス**: プロンプト処理のため特別な要件なし
- **セキュリティ**: 名前入力値のバリデーション（正規表現による制限）
- **スケーラビリティ**: 将来的なモード追加に対応可能な分岐構造
- **可用性**: `mode=default` 時の後方互換が完全に維持されること

## 技術的考慮事項
- `inception.md` のステップ6（バージョン決定）付近にモード分岐ロジックを追加
- サイクル名入力は `setup-branch.sh` 呼び出し前に完了させる
- `suggest-version.sh` の `all_cycles` 出力を取得し、AI側で `${cycle_name}/v*` をフィルタして名前付き系列を抽出・再計算（スクリプト改修不要）
- `all_cycles` はUnit 002で名前付きサイクルのパスも含む形に対応済み（重複チェック用）
- 変更は `prompts/package/prompts/inception.md` に対して行う（メタ開発ルール）

## 実装優先度
High

## 見積もり
中〜大（プロンプトフローの分岐追加、複数の受け入れ基準の検証）

## 関連Issue
- #293 名前付きサイクル

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-10
- **完了日**: 2026-03-10
- **担当**: @claude

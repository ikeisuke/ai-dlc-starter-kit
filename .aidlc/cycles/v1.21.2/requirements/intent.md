# Intent（開発意図）

## プロジェクト名
ai-dlc-starter-kit

## 開発の目的
CLIスクリプトの品質・堅牢性を改善し、開発体験を向上させる。具体的には、サイクルIDバリデーションの非SemVer対応、バリデーション正規表現の共通関数化、エラーハンドリング方針の統一、PRオープン前のローカルCIチェック組み込み、ブランチ作成方式の設定化、および個人設定ファイルのリネームを実施する。

## ターゲットユーザー
AI-DLCスターターキットを使用する開発者

## ビジネス価値
- カスタムサイクル名使用時の履歴記録失敗を解消し、非SemVer運用を正式サポート
- バリデーションロジックの一元化により、仕様変更時のドリフトリスクを排除
- エラーメッセージ形式の統一により、スクリプト呼び出し側のエラー処理が安定
- ローカルCIチェックにより、PRオープン後のCI失敗・手戻りを防止
- ブランチ作成方式の設定化により、毎回の質問を省略し作業効率を向上
- 個人設定ファイルのリネームにより、エディタのシンタックスハイライトが正しく動作

## 成功基準
- `write-history.sh --cycle feature-auth` 実行時に終了コード0で履歴が追記されること
- `write-history.sh --cycle 2026-03` 実行時に終了コード0で履歴が追記されること
- `lib/validate.sh`（または同等の共通ライブラリ）にバリデーション関数が抽出され、`write-history.sh`・`setup-branch.sh` 等が直接 `source` して使用していること
- 全CLIスクリプトのエラー出力が `error:<code>:<message>` 形式に統一されていること
- Operations Phaseステップ6.4で `bin/check-bash-substitution.sh` がローカル実行され、違反検出時にエラー終了すること
- `docs/aidlc.toml` に `rules.branch.mode = "branch"` を設定した状態で Inception Phase を開始すると、ブランチ作成方式の質問がスキップされブランチが自動作成されること
- `aidlc.local.toml` ファイルが `read-config.sh` で正しく読み込まれ、エディタでTOMLシンタックスハイライトが適用されること

## 期限とマイルストーン
パッチリリース（v1.21.2）として完了

## 制約事項
- メタ開発プロジェクト: `prompts/package/` を編集し、`docs/aidlc/` は直接編集しない
- 既存のCLIスクリプトインターフェースの後方互換性を維持する
- `aidlc.toml.local` → `aidlc.local.toml` のリネームは移行ガイドを提供する

## スコープ

### 含めるもの
- #312: サイクルIDバリデーションの非SemVer対応
- #311: Operations PhaseへのローカルCIチェック（Bash Substitution Check）組み込み
- #310: CLIスクリプトのエラーハンドリング方針統一
- #309: サイクル名バリデーション正規表現の共通関数化
- `rules.branch.mode` 設定のプロンプトへの正式追加
- `aidlc.toml.local` → `aidlc.local.toml` リネーム

### 変更タイプの定義
- **対象**: 既存フローの設定化・リファクタリング・バグ修正・ファイルリネーム
- **対象外**: 新規UIやコマンドの追加、新しいフェーズやステップの新設

### 除外するもの
- 新機能追加（ナビゲーションモード等）
- 他のバックログIssue

## 影響分析

| 対象 | 変更内容 | 互換性方針 | 移行手順 |
|------|----------|-----------|---------|
| `write-history.sh` | `validate_cycle` の正規表現を緩和し非SemVer名を許可 | 既存SemVer名は引き続き有効 | 変更不要 |
| `setup-branch.sh` | バリデーションを共通ライブラリに委譲 | インターフェース変更なし | 変更不要 |
| 全CLIスクリプト | エラー出力を `error:<code>:<message>` 形式に統一 | 呼び出し側がエラー文字列をパースしている場合は影響あり | プロンプト内のエラーパース箇所を更新 |
| `read-config.sh` | `aidlc.toml.local` → `aidlc.local.toml` の参照先変更 | 旧名 `aidlc.toml.local` も暫定サポート（存在すれば読み込み、警告を表示） | ユーザーはファイルをリネームするだけ |
| `.gitignore` | `aidlc.toml.local` → `aidlc.local.toml` に変更 | 旧名も残す（移行期間中） | 変更不要 |
| プロンプト各種 | `aidlc.toml.local` の参照を `aidlc.local.toml` に更新 | - | 自動更新（aidlc-setup時） |
| `inception.md` | `rules.branch.mode` 設定の参照を追加 | 未設定時は `ask`（従来動作）にフォールバック | 変更不要 |

## 不明点と質問（Inception Phase中に記録）

（なし — Issue内容から要件は明確）

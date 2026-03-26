# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.27.1

## 開発の目的
開発支援スクリプトの堅牢性向上、Kiroエージェント設定管理の改善、defaults.toml関連の問題対応を行う。具体的には、post-merge-cleanup.shのマルチリモート環境におけるリモート解決ロジックのバグ修正・機能改善、setup_kiro_agentの実ファイルマージ対応、プロンプト・ガイド文書でdefaults.tomlのフルパスを明記してAIの誤案内を防止、およびdefaults.toml不在時の診断・ガイダンス機能を追加する。

## ターゲットユーザー
AI-DLCスターターキットを使用する開発者（特にマルチリモート構成やKiro CLIを利用する開発者）

## ビジネス価値
- マルチリモート環境でのpost-merge後のブランチクリーンアップが正しく動作し、誤ったリモートへの操作を防止する
- Kiroエージェント設定ファイルがユーザーカスタマイズ済みの場合でもテンプレートとの差分マージが実行され、手動更新の手間を削減する
- AIがdefaults.tomlの正確なパスを把握でき、ユーザーへの誤案内（`docs/aidlc/defaults.toml` 等）を防止する
- defaults.toml不在時に原因と対処法（aidlc-setup実行）が案内され、ユーザーが自力で復旧できる

## 成功基準
- post-merge-cleanup.shがローカルブランチ削除済みの状態でも正しいリモートを特定できる（複数リモート時はorigin優先、該当なし時はスキップ+警告）
- setup_kiro_agentが実ファイルに対してallowedCommandsの差分マージを実行でき、マージ件数がコンソールに出力される
- シングルリモート環境およびsymlink状態ファイルでの既存動作に変更がない
- config-merge.mdおよびrules.mdにdefaults.tomlのフルパス（`docs/aidlc/config/defaults.toml`）が明記されている
- defaults.toml不在時にread-config.shが終了コード0で動作し、標準エラーに診断メッセージを出力する
- プリフライトチェックのconfig-validationがdefaults.toml不在をwarningとして報告する

## 期限とマイルストーン
パッチリリース（小規模改善）

## 制約事項
- 既存のpost-merge-cleanup.shおよびsetup_kiro_agentのインターフェースを維持する（後方互換性）
- Kiroエージェントのマージロジックは、Claude Code側のsetup_claude_permissions()と同等のset-difference方式を採用する
- jq/python両方のフォールバックパスを維持する
- defaults.tomlのパス明記はプロンプト正本（`prompts/package/`）を編集し、`docs/aidlc/`にはrsync同期で反映する

## 不明点と質問（Inception Phase中に記録）

[Question] #390と#389は統合して1つのUnitとして扱うか？
[Answer] はい、統合する。リモート解決ロジックのバグ修正と機能改善をまとめて1Unitで対応。

[Question] defaults.tomlのパス問題の具体的な状況は？
[Answer] 他プロジェクトでAIが `docs/aidlc/defaults.toml` と誤案内した（正しくは `docs/aidlc/config/defaults.toml`）。プロンプト・ガイドにフルパスが明記されていないことが原因。

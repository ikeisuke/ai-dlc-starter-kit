# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.18.3

## 開発の目的
AI-DLCスターターキットの既知のバグ修正と、日常的な開発ワークフローの摩擦を軽減する。具体的には、セミオートモードでのレビューサマリ未生成バグの修正、upgrade-aidlc.shの堅牢化、CI品質チェックの追加、およびworktree運用の自動化を行う。

## ターゲットユーザー
AI-DLCスターターキットを使用して開発を行うAIエージェントおよび開発者

## ビジネス価値
- セミオートモードの信頼性向上（レビューサマリが確実に生成される）
- upgrade-aidlc.shの簡素化と堅牢化（dasel必須化、不要オプションの廃止）
- プロンプト品質の回帰防止（CI自動検出によるBashコードブロック内コマンド置換 `$()` / バッククォートの検出）
- サイクルバージョン決定の判断材料充実（バックログ・過去サイクル状況の提示）
- マージ後のworktree運用手順の自動化（手動作業の削減）

## 成功基準
- セミオートモードでConstruction Phaseを実行した際、全Unitの `{NNN}-review-summary.md` が `docs/cycles/v1.18.3/construction/units/` に生成されること（AIレビュー指摘0件またはすべて対応済みのケース）
- upgrade-aidlc.sh実行時、`command -v dasel` が失敗する環境で `error:dasel-required` とインストール手順が表示され、exit 1で終了すること
- upgrade-aidlc.shの `--config` オプションが削除され、指定時にエラーメッセージが表示されること（実利用者なしのため段階的非推奨は不要。リリースノートに明記）
- GitHub Actions CIで `prompts/package/prompts/**/*.md` 内のBashコードブロックに `$()` またはバッククォートによるコマンド置換が含まれるPRがチェック失敗すること
- Inception Phase ステップ6でバージョン提案前にバックログ一覧と直近サイクルの概要が表示されること
- suggest-version.shが非SemVerサイクルディレクトリも認識し、SemVer以外の自由入力を促すフローがInceptionプロンプトに追加されること
- マージ後の同期スクリプトが親リポジトリのmain pull、worktreeのdetached HEAD化、マージ済みサイクルブランチ削除を実行すること

## 期限とマイルストーン
特に期限なし。1サイクル内で完了を目指す。

## 制約事項
- `docs/aidlc/` は直接編集禁止。プロンプト・テンプレートの修正は `prompts/package/` を編集すること
- #211（worktree同期自動化）はリポジトリ固有のため、共通プロンプトではなく `docs/cycles/rules.md` に記述
- #264の `--config` オプション廃止は、利用者が0であることが確認済みのため互換性影響は実質なし。ただしリリースノートに明記する

## スコープ

### 含まれるもの
- #262: セミオートモードでConstruction Phaseのレビューサマリが生成されないバグの修正
- #261: プロンプト内Bashコードブロックのコマンド置換（`$()`・バッククォート）をCIで自動検出
- #263: upgrade-aidlc.sh: daselを必須依存に変更
- #264: upgrade-aidlc.sh: --configオプションを廃止（利用者なし確認済み）
- #217: サイクルバージョン決定時にバックログ・過去サイクルの状況を提示、suggest-version.shの非SemVer対応
- #211: マージ後に親リポジトリのmain pull、worktreeのdetached HEAD化、マージ済みサイクルブランチ削除を自動化

### 除外するもの
- #218: Amazon AIDLC リポジトリからエッセンスを取り込む
- #31: GitHub Projects連携
- 新規機能の大規模追加

## 既存機能への影響

| 変更対象 | 影響範囲 | フォールバック |
|---------|---------|-------------|
| review-flow.md（#262） | セミオートモードのレビューサマリ生成タイミング変更 | manualモードには影響なし |
| upgrade-aidlc.sh（#263） | dasel未インストール時にエラー終了に変更 | エラーメッセージにインストール手順を表示 |
| upgrade-aidlc.sh（#264） | --configオプション削除 | 全ユーザーがデフォルトパス使用のため実質影響なし。リリースノートに明記 |
| CI workflow（#261） | 新規CIチェック追加 | 既存CIに影響なし（追加のみ） |
| inception.md（#217） | バージョン決定フローの拡張 | 既存SemVerフローは維持。非SemVerは追加フロー |
| rules.md（#211） | マージ後の運用手順を自動化スクリプトに置換 | スクリプト失敗時は従来の手動手順で対応可能 |

## 不明点と質問（Inception Phase中に記録）

[Question] #264 --configオプションは廃止する方向か、下流スクリプトに透過する方向か？
[Answer] Issue本文に「全ユーザーがデフォルトパスを使用しており実需がない」とあるため、廃止する。リリースノートに明記する。

[Question] #217 SemVer以外のサイクル命名にも対応するか？
[Answer] A+B両方を含める。バックログ・過去サイクル情報の提示に加え、suggest-version.shの非SemVer対応とInceptionプロンプトのフロー改善も実施する。影響範囲は限定的（suggest-version.shとInceptionプロンプトのステップ6のみ）。

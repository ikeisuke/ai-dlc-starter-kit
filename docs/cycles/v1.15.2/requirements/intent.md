# Intent（開発意図）

## プロジェクト名
AI-DLC スターターキット - シェルスクリプト・ドキュメント品質改善

## 開発の目的
PR #1162 (infrastructure-hub) のレビューで発見された AI-DLC スターターキットのシェルスクリプト（`prompts/package/bin/`）およびドキュメント（`prompts/package/guides/`）のバグ・改善点を修正し、スターターキットの品質と信頼性を向上させる。

**注意**: `docs/aidlc/` は `prompts/package/` の rsync コピーのため、すべての修正は `prompts/package/` 配下で行う。

## ターゲットユーザー
AI-DLCスターターキットの利用者（外部プロジェクトでAI-DLCを使用する開発者）

## ビジネス価値
- シェルスクリプトの実行時エラーを未然に防止する（grep正規表現、変数展開、構文エラーの修正）
- エラー処理の堅牢性向上により、利用者の問題解決時間を削減する
- コードの可読性・保守性を向上させる

## 成功基準
- Issue #194 の指摘のうち、実際に修正が必要な12件が修正されている
  - must (critical): 5件（11件中6件は誤検出のため除外）
  - want (改善推奨): 4件
  - imo (参考): 3件
  - ※ 誤検出6件（#1, #3, #4, #5-8）はコードが既に正しいため対象外（詳細は existing_analysis.md 参照）
- 修正対象のスクリプトが正常に動作する（各スクリプトの代表ユースケースで動作確認）
- 既存の機能に影響を与えていない（成功系・失敗系の既存動作互換を維持）

### 検証方法
- 各修正対象スクリプトの実行確認（`--help` や代表的な引数での動作確認）
- shellcheck による静的解析（利用可能な場合）
- エラー処理追加箇所は異常系パスの動作確認

## 期限とマイルストーン
- 1サイクルで完了

## 制約事項
- `docs/aidlc/` は `prompts/package/` の rsync コピーのため、修正は `prompts/package/` で行うこと
- macOS互換性を維持すること（特にsed、realpath等）
- 既存のスクリプトインターフェース（引数、出力形式、終了コード）を変更しないこと
- エラー処理分岐の追加（want項目）は、成功系パスの既存動作に影響を与えないこと

## スコープ

### 含まれるもの（Issue #194 項番対応）

**must (critical) 5件**（元11件中6件は誤検出、詳細は existing_analysis.md）:
| # | 対象ファイル（`prompts/package/` 起点） | 修正内容 |
|---|------------|---------|
| 2 | `prompts/package/bin/check-open-issues.sh:32` | `--limit` 数値バリデーション追加 |
| 9 | `prompts/package/bin/suggest-version.sh:78` | case文defaultケース追加 |
| 10 | `prompts/package/guides/ios-version-update.md:39` | パラメータ展開構文修正（`${{CYCLE}#v}` → `${CYCLE#v}`） |
| 11 | `prompts/package/guides/config-merge.md` | TOML同一テーブル重複定義修正（実際は `[rules.reviewing]` の重複） |

**誤検出（対象外）6件**: #1, #3, #4, #5-8（コードは既に正しい。レビューツールの表示上の問題）

**want (改善推奨) 4件**:
| # | 対象ファイル（`prompts/package/` 起点） | 修正内容 |
|---|------------|---------|
| 12 | `prompts/package/bin/check-open-issues.sh:56` | エラー処理フォールバック改善 |
| 13 | `prompts/package/bin/issue-ops.sh:158` | `parse_gh_error` 認証エラー対応追加 |
| 14 | `prompts/package/bin/cycle-label.sh:103` | リダイレクト設定の補足コメント追加 |
| 15 | `prompts/package/bin/setup-branch.sh:56` | `realpath` 利用への変更 |

**imo (参考) 3件**:
| # | 対象ファイル（`prompts/package/` 起点） | 修正内容 |
|---|------------|---------|
| 16 | `prompts/package/bin/aidlc-git-info.sh:18` | IFS初期化追加 |
| 17-18 | `prompts/package/bin/env-info.sh:103,120,205` | dasel `-f` オプション利用（3箇所） |

### 除外するもの
- スクリプトの機能追加
- インターフェースの変更（引数、出力形式、終了コード）
- 新規スクリプトの作成

## 関連Issue
- #194: 諸々調整

## 不明点と質問（Inception Phase中に記録）

（なし - Issue #194に具体的な修正内容が明記されているため）

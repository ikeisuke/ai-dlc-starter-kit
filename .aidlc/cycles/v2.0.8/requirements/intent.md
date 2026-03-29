# Intent（開発意図）

## プロジェクト名
ai-dlc-starter-kit

## 開発の目的
バグ修正と主要4アクション（inception/construction/operations/setup）の総点検を行い、ステップファイルの記述と実動作の乖離を検出・修正する。v2.0.7までの開発で蓄積した不整合や未対応バグを解消し、AI-DLCの実行品質を向上させる。

## ターゲットユーザー
AI-DLCスターターキットを利用する開発者（自身を含む）

## ビジネス価値
- ステップファイルと実動作の乖離を解消することで、AIエージェントの実行精度が向上する
- 既知バグの修正により、日常的な開発フローでのエラー・手戻りが減少する
- 総点検による品質基盤の確立で、今後のサイクルでの開発効率が向上する

## スコープ

### 含まれるもの
1. **バグ修正**（#463〜#466）:
   - #466: squash-unit.sh の --dry-run 時に --message 必須チェックをスキップする
   - #465: aidlc-setup/aidlc-migrate スクリプトの bootstrap.sh 依存脱却
   - #464: /aidlc help (h) アクションの追加
   - #463: cleanup trap causes migrate-config.sh --dry-run to exit with unbound variable
2. **主要アクション総点検**:
   - inception: ステップファイル（steps/inception/）の記述と実動作の突き合わせ
   - construction: ステップファイル（steps/construction/）の記述と実動作の突き合わせ
   - operations: ステップファイル（steps/operations/）の記述と実動作の突き合わせ
   - setup: aidlc-setupスキルの記述と実動作の突き合わせ
   - 対象: ステップファイル（.md）+ 関連スクリプト（.sh）
   - 方針: 重大な乖離はこのサイクルで修正、軽微なものはIssue化
3. **ガイドライン整備**:
   - bootstrap.sh脱却の知見をスキルスクリプト設計ガイドラインとして文書化

### 含まれないもの
- express/feedback/migrateアクションの総点検
- 新機能追加（#443以前のバックログ）
- テンプレート・ガイドの総点検（ステップファイルからの参照で問題が見つかった場合のみ対応）

## 成功基準
- #463〜#466の全Issueがクローズされている
- inception/construction/operations/setupの各アクションについて、ステップファイルと実動作の乖離が洗い出され、重大なものが修正されている
- 軽微な乖離がIssueとしてバックログに登録されている

## 期限とマイルストーン
- 1サイクル内で完了（パッチリリース）

## 制約事項

### パス別操作範囲
| 区分 | 対象パス | 許可操作 |
|------|---------|---------|
| 修正対象 | `skills/aidlc/**`, `skills/aidlc-setup/**` | read, write, create |
| 参照対象 | `docs/aidlc/**`, テンプレート, ガイド | read のみ（ただし総点検で重大な乖離を発見した場合、参照先のテンプレート・ガイドも修正対象に含む） |
| 非対象 | `docs/aidlc/**` への直接write | 禁止（Operations Phase の rsync で反映） |

- 総点検は網羅性より実効性を重視し、主要フローの動作確認を優先する

## 不明点と質問（Inception Phase中に記録）

[Question] アクション総点検の対象範囲は？
[Answer] inception/construction/operations/setupの4アクション。ステップファイル + スクリプトが対象。express/feedback/migrateはスコープ外。

[Question] 総点検で発見した乖離の対応方針は？
[Answer] 検出＋重要なもののみ修正。軽微なものはIssue化。

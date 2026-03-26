# レビューサマリ: エラーハンドリング方針統一

## 基本情報

- **サイクル**: v1.21.2
- **フェーズ**: Construction
- **対象**: Unit 002 - エラーハンドリング方針統一

---

## Set 1: 2026-03-14 10:29:36

- **レビュー種別**: architecture
- **使用ツール**: codex
- **反復回数**: 5
- **結論**: 指摘0件

### 指摘一覧

| # | 重要度 | 内容 | 対応 |
|---|--------|------|------|
| 1 | 中 | unit-002-plan.md のエラーAPI契約仕様 - 出力形式・パース規則・終了コードポリシーが未定義で消費層が安定してパースできない | 修正済み（unit-002-plan.md: エラーAPI契約仕様セクションを追加し出力形式・パース規則・レイヤー責務を明記） |
| 2 | 中 | unit-002-plan.md の依存方向 - validate.shへの依存パスが未記載で実装時にsource先が不明 | 修正済み（unit-002-plan.md: validate.shのパスを`prompts/package/lib/validate.sh`と明記） |
| 3 | 中 | unit-002-plan.md のレイヤー責務 - 出力整形層・呼び出し層・消費層の責務分離が不明確 | 修正済み（unit-002-plan.md: レイヤー責務テーブルを追加） |
| 4 | 低 | unit-002-plan.md のステータスAPI例外ポリシー - check-gh-status.sh等の対象外基準が未定義 | 修正済み（unit-002-plan.md: ステータスAPIとの棲み分けテーブルと対象外基準を追記） |
| 5 | 中 | logical_design.md のsetup-branch.sh変更仕様 - output()関数を変更する方針が既存プロンプトのパースを壊す | 修正済み（logical_design.md: output()関数は変更せずerror_codeフィールド追加方式に変更） |
| 6 | 中 | domain_model.md のemit_errorメッセージ契約 - 送信側と受信側で必須/任意が未整理 | 修正済み（domain_model.md: 送信契約（message必須）と受信互換（message任意）を分離定義） |
| 7 | 低 | domain_model.md のread-config.sh終了コード - 入力バリデーションエラーにexit 2を使用し終了コードポリシーと不整合 | 修正済み（domain_model.md: read-config.shの入力系エラーの終了コードを2→1に修正） |
| 8 | 低 | logical_design.md のパース規則セクション - エラーAPI単一系統のみ記載でステータスAPI+error_code系統が欠落 | 修正済み（logical_design.md: パース規則を2系統（エラーAPI/ステータスAPI+error_code）に分離し適用対象スクリプトを明記） |
| 9 | 低 | logical_design.md のアーキテクチャパターン記述 - 「エラーAPI契約のみに依存」がステータスAPI+error_code契約と矛盾 | 修正済み（logical_design.md L11: 「原則としてエラーAPI契約に依存し、構造化出力スクリプトに対してはステータスAPI+error_code契約にも依存する」に修正） |

指摘なし（最終ラウンド）

---

## Set 2: 2026-03-14 11:45:00

- **レビュー種別**: code
- **使用ツール**: codex
- **反復回数**: 4
- **結論**: 指摘0件

### 指摘一覧

| # | 重要度 | 内容 | 対応 |
|---|--------|------|------|
| 1 | 高 | 複数スクリプトの終了コードポリシー違反 - 外部依存/操作エラー（git操作失敗、gh未インストール等）がexit 1で返されているがポリシーではexit 2 | 修正済み（setup-branch.sh, check-open-issues.sh, cycle-label.sh, label-cycle-issues.sh, validate-git.sh: 操作エラーをexit 2/return 2に修正） |
| 2 | 高 | read-config.sh get_value()のinvalid-key-formatがreturn 2だが入力バリデーションなのでreturn 1が妥当 | 設計判断維持（get_value()の内部契約0=存在/1=不在/2=エラーを維持。return 1にすると「キー不在」と区別不能になり--defaultで成功してしまうバグを招く） |
| 3 | 中 | setup-branch.sh usage()が自由テキスト出力 - status/error_codeパース前提の呼び出し側で扱いづらい | 修正済み（setup-branch.sh: usage()をoutput()経由の構造化出力に変更） |
| 4 | 低 | write-history.sh, validate-git.sh のヘッダコメントが旧形式error:<理由>のまま | 修正済み（error:<code>:<message>形式に更新） |
| 5 | 低 | テストカバレッジ不足 - emit_error仕様のテストがない | 修正済み（test_emit_error.sh追加: 7テストケース全パス） |
| 6 | 中 | validate-git.sh run_all()のエラー終了コードがreturn 1のまま | 修正済み（validate-git.sh: run_all()内のreturn 1をreturn 2に修正） |
| 7 | 低 | check-open-issues.sh ヘッダコメントの終了コード説明が実装と不一致 | 修正済み（exit 1/exit 2の区分を反映するよう更新） |

指摘なし（最終ラウンド）

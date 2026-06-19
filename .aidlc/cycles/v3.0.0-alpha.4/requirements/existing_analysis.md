# 既存コードベース分析

対象: `skills/aidlc-v3/`（AI-DLC v3 本体スクリプト群）。振り返り #733（frontmatter/JSON パース安全境界の共有ライブラリ集約）に向けた現状把握。

## ディレクトリ構造・ファイル構成

```
skills/aidlc-v3/
  ├── SKILL.md                 (skill マニフェスト / ルーティング)
  ├── scripts/
  │   ├── state-init.sh        (cycle state 初期化 / create-only / jq -n)
  │   ├── state-read.sh        (state.json 読取 / jq getpath)
  │   ├── state-validate.sh    (state.json schema 検証 / SoT / schema_version 互換)
  │   ├── state-write.sh       (state.json atomic 更新 / jq setpath)
  │   ├── work-item-validate.sh(work item frontmatter 検証)
  │   ├── work-item-next.sh    (依存解決・次 item 選定)
  │   ├── work-item-status.sh  (status 行読取・書込)
  │   └── tests/               (test-state-scripts / test-work-item-next / test-define-flow / test-develop-flow / test-activation)
  ├── steps/                   (define.md / develop.md / status.md)
  └── templates/               (work-item.md / intent.md / journal.md)
```

- ファイル総数: 約19。`scripts/lib/` は**存在しない**（共有ライブラリ未整備）。
- テストは自己完結型 bash ハーネス（bats 不使用 / jq・git のみ前提）。

## アーキテクチャ・パターン

- **行指向 frontmatter parse**: frontmatter は素の YAML parser ではなく、delimiter `---` を境界に `grep`/`sed`/`awk` で行単位抽出（根拠: work-item-validate.sh L50-65, L122-128）。
- **JSON は jq に一本化**: state-*.sh はすべて jq で読み書き。schema 検証は state-validate.sh が SoT（schema_version 互換判定を集約 / Unit 004 #731）。
- **終了コード規約統一**: 0=成功/valid, 1=バリデーションエラー, 2=システムエラー。
- **dynamic scope namespace 化**: 関数内部 local に関数固有プレフィックス（`_rs_`/`_wis_`/`_wid_`/`_rsv_` 等）。
- **malformed guard**: 閉じ `---` 不在時にファイル末尾まで frontmatter と誤認しないよう awk ガード（codex premerge R7 P2 対応）。

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | bash（GNU 4.0+ / macOS 3.2 互換考慮 / `set -euo pipefail`） | 全 `scripts/*.sh` シェバン |
| frontmatter 操作 | grep / sed / awk / tr（パーサーライブラリなし） | work-item-*.sh |
| JSON 操作 | jq のみ（yq/dasel 不使用） | state-*.sh |
| 依存コマンド | jq, grep, sed, awk, tr, printf, date, mktemp, git | 各スクリプト |
| CI | marketplace.json 登録確認のみ（test-activation.sh / Unit 005） | scripts/tests/test-activation.sh |

## 依存関係

- **共有 parser なし**: 各スクリプトが個別にパースロジックを保持（source 経由の共通化ゼロ）。
- **frontmatter スカラー抽出の重複（高）**: `read_scalar()`（validate L50-65, enum 厳格）/ `wi_scalar()`（next L60-68, enum なし）/ `read_status_value()`（status L60-69, status 専用）が **同一 regex パターン** で複製。
- **dependencies 配列パースの重複（高）**: validate.sh L186-210 と next.sh `wi_deps()` L76-97 がほぼ同一（`[id1, id2]` CSV 形式 / IFS=',' split / 要素 regex `^([A-Za-z0-9]+|"[A-Za-z0-9]+")$`）。
- **frontmatter ブロック抽出 + malformed guard の重複（高）**: validate / next / status の3箇所に同一 awk。
- **集約済み**: JSON schema_version 互換判定は state-validate.sh の単一 SoT。
- 循環依存: なし（source 連鎖が存在しないため）。

## 特記事項

- **#733 P4（CycleResolver / T6）の所在不明**: v3 本体には gitlog 推定ロジックが**存在せず**、cycle は state.json の `current_cycle`（明示指定）に一本化済み（data-model.md RFC DG-6）。P4 で「gitlog から誤った cycle（v2.6.6）を返した」CycleResolver は **v3 本体ではない可能性が高い**（framework 側 `skills/aidlc/` の retrospective/operations ツール等）。T6 のスコープ/対象コンポーネントは Intent 対話で要確認。
- **doctor コマンドは未実装（予約）**: T4 の機械検出を doctor に載せる場合は新設が必要。CI 側は現状 activation 確認のみ。
- **テスト fixture 再利用可能**: `put_wi()`（frontmatter）/ `make_valid_state()`（JSON）が既存。共有 parser の conformance fixture（T2'）はこの形式で統一可能。
- **未実装の予約フロー**: develop normal/risky, release, reflect, doctor。パース面が今後さらに増えるため、共有化の最適タイミングは「これらの実装前」（#733 T1 の主張と一致）。

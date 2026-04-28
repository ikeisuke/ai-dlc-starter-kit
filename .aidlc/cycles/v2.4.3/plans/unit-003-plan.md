# Unit 003 実装計画: migrate-backlog.sh の UTF-8 対応（#610）

## 対象

- Unit 定義: `.aidlc/cycles/v2.4.3/story-artifacts/units/003-migrate-backlog-utf8-fix.md`
- 対象 Issue: #610（Closes 対象。サイクル PR でクローズ）
- 主対象ファイル:
  - `skills/aidlc-setup/scripts/migrate-backlog.sh`（`generate_slug()` 内 Perl invocation。L75 周辺）
- 整合確認のみ（変更しない可能性が高い）:
  - `skills/aidlc-setup/scripts/migrate-backlog.sh` 内の他のパイプライン処理（`tr` / `sed` / `cut`）
  - `skills/aidlc-setup/` 配下の DEPRECATED マーク文言（維持確認）

## スコープ

Issue #610 の修正案（Issue 本文「修正案」セクション、Unit 定義「責務」セクション）に整合させる:

- **`generate_slug()` の Perl invocation を UTF-8 化**: `perl -pe 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g'` → `perl -CSD -Mutf8 -pe 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g'`
  - `-CSD`: STDIN/STDOUT/STDERR を UTF-8 として扱う（IO 層）
  - `-Mutf8`: Perl ソース（ここではコマンドラインの正規表現リテラル）を UTF-8 として解釈する（regex 層）
  - 両方併用が必須（`-CSD` のみでは regex リテラルが Latin-1 解釈となり不十分）
- **動作確認 3 ケース**（Unit 定義「責務」必須ケース、fullwidth カッコ等で UTF-8 不正バイト発生する問題ケース）:
  - `テスト分離の改善（並列テスト対応）` → `テスト分離の改善並列テスト対応`（fullwidth カッコのみ除去、後半保持）
  - `SQLite vnode エラー（DB差し替え時の競合アクセス）` → `sqlite-vnode-エラーdb差し替え時の競合アクセス`
  - `AgencyConfig DDD責務整理` → `agencyconfig-ddd責務整理`
- **Issue 本文 4 ケース目（参考）**: `Cloudflare Worker GTFS ダウンロード最適化` → `cloudflare-worker-gtfs-ダウンロード最適化`
  - **Unit スコープからの除外理由**: fullwidth カッコ等を含まないため UTF-8 不正バイトを発生させない。修正前でも `Illegal byte sequence` は出ない（後半が切れるが規定の 50 文字切り詰め範囲外）。問題ケースではないため、Unit 定義「責務」の必須ケース（3 件）からは除外
  - **扱い**: 検証-A 実行表に「参考行」として併記し、修正前後で同じ出力（`cloudflare-worker-gtfs-ダウンロード最適化` の前後同等）になる回帰確認に活用する。完了条件のチェック対象には含めない
- **`--dry-run` モードでの同等動作確認**: 実体ファイル変更を伴わない `--dry-run` 実行で同じ slug が生成されることを確認
- **DEPRECATED マークは維持**: ファイルヘッダ・関連コメントの DEPRECATED 表記は変更しない（Unit 定義「境界」）

### スコープ外（Unit 定義「境界」由来）

- `migrate-backlog.sh` 自体の DEPRECATED 解除や全面リライト
- 削除タイミングの見直し（必要なら別 Issue 化）
- 他のスクリプトでの UTF-8 / locale 対応

## 実装方針

### Phase 1（設計）

#### ドメインモデル設計

slug 生成パイプラインの概念モデルを以下で整理する（小規模）:

- エンティティ:
  - `BacklogTitle`（入力タイトル文字列、UTF-8 多言語混在）
  - `SlugGenerationPipeline`（`tr` → `perl regex filter` → `tr` → `sed` → `cut` の合成パイプ）
    - 段階: `lowercase` / `regex_filter` / `space_to_hyphen` / `dedup_hyphen` / `trim_hyphen` / `truncate`
    - 不変条件: 各段階は前段の出力を入力として受ける単方向パイプライン。文字エンコーディングは全段階で UTF-8 を維持する必要がある
  - `RegexFilterStage`（`generate_slug()` 内の `perl -pe ...` を表現）
    - 振る舞い: 正規表現 `[^a-z0-9一-龯ぁ-んァ-ヶー ]` で許容文字以外を削除
    - **エンコーディング契約**: STDIN/STDOUT は UTF-8（`-CSD`）、regex リテラルも UTF-8 として解釈（`-Mutf8`）。両者揃わない場合はバイト単位処理にフォールバックし、マルチバイト境界を分断する
- ルール:
  - regex リテラルの日本語範囲（`一-龯` / `ぁ-ん` / `ァ-ヶー`）が Unicode コードポイント範囲として解釈されるためには Perl の utf8 プラグマが必須
  - 範囲外の UTF-8 文字（fullwidth カッコ等）は**削除対象**であり、`-CSD -Mutf8` 環境では UTF-8 シーケンスごと削除される
  - 範囲外文字を削除した結果残った UTF-8 シーケンスは整形性を保つ
- イベント:
  - `SlugGenerated`（パイプライン完走、最終 slug 確定）
  - `EncodingViolation`（regex 段階で不正バイト列が発生 → 後段 `tr` が `Illegal byte sequence` を出力。修正前環境で観測される）

#### 論理設計

1. **`migrate-backlog.sh` 修正内容**（実質 1 行）:
   - 対象行: `generate_slug()` 関数内の `perl -pe 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g'`
   - 変更後: `perl -CSD -Mutf8 -pe 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g'`
   - 行番号の確認: 計画作成時点で L75 を確認済（実装時に再確認、design.md に最終行番号を記録）

2. **副作用と互換性**:
   - 既存の slug 生成ロジック（許容文字範囲・トリム順序・先頭/末尾ハイフン除去・50 文字切り詰め）は不変
   - macOS / Linux の Perl 5.x 標準機能のみを使用するため、ランタイム要件は変化なし
   - `LANG=ja_JP.UTF-8` 以外のロケールでも `-CSD -Mutf8` の指定により regex/IO の UTF-8 扱いが保証される（環境ロケール非依存化）
   - DEPRECATED マークと将来削除タイミングは変更しない

3. **検証手段の選択**（Phase 1 設計レビューで A/B 確定。**既定: 検証-A**）:
   - **検証-A（手動コマンド実行表、既定）**: design.md に修正前後の `generate_slug()` 相当パイプラインに 3 ケースを通した実行結果を表で記録。最小実装、文書整合性レビューと整合
   - **検証-B（bats テスト追加、明示的判断時のみ採用）**: `tests/` 配下に bats テストを新規追加し、`generate_slug()` を呼び出すケースを 3 件追加
   - **検証-B 採用条件（全て満たす場合のみ）**:
     1. `find tests/ skills/aidlc-setup/tests/ -name '*.bats' 2>/dev/null` で 1 件以上の bats ファイルが存在
     2. `grep -lE 'bats|run-bats' .github/workflows/*.yml 2>/dev/null` で CI ワークフロー内に bats 実行ステップが定義されている（CI 連動の客観的判定条件）
     3. 既存 bats テストが `migrate-backlog.sh` または `aidlc-setup/scripts/` を対象としている、または対象に含めても 1 セッション内で完結する小規模追加で済む
   - **判定**: 上記 1〜3 のすべて満たす場合のみ検証-B を採用、それ以外は検証-A（既定）。**優先候補は検証-A**

4. **A/B 確定結果の記録先**:
   - 検証-A/B の確定結果は design.md（論理設計成果物）の「設計判断記録」セクションに明記
   - `history/construction_unit03.md` の Phase 1 設計レビュー完了エントリで決定を要約参照

### Phase 2（実装）

#### コード生成

`skills/aidlc-setup/scripts/migrate-backlog.sh` の `generate_slug()` 関数の Perl invocation のみを修正:

```diff
-        perl -pe 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g' | \
+        perl -CSD -Mutf8 -pe 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g' | \
```

他の行・他の関数・DEPRECATED マークは変更しない。

#### テスト生成・実行

検証-A 採用時:

- design.md または history に以下のテーブルを記録:

  | 入力タイトル | 修正前 slug | 修正後 slug（期待値） | 修正後 slug（実測） | 備考 |
  |-------------|------------|---------------------|---------------------|------|
  | `テスト分離の改善（並列テスト対応）` | `テスト分離の改善`（エラー） | `テスト分離の改善並列テスト対応` | （実行記録） | fullwidth カッコ U+FF08/U+FF09 |
  | `SQLite vnode エラー（DB差し替え時の競合アクセス）` | `sqlite-vnode-エラー`（エラー） | `sqlite-vnode-エラーdb差し替え時の競合アクセス` | （実行記録） | 全角＋半角混在 |
  | `AgencyConfig DDD責務整理` | `agencyconfig-ddd`（エラーは無いが切れる） | `agencyconfig-ddd責務整理` | （実行記録） | 半角主体＋日本語末尾 |

- `--dry-run` モードでも同じ slug が出力されることを別途確認し、結果を記録

検証-B 採用時:

- `tests/` 配下に bats テストファイルを新規作成し、`generate_slug` 相当の関数を source または再現してケース 3 件 + `--dry-run` 1 件を実装

#### 設計AIレビュー / コードAIレビュー / 統合AIレビュー

- `review_mode=required`、`tools=['codex']` のため、`steps/common/review-flow.md` および `steps/common/review-routing.md` に従って実施
- 計画承認前 / 設計レビュー（Phase 1 完了時、`depth_level=standard` のため必須）/ コード生成後（コードAIレビュー）/ 統合（テスト完了後）の 4 タイミングで実施
  - 計画承認前は本計画ファイル作成時に実施（履歴に記録）
- フォールバック条件（codex usage limit 等）に該当した場合はパス 2（self-review）に降りる（v2.4.3 Unit 002 で正式統合された `SelfBackcompatShim` の挙動）

### 完了処理（Phase 3）

`steps/construction/04-completion.md` に従う。

## 完了条件チェックリスト

Unit 定義「責務」セクションと Issue #610 受け入れ基準から抽出。

### Unit 定義「責務」由来

- [ ] `skills/aidlc-setup/scripts/migrate-backlog.sh` の `generate_slug()` 関数の Perl invocation を `-CSD -Mutf8` 化
- [ ] 動作確認 3 ケースを実施し結果を記録: `テスト分離の改善（並列テスト対応）` / `SQLite vnode エラー（DB差し替え時の競合アクセス）` / `AgencyConfig DDD責務整理`
- [ ] `--dry-run` モードでの同等動作を確認
- [ ] DEPRECATED マークが維持されていること（変更しないことの確認）

### Issue #610 受け入れ基準（本文「修正案」「検証結果（修正後）」セクション由来）

- [ ] `perl -CSD -Mutf8 -pe ...` のコマンドラインに変更されている
- [ ] fullwidth カッコ含むタイトルでも slug が後半まで保持される
- [ ] `tr: Illegal byte sequence` が発生しなくなる
- [ ] Issue 本文の検証結果テーブル（4 ケース中、必須 3 ケース + 参考 1 ケース）と一致する出力が得られる
- [ ] ロケール非依存化検証（**Perl 段階の効果確認に再定義** / Phase 2 で発見された `cut -c1-50` のロケール依存は別 Issue #615 として OUT_OF_SCOPE 化）: `LANG=C` 環境でも Perl regex 段階で日本語が分断されず・stderr エラーなしで slug の **本体（50 バイト以内範囲）** が生成される。50 バイト超のケースで末尾文字化けが発生する `cut -c1-50` 問題は Issue #615 にバックログ登録済み

### Construction Phase 共通

- [ ] 設計成果物（domain_model.md / logical_design.md または同等の集約 design.md）が作成されている
- [ ] 計画 AI レビュー / 設計 AI レビュー / コード AI レビュー / 統合 AI レビューの 4 タイミングが実施され、`history/construction_unit03.md` に記録されている
- [ ] 意思決定記録の追加要否を確認し、対象あれば `inception/decisions.md` または同等の記録先に追記している
- [ ] Unit 定義ファイル `003-migrate-backlog-utf8-fix.md` の実装状態を「完了」に更新（開始日 / 完了日記入）
- [ ] markdownlint チェックを通過（`markdown_lint=true`）
- [ ] Unit 中間コミットが squash されている（`squash_enabled=true`）

## リスクと注意点

- **環境依存リスク**: `-CSD -Mutf8` は Perl 5.x 標準機能であり、macOS / Linux 共通で動作する。BSD / GNU 差は無い
- **regex 範囲文字の境界**: `一-龯` は CJK 統合漢字の主要範囲（既存仕様維持）。具体的なコードポイント範囲（U+4E00〜U+9FA5 / U+9FAF / U+9FFF のいずれか）は Phase 1 設計時に Perl での実測（`perl -CSD -Mutf8 -e 'printf "U+%04X\n", ord("龯")'` 等）で確定し design.md に記録する。CJK 拡張 A/B 範囲は対象外（既存仕様維持）
- **DEPRECATED スクリプトの修正**: ユーザーが v2.0.0 リリース前に migrate-backlog.sh を使う可能性があるため、最小修正で UTF-8 を成立させる方針（Issue 本文「補足」と整合）
- **検証パイプラインの再現**: Issue 本文の手動コマンド再現と `migrate-backlog.sh:generate_slug()` 内パイプラインで `tr '[:upper:]' '[:lower:]'` の段階差が生じない（順序同一）
- **ロケール非依存化の検証**: `LANG=C` / `LANG=POSIX` 環境では IO 層がデフォルトでバイトオリエンテッドになるが、`-CSD` で UTF-8 IO に強制できる。検証-A 実行表または Phase 2 動作確認で `LANG=C` 相当の手動コマンドを 1 ケース実行し、Perl regex 段階で日本語が分断されないこと・stderr エラーが出ないことを確認する。**Phase 2 で発見された副次問題**: `cut -c1-50` 段階が `LANG=C` 等で BSD/POSIX 挙動によりバイト単位切り詰めとなり、UTF-8 多バイト境界を分断するケースがある（50 バイト超入力時）。Issue #615 として GitHub バックログ登録済み（OUT_OF_SCOPE、本 Unit のスコープは Perl invocation の UTF-8 化のみ、Intent §「成功基準」#610 と整合）

## 履歴記録方針

- `history/construction_unit03.md` を新規作成し、以下のタイミングで記録:
  - Phase 1 開始 / 設計 AI レビュー完了 / 設計承認
  - Phase 2 開始 / コード AI レビュー完了 / テスト実行完了 / 統合 AI レビュー完了 / 実装承認
  - 完了処理開始 / Unit 完了
- 履歴粒度は `history_level=standard` 準拠

## 参考

- Issue 本文: `gh issue view 610` で取得済み（修正案・検証結果テーブル含む）
- 関連サイクル: v2.4.2（DEPRECATED マーク追加サイクル、変更しない）
- v2.4.3 並列実行 Units: 001 / 002（完了）/ 004（並列、依存なし）

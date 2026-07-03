# ユーザーストーリー

対象: AI-DLC v3 本体（`skills/aidlc-v3/`）の frontmatter パース安全境界の構造改善（振り返り #733 / v3.0.0-alpha.4）。

## Epic: frontmatter パース安全境界の共有ライブラリ集約

### ストーリー 1: 共有 frontmatter parser ライブラリへの集約（T1）

**優先順位**: Must-have

As a v3 本体の保守者
I want to frontmatter のスカラー抽出・dependencies 配列パース・frontmatter ブロック抽出 + malformed guard を `skills/aidlc-v3/scripts/lib/` の単一共有ライブラリに集約し、個別スクリプトでの構造解釈を禁止規約として明文化したい
So that 寛容な line ベース regex が malformed YAML を通すバリデーションクラスの反復再発を、重複実装の解消と境界の一元化によって構造的に断てる

**受け入れ基準**:
- [ ] `skills/aidlc-v3/scripts/lib/` に共有 frontmatter parser ライブラリ（例: `frontmatter.sh`）が新設され、スカラー抽出 / dependencies 配列パース / frontmatter ブロック抽出 + malformed guard / 拒否理由の標準化を提供する関数を公開している
- [ ] `work-item-validate.sh` / `work-item-next.sh` / `work-item-status.sh` が個別パース実装（`read_scalar()` / `wi_scalar()` / `read_status_value()` / `wi_deps()` / インライン awk）を撤去し、共有ライブラリを `source` して呼び出している
- [ ] 共有ライブラリは enum 検証の要否（validate=厳格 / next=最小）を引数または別関数で表現でき、3 consumer の既存の受理/拒否挙動を変えずに置換できる
- [ ] 共有 parser API の責務境界（構造抽出・型/必須キー/範囲検証・拒否理由の標準化）が文書化され、個別 consumer スクリプトでの frontmatter 構造解釈に `grep`/`sed`/`awk`/permissive `jq` を使うことを禁止する規約が明記されている
- [ ] `state-*.sh`（JSON / jq 集約済み）は本ストーリーの変更対象外であることが明記されている
- [ ] （異常系）閉じ `---` 不在の malformed frontmatter は共有ライブラリが従来どおり拒否（exit 1）する

**技術的考慮事項**:
bash 3.2/4.0+ 互換、`set -euo pipefail`、dynamic scope namespace 化（関数固有プレフィックス）を踏襲。`printf -v` result-out を使う場合は CLAUDE.md の local 命名規約に従う。

---

### ストーリー 2: conformance test suite による受理/拒否境界の固定（T2'）

**優先順位**: Must-have

As a v3 本体の保守者
I want to 共有 parser の受理ケース・拒否ケースを仕様 fixture として固定し、validate / next / status が同一 fixture を通る conformance test suite を持ちたい
So that 集約リファクタが既存の境界を壊していないことを実行可能契約として保証でき、将来 parser を触る変更が境界を破ったら即座にテストで検出できる

**受け入れ基準**:
- [ ] `skills/aidlc-v3/scripts/tests/` に共有 parser の conformance test（例: `test-frontmatter-parser.sh`）が追加され、自己完結型 bash ハーネス形式（既存 `assert_rc` / `assert_out` 等）で実装されている
- [ ] 受理ケース（quoted/unquoted id、enum 値、空 dependencies、複数要素 dependencies 等）と拒否ケース（閉じ `---` 不在、不正 enum、malformed 配列、片側引用符、#733 で検出された既知 malformed クラス）の双方を fixture として固定している
- [ ] validate / next / status の 3 consumer が同一 fixture セットに対して期待どおりの受理/拒否を返すことを検証している
- [ ] Unit 完了条件として「新たに構造データを読む場合、共有 parser を使い conformance fixture にケースを追加済みであること」が文書（規約）に組み込まれている
- [ ] （異常系）既知の malformed / partial-parse クラスは拒否 fixture として明示的に列挙され、拒否側に倒ることをテストが保証する

**技術的考慮事項**:
既存 `put_wi()` の frontmatter fixture 生成形式を再利用。互換維持対象と意図的な拒否強化を fixture コメントで区別する。

---

### ストーリー 3: 禁止パースパターンの CI 機械検出（T4）

**優先順位**: Must-have

As a v3 本体の保守者
I want to 個別 consumer スクリプトに frontmatter の構造解釈の禁止パターン（`grep`/`sed`/`awk`/permissive `jq`）が混入していないかを機械検出する CI チェックを持ちたい
So that 人手レビューに頼らず、共有境界からの逸脱（個別スクリプトでのローカルパース再実装）を自動で弾き、#733 の P3（per-Unit レビューの横展開見逃し）を構造的に防げる

**受け入れ基準**:
- [ ] `skills/aidlc-v3/scripts/`（`lib/` 配下と `tests/` を除く個別 consumer スクリプト）を走査し、frontmatter 構造解釈の禁止パターンを検出する独立スクリプト（例: `scripts/check-frontmatter-parse-guard.sh`）が追加されている
- [ ] 検出スクリプトは allowlist として `lib/`（共有 parser 本体）と `tests/`（fixture）を除外する
- [ ] 禁止する `jq` coerce の例（`// 既定値` による欠損補完、`?` による型エラー抑制、暗黙型変換）を検出対象に含む
- [ ] 違反検出時は exit 1 で違反箇所（ファイル:行）を報告し、違反なし時は exit 0 を返す（終了コード規約: 0=合格, 1=違反, 2=システムエラー）
- [ ] GitHub Actions ワークフローのジョブとして検出スクリプトが実行され、PR で違反を CI が fail させる
- [ ] （異常系）共有ライブラリ集約後の 3 consumer は本チェックに合格する（移行が完了していることを CI が裏付ける）

**技術的考慮事項**:
ドッグフーディング特殊処理を本体に埋めない原則に従い、opt-in シグナル（検出スクリプトの存在）で動作。検出は false positive を抑えるためコメント行・文字列リテラル内の誤検出に配慮する。

---

### ストーリー 4: CycleResolver 明示指定優先の回帰テスト（T6）

**優先順位**: Should-have

As a v3 本体の保守者
I want to v3 の cycle 解決入口が `state.json` の `current_cycle`（明示指定）を最優先し、git 履歴・周辺ファイル名・ディレクトリ走査順に影響されないことを固定する回帰テストを持ちたい
So that #733 の P4（CycleResolver が明示指定を無視し gitlog から誤った cycle を返した）クラスが v3 本体で再発しないことを保証できる（v3 は既に明示指定一本化済みのため、その仕様を回帰テストで固定する）

**受け入れ基準**:
- [ ] `skills/aidlc-v3/scripts/tests/` に cycle 解決の回帰テスト（例: `test-cycle-resolution.sh`、または既存 `test-state-scripts.sh` への追加）が存在する
- [ ] テストは「`state.json` の `current_cycle` が設定されている場合、その値が cycle として解決される」ことを検証する
- [ ] テストは「git 履歴（直近 commit メッセージ）や周辺ファイル名が `current_cycle` と異なっても、解決結果が `current_cycle` に影響されない」ことを検証する（gitlog 推定への非依存）
- [ ] framework 側（`skills/aidlc/`）の CycleResolver は本ストーリーの変更対象外であることが明記されている
- [ ] （異常系）`current_cycle` が未設定/欠損の state.json に対する解決経路の振る舞い（拒否 or 明示エラー）が既存仕様どおりであることをテストが確認する

**技術的考慮事項**:
v3 の cycle 解決入口は `state-read.sh` の `current_cycle` 読取。既存 `make_valid_state()` fixture を再利用し、git 履歴非依存を mktemp サンドボックスで検証する。

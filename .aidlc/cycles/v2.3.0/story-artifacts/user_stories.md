# ユーザーストーリー

## Epic: AI-DLC コンテキスト圧縮 Tier 2/3（インデックス集約型）

本エピックは Issue #519 の完遂を目的とし、S4alt プログレッシブロードの「インデックス集約型（案D）」を実装する。副次的に #553 のコンパクション復帰誤判定バグを根本解決する。

### 検証用サンプルの定義

本エピック全体で使用する共通の検証サンプルを以下に固定する。受け入れ基準内で「検証サンプル A」と参照する場合、以下を指す。

- **検証サンプル A**: 空の `.aidlc/cycles/vTEST/` ディレクトリからサイクル開始し、Intent → ストーリー → Unit 定義 → Inception 完了処理までを semi_auto モードで実行するシナリオ
- **比較基準**: v2.2.3 タグ（コミット `d88b0074`）の同一サンプル実行結果を「期待値」とし、以下の**安定項目のみ**を比較対象とする。タイムスタンプ・実行ID・セッションID・コミットハッシュ等の可変項目は比較から除外する:
  - 生成ファイルのパス一覧（ファイル名のみ、生成順序は問わない）
  - 各成果物ファイルの必須セクション見出し（`## 開発の目的` 等の H2/H3 見出しレベル）
  - `progress.md` の各ステップの完了マーク（「完了」「未着手」「スキップ」等のラベル）
  - `history/inception.md` に追記されたエントリのステップ名集合（追記行数ではなく、記録されたステップ名の集合で比較）
  - `decisions.md` の意思決定IDの連番（DR-001, DR-002 等）と対象要件ラベル
- **計測コマンド**: `/tmp/anthropic-venv/bin/python3 -c "import tiktoken; ..."` による `cl100k_base` トークン数計測。計測対象は SKILL.md + rules-core.md + preflight.md + session-continuity.md + 各フェーズのステップファイル全て（インデックス化後は、初回ロードに含まれるファイル群）

---

### ストーリー 1: Inception フェーズインデックスによる初回ロード削減

**優先順位**: Must-have

As a AI-DLC 利用開発者
I want to Inception Phase 開始時に読み込むファイルサイズが 15,000 tok 以下になる
So that セッション初期からコンテキストウィンドウに余裕を持たせ、中盤のコンパクションリスクを低減できる

**受け入れ基準**:
- [ ] `steps/inception/` 配下にフェーズインデックスファイル（例: `index.md`）が存在し、以下3点を集約している: (1) 全ステップの目次・概要、(2) ステップ間分岐ロジック、(3) 現在位置判定チェックポイント
- [ ] `SKILL.md` の共通初期化フロー（ステップ4: フェーズステップ読み込み）が更新され、Inception Phase 開始時に読み込む対象がフェーズインデックスファイルのみになっている
- [ ] **【計測】** 計測コマンドで Inception 初回ロードを計測した結果が **15,000 tok 以下**
- [ ] **【回帰検証】** 検証サンプル A を semi_auto モードで実行した結果、以下が v2.2.3 と一致する:
  - 生成ファイルのパス一覧（diff で差分ゼロ）
  - 各成果物ファイルの必須セクション見出し（Intent の `## 開発の目的` 等）
  - `inception/progress.md` の各ステップが「完了」マークになっている
  - `history/inception.md` にステップ完了ごとのエントリが追記されている
- [ ] 既存ステップファイル（`01-setup.md` 〜 `05-completion.md`）はインデックス側に集約された分岐・判定が重複していない（grep で確認）

---

### ストーリー 2: Construction フェーズインデックス化

**優先順位**: Must-have

As a AI-DLC 利用開発者
I want to Construction Phase 開始時の初回ロードがインデックス集約型で最適化されている
So that Unit 実装の複数ループ中にコンパクションリスクが高まらず、長期 Unit でも集中できる

**受け入れ基準**:
- [ ] `steps/construction/` 配下にフェーズインデックスファイルが存在し、ストーリー1と同じ3点（目次・分岐・判定チェックポイント）を集約している
- [ ] `SKILL.md` の引数ルーティング（`cycle/*` ブランチ判定および `action=construction`）がインデックスファイル読み込みを指すよう更新されている
- [ ] **【計測】** 計測コマンドで Construction 初回ロードを計測した結果が **17,980 tok 以下**（v2.2.3 ベースライン維持）
- [ ] **【回帰検証】** 最低1つの Unit（例: サンプル Unit「dummy-feature」）を Phase 1（設計）→ Phase 2（実装）→ 完了処理まで semi_auto モードで実行した結果、以下が v2.2.3 と一致する:
  - 生成される design-artifacts 配下のファイルパス一覧
  - 生成される construction/units/ 配下のレビューサマリファイル構造
  - Unit 定義ファイルの「実装状態」セクションが「完了」に更新される
  - `history/construction_unitNN.md` にステップ完了エントリが追記される

---

### ストーリー 3: Operations フェーズインデックス化

**優先順位**: Must-have

As a AI-DLC 利用開発者
I want to Operations Phase 開始時の初回ロードがインデックス集約型で最適化されている
So that リリース準備中のコンパクションを避け、複雑なリリース手順を一気通貫で実行できる

**受け入れ基準**:
- [ ] `steps/operations/` 配下にフェーズインデックスファイルが存在し、ストーリー1と同じ3点を集約している
- [ ] `SKILL.md` の引数ルーティング（`action=operations`）がインデックスファイル読み込みを指すよう更新されている
- [ ] **【計測】** 計測コマンドで Operations 初回ロードを計測した結果が **17,209 tok 以下**（v2.2.3 ベースライン維持）
- [ ] **【回帰検証】** サンプルサイクル（完了済みの Construction 成果物を持つ）で Operations Phase を実行した結果、以下が v2.2.3 と一致する:
  - `operations/progress.md` の各ステップが「完了」マークになる
  - `CHANGELOG.md`、`version.txt`、`skills/aidlc/version.txt` が新バージョンに更新される
  - `gh pr create` / `gh pr edit --add-label ready-for-review` 相当のコマンドが順序どおり呼ばれる（dry-run で確認）

---

### ストーリー 4: 汎用復帰判定基盤（インデックス集約型）

**優先順位**: Must-have

As a AI-DLC 利用開発者
I want to コンパクション後に各フェーズのインデックスファイルだけを読めば、現在位置と次のアクションが一意に判定できる
So that 復帰時のロード量を最小化し、中断前の作業を即座に再開できる

**受け入れ基準**:
- [ ] 各フェーズのインデックスファイルに「現在位置判定セクション」が存在し、以下を明記している:
  - 参照する成果物の一覧（`requirements/`, `story-artifacts/`, `construction/`, `operations/` の具体ファイル）
  - 同点時の優先順位: `operations/` > `construction/` > `inception/`、progress.md 完了状態での補正
  - 判定結果マッピング（どのファイルが存在したら現在どのステップか）
- [ ] **【正常系検証】** 各フェーズの代表的な進行中状態（Intent完了時点、Unit定義完了時点、Construction Unit 2 実装中、Operations リリース準備中）で復帰コマンドを実行した結果、すべて正しいステップから再開する
- [ ] **【異常系: 欠損】** 期待する成果物ファイル（例: `requirements/intent.md`）が存在しない場合、インデックスは「判定不能: 必須ファイル欠損」を表示し、ユーザー選択（新規開始/手動で位置指定）を求める。`automation_mode=semi_auto` でも自動継続しない
- [ ] **【異常系: 競合】** 複数フェーズの成果物が同時に存在する場合（例: `inception/progress.md` 未完了 + `construction/` 配下にファイル存在）、優先順位補正ルールに従い Inception と判定する。ただし progress.md 完了マークで補正できないケースは「判定不能: フェーズ競合」を表示
- [ ] **【異常系: 不正フォーマット】** `progress.md` が期待する表形式でない（見出しテーブル破損、YAML front-matter の不整合等）場合、インデックスは「判定不能: progress.md パース失敗」を表示し、ユーザー選択を求める。自動継続しない
- [ ] **【異常系: 旧バージョン混在】** v2.2.x 以前の成果物構造（例: `session-state.md` ファイルの存在）を検出した場合、「旧構造の成果物を検出: v2.3.0 以降ではこのサイクルの継続利用は保証されません」を警告表示し、ユーザーに継続/中止を選択させる。自動継続しない
- [ ] **【廃止検証】** `compaction.md` の現在位置判定テーブルが削除され、当該ファイルには `automation_mode` 復元等の他機能のみが残っている（grep で判定テーブルセクションが存在しないことを確認）

---

### ストーリー 5: #553 回帰防止シナリオ（ストーリー4の受け入れ確認）

**優先順位**: Must-have

As a AI-DLC 利用開発者（#553 影響ユーザー）
I want to Inception Phase の Unit 定義ファイル作成後にコンパクションが発生しても、正しく Inception Phase として復帰する
So that Construction と誤判定されて Inception の残作業（完了処理、履歴記録、コミット等）が飛ばされる事故を防げる

**位置づけ**: ストーリー4の「異常系: 競合」受け入れ基準が #553 の再現ケースで正しく動作することを保証する回帰防止シナリオ。ストーリー4の基盤が完成していれば自動的に成立する。

**受け入れ基準**:
- [ ] **【#553 再現シナリオ 1: PRFAQ 作成前】** 以下の状態で復帰判定を実行した結果、**Inception Phase のステップ5（PRFAQ 作成）** として再開する:
  - `.aidlc/cycles/vTEST/story-artifacts/units/001-dummy.md` が存在
  - `.aidlc/cycles/vTEST/inception/progress.md` の「ステップ4: Unit定義」が「完了」、「ステップ5: PRFAQ 作成」が「未着手」
  - `requirements/prfaq.md` は存在しない
  - Construction Phase の成果物（`construction/units/` 等）は存在しない
- [ ] **【#553 再現シナリオ 2: 完了処理中】** 以下の状態で復帰判定を実行した結果、**Inception Phase の完了処理（履歴記録・squash・コミット）** として再開する:
  - `.aidlc/cycles/vTEST/story-artifacts/units/001-dummy.md` が存在
  - `.aidlc/cycles/vTEST/inception/progress.md` の「ステップ4: Unit定義」「ステップ5: PRFAQ 作成」が「完了」
  - `requirements/prfaq.md` が存在
  - Construction Phase の成果物（`construction/units/` 等）は存在しない
- [ ] **【回帰防止】** v2.2.3 で再現シナリオ 1 を実行した場合は Construction と誤判定される（既知バグ #553）ことを確認し、v2.3.0 では Inception と正しく判定されることを対比で記録する

---

### ストーリー 6: Tier 2 施策の統合適用（operations-release.md スクリプト化）

**優先順位**: Must-have

As a メタ開発者
I want to `steps/operations/operations-release.md` の手順がスクリプト化され、インデックスからの参照形式になっている
So that 将来の Operations 手順変更時に影響範囲が局所化される

**受け入れ基準**:
- [ ] `operations-release.md` の手順部分が `scripts/` 配下のシェルスクリプト（例: `scripts/operations-release.sh`）に移管されている
- [ ] インデックスファイルから「operations-release を実行する場合は `scripts/operations-release.sh` を呼ぶ」と参照されている
- [ ] **【動作等価性検証】** 検証サンプル（完了済み Construction 成果物）で Operations を実行した結果、スクリプト化前後で以下が一致する:
  - `CHANGELOG.md`、`version.txt` の更新内容（diff で差分ゼロ）
  - `gh pr create` / `gh pr edit` の引数（dry-run で捕捉）
  - `operations/progress.md` のステップ完了マーク
- [ ] **【トークン削減貢献】** スクリプト化により `operations-release.md` のサイズが少なくとも 50% 縮小していること（tiktoken 計測）

---

### ストーリー 7: Tier 2 施策の統合適用（review-flow.md 判定ロジック簡略化）

**優先順位**: Must-have

As a メタ開発者
I want to `review-flow.md` の条件分岐表がインデックス側（または共通参照）に集約されている
So that AI レビューの判定ロジックが一元管理され、将来の設定変更時に影響範囲が局所化される

**受け入れ基準**:
- [ ] `review-flow.md` 内の「処理パス分岐（パス1/2/3）」「遷移判定」の条件分岐表が、インデックスファイルまたは共通参照ファイル（例: `steps/common/review-routing.md`）に移管されている
- [ ] `review-flow.md` 本体は手順記述に特化し、条件分岐ロジックは参照形式のみになっている
- [ ] **【動作等価性検証】** 検証サンプル A の Intent レビュー実行で、以下が整理前後で一致する:
  - 使用される外部 CLI（codex）
  - 反復回数の上限（3回）
  - 指摘0件時の自動承認フロー
  - 指摘対応判断フローへの分岐条件
- [ ] **【トークン削減貢献】** `review-flow.md` + 参照先ファイルの合計サイズが、整理前の `review-flow.md` 単体と比較して少なくとも同等以下に収まっている（拡散による増加なし）

---

### ストーリー 8: 削減目標達成の計測レポート

**優先順位**: Must-have

As a プロダクトオーナー兼メタ開発者
I want to v2.3.0 実装完了時点で各フェーズの初回ロード tok 数を実測したレポートを入手できる
So that #519 コンテキスト圧縮プロジェクトの達成状況を定量的に把握できる

**受け入れ基準**:
- [ ] `.aidlc/cycles/v2.3.0/` 配下に計測レポートファイル（例: `measurement-report.md`）が作成されている
- [ ] レポートに以下が含まれる:
  - v2.2.3 ベースライン値: Inception 22,972 tok / Construction 17,980 tok / Operations 17,209 tok（同一計測コマンドで再計測した値）
  - v2.3.0 実装後の計測値: Inception / Construction / Operations
  - 差分（tok 数、削減率 %）
  - 計測に使用したファイルリスト（インデックス化後に初回ロードに含まれるファイル）
- [ ] **【目標達成判定】** Inception 初回ロードが **15,000 tok 以下** であることが明示されている
- [ ] Construction / Operations が現状維持（17,980 / 17,209 tok 以下）であることが明示されている

---

### ストーリー 9: #519 クローズ判断と未達時運営タスク

**優先順位**: Must-have

As a プロジェクト運営者
I want to 計測レポートを元に #519 のクローズ判断を行い、未達項目があれば次サイクル向けバックログに登録する
So that 長期プロジェクトである #519 に明確な区切りをつけ、次の改善サイクルに進める

**受け入れ基準**:
- [ ] ストーリー8の計測レポートを元に #519 Issue にクローズ判断コメントが追加されている
- [ ] **達成時**: #519 のステータスが `status:done` ラベルに更新され、クローズされている
- [ ] **未達時**: 未達項目（目標 tok 数未達、未適用の Tier 2 施策、異常系未対応など）がバックログ Issue として登録されている（`backlog` + `type:feature` or `type:bugfix` ラベル）
- [ ] 本サイクルで実装された主要変更点（案D、#553 解決、Tier 2 施策）が CHANGELOG.md に記載されている

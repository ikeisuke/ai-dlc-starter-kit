# Unit 002 実装計画: §1.2.5 セルフレビュー観点新ステップ + 3 問固定判別ガイド

## 対象 Unit

- **Unit**: 002 - §1.2.5 セルフレビュー観点新ステップ + 3 問固定判別ガイド
- **関連 Issue**: #704（OPEN / 本サイクル PR で Closes / Try B 相当の Retrospective skill セルフレビュー観点不在を解消）
- **優先度**: High
- **depth_level**: standard（Phase 1 設計を実施）

## 背景・目的

v0.3.6 サイクル振り返り（Issue #704 / Try B）で、`aidlc-retrospective` skill 自体が「個別チェック追加に逃げやすい」構造であることが顕在化した。本 Unit では `steps/retrospective.md` §1.2 主因切り分け後・§1.5 Issue 起票前に新ステップ **§1.2.5「Try 構造性セルフレビュー」** を追加し、`AskUserQuestion` 経由で 3 観点を必須確認する。表面的判定時は最大 3 回まで Try 起草に差し戻し、上限到達時は `selfreview-capped` ラベルを T Issue に付与して起票許可する。

あわせて、3 問固定の判別質問テンプレ `templates/try_classification_guide.md` を新規追加し、§1.2.5 から参照する。

本 Unit は Unit 004（§1.5 ループ起票本体）に対して「セルフレビュー差し戻し履歴 + `selfreview-capped` ラベル付与経路」を提供する依存契約となる。

## スコープ

### 含まれるもの（責務）

- **必須対応 1**: `skills/aidlc-retrospective/steps/retrospective.md` への新ステップ §1.2.5 挿入
  - 挿入位置: 既存 §1.2「主因切り分け」直後・§1.3「格納先の選択」直前（§1.5 起票前に必ず通過する位置）
  - SC-05 充足条件: 「## 1.2.5 Try 構造性セルフレビュー」見出しが存在
- **必須対応 2**: §1.2.5 内に `AskUserQuestion` 必須 3 観点の手順を記述
  - 観点 A: Try が「次回から気をつける / チェックを 1 項目追加する」で済んでいないか
  - 観点 B: Problem を個別事象から構造課題（プロセス / 設計 / 規約 / SoT）に昇格できているか
  - 観点 C: P → T が再発防止チェックの追加で逃げていないか
  - 3 観点とも 1 件の `AskUserQuestion`（multiSelect=true）で必須確認する想定
  - `SKILL.md` の「ユーザー選択（振り返り内容の決定）」種別仕様に整合
- **必須対応 3**: 差し戻しループ上限 3 回の制御フロー定義
  - 「該当する（= 表面的）」回答が 1 件以上 → Try 起草に差し戻し
  - 差し戻し回数を 1 cycle 単位で累計し、上限到達時は Try 採択 + `selfreview-capped` ラベル付与で続行
  - 差し戻し履歴は `history/operations.md` 等の retrospective 実行ログに記録
- **必須対応 4**: `skills/aidlc-retrospective/templates/try_classification_guide.md` 新規追加（3 問固定）
  - 質問 1: 再発性（評価窓: 本サイクルを含まない直前 3 サイクル分の `cycles/v*/operations/` + retrospective Issue）
  - 質問 2: 対象レイヤ（心がけ vs skill/プロンプト/SoT/CI ガード）
  - 質問 3: 再入余地（別の入り口から踏める余地）
  - markdown 形式でそのままユーザーに提示可能
- **必須対応 5**: §1.2.5 から `try_classification_guide.md` への参照リンク追加
- **必須対応 6**: `selfreview-capped` GitHub ラベル存在保証機構の実装（**本サイクル必達**）
  - 設計: §1.5 起票直前に `retrospective_api_ensure_label "selfreview-capped"` を呼び、ラベル不在時は `gh label create selfreview-capped --color BFD4F2 --description "Try 構造性セルフレビュー上限到達"` で自動作成する fail-safe 経路
  - 権限不足時: `gh label create` が失敗した場合、当該 T Issue 起票を中断し warn 通知（ラベル付与なしの起票は許可しない / fail-fast）
- **必須対応 7**: bats テスト追加
  - 表面的 Try 陽性ケース: Try 文言に「気をつける」のみを含む入力 → 必ず差し戻しが発生
  - 構造改善 Try 陰性ケース: 具体的な skill / プロンプト変更を含む Try → 差し戻し発生しない
  - 差し戻し上限到達時の `selfreview-capped` ラベル付与確認
  - ラベル既存ケース（自動作成スキップ）/ ラベル不在ケース（自動作成成功）/ 権限不足ケース（fail-fast）
- **設計ドキュメント**: ドメインモデル + 論理設計を `.aidlc/cycles/v2.6.6/design-artifacts/` 配下に作成
- AI レビュー（設計 / コード / 統合）を codex で実施（`review_mode=required`）

### 含まれないもの（境界）

- **§1.5 Issue 起票ループ本体への組み込み（Try 件数分ループ）** → Unit 004（ストーリー 4A）
- **「構造課題昇格根拠」セクションを T Issue 本文必須化する処理** → Unit 004 に委譲
- **`aidlc-setup` フロー側へのラベル事前作成スクリプト組み込み** → 本サイクル対象外（別 Issue で defer）。本サイクルでは runtime 自動作成で必ず成立を保証
- **一次情報三層検証 helper の skill 化** → Unit 003
- **`aggregate_issue_enabled` 仕様 SoT 定義** → Unit 001（完了済）
- **v2.7.0+ defer 項目への着手**（破壊的 API 変更等）

## 実装方針

### Phase 1: 設計

- **ドメインモデル**:
  - 「Try 構造性セルフレビュー」概念モデル: Try / Self-Review Verdict（pass / fail）/ Rebuttal Loop / Capped State
  - 「セルフレビュー 3 観点」の意味分類（表面性 / 構造昇格 / 再発防止逃げ）
  - 「差し戻しループ」の状態遷移（initial → reviewed → capped）と上限到達条件
  - 「`selfreview-capped` ラベル付与経路」の責務境界（Unit 002 / Unit 004 の分担）
- **論理設計**:
  - §1.2.5 ステップの挿入位置確定（既存 §1.2 直後 / §1.3 直前 / §1.5 Step 4 dialog token verify 前完了の制約）
  - `AskUserQuestion` 3 観点の問い文言・選択肢設計（「該当する / 該当しない」二者択一、multiSelect=true）
  - 差し戻しループ制御フロー（疑似コード）と上限カウンタの保持位置（retrospective 実行ログへの記録形式）
  - `retrospective_api_ensure_label` の関数シグネチャ・戻り値・fail-fast 経路
  - `try_classification_guide.md` テンプレ構造（3 質問の見出し / 評価窓定義 / 判定指針）
  - bats テスト構成（陽性 / 陰性 / cap / label 経路）

### Phase 2: 実装

1. `skills/aidlc-retrospective/steps/retrospective.md` §1.2.5 新セクション追加
2. §1.2.5 内に `AskUserQuestion` 3 観点 + 差し戻しループ + 上限到達時 `selfreview-capped` 付与の手順記述
3. §1.2.5 から `try_classification_guide.md` への参照リンク追加
4. `skills/aidlc-retrospective/templates/try_classification_guide.md` 新規追加（3 問固定）
5. `skills/aidlc/scripts/lib/retrospective-api.sh` に `retrospective_api_ensure_label` helper 追加
6. bats テスト追加（陽性 / 陰性 / cap / label 既存 / label 自動作成 / 権限不足 fail-fast）
7. markdownlint 実行 + 二重 SoT CI ガード pass 確認 + 既存 bats 群への影響確認

## 完了条件チェックリスト

### SC-05 充足条件（§1.2.5 ステップ追加 + 差し戻し + 警告ラベル）

- [ ] `steps/retrospective.md` に「## 1.2.5 Try 構造性セルフレビュー」見出しが存在
- [ ] §1.2.5 内で `AskUserQuestion` 経由で 3 観点（表面性 / 構造昇格 / 再発防止逃げ）を必須確認する手順が記載
- [ ] 「該当する」回答時の差し戻しループが定義され、上限 3 回
- [ ] 上限到達時 T Issue 起票時に `selfreview-capped` ラベル付与の手順が記載
- [ ] bats: 表面的 Try 陽性ケース → 差し戻し発生
- [ ] bats: 差し戻し 3 回到達 → `selfreview-capped` ラベル付与経路実行
- [ ] bats: ラベル既存 / ラベル自動作成 / 権限不足 fail-fast の 3 ケース
- [ ] bats: `AskUserQuestion` 失敗時の `undecidable` 経路（差し戻しにも `selfreview-capped` 経路にも入らず保留）→ Unit 定義 NFR「可用性」整合

### SC-06 充足条件（判別ガイドテンプレ追加 + 参照）

- [ ] `skills/aidlc-retrospective/templates/try_classification_guide.md` が存在
- [ ] テンプレ内に 3 問固定（再発性 / 対象レイヤ / 再入余地）が記載
- [ ] §1.2.5 から `try_classification_guide.md` への参照リンクが存在

### Unit 共通完了条件

- [ ] 設計ドキュメント（ドメインモデル + 論理設計）が `.aidlc/cycles/v2.6.6/design-artifacts/` 配下に存在
- [ ] 設計レビュー（codex）clean
- [ ] コードレビュー（codex）clean
- [ ] 統合レビュー（codex）clean
- [ ] 既存 bats 群 + 新規 bats すべて pass
- [ ] markdownlint pass
- [ ] 二重 SoT CI ガード pass（本 Unit では `defaults.toml` 変更なし想定だが事前確認）
- [ ] Unit 定義ファイル状態を「完了」に更新
- [ ] `history/construction_unit02.md` に履歴記録
- [ ] squash 完了
- [ ] Unit 完了コミット作成

## リスク・前提

- **dialog token TTL 干渉**: §1.2.5 の `AskUserQuestion` は §1.5 Step 4 直前の `retrospective_dialog_token_verify` 呼び出し前に完了させる必要がある。論理設計でこの順序制約を明示する
- **既定動作変更**: 既存 retrospective 経路で §1.2.5 を必ず通過させるため、`automation_mode` に関わらず `AskUserQuestion` を使用（SKILL.md「ユーザー選択（振り返り内容の決定）」種別仕様で auto mode 適用外）
- **ラベル作成失敗時の fail-fast**: 既存の retrospective 起票経路は warn-continue が主体だったが、本 Unit ではラベル付与なしの起票を許可しないため `fail-fast` に降格する。これは仕様判断として明示記録
- **bats テストでの `AskUserQuestion` モック**: bats 環境では `AskUserQuestion` ツール直接呼び出しは行えないため、`retrospective_api_*` 関数レベルでの差し戻し判定ロジックを抽出してテスト対象とする想定（論理設計で確定）
- **`AskUserQuestion` 失敗時のフォールトモデル**（指摘 #3 反映 / Unit 定義 NFR「可用性: AskUserQuestion 失敗時はセルフレビュー結果を `undecidable` 扱い」整合）:
  - 失敗事象: AskUserQuestion ツール起動失敗 / 応答取得不能 / ユーザー応答 timeout
  - 即時挙動: セルフレビュー結果を `undecidable` 状態とし、**再試行しない**（dialog token TTL 300 秒内で完了させる制約と整合させ、reset 待ちでの TTL 切れを避ける）
  - フロー継続判定: `undecidable` 時は §1.5 起票を保留し、ユーザー判断を待つ（差し戻しでも採択でもなく保留）。`selfreview_capped` 判定は確定せず、ログ上 `verdict=undecidable` を記録
  - Unit 004 への受け渡し値: `verdict=undecidable` を受け取った場合、Unit 004 側は当該 Try の起票を skip し、`history/operations.md` に「セルフレビュー undecidable のため起票保留」を warn 記録する
  - bats ケース: AskUserQuestion 失敗を模した `undecidable` 入力時に、差し戻しループにも `selfreview-capped` 経路にも入らず保留される回帰テストを 1 件追加（SC-05 補強）

## 責務分割の明確化（指摘 #2 反映）

Unit 002 と Unit 004 の責務境界を以下に明記する。本 Unit が「§1.5 起票直前で実行される helper」を提供するが、**§1.5 起票本体への helper 呼び出しの組み込み（実呼び出し統合）は Unit 004 の責務**である。Unit 002 では呼び出し契約定義・helper 実装・§1.2.5 step 定義（retrospective.md 内）まで完結する。

| 責務 | Unit 002 | Unit 004 |
|------|---------|---------|
| §1.2.5 step 定義（retrospective.md セクション追加） | ✓ | - |
| `AskUserQuestion` 3 観点質問テンプレ | ✓ | - |
| 差し戻しループ制御フロー定義 + ログ形式定義 | ✓ | - |
| `try_classification_guide.md` テンプレ追加 | ✓ | - |
| `retrospective_api_ensure_label` helper 実装 | ✓ | - |
| `retrospective_api_ensure_label` 単体 bats（label 既存 / 自動作成 / 権限不足） | ✓ | - |
| §1.2.5 step 単体 bats（陽性 / 陰性 / cap / undecidable） | ✓ | - |
| §1.5 Step 4 起票直前での helper 呼び出し統合 | - | ✓ |
| §1.5 起票ループから「構造課題昇格根拠」セクションを T Issue 本文に反映 | - | ✓ |
| `selfreview-capped` ラベル値を T Issue 起票 payload に組み込む実装 | - | ✓ |
| 統合 bats（セルフレビュー → 起票までの end-to-end） | - | ✓ |

「依存する Unit: なし」（Unit 定義ファイル `002-selfreview-and-classification-guide.md` 39 行目）は **着手順序として依存しない** ことを意味する。helper の使用主体（Unit 004）は本 Unit が定義する公開契約（次節参照）を消費する側であり、契約の依存方向は Unit 004 → Unit 002（逆流なし）。

## 公開契約（指摘 #1 反映 / Unit 004 が消費する契約 SoT）

本 Unit が外部に提供する公開 API・データ形式の単一定義。**本契約は Unit 004 が依存する SoT であり、本 Unit 完了後は変更不可**。

### 1. `retrospective_api_ensure_label` 公開契約

- **シグネチャ**: `retrospective_api_ensure_label <label_name>`
  - 引数 1（必須）: ラベル名（例: `selfreview-capped`）
  - 環境変数: 既存 `retrospective_api_*` 群と同じ前提（`gh` CLI が PATH 上に存在）
- **stdout**: 成功時は空（最終的にラベルが存在することのみが結果）
- **stderr**: 失敗時は warn 文言（機密マスク済み）
- **exit code**（**ラベル保証 = 起票継続条件として厳格 fail-fast 統一**）:
  - `0`: ラベルが存在することを確認できた（既存 or 自動作成成功）
  - `2`: 自動作成試行が権限不足等で失敗した（fail-fast、呼び出し側は当該 T Issue 起票を中断）
  - `3`: `gh` CLI 自体が利用不能（`gh_status != available` / network 断等）。**呼び出し側は当該 T Issue 起票を中断（厳格 fail-fast）**。スコープ宣言「ラベル付与なしの起票は許可しない / fail-fast」を `2/3` 両 exit code で一本化する。`gh` 利用不能時は起票自体も既存仕様で不可能なため、起票中断の挙動は既存 retrospective 起票経路の `gh_status != available` 時 warn-continue と矛盾しない（起票試行自体に到達しない）
- **副作用**: ラベル不在時 `gh label create <label_name> --color BFD4F2 --description "Try 構造性セルフレビュー上限到達"` を 1 回試行（リトライなし）
- **冪等性**: ラベル既存時は no-op（exit 0、stderr/stdout 空）

### 2. `history/operations.md` ログフォーマット（セルフレビュー実行記録）

`/write-history` 経由で追記。Unit 004 が §1.5 起票時に「構造課題昇格根拠」の参照源として読む。

```text
- イベント: AIDLC retrospective セルフレビュー実行
- サイクル: {{CYCLE}}
- Try ID: <try-N>（Try 番号、Try 件数分繰り返し）
- 観点 A 応答: yes | no
- 観点 B 応答: yes | no
- 観点 C 応答: yes | no
- 差し戻し回数: <0-3>
- 確定 verdict: pass | rebuttal | capped | undecidable
- selfreview_capped: true | false
- 構造課題昇格根拠: <ユーザー追記テキスト / 未記入時は "-">
```

**フィールド意味**:

- 観点 A/B/C: 各 `AskUserQuestion` 設問の回答（`yes` = 「該当する（= 表面的）」、`no` = 「該当しない」）
- `verdict`: `pass`（差し戻し不要 / 3 観点とも no）/ `rebuttal`（差し戻し発生 / 観点 yes ≥ 1 かつ rebuttal count < 3）/ `capped`（差し戻し上限到達 / `selfreview_capped=true` 確定）/ `undecidable`（AskUserQuestion 失敗）
- `selfreview_capped`: `verdict=capped` の場合のみ `true`、それ以外は `false`

### 3. `selfreview_capped` 確定規則（Unit 004 への入力契約）

Unit 004 は `history/operations.md` から各 Try の `selfreview_capped` 値を読み取り、`true` のときに限り T Issue 起票時に `selfreview-capped` ラベルを payload へ含める。

- `verdict=capped` の場合のみ `selfreview_capped=true`
- それ以外（`pass` / `rebuttal` / `undecidable`）は `selfreview_capped=false` または対象 Try を起票 skip（`undecidable`）
- 判定は単一のログ行から再現可能（外部状態に依存しない）

## 依存と引き継ぎ

- **依存**: なし（Unit 001 とは独立に着手可能）
- **Unit 004 への引き継ぎ**: 上記「公開契約」節を SoT として参照する
  - §1. `retrospective_api_ensure_label` の I/O・exit code・副作用
  - §2. `history/operations.md` セルフレビュー実行ログフォーマット
  - §3. `selfreview_capped` 確定規則（T Issue 起票 payload への組み込み判定）

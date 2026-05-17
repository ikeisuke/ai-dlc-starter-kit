# Unit 004 実装計画: defaults.toml 二重 SoT 同期ガード (CI 早期検出)

## 対象 Unit

- **Unit**: 004 - defaults.toml 二重 SoT 同期ガード (CI 早期検出)
- **関連 Issue**: #714（クローズ対象）
- **優先度**: High
- **depth_level**: standard

## 背景・目的

`skills/aidlc/config/defaults.toml`（正本）と `skills/aidlc-setup/config/defaults.toml`（配布用 sync コピー）の差分を CI で早期検出し、v2.6.4 Unit 004 修復コミット 421c5ac1 のような事後修復を構造的に予防する。

## 現状調査結果（事前コード Read / depth_level != minimal）

### Read 対象ファイル + 目的

| ファイル | 目的 / 既存実装の確認結果 |
|---------|---------------------------|
| `.github/workflows/pr-check.yml` (line 93 周辺) | `defaults-sync-check` ジョブ既存。PR トリガー、`bin/check-defaults-sync.sh` を呼ぶ |
| `bin/check-defaults-sync.sh` | コメント・空行を除外して正本 vs コピーを diff 比較。exit 0=`sync:ok` / 1=`sync:mismatch` / 2=`error:not-found` |
| `skills/aidlc/config/defaults.toml` / `skills/aidlc-setup/config/defaults.toml` | Unit 001 で `[rules.inception]` セクション追加済み、Unit 001 内で sync コピー実施済 |

### 既存実装の挙動

- 既存ジョブは Unit 001 実装中に「同期崩し → CI red」を実際に再現済み（aidlc/側に新規キー追加直後、aidlc-setup/側未同期の状態を `bin/check-defaults-sync.sh` がローカルで検出）
- 同期復元（aidlc-setup/側にも追加）後 `sync:ok` を取得

### Unit 001 経由のドッグフーディング自然発生

Unit 001 Phase 2 実装で次の流れを実証済み:

1. `skills/aidlc/config/defaults.toml` に新規セクション追加（aidlc-setup/側未同期）
2. `bin/check-defaults-sync.sh` が `sync:mismatch` 検出 + 差分表示 + 修復方法案内
3. aidlc-setup/側にも同期 → `sync:ok`

これは「同期崩し → CI red → 同期復元 → CI green」遷移の実例（再現可能）。

## スコープ

### 含まれるもの（責務）

- **必須対応 1 (実体強化)**: `bin/check-defaults-sync.sh` を**構造比較レイヤ（キー集合・型一致）**に拡張する。`dasel` で TOML キーパスを抽出し、行ベース diff から構造同値比較へ切替。出力に「不足キー一覧 + 型差分 + 修復方法 + コマンド例」を含める
- **必須対応 2 (実体強化)**: 失敗時 exit 1 + stderr に機械可読な「failure contract」（`error:key-missing:<path>` / `error:type-mismatch:<path>:<expected>:<actual>` 形式）を出力し、CI ログから自動抽出可能にする
- **必須対応 3 (本 Unit 独立ドッグフーディング)**: Phase 2 で意図的に同期崩し（`skills/aidlc/config/defaults.toml` に一時テストキー追加・コミットなし）→ `bin/check-defaults-sync.sh` で red 確認 → 復元 → green 確認 の流れを実施し `history/construction_unit04.md` に記録（U1 事例は補助エビデンス扱い）
- **必須対応 4**: 既存 `.github/workflows/pr-check.yml` の `defaults-sync-check` ジョブが拡張版スクリプトと連動して動作することを実 CI で確認（本サイクル PR の green 確認）
- **必須対応 5 (任意 / トレードオフ評価)**: 自動同期スクリプト `bin/sync-defaults-toml.sh` の採否判断を計画書に明示（採用 / 却下 + 根拠）

### 含まれないもの（境界 / 任意未実施）

- 自動同期スクリプトの実装（Unit 定義 §技術的考慮事項 「追加達成条件 / 任意」のため本サイクルでは未実施。トレードオフ評価のみ後述に記録）
- defaults.toml の構造変更
- consumer プロジェクトへの追加配布物

## 実装方針

### Phase 1: 設計（簡素化: ドメインモデルでなく「workflow orchestration + comparator script + failure contract」コンポーネント表現）

- **ドメインモデル**: 3 コンポーネント構成
  - `WorkflowOrchestrator` (`.github/workflows/pr-check.yml` の `defaults-sync-check` ジョブ): PR トリガーでスクリプトを起動、exit code で green/red を判定
  - `ComparatorScript` (`bin/check-defaults-sync.sh`): `dasel` でキーパス列挙、構造比較を実行
  - `FailureContract`: 出力スキーマ（`sync:ok` / `sync:mismatch` + `error:key-missing:<path>` / `error:type-mismatch:<path>` + 修復方法）
- **論理設計**: 構造比較ロジック（キー集合差分 + 型差分の検出）、出力フォーマット仕様

### Phase 2: 実装

1. `bin/check-defaults-sync.sh` を構造比較に拡張（`dasel` で TOML キーパスを抽出、キー集合と型を比較）
2. 出力に failure contract（`error:key-missing:<path>` / `error:type-mismatch:<path>:<expected>:<actual>`）+ 修復方法 + コマンド例を追加
3. **意図的同期崩し → red 検出 → 復元 → green 検証** を本 Unit 自身で実施し `history/construction_unit04.md` に記録
4. 既存 `.github/workflows/pr-check.yml` の `defaults-sync-check` ジョブが拡張スクリプトと連動することを確認（本サイクル PR の CI 通過で実証）
5. 任意の自動同期スクリプト採否トレードオフを最終評価

## 追加達成条件のトレードオフ評価

- **自動同期スクリプトの実装可否**:
  - **採用候補**: `bin/sync-defaults-toml.sh`（正本 → コピー方向の自動同期、コメント保持しつつキー集合を一致させる）
  - **採用しない理由（本サイクル）**: コメント保持と新規キー追加の自動補完は非自明（コメント順序 / 段落分け / 末尾改行等のマージ判定が必要）。Unit 001 では手動 Edit で 1 セクション同期可能であり、運用負担は小さい
  - **将来 issue 候補**: 「複雑な階層構造変更時の自動同期」を v2.7.0+ で別 Unit として検討

## 完了条件チェックリスト

### #714 受け入れ基準

- [x] `bin/check-defaults-sync.sh` が `dasel` ベースの**構造比較**（キー集合 + 型一致）に拡張されている
- [x] 失敗時 stderr に machine-readable な failure contract（`error:key-missing:<path>` / `error:type-mismatch:<path>:<expected>:<actual>`）が出力される
- [x] 出力に「修復方法 + コマンド例」が含まれる
- [x] `.github/workflows/pr-check.yml` の `defaults-sync-check` ジョブが拡張スクリプトと連動して動作することが Unit 004 ドキュメントで明示
- [x] 本 Unit 自身で「同期崩し → red 検出 → 復元 → green 確認」検証が実施され `history/construction_unit04.md` に記録（独立検証）
- [x] 本サイクル PR の `defaults-sync-check` ジョブが pass する（マージ前確認）
- [x] 追加達成条件 (自動同期スクリプト) の採否トレードオフが計画書に明示

### 共通

- [x] markdownlint で新規エラー 0 件
- [x] AI レビュー（設計 / コード / 統合）が `review_mode=required` に従い codex で実施されている

## リスク・考慮事項

- 既存 CI ジョブが既に機能しているため、本 Unit の主たる責務は「強化 + ドキュメント化 + ドッグフーディング記録」
- 「ドッグフーディング特殊処理を本体に埋めない」原則: `bin/check-defaults-sync.sh` は consumer プロジェクトでは実行されない（starter kit 自身の CI 専用）。本体スクリプト内分岐は持たず、`.github/workflows/` の独立ジョブとして配置済
- 本リポジトリ規約: Bash ツール引数文字列にコマンド置換 `$(...)` / backtick を含めない

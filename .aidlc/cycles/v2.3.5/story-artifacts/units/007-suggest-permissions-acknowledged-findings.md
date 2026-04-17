# Unit: suggest-permissions Review の acknowledged findings 抑制機構追加

## 概要

`suggest-permissions` スキルの Review モード（`--review`）に、既知安全な監査指摘を抑制する機構（acknowledged findings）を追加する。抑制リストは `.claude/settings.json` の `suggestPermissions.acknowledgedFindings` 配列に格納し、マッチする指摘はデフォルトで非表示、Review 出力末尾に集約サマリを 1 行表示する。`--show-suppressed` オプションで抑制済み指摘を再表示できる。既存ユーザーへの挙動変化を最小化し、抑制リスト未設定時は従来通りの出力を保つ。

## 含まれるユーザーストーリー

- ストーリー 6: suggest-permissions Review で既知安全な指摘が抑制される（#576）

## 責務

- `suggest-permissions` Review モードに以下の機能を追加:
  - `.claude/settings.json` の `suggestPermissions.acknowledgedFindings` 配列を読み込む
  - 配列エントリ `{ pattern, severity, note, acknowledgedAt }` に基づき指摘をフィルタリング
  - マッチング条件: `pattern` と `severity` の AND 条件、`severity` は大文字小文字不問、`pattern` は前後空白トリム
  - デフォルトで抑制対象の指摘を非表示化
  - Review 出力末尾に `ℹ N件の既知指摘を抑制しました（詳細は --show-suppressed）` の集約サマリ 1 行を表示（N=0 時は非表示）
  - `--show-suppressed` オプションで抑制済み指摘も含めて全件表示（抑制対象に `(suppressed)` マーカー）
- 設定ファイル破損時の失敗モード実装:
  - JSON パース失敗 / 配列でない場合 → 警告表示して suppression 無効化、従来通り続行
  - `severity` 不正値・`pattern` 欠落 → 該当エントリのみスキップ（部分失敗）
  - `note` / `acknowledgedAt` 欠落・型不正 → 警告なしで許容（任意項目）
- Review モードの既存終了コード・主要出力フォーマットを維持（後方互換）
- マッチング方式（完全一致 / glob / 正規表現）の最終選定（設計フェーズで確定）
- `suggest-permissions` のヘルプ出力・ドキュメントに `--show-suppressed` オプションと acknowledged findings 機構の説明を追加

## 境界

- 実装対象外:
  - `.claude/settings.json` 自体の新規作成（既存ファイルへの読み取りのみ）
  - `suggestPermissions.acknowledgedFindings` フィールドを書き込む UI / CLI（ユーザーが手動で `.claude/settings.json` を編集する想定）
  - Setup モード等 Review 以外の suggest-permissions サブコマンド
  - Claude Code の `.claude/settings.json` スキーマ管理（本機能は独自フィールドを追加するのみ）
  - 抑制リストの記述例を guides 配下に追加するか（設計フェーズで判断）
  - **User-scoped 設定（`~/.claude/settings.json`）の読み取り・マージ処理**（本 Unit では Project-scoped 設定のみを対象とする。User-scoped 対応は別 Issue として切り出し、本サイクルのスコープ外）

## 依存関係

### 依存する Unit

- なし（suggest-permissions スキルは既存、AI-DLC コア（aidlc / aidlc-setup）とは独立）

### 外部依存

- `.claude/settings.json`（既存、Claude Code の設定ファイル）
- JSON パーサ（`jq` 等、既存ツールチェーン）

## 非機能要件（NFR）

- **パフォーマンス**: 設定ファイル読み込み・マッチング処理は Review 全体の実行時間に影響しない程度（N 件 × M パターンの線形比較で許容）
- **セキュリティ**: acknowledged findings 機能は監査抑制のため、誤って本来危険な指摘を抑制してしまうリスクがある。この運用リスクは Construction Phase の設計・ドキュメント整備で軽減する（記述例・ベストプラクティスの提示）
- **スケーラビリティ**: 実運用での `acknowledgedFindings` エントリ数は 10-50 件程度を想定。1000 件規模は想定外
- **可用性**: 設定ファイル不在・破損・フィールド未設定の各ケースで Review 自体は必ず従来通り成功する（suppression 機能の失敗が Review 全体を止めない）

## 技術的考慮事項

- **マッチング方式の選定**: Construction Phase 設計フェーズで以下の観点から選定
  - 完全一致: シンプルだが柔軟性なし（ワイルドカード非対応）
  - glob パターン: Claude Code 権限パターン記法と整合（例: `Bash(bash -n *)`）、実装容易
  - 正規表現: 最も柔軟だが誤マッチのリスクあり
  - **推奨方針（Construction 設計で検証）**: glob パターン（`fnmatch` 相当）
- **読み込み対象のパス解決**: 参照先は **プロジェクトルート直下の `.claude/settings.json` のみ**（User-scoped `~/.claude/settings.json` は本 Unit のスコープ外、境界セクション参照）
- **照合対象文字列**: Review 出力の「指摘対象文字列」は典型的には Bash コマンドパターン（例: `Bash(bash -n *)`）。照合対象の具体項目（コマンド文字列・表示ラベル・正規化前後）の最終選定は設計フェーズで確定
- **JSON パース**: `jq` を使用する場合、パース失敗時の stderr を明示的にキャプチャし警告メッセージに含める
- **後方互換の維持**: 既存の Review モード呼び出し（引数なし / 既存フラグ）で挙動変化がないことをテストで担保
- **`--show-suppressed` フラグ**: 既存フラグ体系と衝突しないようプレフィックス `--show-` に揃える（他に `--show-all` 等があれば統一）
- **ドキュメント整備**: suggest-permissions の README / 関連ガイドに acknowledged findings の設定例を追加する（実装後の整備作業として設計フェーズで段取り）

## 関連Issue

- #576

## 実装優先度

Low（bug ではなく feature、既存運用への即時影響なし）

## 見積もり

**M（Medium）** - suggest-permissions スキル本体の Review ロジックに設定読み込み・フィルタリング・集約サマリ・表示モード分岐を追加。設定ファイル破損時の失敗モードも含め、既存テストとの互換確保が必要。Unit 005 / 006 より変更範囲が広い。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -

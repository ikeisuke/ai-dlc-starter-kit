### Phase 2: 実装【設計を参照してコード生成】

#### ステップ4: コード生成

**タスクステータスを更新してください（着手時: `in_progress`、完了時: `completed`）。**

1. 設計ファイルを読み込み、それに基づいて実装コードを生成
2. **AIレビュー実施**（`steps/common/review-flow.md` に従う）
3. レビュー結果を反映

#### ステップ5: テスト生成

**タスクステータスを更新してください（着手時: `in_progress`、完了時: `completed`）。**

**Depth Level分岐**（`common/rules.md` の「レベル別成果物要件一覧」を参照）:
- `comprehensive`: BDD/TDDに加え、統合テストを強化（コンポーネント間の連携テストを追加）
- `minimal` / `standard`: 変更なし（現行動作）

BDD/TDDに従ってテストコードを作成

#### ステップ6: 統合とレビュー

**タスクステータスを更新してください（着手時: `in_progress`、完了時: `completed`）。**

1. ビルド実行
2. テスト実行
3. **Self-Healingループ**（ビルドまたはテストでエラーが発生した場合）:

   **max_retry=0 の場合**: Self-Healingループをスキップし、即座に項目3c（ユーザー判断フォールバック）に遷移する。以下の「非回復系エラー検出時」テンプレートを使用し、エラー分類は `skipped(max_retry=0)` と表示する。

   **max_retry バリデーション**: プリフライトチェックで取得した `max_retry` の値が負の値または非数値の場合、以下の警告を表示しデフォルト値3を使用する:
   ```text
   ⚠ max_retry の値が不正です（"{value}"）。デフォルト値 3 を使用します。
   ```

   エラー発生時、AIが自動修正を最大 `max_retry` 回試行する。非回復系エラーは即時フォールバックとしリトライ対象外とする。

   **機密情報マスキング【必須】**: エラー要約・失敗要因・エラー内容の出力時、APIキー・トークン・認証ヘッダ・接続文字列・URI資格情報等の機密情報を必ずマスキングする（例: `sk-****`、`Bearer ****`、`postgresql://****@host/db`）。バックログ登録時のIssueタイトル・本文にも同様のマスキングを適用する。

   **3a. エラー分類判定**:

   エラー出力を以下の判定基準テーブルに照合し、カテゴリを決定する（判定優先順位: non_recoverable > transient > recoverable）:

   | カテゴリ | 判定基準パターン | 対応 |
   |---------|----------------|------|
   | `non_recoverable` | 認証エラー（401, 403, auth, token expired）、リソース不足（disk full, ENOMEM, ENOSPC）、環境未設定（command not found, module not found） | 即時フォールバック（項目3cへ） |
   | `transient` | ネットワーク系（connection refused, timeout, DNS resolution failed） | 1回再試行（attempt消費）→ 再失敗時フォールバック（項目3cへ） |
   | `recoverable` | 上記に該当しない（デフォルト） | Self-Healingループ対象（項目3bへ） |

   **3b. Self-Healingループ本体**（最大 `max_retry` 回、カテゴリ横断でattempt共有）:

   各attemptで以下を実行し、結果を出力する:

   1. エラー分析と修正を実施
   2. attempt結果を出力（全フィールド必須）:

      ```text
      【Self-Healing】attempt {N}/{max_retry}
      【エラー種別】{ビルドエラー / テストエラー}
      【エラー分類】{recoverable / non_recoverable / transient}
      【失敗要因】{エラーの要約}
      【修正内容】{実施した修正の要約}
      ```

   3. ビルド/テストを再実行
   4. 成功 → ループ終了、項目4（AIレビュー）へ進む
   5. 失敗 → エラー再分類（項目3aへ戻る）。non_recoverableまたはtransient再失敗の場合は項目3cへ
   6. attempt `max_retry` 回到達 → 項目3cへ

   **3c. フォールバック（ユーザー判断フロー）**:

   エラー発生時はcommon/rules.mdのフォールバック条件（`reason_code=error`）に該当するため、`automation_mode` に関わらず常にユーザー確認を行う（`fallback(error)` として処理）。

   **`max_retry` 回失敗時**:

   ```text
   【Self-Healing失敗】{max_retry}回の自動修正で解決できませんでした。
   【エラー種別】{ビルドエラー / テストエラー}
   【最終エラー】{エラーの要約}
   【試行履歴】
     attempt 1: {失敗要因の要約}
     ...
     attempt {max_retry}: {失敗要因の要約}

   どのように対応しますか？
   1. 手動で修正を継続する
   2. バックログに記録してスキップする
   3. 処理を中断する
   ```

   **非回復系エラー検出時**:

   ```text
   【非回復系エラー検出】自動修正の対象外です。
   【エラー種別】{ビルドエラー / テストエラー}
   【エラー分類】{non_recoverable / transient / skipped(max_retry=0)}
   【エラー内容】{エラーの要約}
   【判定理由】{該当した判定基準}

   どのように対応しますか？
   1. 手動で修正を継続する
   2. バックログに記録してスキップする
   3. 処理を中断する
   ```

   **ユーザー選択に応じた処理**:

   - **「1. 手動で修正を継続する」**: ユーザーが手動で修正を実施後、項目1（ビルド実行）からやり直す
   - **「2. バックログに記録してスキップする」**: 以下のバックログ登録提案フローを実行し、項目4（AIレビュー）へ進む
   - **「3. 処理を中断する」**: 処理を停止する

   **バックログ登録提案**（「2. バックログに記録してスキップする」選択時）:

   1. 以下の処理順でバックログ登録を実行:

      **a. 安全規則の検証**（登録処理の前に必ず確認）:
      - heredoc終端トークンを含む入力値は拒否する
      - `{slug}` は `^[a-z0-9][a-z0-9-]{0,63}$` のパターンのみ許可
      - すべての引数・パスは二重引用符で囲む

      **b. slug生成**: エラー内容から短い識別子を生成（英数字・ハイフン）。空値時は `unspecified-{YYYYMMDD}` を使用。同名ファイル/Issue存在時はサフィックス（`-2`, `-3`...）を付与。

      **c. 登録実行**:

      ステップ3の `gh_status` 判定結果を参照し、GitHub Issue作成を試みる。
      タイトルは `[Backlog] bugfix: {エラー要約}`、ラベルは `"backlog,type:bugfix,priority:medium"`。
      Issue本文はWriteツールで一時ファイルに書き出し、`gh issue create --body-file` で作成後、一時ファイルを削除。

      Issue作成失敗時またはgh CLI不可用時は警告メッセージを表示し、手動対応を依頼。

   2. 選択結果を履歴に記録:

      ```text
      【Self-Healingフォールバック】{手動修正継続 / バックログ記録 / 中断}
      【エラー種別】{ビルドエラー / テストエラー}
      【エラー分類】{recoverable / non_recoverable / transient / skipped(max_retry=0)}
      【試行回数】{実施したattempt数}/{max_retry}
      【バックログ登録】{登録 / スキップ / なし}
      【登録先】{Issue番号 / なし}
      ```

4. **AIレビュー実施**（`steps/common/review-flow.md` に従う）
5. レビュー結果を反映
6. **セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` かつフォールバック条件に該当しない場合、自動承認し次ステップへ進む。上記以外はコードをユーザーに提示し、承認を得る
7. `.aidlc/cycles/{{CYCLE}}/construction/units/[unit_name]_implementation.md` に実装記録を作成（テンプレート: `skills/aidlc/templates/implementation_record_template.md`）

---

## 実行ルール

1. **計画作成**: Unit開始前に計画ファイルを `.aidlc/cycles/{{CYCLE}}/plans/` に作成
2. **ユーザーの承認【重要】**: 計画ファイルのパスを提示し「この計画で進めてよろしいですか？」と明示的に質問、承認を待つ
3. **実行**: 承認後に実行

---

## 完了基準

- すべて完成
- ビルド成功
- テストパス
- 実装記録に「完了」明記
- **Unit定義ファイルの「実装状態」を「完了」に更新**
- **コンテキストリセットの提示完了**（ユーザーが連続実行を明示指示した場合はスキップ可）


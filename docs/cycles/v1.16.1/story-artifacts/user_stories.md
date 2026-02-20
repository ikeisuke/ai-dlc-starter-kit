# ユーザーストーリー - v1.16.1

## Epic: AI-DLCプロンプト軽量化

### ストーリー 1: operations.mdの定型処理スクリプト化
**優先順位**: Must-have

As a AI-DLCスターターキットの利用者
I want to operations.mdの定型処理がシェルスクリプトに切り出されている
So that プロンプトファイルが1000行以内に収まり、AIがより正確に指示を理解できる

**受け入れ基準**:
- [ ] リモート同期確認（6.6.6）がシェルスクリプト `validate-remote-sync.sh` として実装されている
- [ ] コミット漏れ確認（6.6.5）がシェルスクリプト `validate-uncommitted.sh` として実装されている
- [ ] operations.mdから該当セクションがスクリプト呼び出しに置き換えられている
- [ ] operations.mdの行数が1000行以内になっている（`wc -l` で確認）
- [ ] 各スクリプトが `status:ok` / `status:warning` / `status:error` 形式で結果を出力する（既存スクリプトと同じkey:value形式）
- [ ] スクリプト異常終了時に exit code 1 を返し、エラーメッセージを stderr に出力する
- [ ] リモート疎通不可、未追跡ブランチ等の異常系で適切なエラーメッセージを出力する

**技術的考慮事項**:
- 既存のスクリプト（pr-ops.sh等）との命名規則・引数規則の整合性
- `prompts/package/` を編集し、rsyncで `docs/aidlc/` に反映

---

### ストーリー 2: 共通処理スキル化の全体設計（inception/construction含む）
**優先順位**: Must-have

As a AI-DLCスターターキットの開発者
I want to 共通処理のスキル化・切り出し設計が完了している
So that 次サイクル以降でプロンプト保守コストを削減し、変更時の影響範囲を限定できる

**受け入れ基準**:
- [ ] スキル化対象の共通処理が洗い出され、優先度（高/中/低）が付けられている
- [ ] 各スキルのファイル構成（SKILL.md、references/等）が既存スキル（reviewing-*等）の構造を参考に設計されている
- [ ] 各フェーズプロンプト（operations.md, inception.md, construction.md）からスキルへの移行対象セクションが一覧表で明記されている
- [ ] 互換性維持方針（既存の呼び出しパス、rsync手順との共存方法）が記載されている
- [ ] 各フェーズの削減効果見積もり（行数ベース）が記載されている
- [ ] 設計ドキュメントが `docs/cycles/v1.16.1/design-artifacts/architecture/` に配置されている

**技術的考慮事項**:
- 既存スキル（reviewing-*, upgrading-aidlc, versioning-with-jj）のSKILL.md構造を参考にする
- AIツール間の互換性（Claude Code, KiroCLI等）を考慮
- フェーズ固有の処理と共通処理の境界を明確にする

---

### ストーリー 3: 回帰確認
**優先順位**: Must-have

As a AI-DLCスターターキットの利用者
I want to スクリプト化後も既存の動作が維持されている
So that アップグレード後にワークフローが壊れるリスクなく利用できる

**受け入れ基準**:
- [ ] `validate-remote-sync.sh` 正常系: リモート同期済み → `status:ok` + exit 0
- [ ] `validate-remote-sync.sh` 正常系: 未pushコミットあり → `status:warning` + `unpushed_commits:{件数}` + exit 0
- [ ] `validate-remote-sync.sh` 異常系: fetch失敗 → `status:error` + `error:fetch-failed` + exit 1
- [ ] `validate-remote-sync.sh` 異常系: 追跡ブランチなし → `status:error` + `error:no-upstream` + exit 1
- [ ] `validate-uncommitted.sh` 正常系: 変更なし → `status:ok` + exit 0
- [ ] `validate-uncommitted.sh` 正常系: 変更あり → `status:warning` + `files:{ファイル一覧}` + exit 0
- [ ] operations.mdの各ステップがスクリプト呼び出し後も正しい手順で動作する（ステップ6.5〜6.7のフローを手動で確認）
- [ ] `rsync` 同期が正常に動作する（`prompts/package/bin/` → `docs/aidlc/bin/` にスクリプトが反映される）
- [ ] 既存スクリプト（pr-ops.sh, write-history.sh等）が変更なく動作する（`git diff` で変更なしを確認）

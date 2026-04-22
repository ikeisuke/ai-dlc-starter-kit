# Unit: aidlc-setup の prompts/package/ 遺物純削除

## 概要

`skills/aidlc-setup/steps/01-detect.md:89-91` の v1 遺物（`prompts/package/` ディレクトリへの言及）を**純削除**する。実装上は無効な記述だが、メタ開発判定時の混乱を生んでいる。代替判定条件への書き換えは本 Unit 対象外（v2.5.0 以降のバックログで別扱い）。

## 含まれるユーザーストーリー

- ストーリー 5: aidlc-setup の prompts/package/ 遺物削除（#595）

## 責務

- `skills/aidlc-setup/steps/01-detect.md:89-91` の「メタ開発モード: `prompts/package/` ディレクトリが存在する場合は...」「通常利用: 対象プロジェクトのルートディレクトリに移動して...」記述を削除
- 削除に伴うアウトラインの整合確認（前後の見出し・箇条書きが破綻しないこと）
- aidlc-setup スキルの動作確認（純削除後の判定挙動が期待通り）:
  - (a) メタ開発リポジトリの dev worktree 内（`.aidlc/config.toml` あり）→ setup 済み遷移
  - (b) 外部プロジェクト想定のテスト用ディレクトリ + `.aidlc/config.toml` あり → setup 済み遷移
  - (c) 同 + `.aidlc/config.toml` なし → 新規 setup 案内
  - 3 ケースで「メタ開発モード判定」の言及が出力に含まれないことも確認
- CHANGELOG に「`skills/aidlc-setup/steps/01-detect.md` から `prompts/package/` 言及を純削除（代替判定条件は追加しない）」を明記

## 境界

- 代替判定条件（例: `version.txt` + `.claude-plugin/` ベース）の追加は本 Unit 対象外
- 必要性が確認された場合は別 Issue / 別ストーリー（v2.5.0 以降のバックログ）で扱う旨を CHANGELOG または GitHub Issue（後続バックログ Issue を起票）に記録するのみ
- aidlc-setup の他のセクション（バージョン比較・cycle.mode 等）への変更は本 Unit 対象外

## 依存関係

### 依存する Unit

- なし

### 外部依存

- `.claude-plugin/` ディレクトリの存在（v2.0.5 以降の構成、既存）
- `version.txt` ファイル（既存、本 Unit では参照のみ）

## 非機能要件（NFR）

- **パフォーマンス**: 該当なし（マークダウン記述削除のみ）
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: aidlc-setup スキル起動の 3 ケース動作確認すべて成功

## 技術的考慮事項

- 削除対象は `skills/aidlc-setup/steps/01-detect.md:89-91` の 3 行（前後文脈含めて 5-7 行程度の周辺確認）
- 代替判定条件の追加要否を判断するためのバックログ Issue を本 Unit 内で起票するか、Unit 完了報告で言及するかは Construction Phase 設計時に決定
- 本 Unit に関連する意思決定（DR-003: 純削除固定 / DR-007: 代替判定条件追加は本サイクル対象外）は、Inception 完了処理で `inception/decisions.md` に集約記録される（記録対象は `story-artifacts/user_stories.md` 末尾「Inception 完了時の意思決定記録対象」セクション参照）。本 Unit からは決定の追加実施は行わない

## 関連Issue

- #595
- 関連 PR #449（`prompts/package/` 削除 PR、コミットメッセージで参照）
- 関連 CHANGELOG: L471-473（v2.0.x の `prompts/package/` 削除記録、コミットメッセージで参照）

## 実装優先度

Medium（独立した小規模修正、いつでも実施可能）

## 見積もり

0.5 時間（記述削除 + 動作確認 + CHANGELOG 1 行）

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -

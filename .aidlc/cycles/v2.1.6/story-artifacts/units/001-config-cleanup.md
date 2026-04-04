# Unit: 設定キー整理

## 概要
config.tomlの不要・重複・スコープ違いの設定キーを整理する。preflight設定の削除、named_enabledとcycle.modeの統合、size_checkのスコープ見直し、旧キー名の更新を一括で実施する。

## 含まれるユーザーストーリー
- ストーリー 1: 不要なpreflight設定の削除（#520-1）
- ストーリー 2: named_enabledとcycle.modeの統合（#520-2）
- ストーリー 3: size_checkのスコープ見直し（#520-3）
- ストーリー 4: 旧キー名の更新（#520-4）

## 責務
- defaults.tomlからpreflight.enabled/checks、named_enabled、size_check関連キーを削除
- preflight.mdのオプションチェック分岐ロジック簡素化（常時全項目実行）
- 01-setup.mdのステップ7からnamed_enabledチェックを除去しcycle.mode直接参照に変更
- named_enabledの後方互換処理: 旧config.tomlにnamed_enabledが残っていても無視される（共通移行ポリシー: 削除済みキー無視。named_enabledは「削除」であり「改名」ではないため、フォールバック読み取りは不要）
- setupテンプレートからpreflight・size_check設定を除外
- size_checkの配置責務: defaults.tomlから除外し、メタ開発リポジトリのconfig.tomlに直接記載を維持。bin/check-size.shでread-config.sh経由の読み取りが引き続き動作することを確認（キー不在時はexit 1で無効扱い）
- common/rules.mdの設定仕様リファレンスでupgrade_check→version_checkに更新
- プリフライト設定値一括取得からpreflight関連キーを除去

## 境界
- read-config.shの新旧キーフォールバックロジック追加は本Unitでは行わない（Unit 002, 003で実施）
- bin/check-size.sh自体の実行ロジック変更は最小限（キー不在時のハンドリングのみ）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **後方互換性**: 旧config.tomlに削除済みキーが残っていてもエラーにならないこと

## 技術的考慮事項
- preflight.mdの手順4（設定値取得）と手順5（オプションチェック）を大幅に簡素化
- config.tomlテンプレート（setupスキル内）の更新も必要
- defaults.tomlの設定仕様リファレンスとcommon/rules.mdの整合性を確保

## 関連Issue
- #520

## 実装優先度
High

## 見積もり
小〜中規模（設定ファイル・プロンプトファイルの修正が中心）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-04-04
- **完了日**: 2026-04-04
- **担当**: AI
- **エクスプレス適格性**: -
- **適格性理由**: -

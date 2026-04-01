# Unit 001 計画: バージョン三角モデル比較

## 概要
Inception Phase ステップ6のバージョン比較ロジックを三角モデルに拡張し、aidlc-setup同期カスタムワークフローを廃止する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/steps/inception/01-setup.md` | ステップ6: 三角モデル比較ロジック実装（7パターン対応） |
| `.aidlc/rules.md` | 「aidlc-setup同期」カスタムワークフローセクション削除、パーミッション管理セクション内のaidlc-setup同期参照を更新 |
| `.aidlc/operations.md` | 「aidlc-setup同期」セクション（L76-80）の削除・更新 |

## 実装計画

### Phase 1: 設計
1. **ドメインモデル**: バージョン比較の3点モデル定義（リモート/スキル/ローカル設定）
2. **論理設計**: 比較パターン判定フローとアクション提示の設計

### Phase 2: 実装
1. `steps/inception/01-setup.md` ステップ6を書き換え:
   - スキルバージョン取得ロジック追加（SKILL.mdと同じベースディレクトリ配下の`version.txt`を参照。リポジトリルートの`version.txt`と混同しないこと）
   - 7パターンの比較分岐を実装
   - フェイルセーフ（スキルバージョン取得失敗時の2点間フォールバック）
   - アップグレード案内時のstarter_kit_version確認手順を明示
2. `.aidlc/rules.md` の「aidlc-setup同期」セクションを削除し、パーミッション管理セクション内の参照を更新
3. `.aidlc/operations.md` のaidlc-setup同期セクション（L76-80）を削除

## 完了条件チェックリスト
- [ ] 全一致（remote = skill = local）→「アクションなし（最新）」
- [ ] リモートのみ新しい（remote > skill = local）→ スキル更新を促す
- [ ] スキルのみ古い（remote = local > skill）→ スキル更新を促す
- [ ] ローカルのみ古い（remote = skill > local）→ `/aidlc setup`を促す
- [ ] ローカルのみ進んでいる（local > remote = skill）→ 警告表示
- [ ] 複数不一致（上記以外）→ 各差分表示、スキル更新→ローカル設定更新の順にアクション提示
- [ ] 比較不能（取得失敗）→ 取得できた情報で比較、不能箇所は警告表示して続行
- [ ] スキルバージョンはSKILL.mdベースディレクトリの`version.txt`から取得（リポジトリルートの`version.txt`ではない）
- [ ] スキルバージョン取得失敗時に従来の2点間比較にフォールバック
- [ ] アップグレード案内にstarter_kit_version確認手順が含まれている
- [ ] `.aidlc/rules.md` のaidlc-setup同期セクションが削除されている
- [ ] `.aidlc/operations.md` のaidlc-setup同期参照が削除・更新されている

# Unit 001: ベースライン計測 - 実装計画

## 設計方針
計測のみのタスクのため、Phase 1（設計）はスキップ。Phase 2でbaseline.mdを作成する。

## 実装内容
1. SKILL.mdの共通初期化フローに基づき、各フェーズの初回ロード対象ファイルを特定
2. `wc -c` で各ファイルのバイト数を計測
3. フェーズ別合計を算出
4. `.aidlc/cycles/v2.2.1/requirements/baseline.md` に記録

## 完了条件チェックリスト
- [ ] 各フェーズ（Inception/Construction/Operations）の初回ロード対象ファイルごとのバイト数が表形式で記録
- [ ] フェーズ別合計バイト数が算出
- [ ] 計測結果が `.aidlc/cycles/v2.2.1/requirements/baseline.md` に記録
- [ ] 計測対象ファイル一覧がSKILL.mdの共通初期化フローの読み込み指示と一致（対象外ファイル混入なし）

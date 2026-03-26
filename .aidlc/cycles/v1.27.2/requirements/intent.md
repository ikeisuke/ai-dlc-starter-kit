# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.27.2

## 開発の目的
`aidlc-setup.sh` の `resolve_starter_kit_root` 関数で warn メッセージが stdout に混入し、`STARTER_KIT_ROOT` パス解決が失敗するバグを修正する。

## ターゲットユーザー
AI-DLCスターターキットを使用する開発者

## ビジネス価値
- `project.starter_kit_repo` 未設定時でも `aidlc-setup.sh` が正常に動作し、パス解決が確実に成功する
- フォールバック処理の信頼性向上により、初回セットアップ時のエラーを防止する

## 成功基準
- `resolve_starter_kit_root` 関数の warn メッセージが stderr に出力され、stdout には純粋なパスのみが返される
- `project.starter_kit_repo` 未設定時に `aidlc-setup.sh --dry-run` が正常にパス解決できる

## スコープ

### 含まれるもの
- **#394**: aidlc-setup.sh のフォールバック警告が stdout に混入し STARTER_KIT_ROOT パス解決が失敗する
- **#391**: resolve_starter_kit_root 関数で warn メッセージが stdout に混入しパス解決が失敗する

### 除外するもの
- warn メッセージ体系全体の見直し
- aidlc-setup.sh のその他の機能改善

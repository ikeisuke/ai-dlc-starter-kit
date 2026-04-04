# Intent（開発意図）

## プロジェクト名
ai-dlc-starter-kit

## 開発の目的
v2.1.4リリース後に報告されたバグ修正と運用品質の向上。具体的には、aidlc-setupスキルのスクリプトパス解決バグの修正、post-merge-sync.shの出力ステータス明確化、およびdefaults.tomlをスキーマとしてconfig.tomlの欠落キーを検出し追記候補として提示する機能をaidlc-setup時に追加する。

## ターゲットユーザー
AI-DLCスターターキットの開発者（メタ開発チーム）および利用者

## ビジネス価値
- aidlc-setupのバージョン比較が正常動作し、アップグレードフローの信頼性が向上する
- post-merge-sync.shの出力が明確になり、成功と警告の区別がつくようになる
- バージョンアップ時にdefaults.tomlの新キーが追記候補として提示され、ユーザーが新設定の存在に気づける

## 成功基準
- #516: `/aidlc setup` 実行時のバージョン比較ステップで `read-config.sh` が正常に実行されること
- #515: post-merge-sync.shで補助操作失敗時に `status:warning` が出力されること（`status:success(warn:N)` ではなく）
- #517: `/aidlc setup` のアップグレードフロー実行時に、defaults.tomlに存在しconfig.tomlに欠落しているキーが検出され、追記候補として提示されること（ユーザー確認後に追記。自動更新はしない）
- 回帰防止: 既存の正常系セットアップが変わらず成功すること。既存設定値が保持されること。post-merge-sync.shの既存利用側が新しいステータス表現を解釈可能であること

## 含まれるもの
- #516: aidlc-setupスキルの `read-config.sh` パス解決修正
- #515: post-merge-sync.shの出力ステータス明確化（success/warning区別）
- #517: defaults.tomlをスキーマとしたconfig.toml欠落キー検出・追記候補提示機能（aidlc setup時のみ実行）
- 設定ファイル（config.toml / defaults.toml）の説明をREADMEまたはドキュメントに追加

## 含まれないもの
- プリフライトチェックでの欠落キー検出（#517の実行タイミングはaidlc setup時のみ）
- #492: 並列ワークツリー実装
- #443: Operations Phase自律実行モード

## 期限とマイルストーン
patchリリース（v2.1.5）

## 制約事項
- #516の修正はスキル間依存ルール（他スキルの内部実装への依存禁止）を遵守する必要がある
- #517のスクリプトはdaselを利用してTOML解析を行う（既存のread-config.shと同様）
- #517の欠落キー判定: defaults.tomlのリーフキー（値を持つ最終キー）単位で判定する。ネストしたテーブルも対象。既存値は上書きしない（欠落キーのみ追記）。コメント・書式の保持は保証対象外（daselによる追記のため）
- #515の出力変更: post-merge-sync.shの出力をパースする既存スクリプトがないことを確認した上で変更する

## 不明点と質問（Inception Phase中に記録）

[Question] #517の欠落キー検出・追記候補提示の実行タイミングはいつが適切か？
[Answer] aidlc setup時のみ。プリフライトチェックでは実行しない。

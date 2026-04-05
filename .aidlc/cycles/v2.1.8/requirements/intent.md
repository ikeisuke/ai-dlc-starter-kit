# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v2.1.8

## 開発の目的
AI-DLC設定体系の整理と安定性向上。Git関連設定キーが複数セクションに分散しており見通しが悪い問題、サイクル固有でない共通設定ファイルがサイクルディレクトリに配置されている構造的問題、およびdasel v3環境でのセットアップ時バージョン比較エラーを解決する。

## ターゲットユーザー
AI-DLC Starter Kitの利用者および開発者

## ビジネス価値
- 設定構造の簡素化により、新規ユーザーの理解コストを削減
- config.tomlの設定キー体系を統一し、保守性を向上
- dasel v3環境でのセットアップ失敗を解消し、環境互換性を向上

## 含まれるもの
1. **Git関連設定キーの統合** (#521): `rules.branch`, `rules.worktree`, `rules.unit_branch`, `rules.squash`, `rules.commit` を `[rules.git]` セクションに集約。旧キーのフォールバック読み取り、defaults.toml同期、プロンプト内参照箇所の更新を含む
2. **共通設定ファイルの内容整理** (#437): `.aidlc/rules.md` と `.aidlc/operations.md` の内容を整理・再構成する。ファイル配置は既に `.aidlc/` 直下に完了済み。設定的な内容は `config.toml` への統合を検討し、フェーズ固有の記述は適切に分離する
3. **daselエラー修正** (#528): aidlc-setupのバージョン比較でdasel v3の `dasel query` サブコマンド形式に対応、またはdasel非依存のフォールバックを追加

## 含まれないもの
- コンテキストサイズ圧縮 (#519) — 別サイクルで対応
- 新機能の追加
- 既存の動作変更（後方互換性を維持）

## 成功基準
- `[rules.git]` に統合された設定キーで `read-config.sh` による読み取りが成功し、Inception/Construction/Operations各フェーズのプリフライトチェックが通ること
- 旧キー形式（`rules.branch.mode`, `rules.squash.enabled` 等）での設定が `read-config.sh` のフォールバック読み取りで引き続き動作すること
- `.aidlc/rules.md` と `.aidlc/operations.md` の内容が整理され、設定的な項目は `config.toml` に移行されていること
- dasel v3環境で `aidlc-setup` のバージョン比較が正常動作すること（dasel v2との両方で動作確認）
- 更新対象: `defaults.toml`、`read-config.sh`、`preflight.md`、および `rules.*` キーを参照するステップファイル群の参照が更新されていること

## 期限とマイルストーン
特になし（通常のサイクルペース）

## 制約事項
- 後方互換性の維持（旧キーのフォールバック読み取り必須）
- メタ開発の意識: スキル内リソース編集は `skills/aidlc/` 配下（META-001）
- `$()` コマンド置換の使用禁止

## 不明点と質問（Inception Phase中に記録）

[Question] #519（コンテキストサイズ圧縮）は今回のスコープに含めるか？
[Answer] 対象外。別サイクルで対応する。

[Question] #528（daselエラー修正）はスコープに含めるか？
[Answer] 含める。#521/#437とは独立しているため並列実行可能。

[Question] 実行順序は #521→#437→#528 でよいか？ #528は並列可能か？
[Answer] #521→#437 は順序依存あり。#528は独立しているため並列実行可能。

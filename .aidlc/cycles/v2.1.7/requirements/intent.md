# Intent（開発意図）

## プロジェクト名
ai-dlc-starter-kit

## 開発の目的
`aidlc-setup` スキルが `aidlc` スキルの内部ファイル（`config/defaults.toml`）に直接依存している箇所を修正し、`.aidlc/rules.md` のスキル間依存ルール（他スキルの内部実装への依存禁止）に準拠させる。

## ターゲットユーザー
AI-DLCスターターキットの開発者（メタ開発チーム）および利用者

## ビジネス価値
- スキル間の疎結合が維持され、スキル更新時の波及範囲が限定される
- `aidlc` スキルの内部構造変更が `aidlc-setup` に影響しなくなる
- スキル間依存ルールの一貫性が保たれ、ルールの信頼性が向上する

## 成功基準
- #526-1: `aidlc-setup` の欠落キー検出機能が `aidlc` スキルの `config/defaults.toml` を直接参照しなくなること。検証: `skills/aidlc-setup/steps/02-generate-config.md` および `skills/aidlc-setup/scripts/` 内に `aidlc` スキルの内部パスへの参照がないこと
- #526-2: 欠落キー検出機能が従来通り正常に動作すること。検証: `config.toml` から既知のキー（例: `rules.squash.enabled`）を一時的に除去した状態で `/aidlc setup` のアップグレードモードを実行し、該当キーが追記候補として表示され、既存キーが誤検出されないこと
- #526-3: `aidlc` スキルの既存機能の入出力互換性が維持されること。検証: `aidlc` スキルの既存フロー（プリフライトチェック、設定読み込み等）が変更前と同一の動作をすること
- #526-4: コピー時点で `skills/aidlc/config/defaults.toml` と `skills/aidlc-setup/config/defaults.toml` のTOML設定値部分が一致すること。検証: コメント行を除外した `diff` で差分が0であること（同期用コメントの追加は許容）

## 含まれるもの
- `aidlc-setup` から `aidlc` スキルの `config/defaults.toml` への直接参照の除去
- `defaults.toml` を `aidlc-setup` スキル内（`config/defaults.toml`）にコピーして自スキル内で完結させる
- `aidlc-setup` の `02-generate-config.md` のパス解決ロジックを自スキル内の `defaults.toml` を参照するよう修正
- 関連するステップファイルの修正

## 含まれないもの
- `detect-missing-keys.sh` のロジック変更（入出力インターフェイスは維持）
- 他のスキル間依存違反の修正（本サイクルは #526 のみ）
- `defaults.toml` の内容変更

## 推奨方針
`defaults.toml` を `aidlc-setup` スキル内にコピーする方式を採用する。同期責任はメタ開発チームが担い、`aidlc` スキル側の `defaults.toml` 更新時に `aidlc-setup` 側も手動で同期する。公開インターフェイス追加は将来的な選択肢として残すが、本パッチではコピー方式で対応する。

## 期限とマイルストーン
パッチリリース（v2.1.7）

## 制約事項
- `detect-missing-keys.sh` の `--defaults` 引数インターフェイスは変更しない
- スキル間依存ルールに準拠すること（他スキルの `scripts/`, `steps/`, `templates/` 等の内部ファイルパスへの依存禁止）
- `aidlc` スキルへの変更は加えない（既存フローへの非回帰を保証）

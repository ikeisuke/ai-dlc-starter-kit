# Unit 001 計画: aidlc-setupバージョン比較修正

## 概要
aidlc-setupスキルの01-detect.mdが`scripts/read-config.sh`を参照するが、aidlc-setupの`scripts/`には存在しないバグを修正する。

## 対応方針
`01-detect.md`の101行目 `scripts/read-config.sh starter_kit_version` を、AIエージェントへの直接指示に変更する。具体的には `.aidlc/config.toml` から `dasel` で `starter_kit_version` を直接読み取る方式に変更する。

**採用理由**: `read-version.sh`はスキルの`version.txt`を読むスクリプトであり、config.tomlの設定値取得には使えない。`read-config.sh`はaidlcスキル固有のスクリプトでありスキル間依存ルールにより参照できない。dasel直接呼び出しなら外部ツール依存のみでスキル間依存は発生しない。

## 完了条件チェックリスト
- [ ] `/aidlc setup` 実行時のバージョン比較ステップが正常完了すること
- [ ] ローカルバージョン（starter_kit_version）が正常に取得できること
- [ ] スキル間依存ルールに違反しないこと
- [ ] 既存の正常系セットアップが変わらず成功すること
- [ ] starter_kit_versionが未設定・空値の場合にフェイルセーフ（警告+スキップ）が動作すること
- [ ] バージョン取得失敗時にアップグレード不要と誤判定しないこと

## 変更対象ファイル
- `skills/aidlc-setup/steps/01-detect.md` — バージョン取得方法の変更

## リスク
- 低: 変更はプロンプトファイルのみ。実行時の挙動はAIエージェントの解釈に依存するが、明確な指示に変更するためリスクは限定的。

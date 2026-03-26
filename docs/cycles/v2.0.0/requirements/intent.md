# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v2.0.0 - スキル化・プラグイン化

## 開発の目的
AI-DLCのフェーズプロンプト（Inception/Construction/Operations各1,000-1,400行）をClaude Codeスキルとして切り出し、ユーザーレベルプラグインとして配布可能にする。これにより、利用プロジェクト側にAI-DLCファイルを同期する必要がなくなり、プロジェクトのフットプリントを最小化（`.aidlc/config.toml` + `.aidlc/cycles/` のみ）する。

## ターゲットユーザー
- AI-DLCを利用する開発者
- AI-DLC Starter Kitの開発者（ドッグフーディング）

## ビジネス価値
- **フットプリント削減**: 利用プロジェクトから `docs/aidlc/` の大量ファイルが不要になる
- **アップデート簡易化**: プラグイン更新のみで最新版を利用可能（rsync同期不要）
- **保守性向上**: 巨大プロンプトのステップ分割により、個別ステップの修正・テストが容易
- **配布統一**: marketplace.jsonによるプラグイン配布で一貫した導入体験

## 成功基準
- 全フェーズ（Inception/Construction/Operations/Setup）がスキルとして動作すること
- プラグインインストールから別プロジェクトで `/aidlc inception` が実行できること
- v1プロジェクト（`docs/aidlc.toml` + `docs/cycles/`）からの移行が可能なこと
- 既存の6スキル（aidlc, reviewing-code/architecture/inception/security, squash-unit）が正常動作すること

## 期限とマイルストーン
- Unit 001（PoC）完了後に本格実装判断
- Unit 005-008は並列実装可能

## 制約事項
- Claude Codeのスキル・プラグイン機構に依存（オンデマンドReadのパス解決等）
- PoC検証で不可の場合は@参照フォールバック戦略を採用
- `docs/aidlc/` は直接編集禁止（`prompts/package/` がソース）
- v2.0.0はメジャーバージョンアップのため、後方互換性を維持しつつ移行パスを提供

## 不明点と質問（Inception Phase中に記録）

[Question] オン���マンドReadでスキルディレクトリからの相対パスが解決可能か？
[Answer] Unit 001のPoCで検証する。不可の場合は@参照にフォールバック。

[Question] スキル間呼び出し（SkillツールでスキルAからスキルBを呼び出し）は可能か？
[Answer] Unit 001のPoCで検証する。不可の場合はreviewing-*の内容をstepsにコピー。

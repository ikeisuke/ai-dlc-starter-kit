# Intent（開発意図）

## プロジェクト名
ai-dlc-starter-kit

## 開発の目的
config.tomlの設定キーに存在する不要・重複・スコープ違いの項目を整理し、関連する設定の統合・簡素化を行う。具体的には、不要なpreflight設定の削除、named_enabledとcycle.modeの重複解消、size_checkのスコープ見直し、旧キー名の更新、history.levelとdepth_levelの統合、lintingのカスタムコマンド対応、およびcyclesディレクトリのgit管理外オプション追加を実施する。

## ターゲットユーザー
AI-DLCスターターキットの開発者（メタ開発チーム）および利用者

## ビジネス価値
- 設定ファイルの見通しが改善され、ユーザーが設定の意図を理解しやすくなる
- 重複設定の解消により、設定ミスや混乱を防止する
- lintingのカスタムコマンド対応により、プロジェクト固有のlinter利用が可能になる
- cyclesディレクトリのgit管理外オプションにより、OSSリポジトリでの利用体験が向上する

## 成功基準
- #520-1: preflight設定（enabled/checks）がdefaults.toml・config.tomlから削除され、プリフライトチェックが常時実行されること。検証: preflight関連キーを削除したconfig.tomlで `/aidlc inception` が正常に起動すること
- #520-2: named_enabledが削除されcycle.modeのみで制御されること。検証: `cycle.mode=default/named/ask` の3値で従来と同等の動作をすること
- #520-3: size_check設定がdefaults.tomlから除外され、メタ開発リポジトリのconfig.tomlにのみ残ること（一般ユーザーのconfig.tomlには含まれない。メタ開発リポジトリではconfig.toml内で直接設定し、read-config.shで読み取り可能）。検証: size_checkキーがないconfig.tomlでエラーが発生しないこと
- #520-4: common/rules.mdの設定仕様リファレンスでupgrade_check.enabledがversion_check.enabledに更新されていること
- #522: rules.history.levelがrules.depth_level.history_level配下に統合され、未指定時はdepth_levelから自動導出されること（minimal→minimal、standard→standard、comprehensive→detailed）。明示指定時はその値が優先されること。検証: 旧キー `rules.history.level` のみ設定されたconfig.tomlでも正常に読み取れること（新キー優先、旧キーフォールバック）
- #523: rules.lintingにenabled/commandキーが追加され、カスタムlintコマンドが指定可能であること。検証: 旧キー `markdown_lint=true` のみ設定されたconfig.tomlでも `enabled=true` として動作すること（新キー優先、旧キーフォールバック）
- #434: config.tomlにrules.cycle.git_tracked設定が追加され、falseの場合にaidlc-setup時に`.gitignore`への追記を案内すること（案内のみ、自動変更は行わない）。既に追跡済みのファイルの解除は行わない。検証: `rules.cycle.git_tracked=false` 設定時にsetupで案内メッセージが表示されること

## 含まれるもの
- config.toml設定キーの整理・不要設定の削除（#520）
- rules.historyとrules.depth_levelの統合（#522）
- rules.lintingにカスタムコマンド指定を追加（#523）
- .aidlc/cycles/をgit管理外にするオプション（#434）

## 含まれないもの
- Git関連設定キーの統合（#521 - 次サイクル以降）
- コンテキストサイズ圧縮（#519 - 別スコープ）
- その他のRoadmap中期・長期項目

## 期限とマイルストーン
特になし

## 制約事項
- 既存のconfig.tomlとの後方互換性を維持すること
- defaults.tomlのデフォルト値が変更される場合、既存ユーザーの動作に影響がないこと
- 設定キーの削除・リネーム時の移行ポリシー:
  - 新旧キー同時指定時は新キーを優先する
  - 旧キーのみ指定時はフォールバックとして読み取る（read-config.sh内で解決）
  - 旧キー使用時の警告表示は任意（Construction Phaseで設計判断）
  - 旧キーは少なくとも次のメジャーバージョンまで維持する（廃止時は別Issueで定義）
- #434のcycles_git_tracked: 自動でファイルシステムやGit管理を変更しない（案内のみの非破壊方針）。既に追跡済みのファイルのuntrackは行わない

## 不明点と質問（Inception Phase中に記録）

なし（Roadmap #524および各Issue詳細から要件が明確）

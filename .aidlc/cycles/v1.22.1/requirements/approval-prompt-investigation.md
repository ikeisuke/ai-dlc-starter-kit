# 承認プロンプト頻発の原因調査結果

## 調査概要

- **調査日**: 2026-03-15
- **対象**: semi_autoモードでのClaude Code承認プロンプト頻発
- **調査方法**: `.claude/settings.local.json` の allowリスト分析、プロンプトファイル内Bashコマンドパターンの網羅的調査

## 特定されたパターン

### パターン1: 相対パスと絶対パスの重複登録

**症状**: 同一コマンドが相対パスと絶対パスの両方でallowリストに登録されている。AIが一方の形式でコマンドを生成した際に、もう一方しか許可されていなければ承認プロンプトが発生する。

**該当例**:
```
Bash(docs/aidlc/bin/write-history.sh:*)
Bash(/Users/keisuke/.../docs/aidlc/bin/write-history.sh:*)
```

同様の重複:
- `check-gh-status.sh`
- `check-backlog-mode.sh`
- `read-config.sh`
- `sync-package.sh`
- `run-markdownlint.sh`
- `pr-ops.sh`
- `issue-ops.sh`
- `check-setup-type.sh`

**原因**: Claude Code がワーキングディレクトリや呼び出しコンテキストによって相対パス/絶対パスを使い分けるため、最初の承認時に登録されたパス形式と異なる形式が使用されると再度承認を要求される。

**対策案**: プロンプトファイル内のコマンド記述を相対パスに統一する（既に統一済み）。`settings.local.json` はユーザー固有ファイルのため、スターターキット側での対応は限定的。ドキュメントでの案内を検討。

### パターン2: セッション固有の一時ファイルパスの蓄積

**症状**: 一度だけ使用される一時ファイルパスがallowリストに永続的に蓄積される。

**該当例**:
```
Bash(/private/tmp/codex-review-unit002.md:*)
Bash(/private/tmp/codex-review-unit002-r2.md:*)
Bash(/private/tmp/codex-review-unit003.md:*)
Bash(/private/tmp/codex-review-unit003-r2.md:*)
Bash(/private/tmp/commit-msg-unit004.txt:*)
Bash(/tmp/test-gh-api.sh:*)
Bash(/tmp/pr-body.txt:*)
Bash(/tmp/commit-msg.txt:*)
Bash(/tmp/aidlc-commit-msg.txt:*)
```

**原因**: 一時ファイルパスが固定名で使用された場合、そのパスがallowリストに追加される。次セッションで別のパス名が使用されると再承認が必要。

**対策案**: v1.22.0で導入したテンポラリファイル規約（`mktemp /tmp/aidlc-*.XXXXXX`）により、`mktemp` コマンド自体はパターンで許可済み（`Bash(mktemp /tmp/aidlc-history-content.XXXXXX)` 等）。一時ファイルへの書き込みはWriteツール（承認不要）、削除は`\rm`で行う設計のため、新規パターンでの一時ファイル操作では承認プロンプトは発生しにくい。既存の固定名パスは手動クリーンアップが必要。

### パターン3: curlコマンドの未許可

**症状**: `inception.md` のステップ5でバージョン確認に使用する `curl` コマンドがallowリストに存在しない。

**該当コマンド**:
```bash
curl -s --max-time 5 https://raw.githubusercontent.com/ikeisuke/ai-dlc-starter-kit/main/version.txt 2>/dev/null
```

**原因**: `curl` は外部ネットワークアクセスを伴うため、Claude Codeが安全性を自動判定できない。

**対策案**: Unit 003で追加した `rules.upgrade_check.enabled = false` 設定により、オフライン環境やCI環境ではcurlコマンドの実行自体をスキップ可能。allowリストへの追加はユーザー判断。

### パターン4: allowリストのグロブパターン不足

**症状**: `docs/aidlc/bin/` 配下のスクリプトが個別にallowリストに登録されており、新しいスクリプトが追加されるたびに承認プロンプトが発生する。

**現状**: 14個以上の個別エントリが存在。

**対策案**: `Bash(docs/aidlc/bin/*:*)` のようなグロブパターンで一括許可する方法をドキュメントで案内。ただし、Claude Codeの`allowedTools`パターンがグロブをサポートするかは要確認（Claude Code側の仕様依存）。

### パターン5: \rm（エイリアス回避）の未許可

**症状**: `\rm` コマンドがallowリストに存在しない。一時ファイル削除時に毎回承認プロンプトが発生する可能性。

**原因**: `.claude/CLAUDE.md` で `\rm` 使用を指示しているが、Claude Code のallowリストには登録されていない。

**対策案**: `\rm` の許可パターンをセットアップ時に自動追加するか、ドキュメントで案内する。

## 根本原因の分析

承認プロンプト頻発の根本原因は以下の3点に集約される:

1. **Claude Codeの許可モデルとAI-DLCの設計のミスマッチ**: AI-DLCは多数のシェルスクリプトを使用するが、Claude Codeは個別コマンドごとの許可を要求する
2. **パス形式の非一貫性**: 同一コマンドが相対パス・絶対パスの両方で実行される
3. **一時的リソースの永続的登録**: セッション固有のパスがallowリストに蓄積される

## 対策の方向性

| 対策 | 実現可能性 | 効果 | 実施時期 |
|------|-----------|------|---------|
| ドキュメントでallowリスト推奨設定を案内 | 高 | 中 | 次サイクル |
| セットアップスクリプトでsettings.jsonにデフォルト許可パターンを追加 | 中 | 高 | 次サイクル |
| プロンプト内のコマンドパス形式を完全統一 | 高 | 低（既に概ね統一済み） | 対応不要 |
| 一時ファイル規約の徹底（mktemp使用の強制） | 高 | 中 | v1.22.0で導入済み |

## バックログ登録対象

1. **セットアップ時のデフォルト許可パターン追加** - `settings.json` にAI-DLC標準コマンドの許可パターンを自動追加する機能（Issue #329関連）

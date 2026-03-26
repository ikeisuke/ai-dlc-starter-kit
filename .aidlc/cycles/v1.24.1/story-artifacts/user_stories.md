# ユーザーストーリー

## Epic: バグ修正・リファクタリング

**ツール依存方針**: 共通プロンプト（`prompts/package/prompts/`）は原則ツール非依存で記述する。ツール固有の補足が必要な場合は注記として分離する。プロジェクト固有ルール（`rules.md`）はツール固有記述を許容する。

### ストーリー 1: aidlc-setup.shの同期スキップバグ修正（#362）
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to aidlc-setup.shがバージョン一致時でもファイル差分を検出して同期を実行する
So that Operations Phaseでの同期漏れを防止し、手動rsyncによる回避が不要になる

**受け入れ基準**:
- [ ] `prompts/package/` と `docs/aidlc/` にファイル差分がある場合、バージョンが一致していても同期が実行される
- [ ] ファイル差分がない場合は従来通り `skip:already-current` を返す
- [ ] `--force` フラグ指定時は従来通り無条件で同期が実行される（終了コード0、sync出力あり）
- [ ] `--dry-run` フラグ指定時は従来通り差分表示のみで実際の同期は行われない
- [ ] rsyncコマンド実行に失敗した場合、エラーメッセージを出力し非ゼロ終了コードを返す

**技術的考慮事項**:
- `aidlc-setup.sh` L254-262の早期終了ロジックを修正
- rsync dry-run結果で差分有無を判定する方式を検討

---

### ストーリー 2: PRマージ前レビューの汎用化（#361）
**優先順位**: Should-have

As a AI-DLC利用者
I want to PRマージ前レビューステップがツール非依存で記述されている
So that Codex以外のレビューツールを使用するプロジェクトでも同じフローを利用できる

**受け入れ基準**:
- [ ] `operations-release.md` の7.13節からcodex, claude等の具体的ツール名が除去されている
- [ ] PRマージ前にレビューを実施するステップ自体は維持されている
- [ ] `rules.md` の「Codex PRレビューの再実行ルール」「PRマージ前レビューコメント確認」はプロジェクト固有ルールとして維持される
- [ ] 汎用化されたステップがツール選択をプロジェクトに委ねる記述になっている
- [ ] 対象ファイルが存在しない場合、スキップされる旨が記述されている

**技術的考慮事項**:
- `operations-release.md` L492-571のサブステップ1-3を汎用化
- `rules.md` のプロジェクト固有ルールとの役割分離を明確化

---

### ストーリー 3: operations.mdのスリム化（#365）
**優先順位**: Should-have

As a AI-DLC利用者
I want to operations.mdの冗長な情報が削減されている
So that Operations Phase開始時のコンテキスト消費が抑えられ、AIの応答品質が維持される

**受け入れ基準**:
- [ ] operations.mdの総行数（`wc -l` 基準、空行含む）がv1.24.0時点の178行から50%以上削減されている（89行以下）
- [ ] aidlc.tomlから取得可能な情報（プロジェクト概要等）が除去されている
- [ ] git logと重複する更新履歴セクションが除去されている
- [ ] rules.mdに移動済みのメタ開発手順が除去されている
- [ ] デプロイ方針・既知の問題等の運用固有情報は維持されている
- [ ] テンプレート（operations_handover_template.md）の総行数が60行から30行以下に削減されている
- [ ] operations.mdが存在しない場合でもOperations Phaseは警告を出して継続できる（既存動作を維持）

**技術的考慮事項**:
- `docs/cycles/operations.md`（178行）と `prompts/package/templates/operations_handover_template.md`（60行）の両方を修正
- operations.mdは `docs/cycles/` 直下のため、`prompts/package/` ではなく直接編集

---

### ストーリー 4: ブランチ切り替え後のrules.md再読み込み（#363）
**優先順位**: Should-have

As a AI-DLC利用者
I want to ブランチ切り替え後にrules.mdが再読み込みされる
So that サイクルブランチのrules.mdが確実に適用される

**受け入れ基準**:
- [ ] inception.mdのステップ11（ブランチ切り替え）完了後にrules.mdの再読み込みステップが追加されている
- [ ] mainブランチからサイクルブランチに切り替えた場合にrules.mdが最新の内容で読み込まれる
- [ ] ブランチが切り替わらない場合（現在のブランチで続行）は再読み込みをスキップする
- [ ] rules.mdが存在しない場合はエラーにならずスキップされる

**技術的考慮事項**:
- `prompts/package/prompts/inception.md` ステップ11の末尾に再読み込みロジックを追加
- ブランチが実際に切り替わった場合のみ実行する条件分岐

---

### ストーリー 5: テンポラリファイル規約の補完（#341）
**優先順位**: Should-have

As a AI-DLC利用者
I want to テンポラリファイル規約にmktemp後のRead必須ステップが明記されている
So that AIツールのWriteツールで既存ファイル未読エラーが発生しない

**受け入れ基準**:
- [ ] `common/rules.md` のテンポラリファイル規約の使用手順にmktemp後のReadステップが追加されている
- [ ] 手順が「1.パス生成 → 2.Read呼び出し → 3.書き込み → 4.使用 → 5.削除」の5ステップになっている
- [ ] Readステップの目的（既存ファイル認識のため）が注記されている

**技術的考慮事項**:
- `prompts/package/prompts/common/rules.md` L419-425の使用手順を修正
- 注記としてClaude Code等の具体的ツール名は使わず、一般的な説明とする

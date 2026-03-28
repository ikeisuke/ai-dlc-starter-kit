# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v2.0.5 — skills/正本化とv1残存インフラ排除

## 開発の目的
`skills/` ディレクトリをプラグインの唯一の正（Single Source of Truth）として確立し、`docs/aidlc/`・`prompts/` 等のv1残存インフラを排除する。スキルが使用するリソース（guides等）はスキル配下に移動し、スキルが使用しないリソース（テスト、Kiro設定等）は別の適切な場所に再配置する。旧v1エントリポイントは後方互換のため残すが、新しいプラグイン構造への誘導を行う。

## ターゲットユーザー
AI-DLCスターターキットの利用者および開発者

## ビジネス価値
- ファイルの正本が一箇所に集約され、「どこが正しいか」の混乱がなくなる
- `docs/aidlc/` と `skills/aidlc/` の二重管理（rsync同期等）が不要になる
- プラグインモデルとして自己完結し、`claude install` での利用が完全に機能する
- v1残存コードの除去によりメンテナンスコストが削減される

## 含まれるもの
1. **docs/aidlc/ の分解・統合**: 以下のマッピングに従いファイルを移動・削除する
   - `docs/aidlc/guides/` → `skills/aidlc/guides/` に移動（スキルが参照するため）
   - `docs/aidlc/prompts/` → 削除（`skills/aidlc/steps/` と重複）
   - `docs/aidlc/templates/` → 削除（`skills/aidlc/templates/` と重複）
   - `docs/aidlc/lib/validate.sh` → 削除（`skills/aidlc/scripts/lib/validate.sh` と重複）
   - `docs/aidlc/tests/` → `skills/aidlc/scripts/tests/` に移動（スキルスクリプトのテスト）
   - `docs/aidlc/kiro/` → `kiro/` （ルート直下）に移動（スキル非依存のKiro CLI設定）
   - `docs/aidlc/AGENTS.md`, `docs/aidlc/CLAUDE.md` → 削除（`skills/aidlc/` に既存）
2. **prompts/ のv1インフラ廃止**: setup-prompt.md の簡略化（誘導文のみに縮小）、rsync同期スクリプト（`prompts/bin/sync-package.sh`）削除、`prompts/setup/` 配下のv1パスハードコード更新（#450, #449, #448）
3. **パス参照の一括更新**: `{{aidlc_dir}}/guides/...` 参照をスキル内相対パス（`guides/...`）に変更、`config.toml` の `aidlc_dir` キーを廃止
4. **aidlc-setup.sh パス解決修正**: `resolve_starter_kit_root()` でシンボリックリンクを `readlink` で解決してからパスを組み立てる（#447）
5. **update-version.sh v2対応**: `docs/aidlc.toml` 参照を `.aidlc/config.toml` に変更、または `version.txt` 直接更新に簡素化（#444）
6. **バックログ即時実装ルール追加**: `steps/common/agents-rules.md` に「ユーザーが即時実装を指示した場合はバックログに回さない」ルールを追加（#439）
7. **旧エントリポイントの誘導**: v1互換の旧エントリポイントは残しつつ、新しいプラグイン構造への誘導メッセージを設置

## 含まれないもの
- 機能追加（#443, #442, #441, #440）
- プロンプトの分岐条件・実行順・判定ロジックの変更（許容される変更はパス更新、誘導文追加、互換性維持に必要な最小限の文言変更に限定）
- `.aidlc/config.toml` のスキーマ変更（`aidlc_dir` キーの廃止は含むが、他の設定構造は変更しない）

## 成功基準
- `grep -r 'docs/aidlc' skills/ steps/ scripts/ --include='*.md' --include='*.sh'` の結果が0件であること
- `docs/aidlc/` ディレクトリが存在しないこと（`ls docs/aidlc/ 2>/dev/null` が空）
- `skills/aidlc/guides/` に18件のガイドファイルが移動されていること
- `prompts/bin/sync-package.sh` が存在しないこと
- `prompts/setup-prompt.md` に「v2ではプラグインモデルを使用してください」相当の誘導文が設置されていること
- `skills/aidlc/scripts/tests/` に `docs/aidlc/tests/` から移動したテストファイルが存在すること
- `kiro/` ディレクトリにKiro CLI設定が移動されていること
- `.aidlc/config.toml` から `aidlc_dir` キーが除去されていること（または非推奨マーク付き）
- #447, #450, #449, #448, #444, #439 のIssueが解決されていること

## 後方互換性の対象と期待動作

| 利用経路 | 期待動作 |
|---------|---------|
| `/aidlc setup` 実行 | `skills/aidlc/steps/setup/` を参照して正常動作 |
| 旧 `setup-prompt.md` 経由起動 | 誘導メッセージを表示し `/aidlc setup` の使用を案内 |
| `.claude/skills/aidlc` シンボリックリンク | `skills/aidlc` を実体として引き続き動作（リンク構造維持） |
| 既存 `aidlc_dir` 設定を持つプロジェクト | `aidlc_dir` 未設定でもスキル内パスで動作。既存設定は無視（エラーにはならない） |
| `claude install` でのプラグインインストール | `skills/` 配下が自己完結しており、追加ファイルのコピー不要 |

## 期限とマイルストーン
特になし（品質優先）

## 制約事項
- スキルの `SKILL.md` の base directory 指定との整合性を保つ
- `.claude/skills/aidlc` → `skills/aidlc` のシンボリックリンク構造は維持
- 後方互換のため、旧エントリポイント（`prompts/setup-prompt.md`）は即座に削除せずリダイレクト用に残す。`docs/aidlc/` 配下のファイル（AGENTS.md, CLAUDE.md等）はエントリポイントではないため完全削除対象

## 不明点と質問（Inception Phase中に記録）

[Question] docs/aidlc/lib/validate.sh はどこに移動すべきか？
[Answer] skills/aidlc/scripts/lib/validate.sh に既存コピーあり。docs/aidlc/lib/ は重複のため削除。

[Question] docs/aidlc/tests/ 配下のテストはどこに移動すべきか？
[Answer] skills/aidlc/scripts/tests/ に移動。セットアップ専用テストも含め、スキル配下のテストディレクトリに統合する。

[Question] docs/aidlc/kiro/ はどこに移動すべきか？
[Answer] ルート直下の kiro/ に移動。スキル非依存のKiro CLI設定のため、skills/ 配下には置かない。

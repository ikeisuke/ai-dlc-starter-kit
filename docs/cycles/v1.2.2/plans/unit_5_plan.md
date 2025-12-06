# Unit 5: サイクル固有バックログ確認 - 実装計画

## 概要
Inception Phaseでサイクル固有バックログ（`docs/cycles/{{CYCLE}}/backlog.md`）も確認するようにする

---

## 簡易実装先確認

### 1. 対象ファイルの分類

| ファイル | 分類 | 変更種別 |
|---------|------|----------|
| `prompts/package/prompts/inception.md` | ツール側 | 既存修正 |
| `prompts/package/prompts/lite/inception.md` | ツール側 | 既存修正 |

**注意**: `docs/aidlc/prompts/` は rsync でコピーされるため、ツール側（`prompts/package/prompts/`）のみを変更

### 2. 実装先ファイル一覧と変更概要

#### (1) `prompts/package/prompts/inception.md`
- **変更箇所**: ステップ3「バックログ確認」
- **変更内容**:
  - 既存: `docs/cycles/backlog.md`（共通バックログ）のみ確認
  - 追加: `docs/cycles/{{CYCLE}}/backlog.md`（サイクル固有バックログ）も確認
  - 確認の順序: 共通バックログ → サイクル固有バックログ

#### (2) `prompts/package/prompts/lite/inception.md`
- **変更箇所**: 特になし（Full版を参照するため）
- **確認内容**: Full版の変更がそのまま反映されることを確認

---

## 追加作業

### Unit 2 のバックログ戻し
- `docs/cycles/v1.2.2/construction/progress.md` から Unit 2 を削除
- `docs/cycles/backlog.md`（共通バックログ）に Unit 2 の内容を追加

---

## 実装手順

1. `prompts/package/prompts/inception.md` を編集
   - ステップ3のバックログ確認にサイクル固有バックログの確認を追加

2. rsync でコピー
   - `docs/aidlc/prompts/inception.md` に変更を反映

3. Unit 2 をバックログに戻す
   - progress.md から Unit 2 を削除
   - 共通バックログに追加

4. progress.md 更新
   - Unit 5 を「完了」に変更

---

## 完了基準

- [x] 対象ファイルの変更完了
- [ ] rsync でコピー完了
- [ ] Unit 2 のバックログ戻し完了
- [ ] ビルド成功（該当なし）
- [ ] テストパス（該当なし）

# 論理設計: reviewing-inception AIDLC固有観点の追加

## 概要
reviewing-inception SKILL.md のレビュー観点セクションに2つの新規観点を追加し、セルフレビューテンプレートを更新する。

## 変更対象
`prompts/package/skills/reviewing-inception/SKILL.md`（正本。`.claude/skills/` と `docs/aidlc/skills/` は aidlc-setup 同期でコピーされる）

## 追加位置
既存の「Unit定義品質」セクションの後に、2つの新規セクションを追加する。

## セルフレビューテンプレート
指示テンプレート内の「レビュー観点」参照は `{本SKILL.mdの「レビュー観点」セクション内容}` で動的に解決されるため、SKILL.md の観点セクションを更新するだけでセルフレビューにも反映される。テンプレート自体の構造変更は不要。

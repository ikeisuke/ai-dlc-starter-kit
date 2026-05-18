#!/usr/bin/env bash
# tests/lib/retrospective_normalize.bash
#
# 振り返り Issue 本文の正規化規則 SoT（v2.6.6 / #710 / Unit 001 / SC-04）
#
# 目的:
#   - 集約 Issue 起票結果（aggregate_issue_enabled = true 設計時の output）と
#     fixture `tests/fixtures/retrospective_v265_aggregate.json` を比較する際に、
#     タイムスタンプ / セッション ID / 環境固有絶対パス / 生成時差分要因等の
#     「揺らぎ項目」を除外して同等性を判定するための正規化を提供する。
#
# 正規化対象 allowlist:
#   - ISO 8601 タイムスタンプ (YYYY-MM-DDThh:mm:ss[+TZ])
#   - JST 形式タイムスタンプ (YYYY-MM-DD hh:mm:ss[ JST])
#   - セッション ID (UUID v4/v7)
#   - ホーム配下絶対パス (/Users/<name>/ , /home/<name>/)
#   - generated_at: ... 行（行末まで）
#
# 正規化しないキー（比較必須）:
#   - Issue タイトル / 本文 ## / ### 見出し / ラベル名 / cap 数値 / 各見出し配下の非変動本文
#
# 公開関数:
#   - normalize_volatile         : stdin → 正規化済テキストを stdout
#   - normalize_volatile_hash    : stdin → 正規化済テキストの sha256 ハッシュを stdout
#
# 単一 SoT 原則: 正規化規則は本ファイルにのみ記述する。fixture には期待値のみを保持。

# normalize_volatile
# stdin: 正規化対象テキスト（複数行可）
# stdout: 正規化済テキスト
normalize_volatile() {
    sed -E \
        -e 's#/Users/[^/[:space:]]+/#~/#g' \
        -e 's#/home/[^/[:space:]]+/#~/#g' \
        -e 's#[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?([+-][0-9]{2}:?[0-9]{2}|Z)?#<TIMESTAMP>#g' \
        -e 's#[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}( JST)?#<TIMESTAMP>#g' \
        -e 's#[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}#<SESSION_ID>#g' \
        -e 's#^generated_at:.*$#generated_at: <TIMESTAMP>#'
}

# normalize_volatile_hash
# stdin: 正規化対象テキスト
# stdout: 正規化済テキストの sha256 ハッシュ（hex 64 文字 / 末尾改行なし）
normalize_volatile_hash() {
    local _local_normvh_hash_cmd
    if command -v sha256sum >/dev/null 2>&1; then
        _local_normvh_hash_cmd="sha256sum"
        normalize_volatile | "$_local_normvh_hash_cmd" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        _local_normvh_hash_cmd="shasum -a 256"
        normalize_volatile | shasum -a 256 | awk '{print $1}'
    else
        printf '[error] normalize_volatile_hash: sha256sum / shasum どちらも見つかりません\n' >&2
        return 2
    fi
}

# frozen_string_literal: true

# 仕様: docs/spec/official-narou-policy.md
#
# https のリバースプロキシ越しの WebSocket 対応。
# Web UI を https で開いたときだけ、WebSocket を同じホスト・同じポートの /ws に
# wss:// でつなぐ。http で開いたときは公式版のまま ws://<ホスト>:<ポート+1>/ を使う。
#
# 公式版の create_ws_uri() は "ws://" と location.port + 1 を決め打ちしており、
# https の既定ポート(443)では location.port が空になって ws://<ホスト>:NaN/ となり、
# WebSocket が作れず作品一覧が表示されない。
#
# このファイルは lib にはコピーしない。ビルド時に gem のディレクトリを引数にして実行し、
# lib/web/public/resources/narou.library.js を書き換える。
#   ruby overlay/websocket_https.rb <narou の gem ディレクトリ>
# 書き換える箇所が見つからない・複数ある場合は異常終了し、イメージのビルドを失敗させる。

TARGET = "lib/web/public/resources/narou.library.js"

# 公式版 3.9.1 の create_ws_uri() の return 文(行の位置ではなく文字列で探す)
ORIGINAL = <<~'JS'.chomp
  return "ws://" + host + ":" + (parseInt(port) + 1) + "/";
JS

HTTPS_BRANCH = <<~'JS'
  // https で開いたとき(リバースプロキシ経由)は、同じホスト・ポートの /ws を wss で使う
  if (location.protocol === "https:") {
    return "wss://" + location.host + "/ws";
  }
JS

MARKER = 'return "wss://" + location.host + "/ws";'

gem_dir = ARGV[0] or abort "usage: ruby #{$PROGRAM_NAME} <narou gem dir>"
path = File.join(gem_dir, TARGET)
abort "websocket_https: #{path} が見つからない" unless File.file?(path)

source = File.read(path, encoding: Encoding::UTF_8)

if source.include?(MARKER)
  puts "websocket_https: 適用済みのため何もしない (#{TARGET})"
  exit
end

pattern = /^([ \t]*)#{Regexp.escape(ORIGINAL)}$/
count = source.scan(pattern).size
unless count == 1
  abort "websocket_https: #{TARGET} の create_ws_uri() の書き換え箇所が #{count} 件見つかった(1 件のはず)。" \
        "narou のバージョンか PR の差分で該当箇所が変わった可能性がある"
end

source = source.sub(pattern) do
  indent = Regexp.last_match(1)
  HTTPS_BRANCH.each_line.map { |line| indent + line }.join + indent + ORIGINAL
end

File.write(path, source)
puts "websocket_https: 適用した (#{TARGET})"

# frozen_string_literal: true

# 仕様: docs/spec/official-narou-policy.md
#
# Linux/Docker環境で一部サイト（ハーメルン系等）が403 Forbiddenになる問題への対応。
# Ruby の OpenURI/Net::HTTP によるリクエストが一部サイトのボット対策に阻まれるため、
# ブラウザに近いヘッダー構成で `wget` コマンドを使って取得する方式に置き換える。
#
# 出典: Rumia-Channel/narou (docker ブランチ) lib/wget.rb (MIT License)
# https://github.com/Rumia-Channel/narou/tree/docker

require "stringio"
require "open-uri" # For OpenURI::HTTPError
require "open3"
require_relative "inventory"

module Narou
  module Wget
    # A StringIO-like object that mimics the object returned by open-uri.
    class WgetIO < StringIO
      attr_reader :meta, :status

      def initialize(initial_string = "", meta = {}, status = [])
        super(initial_string)
        @meta = meta
        @status = status
      end

      def base_uri
        # This is a simplification. Real redirection handling is more complex.
        # wget follows redirections by default. The last Location is what we want.
        # But parsing it from stderr is tricky. Let's just return the original uri.
        @meta["uri"]
      end
    end

    def self.open(uri, *rest, &block)
      options = rest.find { |arg| arg.is_a?(Hash) } || {}

      ua = Inventory.load("local_setting")["user-agent"] || "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0"

      # Build wget command
      # 仕様: docs/spec/official-narou-policy.md#What（何を）
      # シェルを介さず引数を配列で渡し、値中の記号がシェルに解釈されないようにする
      cmd_headers = []
      # Default headers from user's prompt
      cmd_headers << "User-Agent: #{ua}"
      cmd_headers << "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
      cmd_headers << "Accept-Language: ja,en-US;q=0.9,en;q=0.8"
      cmd_headers << "Accept-Encoding: gzip, deflate"
      cmd_headers << "Accept-Charset: utf-8"
      cmd_headers << "Connection: keep-alive"

      # Headers from options hash
      options.each do |key, value|
        next unless key.is_a?(String)
        cmd_headers << "#{key}: #{value}"
      end

      command = ["wget", "--server-response", "--compression=auto", "-O", "-"]
      command.concat(cmd_headers.map { |header| "--header=#{header}" })
      command << uri.to_s

      begin
        # binmode: 本文の文字コード判定は呼び出し側に任せるため、出力は ASCII-8BIT のまま受け取る
        stdout, stderr, status = Open3.capture3(*command, binmode: true)
      rescue SystemCallError => e
        raise OpenURI::HTTPError.new("wget command could not be executed: #{e.message}", nil)
      end
      # 仕様: docs/spec/official-narou-policy.md#What（何を）
      # wget の出力は ASCII-8BIT で受け取る。wget は非 ASCII（‘’ など）を出力するため、
      # 例外メッセージが narou 本体で UTF-8 文字列と連結された際の
      # Encoding::CompatibilityError を防ぐ。stdout（本文）は文字コード判定に影響するため触らない
      stderr = stderr.dup.force_encoding(Encoding::UTF_8).scrub

      unless status.success?
        http_status_line = stderr.lines.grep(/  HTTP\/\d\.\d /).last
        if http_status_line && http_status_line =~ /  HTTP\/\d\.\d (\d{3}) (.*)/
          code = $1
          msg = $2.strip
          raise OpenURI::HTTPError.new("#{code} #{msg}", nil)
        else
          # Fallback for other errors
          raise OpenURI::HTTPError.new("wget command failed with exit code #{status.exitstatus}: #{stderr.strip}", nil)
        end
      end

      # Parse headers from stderr
      response_headers = {}
      status_line = []
      # The last header block in stderr is the one for the final response
      last_header_block = stderr.split(/(\r\n\r\n|\n\n)/).select{|s| s.start_with?("  HTTP/")}.last || ""
      last_header_block.each_line do |line|
        if line.strip.start_with?("HTTP/")
          _http, code, msg = line.strip.split(" ", 3)
          status_line = [code, msg]
        elsif line =~ /^\s*([^:]+):\s*(.+)$/
          response_headers[$1.downcase] = $2.strip
        end
      end

      io = WgetIO.new(stdout, response_headers, status_line)
      io.meta["uri"] = uri # Store original URI

      if block_given?
        begin
          yield io
        ensure
          # StringIO doesn't need closing, but for compatibility.
        end
      else
        return io
      end
    end
  end
end

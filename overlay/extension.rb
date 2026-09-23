# frozen_string_literal: true

#
# Copyright 2013 whiteleaf. All rights reserved.
#

# 仕様: docs/spec/official-narou-policy.md
#
# 公式版のオリジナルは open-uri (OpenURI.open_uri) を使って直接ダウンロードするが、
# Linux/Docker環境で一部サイトが403 Forbiddenになる問題があるため、`wget` コマンド
# ベースの取得方式（wget.rb）にすべて委譲する。
#
# 出典: Rumia-Channel/narou (docker ブランチ) lib/extension.rb (MIT License)
# https://github.com/Rumia-Channel/narou/tree/docker

require_relative "wget"

# open-uri に渡すオプションを生成（必要に応じて extensions/*.rb でオーバーライドする）
def make_open_uri_options(add)
  # wget ラッパー側でヘッダーを組み立てるため、ここでは何もしない（互換性のためメソッドは維持）
  add
end

module OpenURI
  def self.open_uri(name, *rest, &block)
    # wget ラッパーに委譲する
    Narou::Wget.open(name, *rest, &block)
  end
end

#
# 安全なファイルの書き込み
#
# ファイルに直接上書きしないで、一旦別名で作成してからファイル名変更をすることで、
# ファイル書き込み中のPCクラッシュ等でデータが飛ばない様にする
#
require "securerandom"

def File.write(path, string, *options, mode: nil)
  return super if mode

  dirpath = File.dirname(path)
  FileUtils.makedirs(dirpath) unless Dir.exist?(dirpath)
  temp_path = File.join(dirpath, SecureRandom.hex(15))
  if File.extname(path) == ".yaml" && File.basename(dirpath) != Downloader::SECTION_SAVE_DIR_NAME
    backup = "#{path}.backup"
  end

  res = super(temp_path, string, *options)
  if backup
    super(backup, string, *options)
  end
  File.rename(temp_path, path)
  res
end

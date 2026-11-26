# ========================================
# narou.rb Docker Image (Custom Build - 公式版)
# ========================================
# 仕様: docs/spec/official-narou-policy.md
FROM ruby:3.4-bookworm AS builder

WORKDIR /tmp/build

# 各種取得・展開ツールのインストール
RUN apt update && apt install -y jq unzip wget ca-certificates patch

# kindlegen のダウンロード（固定URLのため最も更新頻度が低い）
RUN curl -L https://web.archive.org/web/20150803131026if_/https://kindlegen.s3.amazonaws.com/kindlegen_linux_2.6_i386_v2_9.tar.gz -o kg.tar.gz && \
    mkdir -p /opt/aozoraepub3 && \
    tar -xzf kg.tar.gz && \
    chmod +x kindlegen && \
    mv kindlegen /opt/aozoraepub3/ && \
    rm -rf kg.tar.gz docs

# Oracle JDK 25 (LTS) のダウンロードとjlink実行
# JDK 21 は Oracle の無償更新が終わり latest の URL が404になったため、現行LTSの25を使う
# 取得失敗時にエラーページをtarに渡さないよう -f で HTTP エラーを検知する
RUN curl -fL -o jdk-25.tar.gz https://download.oracle.com/java/25/latest/jdk-25_linux-x64_bin.tar.gz && \
    mkdir jdk-25 && tar zxf jdk-25.tar.gz -C ./jdk-25 --strip-components 1 && \
    mv jdk-25 /usr/local/jdk-25 && \
    JAVA_HOME=/usr/local/jdk-25 PATH=/usr/local/jdk-25/bin:$PATH \
      jlink --no-header-files --no-man-pages --compress=zip-6 \
            --add-modules java.base,java.datatransfer,java.desktop \
            --output /opt/jre && \
    rm -rf /usr/local/jdk-25 jdk-25.tar.gz

# narou.rb のインストール (公式版 - rubygems.org から最新版を取得)
# narou.gemspecの `tilt ~> 2.0` 指定に上限が無く、tilt 2.5.0以降は
# `tilt/erubis` アダプタが削除されておりWebサーバーが起動できないため、
# アダプタを含む最後のバージョン(2.4.0)を先に固定インストールする
RUN gem install tilt -v 2.4.0 && \
    gem install narou --conservative

# AozoraEpub3 最新版の取得
RUN LATEST_URL=$(curl -s https://api.github.com/repos/kyukyunyorituryo/AozoraEpub3/releases/latest | \
                 jq -r '.assets[] | select(.name | endswith(".zip")) | .browser_download_url') && \
    wget ${LATEST_URL} -O aozoraepub3.zip && \
    unzip aozoraepub3.zip -d /opt/aozoraepub3 && \
    rm aozoraepub3.zip

# narou.rb本体に上書き・書き換えするファイル群（詳細は各ファイル冒頭のコメント・仕様を参照）
# ここまでのステップと独立かつ最も変更頻度が高いため、最後に配置しキャッシュ効率を上げる
# 仕様: docs/spec/official-narou-policy.md
COPY overlay/ overlay/

# サイト構造変更への追従 (PR456, 本家未マージのためビルド時に最新差分を取得して適用) と
# Linux/Docker環境の403 Forbidden対策 (wgetベース取得方式への置き換え) と
# https のリバースプロキシ越しの WebSocket 対応 (overlay/websocket_https.rb で narou.library.js を書き換え)
# https://github.com/whiteleaf7/narou/pull/456
# 取得失敗（HTTPエラー・空応答・エラーページ）を検知するため、パイプせず一旦ファイルに保存して検証する
# 仕様: docs/spec/official-narou-policy.md
RUN NAROU_GEM_DIR=$(gem environment gemdir)/gems/narou-* && \
    curl -fsSL --retry 5 --retry-delay 3 --retry-all-errors \
      https://patch-diff.githubusercontent.com/raw/whiteleaf7/narou/pull/456.diff -o pr456.diff && \
    grep -q '^diff --git' pr456.diff && \
    patch -d $NAROU_GEM_DIR -p1 < pr456.diff && \
    ruby overlay/websocket_https.rb $NAROU_GEM_DIR && \
    cp overlay/wget.rb overlay/extension.rb $NAROU_GEM_DIR/lib/

# ========================================
# 最終イメージ
# ========================================
FROM ruby:3.4-slim-bookworm

ARG UID=1000
ARG GID=1000

# ビルダーステージから必要なファイルをコピー
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /opt/aozoraepub3 /opt/aozoraepub3
COPY --from=builder /opt/jre /opt/jre
COPY --from=builder /lib/x86_64-linux-gnu/libjpeg* /lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libjpeg* /usr/lib/x86_64-linux-gnu/
COPY init.sh /usr/local/bin/

ENV JAVA_HOME=/opt/jre \
    PATH="/opt/jre/bin:${PATH}"

# wget: lib/wget.rb（403 Forbidden対策の取得方式）が実行時に利用する
# narou ユーザーの作成
RUN apt update && apt install -y wget && rm -rf /var/lib/apt/lists/* && \
    groupadd -g ${GID} narou && \
    adduser narou --shell /bin/bash --uid ${UID} --gid ${GID} && \
    chmod +x /usr/local/bin/init.sh

USER narou
WORKDIR /home/narou/novel

EXPOSE 33000-33001

ENTRYPOINT ["init.sh"]
CMD ["narou", "web", "-np", "33000"]

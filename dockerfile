# ========================================
# narou.rb Docker Image (Custom Build)
# ========================================
FROM ruby:3.4.1-bookworm AS builder

# JDK、narou、AozoraEpub3、kindlegen のセットアップ
RUN apt update && apt install -y jq unzip wget ca-certificates git && \
    # Oracle OpenJDK 21 (LTS) のダウンロードとjlink実行
    curl -L -o jdk-21.tar.gz https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.tar.gz && \
    mkdir jdk-21 && tar zxf jdk-21.tar.gz -C ./jdk-21 --strip-components 1 && \
    mv jdk-21 /usr/local/jdk-21 && \
    export JAVA_HOME=/usr/local/jdk-21 && \
    export PATH=/usr/local/jdk-21/bin:$PATH && \
    jlink --no-header-files --no-man-pages --compress=2 \
          --add-modules java.base,java.datatransfer,java.desktop \
          --output /opt/jre && \
    # narou.rb のインストール (Rumia版 - User-Agent問題解決版)
    gem install specific_install && \
    gem specific_install -b docker https://github.com/Rumia-Channel/narou.git && \
    # AozoraEpub3 最新版の取得
    LATEST_URL=$(curl -s https://api.github.com/repos/kyukyunyorituryo/AozoraEpub3/releases/latest | \
                 jq -r '.assets[] | select(.name | endswith(".zip")) | .browser_download_url') && \
    wget ${LATEST_URL} -O aozoraepub3.zip && \
    unzip aozoraepub3.zip -d /opt/aozoraepub3 && \
    # kindlegen のダウンロード
    curl -L https://web.archive.org/web/20150803131026if_/https://kindlegen.s3.amazonaws.com/kindlegen_linux_2.6_i386_v2_9.tar.gz -o kg.tar.gz && \
    tar -xzf kg.tar.gz && \
    chmod +x kindlegen && \
    mv kindlegen /opt/aozoraepub3/ && \
    rm -rf kg.tar.gz docs

# ========================================
# 最終イメージ
# ========================================
FROM ruby:3.4.1-slim-bookworm

ARG UID=1000
ARG GID=1000

# ビルダーステージから必要なファイルをコピー
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /opt/aozoraepub3 /opt/aozoraepub3
COPY --from=builder /opt/jre /opt/jre
COPY --from=builder /lib/x86_64-linux-gnu/libjpeg* /lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libjpeg* /usr/lib/x86_64-linux-gnu/
COPY init.sh /usr/local/bin/
COPY fix-websocket-port.patch /tmp/

ENV JAVA_HOME=/opt/jre \
    PATH="/opt/jre/bin:${PATH}"

# 必要なパッケージのインストール、パッチ適用、narou ユーザーの作成
RUN apt update && apt install -y wget patch && rm -rf /var/lib/apt/lists/* && \
    cd /usr/local/bundle/gems/narou-* && \
    patch -p1 < /tmp/fix-websocket-port.patch && \
    rm /tmp/fix-websocket-port.patch && \
    groupadd -g ${GID} narou && \
    adduser narou --shell /bin/bash --uid ${UID} --gid ${GID} && \
    chmod +x /usr/local/bin/init.sh

USER narou
WORKDIR /home/narou/novel

EXPOSE 33000-33001

ENTRYPOINT ["init.sh"]
CMD ["narou", "web", "-np", "33000"]

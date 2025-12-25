# ========================================
# narou.rb Docker Image (Custom Build)
# ========================================
FROM ruby:3.4-bookworm AS builder

ARG NAROU_VERSION=3.9.1

# JDK、narou、AozoraEpub3、kindlegen のセットアップ
RUN apt update && apt install -y jq unzip wget ca-certificates && \
    # Oracle OpenJDK 21 (LTS) のダウンロードとjlink実行
    curl -L -o jdk-21.tar.gz https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.tar.gz && \
    mkdir jdk-21 && tar zxf jdk-21.tar.gz -C ./jdk-21 --strip-components 1 && \
    mv jdk-21 /usr/local/jdk-21 && \
    export JAVA_HOME=/usr/local/jdk-21 && \
    export PATH=/usr/local/jdk-21/bin:$PATH && \
    jlink --no-header-files --no-man-pages --compress=2 \
          --add-modules java.base,java.datatransfer,java.desktop \
          --output /opt/jre && \
    # narou.rb のインストール
    gem install tilt -v 2.4.0 && \
    gem install narou -v ${NAROU_VERSION} --no-document && \
    # AozoraEpub3 最新版の取得
    LATEST_URL=$(curl -s https://api.github.com/repos/kyukyunyorituryo/AozoraEpub3/releases/latest | \
                 jq -r '.assets[] | select(.name | endswith(".zip")) | .browser_download_url') && \
    wget ${LATEST_URL} -O aozoraepub3.zip && \
    unzip aozoraepub3.zip -d /opt/aozoraepub3 && \
    # narou PR446 パッチの適用
    wget https://github.com/kokotaro/narou/releases/download/PR446_20251001/narou_PR446_20251001.zip -O patch.zip && \
    unzip patch.zip && \
    NAROU_DIR=$(gem environment gemdir)/gems/narou-${NAROU_VERSION}/webnovel && \
    cp -f ncode.syosetu.com.yaml novel18.syosetu.com.yaml ${NAROU_DIR}/ && \
    # kindlegen のダウンロード
    curl -L https://web.archive.org/web/20150803131026if_/https://kindlegen.s3.amazonaws.com/kindlegen_linux_2.6_i386_v2_9.tar.gz -o kg.tar.gz && \
    tar -xzf kg.tar.gz && \
    chmod +x kindlegen && \
    mv kindlegen /opt/aozoraepub3/ && \
    rm -rf kg.tar.gz docs

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

# narou ユーザーの作成
RUN groupadd -g ${GID} narou && \
    adduser narou --shell /bin/bash --uid ${UID} --gid ${GID} && \
    chmod +x /usr/local/bin/init.sh

USER narou
WORKDIR /home/narou/novel

EXPOSE 33000-33001

ENTRYPOINT ["init.sh"]
CMD ["narou", "web", "-np", "33000"]

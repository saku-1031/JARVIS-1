# ベースイメージに Miniconda を使用
FROM continuumio/miniconda3:latest

# システム依存パッケージのインストール
# (git, openjdk, xvfb, patch, unzip)
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    gnupg \
    git \
    patch \
    unzip \
    # For building python packages
    build-essential \
    # VNC and window manager for GUI
    tigervnc-standalone-server \
    fluxbox \
    xterm \
 && rm -rf /var/lib/apt/lists/*

# Eclipse Temurin (Java 8) のリポジトリを追加してインストール
RUN wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor > /usr/share/keyrings/adoptium.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main" > /etc/apt/sources.list.d/adoptium.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    temurin-8-jdk \
    xvfb \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# JAVA_HOME を設定 (ARM64/aarch64 と AMD64 の両方に対応)
# ENV JAVA_HOME /usr/lib/jvm/temurin-8-jdk-$(dpkg --print-architecture)

# 作業ディレクトリを設定
WORKDIR /opt/jarvis

# ローカルのコードをコンテナ内にコピー
# .dockerignore で不要なファイルを除外
COPY . /opt/jarvis

# Conda 環境の作成と有効化
RUN conda create -n jarvis python=3.10 -y && \
    conda clean -afy

# シェルを conda 環境付きに変更
SHELL ["conda", "run", "-n", "jarvis", "/bin/bash", "-c"]

# MCP の準備とビルド
RUN export JAVA_HOME="/usr/lib/jvm/temurin-8-jdk-$(dpkg --print-architecture)" && \
    stark_tech_dir="/opt/jarvis/jarvis/stark_tech" && \
    mkdir -p "$stark_tech_dir" && \
    cd "$stark_tech_dir" && \
    git clone https://github.com/Hexeption/MCP-Reborn.git && \
    cd MCP-Reborn && \
    git checkout 1.16.5-20210115 && \
    chmod +x gradlew && \
    ./gradlew setup && \
    cp -r /opt/jarvis/scripts/cursors ./src/main/resources

# JARVIS-1 パッケージのインストール
RUN pip install -e .

# シェルをデフォルトに戻す
SHELL ["/bin/bash", "-c"]

# エントリポイントスクリプトをコピー
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# デフォルトの ENTRYPOINT
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
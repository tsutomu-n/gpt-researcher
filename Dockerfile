# Python 3.12をベースにしたイメージを使用し、install-browserという名前のビルドステージを開始
FROM python:3.12-slim-bullseye as install-browser

# aptパッケージマネージャーを更新し、Chromiumとそのドライバーをインストール
RUN apt-get update \
    && apt-get satisfy -y \
    "chromium, chromium-driver (>= 116.0)" \
    && chromium --version && chromedriver --version

# Firefox ESRとwgetをインストールし、geckodriverをダウンロードして配置
RUN wget https://github.com/mozilla/geckodriver/releases/download/v0.34.0/geckodriver-v0.34.0-linux64.tar.gz \
    && tar -xvzf geckodriver* \
    && chmod +x geckodriver \
    && mv geckodriver /usr/local/bin/

# install-browserステージをベースにしてgpt-researcher-installステージを開始
FROM install-browser as gpt-researcher-install

# pipの設定を環境変数で定義
ENV PIP_ROOT_USER_ACTION=ignore

# アプリケーションのソースコードを置くディレクトリを作成し、作業ディレクトリとして設定
RUN mkdir /usr/src/app
WORKDIR /usr/src/app

# ホストマシンからrequirements.txtをコピーし、pipを使って依存関係をインストール
COPY ./requirements.txt ./requirements.txt
RUN pip install -r requirements.txt

# gpt-researcher-installステージをベースにしてgpt-researcherステージを開始
FROM gpt-researcher-install AS gpt-researcher

# gpt-researcherというユーザーを作成し、アプリケーションのディレクトリの所有者を変更
RUN useradd -ms /bin/bash gpt-researcher \
    && chown -R gpt-researcher:gpt-researcher /usr/src/app

# 作成したユーザーに切り替え
USER gpt-researcher

# ホストマシンからアプリケーションのソースコードをコピー
COPY --chown=gpt-researcher:gpt-researcher ./ ./

# コンテナの8000番ポートを外部に公開
EXPOSE 8000

# コンテナ起動時にuvicornを使ってFastAPIアプリケーションを実行
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
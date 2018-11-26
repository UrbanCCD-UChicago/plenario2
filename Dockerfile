FROM ubuntu:xenial

# setup environment

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV HOME /opt/build
ENV TERM xterm

# apt install build deps

RUN mkdir -p /opt/deps
WORKDIR /opt/deps

RUN apt-get update -qq && \
  apt-get install -y wget build-essential locales curl git && \
  locale-gen "en_US.UTF-8"

# install erlang 20.2.2

RUN wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && \
  dpkg -i erlang-solutions_1.0_all.deb && \
  apt-get update -qq && \
  apt-get install -y esl-erlang=1:20.2.2

# install elixir 1.6.0

RUN wget https://github.com/elixir-lang/elixir/archive/v1.6.0.tar.gz && \
  tar xzf v1.6.0.tar.gz && \
  cd elixir-1.6.0 && \
  make clean install && \
  cd ..

# install nodejs

RUN curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh && \
  bash nodesource_setup.sh && \
  apt-get update -qq && \
  apt-get install -y nodejs

# install yarn

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update -qq && \
  apt-get install yarn

# make build dir and work from there

RUN mkdir -p /opt/build
WORKDIR /opt/build
CMD ["/bin/bash"]

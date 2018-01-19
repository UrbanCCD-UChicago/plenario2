FROM ubuntu:xenial

# install erlang 20.2.2

RUN apt-get update -qq
RUN apt-get install wget -y
RUN wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
RUN dpkg -i erlang-solutions_1.0_all.deb
RUN apt-get update -qq
RUN apt-get install esl-erlang=1:20.2.2 -y

# install elixir 1.6.0

RUN apt-get install build-essential -y
RUN apt-get install locales -y
RUN locale-gen "en_US.UTF-8"
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN wget https://github.com/elixir-lang/elixir/archive/v1.6.0.tar.gz
RUN tar xzf v1.6.0.tar.gz
RUN cd elixir-1.6.0 && make clean install && cd ..
RUN elixir -v

# clone repo down

RUN apt-get install git -y
RUN git clone https://github.com/UrbanCCD-UChicago/plenario2.git
WORKDIR plenario2/

# install dependencies

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get

# install nodejs

RUN apt-get install curl -y
RUN curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh
RUN bash nodesource_setup.sh
RUN apt-get update
RUN apt-get install nodejs -y
RUN if [ -d "./assets/node_modules" ]; then rm -rf ./assets/node_modules; fi
RUN cd assets && npm install && cd ..

# compile assets

RUN cd assets && node node_modules/.bin/brunch build --production && cd ..
RUN mix phx.digest

# when this is done, run `docker cp config/prod.secret.exs ${container id}:/plenario2/config/prod.secret.exs`
# to

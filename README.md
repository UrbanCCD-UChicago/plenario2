# Plenario2
[![Build Status](https://travis-ci.org/UrbanCCD-UChicago/plenario2.svg?branch=master)](https://travis-ci.org/UrbanCCD-UChicago/plenario2)
[![Coverage Status](https://coveralls.io/repos/github/UrbanCCD-UChicago/plenario2/badge.svg?branch=master)](https://coveralls.io/github/UrbanCCD-UChicago/plenario2?branch=master)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/UrbanCCD-UChicago/plenario2.svg)](https://beta.hexfaktor.org/github/UrbanCCD-UChicago/plenario2)

## Running the Tests

You're going to need a local version of Postgres with the PostGIS extension
enabled running. If you need to install it, use Docker and pull the 
`mdillon/postgis` image:

```bash
$ docker pull mdillon/postgis
$ docker run -p 5432:5432 -e POSTGRES_PASSWORD=password mdillon/postgis
```

When you've got that running, cd into the project, install the dependencies,
create and migrate the database, and run the test suite:

```bash
$ cd plenario2
$ mix deps.get
$ MIX_ENV=test mix ecto.create
$ MIX_ENV=test mix ecto.migrate
$ mix coveralls
```

If during development you need to make configuration changes, do that in the
`config/test.exs` file. If your tests work locally, but something is screwy on
Travis, update the `config/travis.exs` file.

## Formatting

Code will be required to be formatted with the built in 1.6 formatter that's 
coming in the near future. Until then, our builds do not check for formatting,
but it is highly encouraged. In order to use the formatter you must build
Elixir from their `master` branch and run:

```bash
mix format
```

# Plenario
[![Build Status](https://travis-ci.org/UrbanCCD-UChicago/plenario2.svg?branch=master)](https://travis-ci.org/UrbanCCD-UChicago/plenario2)
[![Coverage Status](https://coveralls.io/repos/github/UrbanCCD-UChicago/plenario2/badge.svg?branch=master)](https://coveralls.io/github/UrbanCCD-UChicago/plenario2?branch=master)

## Open RFCs

We encourage everyone to participate in this project -- filing bugs, opening
feature requests, etc. One of the most impactful areas is participating in open
RFCs specifically. The following link will bring you to the list of currently
active RFCs:
https://github.com/UrbanCCD-UChicago/plenario2/issues?q=is%3Aopen+is%3Aissue+label%3Arfc

## Tool Versioning

With the rapid development of Elixir, we want to be deliberate about which tools
we are using when working with the code. For this, we recommend using
[asdf](https://github.com/asdf-vm/asdf).

If you already have Elixir and Erlang installed on your local system, and they
are not dependencies for anything else, remove them. The next step is to
install `asdf`, then install the prerequisites for Erlang, then install the
Erlang and Elixir plugins:

```bash
$ cd ~
$ git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.4.1  # check the docs from asdf for the current version
$ echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bashrc
$ sudo apt install build-essential autoconf m4 libncurses5-dev libwxgtk3.0-dev libgl1-mesa-dev libglu1-mesa-dev libssh-dev unixodbc-dev
$ source .bashrc
$ asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
```

There's going to be a decent amount of output here, and it's going to take
_for-freaking-ever_ to compile Erlang. Go get some coffee. Then:

```bash
$ asdf install erlang 20.2.2  # or whatever version you want
$ asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
$ asdf install elixir 1.6.0-otp-20  # or whatever version, just make sure you add the corresponding otp version
```

After that, you can set the global versions of each:

```bash
$ asdf global erlang 20.2.2
$ asdf global elixir 1.6.0-otp-20
```

Relevant links:

- https://github.com/asdf-vm/asdf
- https://github.com/asdf-vm/asdf-erlang
- https://github.com/asdf-vm/asdf-elixir

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

## Building Releases

A quick sidebar about building and deploying releases in Elixir and Erlang: it's
a flipping mess right now. Erlang, which Elixir is built on top of, is old.
Like really old. Like almost as old as me (Vince). Given it's advanced age, it
doesn't like being nimble. So, unlike Python or Ruby or (sadly) even Java,
deploying Elixir is a pain. Hence, this walk through...

The target environment for releases is Ubuntu 16.04 with locales set to
`EN_US.UTF8`. Obviously, not everyone is going to have a clean version of
Xenial as their dev environment, so to make the release build process as clean
as possible we use Docker.

To build the image, run `./build`.

**Note:** you will need the following software installed and configured on
your host/build machine:

- docker
- awscli

You should be signed into a docker account (`$ docker signin`) and you should
have your AWS credentials set up (`$ aws config`).

## Deploying Releases

Deployments are naive -- they will download a specific release archive from S3
to your machine and then upload it to the target server. This is done so that you
make deliberate choices.

To deploy, run `./deploy {{ version number }} {{ hostname }}`

**Note:** you will need the hostname configured in your local SSH config. You
should also have configured your AWS credentials set up (`$ aws config`).

### Deployments with Migrations

If the latest changes have deployments, there's a convenience wrapper included
to run the changes. all you have to do is append `--run-migrations` to the
end of the deployment command:
`./deploy {{ version_number }} {{ hostname }} --run-migrations`.

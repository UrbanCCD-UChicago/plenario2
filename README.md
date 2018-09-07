<h1 align="center">
  <img src="./assets/static/images/arch-md.png">
  <br>
  Plenario
</h1>
<p align="center">
  The Premier Open Data Platform
</p>
<p align="center">
  <a href="https://travis-ci.org/UrbanCCD-UChicago/plenario2">
    <img alt="build status"
      src="https://travis-ci.org/UrbanCCD-UChicago/plenario2.svg?branch=master">
  </a>
  <a href="https://coveralls.io/github/UrbanCCD-UChicago/plenario2?branch=master">
    <img alt="coverage status"
      src="https://coveralls.io/repos/github/UrbanCCD-UChicago/plenario2/badge.svg?branch=master">
  </a>
</p>

## Open RFCs

We encourage everyone to participate in this project — filing bugs, opening
feature requests, etc. One of the most impactful areas is participating in open
RFCs specifically. You can find the list of currently
active RFCs [here](https://github.com/UrbanCCD-UChicago/plenario2/issues?q=is%3Aopen+is%3Aissue+label%3Arfc).

## Development Software Prerequisites

Plenario is primarily written in the super-fast, functional
[Elixir](https://elixir-lang.org). This lets us operate on huge amounts of data
in the blink of an eye; unfortunately it also means setting up a Plenario
development environment is a little more involved than the average GitHub
project. Follow the steps below, though, and we'll have you up and running in no
time!

With the rapid development of Elixir, we want to be deliberate about which
tool versions we are using when working with the code. We use
[asdf](https://github.com/asdf-vm/asdf) to automate management of our Erlang,
Elixir, and Node environments, but you can do it manually if you're feeling
bold. We also use [Docker](https://docker.com) to set up our Postgres database
for development and testing and to provide a consistent environment when
building releases.

### Erlang, Elixir, and Node

#### Using asdf

First make sure you have [asdf](https://github.com/asdf-vm/asdf) installed
and configured properly. Instructions for doing so are available
[here](https://github.com/asdf-vm/asdf#setup). Make sure to install the system
packages listed at the end of those instructions.

You'll also need the Erlang, Elixir, and Node plugins
for asdf. You can check your list of installed plugins with

```sh
$ asdf plugin-list
elixir
erlang
nodejs
```

and add any missing ones with

```sh
asdf plugin-add erlang
asdf plugin-add elixir
asdf plugin-add nodejs
```

Now you can just enter the project directory and run

```sh
asdf install
```

to automatically install the correct versions of all three tools. When
inside the project directory tree you'll automatically and transparently use the
correct tool version when calling commands, e.g. `mix`.

#### Manually

If you don't want to use asdf, perhaps because you already have other version
managers running like nvm or kerl, you can find our currently employed versions
of Erlang, Elixir, and Node listed in human-readable format in
[.tool-versions](.tool-versions). Install them globally or with your version
managers of choice, and make sure you're using them when working on Plenario.

### Yarn

We use [Yarn](https://yarnpkg.com/en/docs/install) to manage our JavaScript dependencies. While NPM has made great strides in the last few versions to match the "killer features" of Yarn, such a rapid release schedule comes with reliability issues. As such, we still prefer the stability afforded by Yarn.

Please refer to [the Yarn documentation](https://yarnpkg.com/en/docs/install) for installation instructions.

### Docker and Postgres

We use [Docker](https://docker.com) to stand up our local development database
environment with Postgres+PostGIS. We also use it to provide a consistent,
Ubuntu-based build environment to ensure a version of Plenario built on any
development machine will run just as well in the production environment.

#### Installing Docker

We highly recommend using the latest instructions and installation packages from
Docker themselves, especially on macOS and Windows. The new Docker for
Mac/Windows distributions use the native virtualization technologies under those
operating systems, and so should be more performant than the standard VirtualBox
distribution.

- [Docker for Mac](https://docs.docker.com/docker-for-mac/install/)
- [Docker for Windows](https://docs.docker.com/docker-for-windows/install/)
- Linux
  - [CentOS](https://docs.docker.com/install/linux/docker-ce/centos/)
  - [Debian](https://docs.docker.com/install/linux/docker-ce/debian/)
  - [Fedora](https://docs.docker.com/install/linux/docker-ce/fedora/)
  - [Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
  - [Binaries](https://docs.docker.com/install/linux/docker-ce/binaries/) (you
    might also be able to find `docker` in your distro's default package
    repository)

#### Postgres+PostGIS

Plenario expects to connect to a Postgres database with the PostGIS extension
enabled. Rather than setting that up yourself, you can pull down a
pre-configured Docker image with

```sh
docker pull mdillon/postgis
```

### Project Dependencies

> **NOTE**  
> We recommend repeating this step every time you check out a new git branch.
> Installed dependencies are not tracked in git and will not update
> automatically when changing branches.

One last step; we need to install the Elixir plugins and Node modules that
Plenario depends on. Run the following from the project root:

```sh
mix deps.get
cd assets/
yarn
```

You're all set! Read [Running Development Server](#running-development-server)
to get started contributing, and [Running Test Suite](#running-test-suite) learn
how to run our automated test suite.

## Running Development Sever

> **NOTE**  
> Remember to re-run the commands in
> [Project Dependencies](#project-dependecies) if you have checked out a
> different branch. Git can't update them automatically.

Once you're sure you've got all of your
[software prerequisites](#development-software-prerequisites) set up, you're
ready to get started! This requires just a couple steps:

```sh
# Stand up the development database and populate it
docker run -dp 5432:5432 -e POSTGRES_PASSWORD=password mdillon/postgis
mix ecto.create
mix ecto.migrate

# Start the Phoenix server
mix phx.serve
```

Now you can access the Plenario front end at `http://localhost:4000` and the API
via `http://localhost:4000/api/v2/...`. HTML/style changes will live update in
your browser, and most API changes will be visible the next time you call the
endpoint.

To stop the Phoenix server, press <kbd>Ctrl-C</kbd> twice. You can stop the
Postgres container with the usual `docker container stop <container name/hash>`.

For more specific information on the locally running server, check the
[Phoenix Framework documentation](https://hexdocs.pm/phoenix).

### Sample Data

By default, the development server is empty; it doesn't have any users, data
sets, or Array of Things networks. You can add them manually as needed, but we
also offer the following command to quickly create a Plenario user with
administrator privileges and some sample data.

```sh
mix run priv/repo/seeds.exs
```

The created user has these login credentials:

- **Email**: `plenario@uchicago.edu`
- **Password**: `password` (yes, we know)

## Running the Test Suite

> **NOTE**  
> Remember to re-run the commands in
> [Project Dependencies](#project-dependecies) if you have checked out a
> different branch. Git can't update them automatically.

First make sure you've got all of your
[software prerequisites](#development-software-prerequisites) set up. Then run
the following from the project root to execute the automated tests.

```sh
# Stand up the test database and populate it
docker run -dp 5432:5432 -e POSTGRES_PASSWORD=password mdillon/postgis
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate

# Run the tests
mix coveralls
```

If during development you need to make configuration changes, do that in the
`config/test.exs` file. If your tests work locally, but something is screwy on
Travis, update the `config/travis.exs` file.

## Building and Deploying Releases

Erlang, which Elixir is built on top of, is old.  
Like really old.  
Like old enough to have gone to its 10-year college reunion old.

That means Erlang is mature, fast, and well supported, but it also means Elixir
doesn't have access to the same level of deployment tooling as Node or Python or
Ruby or even Java. Hence, this walk through&hellip;

### Extra Software Prerequisites

In addition to everything listed in the development
[software prerequisites](#development-software-prerequisites) above, building a
Plenario release also requires the following:

- A Docker account, signed in with `docker signin`
- **awscli**, with your AWS credentials already set up (`aws config`)

### Building

To build the image, run the included `build` script as follows.

```sh
./build --tag <version number>
```

This will build the release, tag it properly, copy it to your host machine,
and upload it to S3.

If you don't want to upload it to S3, append the `--skip-upload` flag:

```sh
./build --tag <version number> --skip-upload
```

### Deploying

Deployments are naive: they will download a specific release archive from S3
to your machine and then upload it to the target server. This is done so that
you make deliberate choices.

To deploy, run the included `deploy` script as follows.

> **NOTE**
> You will need the target hostname configured in your local SSH config.

```sh
./deploy --tag <version number> --host <hostname>
```

This will download a built release archive from S3 and deploy it to the target
host.

If you already have a local copy of the archive, you can skip the
download with the `--skip-download` flag.

```sh
./deploy --tag <version number> --host <hostname> --skip-download
```

#### Deployments with Migrations

If the latest changes have deployments, there's a convenience wrapper included
to run the changes. All you have to do is append `--run-migrations` to the
end of the deployment command:

```sh
./deploy --tag <version number> --host <hostname> --run-migrations
```

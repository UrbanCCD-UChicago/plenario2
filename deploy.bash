#!/bin/bash

set -e

# uncomment next line if you are having issues and need verbose output
# set -x


# read in cmd args

POSITIONAL=()
while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
      -t|--tag)
        TAG="$2"
        shift # past argument
        shift # past value
      ;;
      -h|--host)
        HOST="$2"
        shift # past argument
        shift # past value
      ;;
      --skip-download)
        SKIP_DOWNLOAD=true
        shift # past argument
      ;;
      --run-migrations)
        RUN_MIGRATIONS=true
        shift # past argument
      ;;
      *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters


# colorized output

CYAN="\e[1;36m"
RED="\e[1;31m"
GREEN="\e[1;32m"
NORM="\e[0m"

function printcyan {
  echo -e "${CYAN}$1${NORM}"
}

function printred {
  echo -e "${RED}$1${NORM}"
}

function printgreen {
  echo -e "${GREEN}$1${NORM}"
}


# check params

if [ -z "$TAG" ];
then
  printred "you need to specify a tag!"
  exit 1
fi

if [ -z "$HOST" ];
then
  printred "you need to specify a host to deploy to!"
  exit 1
fi


# let user know what's going on

printcyan "we're going to deploy version $TAG to $HOST..."
if [ "$RUN_MIGRATIONS" = true ];
then
  printcyan "and we'll run migrations too (if there are any that need to be run)..."
fi


# download release archive if necessary

if [ "$SKIP_DOWNLOAD" = true ];
then
  printcyan "skipping download and using local archive..."
else
  printcyan "downloading archive..."
  aws s3 cp s3://plenario2-releases/plenario2-$TAG.tar.gz _build/prod/
fi


# upload release archive to host, decompress and rejigger symlinks

printcyan "uploading release archive to $HOST..."
ssh $HOST "if [ ! -d \"releases\" ]; then mkdir releases; fi"
scp _build/prod/plenario2-$TAG.tar.gz $HOST:releases/

printcyan "decompressing archive on $HOST..."
ssh $HOST "cd releases && tar xzf plenario2-$TAG.tar.gz"

printcyan "stopping current version of app on $HOST..."
 ssh $HOST "if [[ -d \"plenario2/bin/\" ]]; then ./plenario2/bin/plenario stop; fi"

printcyan "unlinking current version on $HOST..."
ssh $HOST "if [[ -L \"plenario2\" ]]; then rm plenario2; fi"

printcyan "symlinking plenario2 to $TAG on $HOST..."
ssh $HOST "ln -s releases/$TAG/ plenario2"


# run migrations

if [ "$RUN_MIGRATIONS" = true ];
then
  printcyan "running migrations on $HOST..."
  ssh $HOST "./plenario2/bin/plenario migrate"
fi


# restart server with new link

printcyan "starting application back up on $HOST..."
ssh $HOST "./plenario2/bin/plenario start"


# remove archive

printcyan "removing release archive on $HOST..."
ssh $HOST "rm releases/plenario2-$TAG.tar.gz"


# done

printgreen "DONE!"

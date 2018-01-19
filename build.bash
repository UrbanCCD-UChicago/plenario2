#!/bin/bash

set -ex

echo "getting the version number..."
TAG=$(grep 'version' mix.exs | awk '{gsub(/[^0-9\.]/, "")}1')
echo "version tag is $TAG"


echo "building the docker image for the release version..."
docker build --no-cache --tag plenario2-builder:$TAG .

IMAGE_ID=$(docker images | grep "$TAG" | awk '{print $3}')
echo "docker image id is $IMAGE_ID"


echo "running the image so we can add the secrets and generate the release..."
docker run -it -d $IMAGE_ID

CONTAINER_ID=$(docker ps | grep "$IMAGE_ID" | awk '{print $1}')
echo "container id is $CONTAINER_ID"


echo "copying prod secrets to the container..."
docker cp config/prod.secret.exs $CONTAINER_ID:/plenario2/config/prod.secret.exs


echo "building the release..."
docker exec -it $CONTAINER_ID sh -c 'MIX_ENV=prod mix release --env=prod'


echo "making a tarball of the release and copying to your machine..."
if [ ! -d "_build/prod" ]; then mkdir -p _build/prod; fi
docker exec -it $CONTAINER_ID tar czf plenario2-$TAG.tar.gz /plenario2/_build/prod/rel/plenario2
docker cp $CONTAINER_ID:/plenario2/plenario2-$TAG.tar.gz _build/prod/


echo "stopping the container..."
docker stop $CONTAINER_ID


echo "DONE!"

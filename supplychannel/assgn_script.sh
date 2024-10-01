export PATH=${PWD}/../bin:${PWD}:$PATH
cryptogen generate --config=./organizations/cryptogen/crypto-config-org4.yaml --output="organizations"
cryptogen generate --config=./organizations/cryptogen/crypto-config-org5.yaml --output="organizations"
cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"
export DOCKER_SOCK=/var/run/docker.sock
IMAGE_TAG=latest docker-compose -f compose/compose-test-net.yaml -f compose/docker/docker-compose-test-net.yaml up
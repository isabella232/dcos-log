# This script runs the tests for the dcos-log go code.  In order to provide
# an environment where systemd/journald is running, it first starts up
# a container running /sbin/init.  It then execs into that container to run
# the go test suite. Before the script exits, it will destroy the container.

set -e # exit on failure
set -x # print each command

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/../..

cleanup() {
	echo "Cleaning up the container..."
	docker rm -f ${CONTAINER_NAME} >/dev/null
}
trap cleanup EXIT

echo "Starting container that is running systemd and journald..."
echo "current dir is ${CURRENT_DIR}"
docker run \
	-d \
	-v $(pwd):${PKG_DIR}/${BINARY_NAME} \
	--privileged \
	--rm \
	--name ${CONTAINER_NAME}  \
	${IMAGE_NAME} \
	/sbin/init >/dev/null

echo "Installing code in the container..."
docker exec \
	${CONTAINER_NAME} \
	bash -c '\
		cd /go/src/github.com/dcos/dcos-log && \
		go install $(go list github.com/dcos/dcos-log/...|grep -v vendor)'

echo "Running tests against that container..."
docker exec \
	${CONTAINER_NAME} \
	bash -c '\
		cd /go/src/github.com/dcos/dcos-log && \
		go test -race -cover -test.v $(go list ./...|grep -v vendor)'



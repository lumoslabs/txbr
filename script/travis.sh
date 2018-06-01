#! /bin/bash
set -ev

# args: directory, repo
build_image() {
  docker_repo_name=$2

  docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD quay.io
  echo $TRAVIS_COMMIT > REVISION
  export COMMIT=${TRAVIS_COMMIT::8}

  docker build -t quay.io/$docker_repo_name:$TRAVIS_BRANCH .
  docker tag quay.io/$docker_repo_name:$TRAVIS_BRANCH quay.io/$docker_repo_name:$COMMIT
  docker tag quay.io/$docker_repo_name:$COMMIT quay.io/$docker_repo_name:travis-$TRAVIS_BUILD_NUMBER
  docker push quay.io/$docker_repo_name
}

if [ "${TRAVIS_JOB}" = "build" ]; then
  set -x
  build_image 'lumoslabs/txbr'
elif [ "${TRAVIS_JOB}" = "test" ]; then
  set -x
  bundle install --jobs 3 --retry 3
  bundle exec rspec
fi

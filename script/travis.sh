#! /bin/bash
set -ev

if [ "${TRAVIS_JOB}" = "test" ]; then
  set -x
  bundle install --jobs 3 --retry 3
  bundle exec rspec
fi

#!/bin/bash

set -e
path="$(dirname "$0")"
pushd $path/..
base="$(pwd)";

drupal_base="$base/htdocs"

drush="$PWD/vendor/bin/drush $drush_flags -y -r $drupal_base"

if [[ -f .env ]]; then
  source .env
else
  echo "No env file found. Please create one. You can use env.dist as an example."
  exit 1
fi
# Confirm our working directory
if [ ! -d $drupal_base ]; then
  mkdir $drupal_base
fi

# Then push it to memory
pushd $drupal_base

# Then run Composer
echo "Installing dependencies with Composer.";
cd $base
composer install

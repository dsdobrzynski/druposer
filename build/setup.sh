#!/bin/bash
set -e

read -p "Project name: " project

project_machine="$(tr [A-Z] [a-z] <<< "$project")"
project_machine=${project_machine//[-+=.,]/_}
project_machine="${project_machine// /_}"
path=$(dirname "$0")
base=$(cd $path/.. && pwd)

cd $base

[[ ! -z `grep "PROJECT=default" env.dist` ]] && sed -i '' "s/default/$project_machine/" env.dist

if [[ ! -f .env ]]
then
  echo "Creating Environment File"
  echo "source env.dist" > .env
fi

if [[ -f default.module ]]
then
  echo "Setting up Default Project Modules."
  mkdir $base/htdocs/sites/all/modules/custom/$project_machine
  mv default.module $base/htdocs/sites/all/modules/custom/$project_machine/$project_machine.module
  mv default.info $base/htdocs/sites/all/modules/custom/$project_machine/$project_machine.info
  sed -i '' s/default/$project_machine/g $base/htdocs/sites/all/modules/custom/$project_machine/$project_machine.*
  echo "*****************************************"
  echo "* Don't forget to Commit these changes. *"
  echo "*****************************************"
fi

if [[ ! -z `grep "# Druposer" README.md` ]]
then
  sed -i '' "1s/^# Druposer/# $project/" README.md
  sed -i '' "s/drupalproject/$project_machine/" README.md
fi

if [[ ! -f $base/htdocs/sites/default/settings.php ]]
then
  echo "Creating settings.php File from default.settings.php";
  cp $base/htdocs/sites/default/default.settings.php $base/htdocs/sites/default/settings.php
fi

if [[ -z `grep "settings.local.php" $base/htdocs/sites/default/settings.php` ]]
then
  echo "Adding local settings file config to settings.php";
  cat $base/cnf/default.settings.addendum >> $base/htdocs/sites/default/settings.php
fi

if [[ ! -f $base/htdocs/sites/default/settings.local.php ]]
then
  echo "Creating settings.local.php File";
  cp $base/cnf/settings.local.php $base/htdocs/sites/default/settings.local.php
  echo "Configuring database settings.";
  read -p "Database driver (default: 'mysql'): " driver
  driver=${driver:-mysql}
  read -p "Database name (default: 'default'): " database
  database=${database:-default}
  read -p "Database username (default: 'default'): " username
  username=${username:-default}
  read -p "Database password (default: 'default'): " password
  password=${password:-default}
  read -p "Database host (default: 'localhost'): " host
  host=${host:-localhost}
  read -p "Database port (default: '3306'): " port
  port=${port:-3306}
  read -p "Database prefeix (default: ''): " prefix
  prefix=${prefix:-}
  sed -i '' "s/'driver' => 'mysql',/'driver' => '$driver',/" $base/htdocs/sites/default/settings.local.php
  sed -i '' "s/'database' => 'default',/'database' => '$database',/" $base/htdocs/sites/default/settings.local.php
  sed -i '' "s/'username' => 'default',/'username' => '$username',/" $base/htdocs/sites/default/settings.local.php
  sed -i '' "s/'password' => 'default',/'password' => '$password',/" $base/htdocs/sites/default/settings.local.php
  sed -i '' "s/'host' => 'localhost',/'host' => '$host',/" $base/htdocs/sites/default/settings.local.php
  sed -i '' "s/'port' => '3306',/'port' => '$port',/" $base/htdocs/sites/default/settings.local.php
  sed -i '' "s/'prefix' => '',/'prefix' => '$prefix',/" $base/htdocs/sites/default/settings.local.php
fi
pwd
source "$path/install.sh"

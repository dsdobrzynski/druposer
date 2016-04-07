#!/bin/bash
set -e
path=$(dirname "$0")
base=$(cd $path/.. && pwd)
true=`which true`
source $path/common.sh

echo "Installing site...";
cd $base/htdocs
sqlfile=$base/build/ref/$PROJECT.sql
gzipped_sqlfile=$sqlfile.gz
if [ -e "$gzipped_sqlfile" ]; then
  echo "...from reference database."
  $drush sql-drop -y
  zcat "$gzipped_sqlfile" | $drush sqlc
elif [ -e "$sqlfile" ]; then
  echo "...from reference database."
  $drush sql-drop -y
  $drush sqlc < $sqlfile
else
  echo "...from scratch, with Drupal minimal profile.";
  read -p "Drupal admin username (default: 'admin'): " drupal_admin
  drupal_admin=${drupal_admin:-admin}
  read -p "Drupal admin password (default: 'pass'): " drupal_password
  drupal_password=${drupal_password:-pass}
# Setting PHP Options so that we don't fail while sending mail if a mail sytem
# doesn't exist.
  PHP_OPTIONS="-d sendmail_path=`which true`" $drush si minimal --account-name=$drupal_admin --account-pass=$drupal_password
fi
source $path/update.sh

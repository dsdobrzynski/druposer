#!/bin/bash
set -e
path="$(dirname "$0")"
true="$(which true)"
source "$path/common.sh"

echo "Installing site...";
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
  read -p "Drupal site name (default: 'Site-Install'): " drupal_sitename
  drupal_sitename=${drupal_sitename:-Site-Install}
# Setting PHP Options so that we don't fail while sending mail if a mail sytem
# doesn't exist.
  PHP_OPTIONS="-d sendmail_path=`which true`" $drush si minimal --account-name=$drupal_admin --account-pass=$drupal_password --site-name="$drupal_sitename"
fi
source "$path/update.sh"

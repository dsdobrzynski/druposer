# PMMI

This is an example of a starting point for developing a Drupal project using
Composer.

You can most easily start your Drupal project with this baseline by using
[Composer](getcomposer.org):

```bash
composer create-project dsdobrzynski/druposer your_project_name
./build/setup.sh
```

Running the `composer create-project` command will download the latest
release of this project to a new directory called `your_project_name` and
invoke `composer install` inside it, which will trigger additional scripts
to create a working Drupal root in the htdocs subdirectory from the packages
downloaded with composer.

We reference a custom composer repository in composer.json
[here](composer.json#L6-9). This repository was created by
traversing the list of known projects on drupal.org using
`drupal/parse-composer`, and has the package metadata for all the valid packages
with a Drupal 7 release, including Drupal itself.

We use `derhasi/composer-preserve-paths` to preserve custom Drupal paths, and
`composer/installers` to install packages to the correct location.

As you add modules to your project, just update composer.json and run `composer
update`. You will also need to pin some versions down as you run across point
releases that break other functionality. If you are fastidious with this
practice, you will never accidentally install the wrong version of a module if
a point release should happen between your testing, and client sign off, and
actually deploying changes to production. If you are judicious with your
constraints, you will be able to update your contrib without trying to remember
known untenable versions and work arounds -- you will just run `composer update`
and be done.

This strategy may sound a lot like `drush make`, but it's actually what you
would get if you took the good ideas that lead to `drush make`, and then
discarded everything else about it, and then discarded those good ideas for
better ideas, and then added more good ideas.

See:

* [composer](https://getcomposer.org)
  * [composer install](https://getcomposer.org/doc/03-cli.md#install)
  * [composer update](https://getcomposer.org/doc/03-cli.md#update)
  * [composer create-project](https://getcomposer.org/doc/03-cli.md#create-project)
  * [composer scripts](https://getcomposer.org/doc/articles/scripts.md)
* [drupal/parse-composer](https://packagist.org/packages/drupal/parse-composer)


## Usage

First you need to [install composer](https://getcomposer.org/doc/00-intro.md#installation-linux-unix-osx).

> Note: The instructions below refer to the [global composer installation](https://getcomposer.org/doc/00-intro.md#globally).
You might need to replace `composer` with `php composer.phar` (or similar) 
for your setup.

After that you can create the project:

```
composer create-project drupal-composer/drupal-project:8.x-dev some-dir --stability dev --no-interaction
```

With `composer require ...` you can download new dependencies to your 
installation.

```
cd some-dir
composer require drupal/devel:8.*
```

The `composer create-project` command passes ownership of all files to the 
project that is created. You should create a new git repository, and commit 
all files not excluded by the .gitignore file.

## What does the template do?

When installing the given `composer.json` some tasks are taken care of:

* Drupal will be installed in the `htdocs`-directory.
* Autoloader is implemented to use the generated composer autoloader in `vendor/autoload.php`,
  instead of the one provided by Drupal (`htdocs/vendor/autoload.php`).
* Modules (packages of type `drupal-module`) will be placed in `htdocs/modules/contrib/`
* Theme (packages of type `drupal-theme`) will be placed in `htdocs/themes/contrib/`
* Profiles (packages of type `drupal-profile`) will be placed in `htdocs/profiles/contrib/`
* Creates default writable versions of `settings.php` and `services.yml`.
* Creates `sites/default/files`-directory.
* Latest version of drush is installed locally for use at `vendor/bin/drush`.
* Latest version of DrupalConsole is installed locally for use at `vendor/bin/drupal`.

## Updating Drupal Core

This project will attempt to keep all of your Drupal Core files up-to-date; the 
project [drupal-composer/drupal-scaffold](https://github.com/drupal-composer/drupal-scaffold) 
is used to ensure that your scaffold files are updated every time drupal/core is 
updated. If you customize any of the "scaffolding" files (commonly .htaccess), 
you may need to merge conflicts if any of your modfied files are updated in a 
new release of Drupal core.

Follow the steps below to update your core files.

1. Run `composer update drupal/core`.
1. Run `git diff` to determine if any of the scaffolding files have changed. 
   Review the files for any changes and restore any customizations to 
  `.htaccess` or `robots.txt`.
1. Commit everything all together in a single commit, so `htdocs` will remain in
   sync with the `core` when checking out branches or running `git bisect`.
1. In the event that there are non-trivial conflicts in step 2, you may wish 
   to perform these steps on a branch, and use `git merge` to combine the 
   updated core files with your customized files. This facilitates the use 
   of a [three-way merge tool such as kdiff3](http://www.gitshah.com/2010/12/how-to-setup-kdiff-as-diff-tool-for-git.html). This setup is not necessary if your changes are simple; 
   keeping all of your modifications at the beginning or end of the file is a 
   good strategy to keep merges easy.
   
# The Build and Deployment Scripts

You may have noticed that running `./build/setup.sh` causes `build/install.sh`
to be invoked, and that this causes all of our modules to be enabled, giving us
a starting schema.

You should note that `build/install.sh` really just installs Drupal and then
passes off to `build/update.sh`, which is the reusable and non-destructive
script for applying updates in code to a Drupal site with existing content. This
is the tool you can use when testing to see if your changes have been persisted
in such a way that your collaborators can use them:

```bash
build/install.sh                                # get a baseline
alias drush="$PWD/vendor/bin/drush -r $PWD/htdocs" # use drush from composer
drush sql-dump > base.sql                       # save your baseline
# ... do a whole bunch of Drupal hacking ...
drush sql-dump > tmp.sql                        # save your intended state
drush -y sql-drop && drush sqlc < base.sql      # restore baseline state
build/update.sh                                 # apply changes to the baseline
```

You should see a lot of errors if, for example, you failed to provide an update
hook for deleting a field whose fundamental config you are changing. Or, perhaps
you've done the right thing and clicked through the things that should be
working now and you see that it is not working as expected. This is a great time
to fix these issues, because you know what you meant to do and your
collaborators don't!

The actual application of updates, including managing the enabled modules,
firing their update hooks, disabling things that should not be enabled and
reverting features is handled by `drupal/drop_ship`, which uses (a fork of)
`kw_manifests` for providing an extensible set of deployment tasks that have
dependencies on one another.

Because manifests can't receive commandline arguments, we pass information to
them with Environment Variables and we provide an env.dist from which to create
a .env file that our scripts will then source. This allows an operator with
access to the target environment to update these tunables out of channel so that
you can deploy any arbitrary revision to any environment.

Particularly, the list of modules used to generate the dependency graph of all
the things we should enable resides in the `DROPSHIP_SEEDS` environment
variable. You may notice that it's a list of one and that it's a poorly named
do-nothing module with nothing besides dependencies. In real life, you would
name this module something relevant to your project and it would be responsible
for over-arching functionality or the application, like providing the minimal
set of modules to generate the dependencies of everything that must be enabled
for the application to work properly. You can think of this like an install
profile that doesn't suck, because it's not a singleton, so with care, you can
embed your whole project in another project that uses this workflow.

See:

* [drupal/drop_ship](https://github.com/promet/drop_ship)
* [drupal/kw_manifests](https://github.com/promet/kw_manifests)

## FAQ

### Should I commit the contrib modules I download

Composer recommends **no**. They provide [argumentation against but also 
workrounds if a project decides to do it anyway](https://getcomposer.org/doc/faqs/should-i-commit-the-dependencies-in-my-vendor-directory.md).

### How can I apply patches to downloaded modules?

If you need to apply patches (depending on the project being modified, a pull 
request is often a better solution), you can do so with the 
[composer-patches](https://github.com/cweagans/composer-patches) plugin.

To add a patch to drupal module foobar insert the patches section in the extra 
section of composer.json:
```json
"extra": {
    "patches": {
        "drupal/foobar": {
            "Patch description": "URL to patch"
        }
    }
}
```

#!/bin/sh
# Used in the sandbox rake task in Rakefile

set -e

case "$DB" in
postgres)
  RAILSDB="postgresql"
  ;;
mysql)
  RAILSDB="mysql"
  ;;
sqlite|'')
  RAILSDB="sqlite3"
  ;;
*)
  echo "Invalid DB specified: $DB"
  exit 1
  ;;
esac

rm -rf ./sandbox
bundle exec rails new sandbox --database="$RAILSDB" \
  --skip-bundle \
  --skip-git \
  --skip-keeps \
  --skip-rc \
  --skip-spring \
  --skip-test \
  --skip-coffee \
  --skip-javascript \
  --skip-bootsnap

if [ ! -d "sandbox" ]; then
  echo 'sandbox rails application failed'
  exit 1
fi

cd ./sandbox

if [ "$SPREE_AUTH_DEVISE_PATH" != "" ]; then
  SPREE_AUTH_DEVISE_GEM="gem 'spree_auth_devise', path: '$SPREE_AUTH_DEVISE_PATH'"
else
  SPREE_AUTH_DEVISE_GEM="gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: 'master'"
fi

if [ "$SPREE_GATEWAY_PATH" != "" ]; then
  SPREE_GATEWAY_GEM="gem 'spree_gateway', path: '$SPREE_GATEWAY_PATH'"
else
  SPREE_GATEWAY_GEM="gem 'spree_gateway', github: 'spree/spree_gateway', branch: 'master'"
fi

cat <<RUBY >> Gemfile
# temp Rails 6 gems
gem 'acts-as-taggable-on', '~> 6.0', github: 'spark-solutions/acts-as-taggable-on', branch: 'fix/rails-6-and-failing-specs'
gem 'awesome_nested_set', '~> 3.1.4', github: 'collectiveidea/awesome_nested_set', branch: 'master'

gem 'spree', path: '..'
$SPREE_AUTH_DEVISE_GEM
$SPREE_GATEWAY_GEM

group :test, :development do
  gem 'bullet'
  gem 'pry-byebug'
  gem 'rack-mini-profiler'
  gem 'awesome_print'
end
RUBY

bundle install --gemfile Gemfile
bundle exec rails db:drop || true
bundle exec rails db:create
bundle exec rails g spree:install --auto-accept --user_class=Spree::User --enforce_available_locales=true --copy_views=false
bundle exec rails g spree:auth:install
bundle exec rails g spree_gateway:install

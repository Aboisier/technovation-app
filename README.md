# Technovation Challenge Platform

Build: [![CircleCI](https://circleci.com/gh/Iridescent-CM/technovation-app/tree/master.svg?style=svg&circle-token=2761348ab1cf794859c6cc40536654b342a8a9d1)](https://circleci.com/gh/Iridescent-CM/technovation-app/tree/master)

## Installation and Setup

### Prerequisites

You **must** install `qt5` for the gem `capybara-webkit` to install:

https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit

You **must** install `elasticsearch`

```
brew install elasticsearch
brew services start elasticsearch
```

You **must** install `postgresql`

```
brew install postgresql
```

You **must** install `redis server`

```
brew install redis
```

You **must** install `pdftk`

Find your download and install from
https://www.pdflabs.com/tools/pdftk-server/

### Setup

Set your Ruby version with your favorite ruby version management tool **(RVM, rbenv, chruby, etc)** to:

`Use Ruby Version: 2.4.1`

Request sensitive keys from your teammates for the `.env` file.

```
git clone git@github.com:Iridescent-CM/technovation-app.git
cd technovation-app
*** GET THE SENSITIVE INFO FROM DEV TEAM FOR .env FILE ***
echo "PDFTK_PATH=`which pdftk`" >> .env
./bin/setup
```

## Drop / recreate / re-seed / re-bootstrap  database

```
rails db:drop db:create db:migrate && rails db:seed bootstrap
```


## Copy data from production (don't be reckless with the data!)

```
dropdb technovation-app_development
heroku pg:pull DATABASE_URL technovation-app_development --app technovation
```

## Development server

```
rails server
```

**Visit http://localhost:3000 for the web**

## Tests

TechnovationApp uses RSpec

```
rake
```

## Rake tasks

```
rails db:seed 
# Seeds with a student, a couple of mentors, and an admin for manual testing
```

```
rails bootstrap
# Adds the Technovation expertises for mentors to choose for their profile
# Adds the Technovation admin account
```

## Release to production

For current version, see [VERSION](VERSION)

Release next patch:

example: 2.45.5 -> 2.45.6

```
rails release
```

Release next minor:

example: 4.32.8 -> 4.33.0

```
rails release minor
```

Release next major:

example: 2.59.8 -> 3.0.0

```
rails release major
```

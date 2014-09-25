source 'https://rubygems.org'

gem 'rails', '3.2.2'

gem 'formtastic'
gem 'omniauth'
gem 'omniauth-facebook'
gem 'koala'
gem 'cocoon'
gem 'paperclip', '2.4.5'
gem 'event-calendar', :require => 'event_calendar'
gem 'activerecord-import'
gem 'date_validator'
gem 'delayed_job_active_record'
gem 'rmagick'
gem 'aws-s3', :require => 'aws/s3' # TODO remove this (map)
#gem 'aws-sdk'
gem 'kaminari'

group :development do
  gem "daemons"
  gem 'sqlite3'
  gem 'yaml_db', :git => 'https://github.com/lostapathy/yaml_db'
end

group :production do
  gem 'pg'
  gem 'thin'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'sass-twitter-bootstrap-rails', '~> 1.0'
  gem 'therubyracer'
  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

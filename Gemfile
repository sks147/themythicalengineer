source "https://rubygems.org"

gem "minima", "~> 2.5"
gem "webrick"

group :jekyll_plugins do
  gem 'jekyll-compose', '~> 0.12.0'
  gem "jekyll-feed", "~> 0.15.1"
  gem 'jekyll-sitemap', '~> 1.4'
  gem 'github-pages'
end

# Windows and JRuby does not include zoneinfo files, so bundle the tzinfo-data gem
# and associated library.
platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", "~> 2.0.4"
  gem "tzinfo-data"
end

# Performance-booster for watching directories on Windows
gem "wdm", "~> 0.1.1", :platforms => [:mingw, :x64_mingw, :mswin]
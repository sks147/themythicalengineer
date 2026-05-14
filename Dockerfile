FROM ruby:3.2-alpine

RUN apk add --no-cache build-base gcc cmake git

WORKDIR /srv/jekyll

COPY Gemfile ./
RUN bundle install

EXPOSE 4000 35729

CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--force_polling", "--livereload"]

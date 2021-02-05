FROM ruby:3.0.0-alpine

RUN gem install bundler

RUN mkdir /app
WORKDIR /app

COPY . .
RUN bundle check || bundle install
RUN rake enable_logging

EXPOSE 2345

CMD bundle exec ruby runner.rb

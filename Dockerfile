FROM ruby:3.4.4

WORKDIR /app
COPY . .
RUN bundle install

ENTRYPOINT ["bundle", "exec"]
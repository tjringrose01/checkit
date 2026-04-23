FROM ruby:3.3.1

RUN apt-get update -qq \
    && apt-get install --no-install-recommends -y build-essential libsqlite3-dev git curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

COPY Gemfile ./
RUN bundle install

COPY . .

RUN chmod +x bin/* 2>/dev/null || true

EXPOSE 3000

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

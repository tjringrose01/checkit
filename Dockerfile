FROM ruby:3.3.1

ARG APP_NAME=Checkit
ARG APP_BUILD_ENVIRONMENT=dev
ARG APP_BUILD_NUMBER=local
ARG APP_BUILD_TIMESTAMP=unknown

RUN apt-get update -qq \
    && apt-get install --no-install-recommends -y build-essential libsqlite3-dev git curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    APP_NAME=${APP_NAME} \
    APP_BUILD_ENVIRONMENT=${APP_BUILD_ENVIRONMENT} \
    APP_BUILD_NUMBER=${APP_BUILD_NUMBER} \
    APP_BUILD_TIMESTAMP=${APP_BUILD_TIMESTAMP}

COPY Gemfile ./
RUN bundle install

COPY . .

RUN chmod +x bin/* 2>/dev/null || true

EXPOSE 3000

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

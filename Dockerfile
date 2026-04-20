ARG RUBY_VERSION=3.4.1
FROM ruby:${RUBY_VERSION}-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential git nodejs \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /srv/jekyll

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_APP_CONFIG=/usr/local/bundle \
    BUNDLE_BIN=/usr/local/bundle/bin \
    BUNDLER_VERSION=2.6.2 \
    GEM_HOME=/usr/local/bundle \
    PATH=/usr/local/bundle/bin:$PATH \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

RUN mkdir -p /usr/local/bundle /srv/jekyll \
  && chmod 755 /usr/local/bundle

COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v "$BUNDLER_VERSION"
RUN bundle install

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--livereload", "--force_polling"]

FROM ubuntu:14.04
MAINTAINER Tackhunter Team <admin@tackhunter.com>
RUN apt-get -yqq update

# Install RVM, Ruby, and Bundler
RUN apt-get -yqq install curl git libxml2
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
RUN \curl -L https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.3.1"

# install gems globally
ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH
RUN /bin/bash -l -c 'gem install bundler \
  && bundle config --global path "$GEM_HOME" \
  && bundle config --global bin "$GEM_HOME/bin"'

# don't create ".bundle" in all our apps
ENV BUNDLE_APP_CONFIG $GEM_HOME

# Install deps
RUN apt-get -yqq install build-essential mysql-client libmysqlclient-dev mysql-server-5.5 libpq-dev postgresql-client libxslt-dev libxml2-dev nodejs npm sphinxsearch imagemagick

# Create directory for tackhunter
RUN /bin/bash -l -c "mkdir -p /appr"
RUN /bin/bash -l -c "ln -s /usr/bin/nodejs /usr/bin/node"
WORKDIR /app


RUN /bin/bash -l -c "curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -"
RUN /bin/bash -l -c "sudo apt-get install -y nodejs"
RUN /bin/bash -l -c "npm install --unsafe-perm"
RUN /bin/bash -l -c "rm -rf client/node_modules/caniuse-*"
RUN /bin/bash -l -c "npm install --unsafe-perm"

# Run Bundle install
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN /bin/bash -l -c "bundle install"

EXPOSE 3000
EXPOSE 9001
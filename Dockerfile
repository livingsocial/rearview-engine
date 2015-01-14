FROM centos:centos6

MAINTAINER Cory Flanigan <cory.flanigan@livingsocial.com>

# Update package manager cache and local dependencies
RUN yum -y update && yum -y groupinstall 'Development Tools'
RUN yum -y install bzip2-devel glib2-devel kernel-devel libcurl libcurl-devel libevent-devel libffi-devel libxml2-devel libxslt-devel MAKEDEV mysql-devel openssl openssl-devel readline readline-devel tar zlib-devel which
RUN yum -y clean all

# Install Java Runtime
ENV JAVA_VERSION 1.7.0
RUN yum install -y java-"${JAVA_VERSION}"-openjdk && yum clean all

# Install jruby
ENV JRUBY_VERSION 1.7.18
RUN mkdir /opt/jruby
WORKDIR /opt/jruby
RUN curl -o ${JRUBY_VERSION}.tar.gz https://s3.amazonaws.com/jruby.org/downloads/${JRUBY_VERSION}/jruby-bin-${JRUBY_VERSION}.tar.gz
RUN tar -xzf ${JRUBY_VERSION}.tar.gz --strip-components=1
RUN update-alternatives --install /usr/local/bin/ruby ruby /opt/jruby/bin/jruby 1

# Install rvm, for the sandbox
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
RUN \curl -sSL https://get.rvm.io | bash -s stable

# rvm_debug is missing for some reason. We fake it out here.
RUN touch /usr/local/rvm/bin/rvm_debug && chmod a+x /usr/local/rvm/bin/rvm_debug

RUN /usr/local/rvm/bin/rvm install ruby-1.9.3-p448 && /usr/local/rvm/bin/rvm ruby-1.9.3-p448 do rvm gemset create rearview-sandbox

# Set path
ENV PATH /opt/jruby/bin:/usr/local/rvm/bin:$PATH

# Create a directory from which to serve our application
RUN mkdir -p /usr/src/app

# Add a user to run under
RUN groupadd -r app -g 433
RUN useradd -u 431 -r -g app -d /usr/src/app -s /sbin/nologin -c "Docker image user" app

# Set ownership of application directory to application user
RUN chown -R app:app /usr/src/app

# Set working directory to application path
WORKDIR /usr/src/app

# Set Rubygem configuration
RUN echo 'gem: --no-rdoc --no-ri' >> ./.gemrc

# Update Rubygems
RUN gem update --system
  
# Install bundler
RUN gem install bundler

# Copy rearview-engine and files needed for bundle
COPY Gemfile Gemfile.lock rearview.gemspec README.md Rakefile /usr/src/app/
COPY lib/rearview/version.rb /usr/src/app/lib/rearview/
COPY spec/dummy/sandbox/* /usr/src/app/spec/dummy/sandbox/

RUN bundle install
RUN /bin/bash --login -c "cd /usr/src/app/spec/dummy/sandbox; rvm use 1.9.3-p448@rearview-sandbox; bundle install"

# Copy app
COPY . /usr/src/app

# Default Command
CMD [""]

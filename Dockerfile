ARG UBUNTU_VERSION="14.04"
FROM ubuntu:${UBUNTU_VERSION}

MAINTAINER Alex Gonzalez <alex@lindusembedded.com>

# Non-interactive debconf package configuration
ARG DEBIAN_FRONTEND=noninteractive

ENV DOCKER_ANDROID_LANG en_US
ENV DOCKER_ANDROID_DISPLAY_NAME docker-android-builder

# Update apt-get
RUN rm -rf /var/lib/apt/lists/* && apt-get update && apt-get dist-upgrade -y && apt-get install -y \
  autoconf \
  locales \
  build-essential \
  bzip2 \
  curl \
  gcc \
  git \
  groff \
  lib32stdc++6 \
  lib32z1 \
  lib32z1-dev \
  lib32ncurses5 \
  lib32bz2-1.0 \
  libc6-dev \
  libgmp-dev \
  libmpc-dev \
  libmpfr-dev \
  libxslt-dev \
  libxml2-dev \
  m4 \
  make \
  ncurses-dev \
  ocaml \
  openssh-client \
  pkg-config \
  python-software-properties \
  rsync \
  software-properties-common \
  unzip \
  wget \
  zip \
  zlib1g-dev \
  sudo \
  git-core \
  gnupg \
  flex \ 
  bison \ 
  gperf \
  zip \
  gcc-multilib \
  g++-multilib \
  libc6-dev-i386 \
  lib32ncurses5-dev \
  x11proto-core-dev \
  libx11-dev \
  lib32z-dev \
  libgl1-mesa-dev \
  libxml2-utils \
  xsltproc \
  unzip \
  ccache \
  schedtool \
  imagemagick \
  --no-install-recommends

# Install Java
RUN apt-add-repository ppa:openjdk-r/ppa && apt-get update && apt-get -y install openjdk-8-jdk

# Clean Up Apt-get
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && apt-get clean

# Set bash as default shell
RUN echo "dash dash/sh boolean false" | debconf-set-selections - && dpkg-reconfigure dash

# Set the locale
RUN locale-gen en_US.UTF-8 && \
    dpkg-reconfigure locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8

# Add build user account, values are set to default below
ENV USER build

# User management
RUN groupadd -g 1000 ${USER} && useradd -u 1000 -g 1000 -ms /bin/bash ${USER}
RUN echo "${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ENV ANDROID_HOME /usr/local/android-sdk
ENV ANDROID_SDK_HOME $ANDROID_HOME
ENV ANDROID_NDK_HOME /usr/local/android-ndk
RUN mkdir -p $ANDROID_HOME $ANDROID_SDK_HOME $ANDROID_NDK_HOME

ENV PROJECT /project
RUN mkdir $PROJECT && chown -R $USER:$USER $PROJECT

# Install repo
RUN curl -o /usr/local/bin/repo http://commondatastorage.googleapis.com/git-repo-downloads/repo && chmod a+x /usr/local/bin/repo

# Fix permissions
RUN chown ${USER}:${USER} $ANDROID_HOME $ANDROID_SDK_HOME $ANDROID_NDK_HOME
RUN chmod -R u+w $ANDROID_HOME $ANDROID_SDK_HOME $ANDROID_NDK_HOME
RUN chmod -R a+rx $ANDROID_HOME $ANDROID_SDK_HOME $ANDROID_NDK_HOME
USER $USER

# Install Android SDK
RUN cd ${ANDROID_SDK_HOME} && wget https://dl.google.com/android/android-sdk_r24.4.1-linux.tgz && tar xvzf android-sdk_r24.4.1-linux.tgz --strip-components=1 && rm android-sdk_r24.4.1-linux.tgz

ENV ANDROID_COMPONENTS platform-tools,android-23,build-tools-23.0.2,build-tools-24.0.0

# Install Android tools
RUN echo y | /usr/local/android-sdk/tools/android update sdk --filter "${ANDROID_COMPONENTS}" --no-ui -a

# Install Android NDK
#RUN cd ${ANDROID_SNDK_HOME} && wget http://dl.google.com/android/repository/android-ndk-r12-linux-x86_64.zip && unzip android-ndk-r12-linux-x86_64.zip && rm android-ndk-r12-linux-x86_64.zip

# Environment variables
ENV PATH ${INFER_HOME}/bin:${PATH}
ENV PATH $PATH:$ANDROID_SDK_HOME/tools
ENV PATH $PATH:$ANDROID_SDK_HOME/platform-tools
ENV PATH $PATH:$ANDROID_SDK_HOME/build-tools/23.0.2
ENV PATH $PATH:$ANDROID_SDK_HOME/build-tools/24.0.0
ENV PATH $PATH:$ANDROID_NDK_HOME

# Export JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

# Support Gradle
ENV TERM dumb
ENV JAVA_OPTS "-Xms4096m -Xmx4096m"
ENV GRADLE_OPTS "-XX:+UseG1GC -XX:MaxGCPauseMillis=1000"

# Tweak Android sources built for speed and avoid out of memory
ENV USE_CCACHE=1
ENV CCACHE_EXEC=/usr/bin/ccache
ENV ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G"
RUN ccache -M 50G

# Creating project directories prepared for build when running
# `docker run`
WORKDIR $PROJECT

RUN echo "sdk.dir=$ANDROID_HOME" > local.properties
RUN echo "echo Welcome to Android builder docker image!" >> /home/build/.bashrc

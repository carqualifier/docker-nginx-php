FROM carqualifier/docker-nginx:latest
MAINTAINER Marcin Ryzycki <marcin@m12.io>,  Eidher Escalona <eescalona@carqualifier.com>

# Add install scripts needed by the next RUN command
ADD container-files/config/install* /config/

RUN \

  `# Install yum-utils (provides yum-config-manager) + some basic web-related tools...` \
  yum install -y yum-utils wget patch mysql tar bzip2 unzip openssh-clients rsync && \


  wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
  wget http://rpms.remirepo.net/enterprise/remi-release-7.rpm && \
  rpm -Uvh remi-release-7.rpm epel-release-latest-7.noarch.rpm && \
  
  yum-config-manager --enable remi-php71 && \
  

  yum install -y \
    php71 \
    php71-php-bcmath \
    php71-php-cli \
    php71-php-common \
    php71-php-devel \
    php71-php-fpm \
    php71-php-gd \
    php71-php-gmp \
    php71-php-intl \
    php71-php-json \
    php71-php-mbstring \
    php71-php-mcrypt \
    php71-php-mysqlnd \
    php71-php-opcache \
    php71-php-pdo \
    php71-php-pear \
    php71-php-process \
    php71-php-pspell \

    `# Also install the following PECL packages:` \
    php71-php-pecl-imagick \
    php71-php-pecl-memcached \
    php71-php-pecl-uploadprogress \
    php71-php-pecl-uuid \
    php71-php-pecl-zip \

    `# Temporary workaround: one dependant package (http, not essential?) fails to install` \
    || true && \
    
   `# Set PATH so it includes newest PHP and its aliases` \
   ln -sfF /opt/remi/php71/enable /etc/profile.d/php71-paths.sh && \
   ls -al /etc/profile.d/ && cat /etc/profile.d/php71-paths.sh && \
   source /etc/profile.d/php71-paths.sh && \
   php --version && \

   `# Move PHP config files from /etc/opt/remi/php70/* to /etc/* ` \
   mv -f /etc/opt/remi/php71/php.ini /etc/php.ini && ln -s /etc/php.ini /etc/opt/remi/php71/php.ini && \
   rm -rf /etc/php.d && mv /etc/opt/remi/php71/php.d /etc/. && ln -s /etc/php.d /etc/opt/remi/php71/php.d && \

   echo 'PHP 7.1 installed.' && \

`# Install libs required to build some gem/npm packages (e.g. PhantomJS requires zlib-devel, libpng-devel)` \
  yum install -y ImageMagick GraphicsMagick gcc gcc-c++ libffi-devel libpng-devel zlib-devel && \

  `# Install common tools needed/useful during Web App development` \

  `# Install Ruby 2` \
  yum install -y ruby ruby-devel && \

  `# Install/compile other software (Git, NodeJS)` \
  source /config/install.sh && \

  yum clean all && rm -rf /tmp/yum* && \

  `# Install common npm packages: grunt, gulp, bower, browser-sync` \
  npm install -g gulp grunt-cli bower browser-sync && \

  `# Update RubyGems, install Bundler` \
  echo 'gem: --no-document' > /etc/gemrc && gem update --system && gem install bundler && \

  `# Disable SSH strict host key checking: needed to access git via SSH in non-interactive mode` \
  echo -e "StrictHostKeyChecking no" >> /etc/ssh/ssh_config && \

  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
  chown www /usr/local/bin/composer

ADD container-files /

ENV STATUS_PAGE_ALLOWED_IP=127.0.0.1

FROM ubuntu:14.04
MAINTAINER MoveHQ <devops@movehq.com>

#################################################
#################################################
#####                                       #####
#####          Arguments Section            #####
#####                                       #####
#################################################
#################################################

###############################
# VIRTUAL_HOST                #
###############################

ARG VIRTUAL_HOST

#################################################
#################################################
#####                                       #####
#####      Dependency Install Section       #####
#####                                       #####
#################################################
#################################################

################################
# Upgrade Everything to latest #
################################

RUN apt-get update -y
RUN apt-get upgrade -y

###############################
# Install stuff for blackfire #
###############################

RUN apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

##############################
# Add the blackfire repo     #
##############################

RUN curl -fsSL https://packagecloud.io/gpg.key | sudo apt-key add -  
RUN echo "deb http://packages.blackfire.io/debian any main" | sudo tee /etc/apt/sources.list.d/blackfire.list  

###############################
# Upgrade and install other   #
# dependencies.               #
###############################

RUN apt-get update -y
RUN apt-get install -y \
nano vim nginx imagemagick \
wget unzip build-essential \
libfuse-dev libcurl4-openssl-dev \
libxml2-dev mime-support \
automake libtool git ssh \
mysql-client-5.5 npm nodejs \
python3 python3-pip \
php5-fpm php-pear php5-mysql php5-gd \
php5-odbc php5-curl php5-cli php5-imap \
php5-oauth php5-imagick php5-memcached \
mailutils ssmtp \
blackfire-agent blackfire-php

###############################
# Enable php modules          #
###############################

RUN sudo php5enmod imap
RUN sudo php5enmod curl
RUN sudo php5enmod imagick
RUN sudo php5enmod oauth

###############################
# Install composer            #
###############################

RUN curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

#################################################
#################################################
#####                                       #####
#####        Pre Clone Tasks Section        #####
#####                                       #####
#################################################
#################################################

###############################
# Set Variables               #
###############################

ENV VIRTUAL_HOST $VIRTUAL_HOST

#################################
# Set xterm and configure ssmtp #
#################################

RUN export TERM=xterm
RUN echo "root=devops@igcsoftware.com" >> /etc/ssmtp/ssmtp.conf && \
    echo "mailhub=smtp02.moverdocs.com:25" >> /etc/ssmtp/ssmtp.conf && \
    echo "UseTLS=NO" >> /etc/ssmtp/ssmtp.conf && \
    echo "FromLineOverride=YES" >> /etc/ssmtp/ssmtp.conf

###############################
# Make Directorys             #
###############################

RUN mkdir /var/www
RUN mkdir /app/
RUN mkdir /EFS/

###############################
# Copy config Files           #
###############################

COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/www.conf /etc/php5/fpm/pool.d/www.conf
COPY config/cacert.pem /etc/ssl/crt/cacert.pem
COPY config/crontabFile /app/crontabFile
COPY config/emptyCrontabFile /app/emptyCrontabFile
COPY config/php.ini /etc/php5/fpm/php.ini
COPY config/php.ini /etc/php5/cli/php.ini
COPY config/crt/movehq.com.crt /etc/ssl/crt/movehq.com.crt
COPY config/crt/movecrm.com.crt /etc/ssl/crt/movecrm.com.crt
COPY config/crt/movehq.com.key /etc/ssl/crt/movehq.com.key
COPY config/crt/movecrm.com.key /etc/ssl/crt/movecrm.com.key
COPY config/vhostHQ /etc/nginx/sites-available/default
COPY config/blackfire.ini /etc/blackfire/agent
COPY config/memcached.ini /etc/php5/mods-available/memcached.ini
COPY config/docker-entrypoint.sh /app/docker-entrypoint.sh
COPY config/.env /var/www/moveHQ/.env
COPY config/master_script.sh /app/master_script.sh

#####################################
# set docker entrypoint permissions #
#####################################

RUN chmod -R 755 /app/

#################################################
#################################################
#####                                       #####
#####           Clone Code Section          #####
#####                                       #####
#################################################
#################################################

###############################
# move the repo               #
###############################

COPY moveHQ /var/www/moveHQ
WORKDIR /var/www/moveHQ

#################################################
#################################################
#####                                       #####
#####        Instance Config Section        #####
#####                                       #####
#################################################
#################################################

#################################
# install composer dependencies #
#################################

RUN cd /var/www/moveHQ && composer install --no-dev

#################################
# add movehq to path            #
#################################

ENV PATH=$PATH:/app/

#################################
# Expose Ports                  #
#################################

EXPOSE 80 443

#################################
# Set our entrypoint            #
#################################

ENTRYPOINT ["/app/docker-entrypoint.sh"]
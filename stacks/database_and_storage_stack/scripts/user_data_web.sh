#!/bin/bash
set -e

## install developer tools
sudo yum groupinstall -y "Development Tools"

## install git image_magick
yum install git ImageMagick ImageMagick-devel

## install rbenv ruby
sudo yum install -y gcc make openssl-devel zlib-devel readline-devel libyaml-devel \
                    libffi-devel tar bzip2 bzip2-devel

git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc
source ~/.bashrc

rbenv install 3.4.7
rbenv global 3.4.7

echo "$(ruby -v)"

## install node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
\. "$HOME/.nvm/nvm.sh"
nvm install 24

echo "$(node -v)"
echo "$(npm -v)"
echo "$(nvm -v)"

## install redis
sudo amazon-linux-extras install epel -y
sudo yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum --enablerepo=remi install -y redis

sudo systemctl enable redis
sudo systemctl start redis

echo "$(redis-cli -v)"

## install mysql client
sudo amazon-linux-extras enable mysql8.0
sudo yum clean metadata

sudo yum install -y mysql

echo "$(mysql --version)"

## fetch rails 8 application
git clone https://github.com/nkajitani/rails_mpa_no_container.git

## boot rails application
rails s -b 0.0.0.0

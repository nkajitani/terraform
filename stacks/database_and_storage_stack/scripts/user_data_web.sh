#!/bin/bash

dnf update -y

dnf install -y nginx mariadb105

# nginx
systemctl start nginx
systemctl enable nginx

# mariadb
systemctl start mariadb
systemctl enable mariadb

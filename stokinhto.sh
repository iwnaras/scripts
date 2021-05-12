#!/bin/bash
filename=$(basename "$1")
mv "$1" /var/www/localhost/files
qr.sh "http://192.168.1.108/files/$filename"

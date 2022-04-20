#!/usr/bin/bash

cd setup-scripts
./configure-athena.sh
./create-tables.sh
./upload-data.sh
./query.sh
cd -

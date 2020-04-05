#!/bin/bash

dir=`dirname "$0"`
cd ${dir}/../
coffee -c -b -m -w ./

#!/bin/bash -x

npm run build
rm docs/*
rsync dist/* docs/ -rv

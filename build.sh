#!/bin/bash -x

npm run build
rm docs/* -r
rsync dist/* docs/ -rv

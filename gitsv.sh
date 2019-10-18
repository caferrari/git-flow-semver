#!/bin/bash
echo "SemVer" >&2
CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`

if [ "master" != $CURRENT_BRANCH ]
then
    echo "- not in the master branch" >&2
    exit 0
fi;

CURRENT_TAG=`git tag -l --points-at HEAD`

if [ ! -z $CURRENT_TAG ]
then
    echo "- commit has tag, nothing to do" >&2
    echo $CURRENT_TAG
    exit 0
fi;

HAS_TAG=0
git describe --abbrev=0 --tags &> /dev/null && HAS_TAG=1

LAST_TAG='v0.0.0'

if [ $HAS_TAG == 1 ]
then
    LAST_TAG=`git describe --abbrev=0 --tags`
fi;

MERGED_FROM=`git log --merges -n 1 --pretty=format:"%B" | cut -d"'" -f 2 | tr '[:upper:]' '[:lower:]'`
IS_RELEASE_BRANCH=0
VERSION_NAME="v0.0.1"
expr match "$MERGED_FROM" "^release\-[0-9]\+.[0-9]\+.[0-9]\+" >/dev/null && IS_RELEASE_BRANCH=1

echo "- merged from: $MERGED_FROM $CURRENT_TAG" >&2

if [ $IS_RELEASE_BRANCH == 1 ] && [ -z $CURRENT_TAG ]
then
    echo "- new release detected: $MERGED_FROM"

    VERSION_NUMBER=`echo $MERGED_FROM | cut -d"-" -f 2`
    VERSION_NAME="v$VERSION_NUMBER"

    TAG_EXISTS=0
    git rev-parse $VERSION_NAME >/dev/null 2>&1 && TAG_EXISTS=1

    if [ $TAG_EXISTS == 1 ]
    then
        echo "- tag already exists: $VERSION_NAME from release: $MERGED_FROM" >&2
        exit 100
    fi;
else 
    VALID_TAG=0
    expr match "$LAST_TAG" "^v[0-9]\+.[0-9]\+.[0-9]\+" >/dev/null && VALID_TAG=1

    if [ $VALID_TAG == 0 ]
    then
        echo "- the last tag is invalid: $LAST_TAG" >&2
        exit 101
    fi;

    echo "- current version: $LAST_TAG" >&2
    VERSION_NAME=`echo $LAST_TAG | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{if(length($NF+1)>length($NF))$(NF-1)++; $NF=sprintf("%0*d", length($NF), ($NF+1)%(100^length($NF))); print}'`
fi;

echo "- new version: $VERSION_NAME" >&2

git tag $VERSION_NAME

echo "$VERSION_NAME"
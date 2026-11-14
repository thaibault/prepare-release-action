#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]tsickert.com) 16.12.2012

# License
# -------

# This library written by Torben Sickert stands under a creative commons naming
# 4.0 international license.
# see https://creativecommons.org/licenses/by/4.0/deed.de
# endregion
# shellcheck disable=SC1090,SC2034,SC2155
declare -r NPM_PACKAGE_FILE_PATH='./package.json'
declare -r PKGBUILD_FILE_PATH='./PKGBUILD'
declare -r VERSION_PATTERN='^([0-9]+)\.([0-9]+)\.([0-9]+)(-[0-9]+)?$'

declare MANIFEST_FORMAT='${MAJOR}.${MINOR}.${PATCH}${CANDIDATE}'
declare FORMAT="$MANIFEST_FORMAT"
declare UPDATE_TYPE=patch
declare DEBUG=false
declare UPDATE_MANIFEST_FILE=false

# Prints all versions given as (optionally "v" prefixed) git tags.
get_tagged_versions() {
    git tag --list 2>/dev/null | \
        sed \
            --quiet \
            --regexp-extended \
            's/^v?([0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?)$/\1/p'
}

while true; do
    case "$1" in
        -d|--debug)
            DEBUG=true
            shift
            ;;
        -f|--format)
            shift
            FORMAT="$1"
            shift
            ;;
        -u|--update-manifest-file)
            UPDATE_MANIFEST_FILE=true
            shift
            ;;
        major|minor|patch|candidate)
            UPDATE_TYPE="$1"
            shift
            ;;
        '')
            shift || \
                true
            break
            ;;
        *)
            echo "Given argument: \"${1}\" is not available." &>/dev/stderr
            exit 1
    esac
done

declare HAS_NPM_PACKAGE_FILE=false
[ -s "$NPM_PACKAGE_FILE_PATH" ] && \
    HAS_NPM_PACKAGE_FILE=true
declare HAS_PKGBUILD_FILE=false
[ -s "$PKGBUILD_FILE_PATH" ] && \
    HAS_PKGBUILD_FILE=true

# NOTE: "package.json" is the single source of truth if it exists. Without
# any manifest file the latest tagged version is used.
if $HAS_NPM_PACKAGE_FILE; then
    declare -r GIVEN_VERSION="$(
        node --eval "console.log(require('${NPM_PACKAGE_FILE_PATH}').version)"
    )"
elif $HAS_PKGBUILD_FILE; then
    declare -r GIVEN_VERSION="$(
        sed \
            --quiet \
            --regexp-extended \
            "s/^pkgver=[\"']?([^\"']+)[\"']?$/\1/p" \
            "$PKGBUILD_FILE_PATH"
    )"
else
    declare GIVEN_VERSION="$(
        get_tagged_versions | \
            sort --version-sort | \
                tail --lines 1
    )"
    [ "$GIVEN_VERSION" = '' ] && \
        GIVEN_VERSION=0.0.0
    declare -r GIVEN_VERSION
fi

declare MAJOR="$(
    echo "$GIVEN_VERSION" | sed --regexp-extended "s/${VERSION_PATTERN}/\1/"
)"
declare MINOR="$(
    echo "$GIVEN_VERSION" | sed --regexp-extended "s/${VERSION_PATTERN}/\2/"
)"
declare PATCH="$(
    echo "$GIVEN_VERSION" | sed --regexp-extended "s/${VERSION_PATTERN}/\3/"
)"
declare CANDIDATE="$(
    echo "$GIVEN_VERSION" | sed --regexp-extended "s/${VERSION_PATTERN}/\4/"
)"

if $DEBUG; then
    echo GIVEN_VERSION: "$GIVEN_VERSION"

    echo MAJOR: "$MAJOR"
    echo MINOR: "$MINOR"
    echo PATCH: "$PATCH"
    echo CANDIDATE: "$CANDIDATE"

    echo TYPE: "$UPDATE_TYPE"
fi

if [ "$UPDATE_TYPE" = major ]; then
    (( MAJOR += 1))
    MINOR=0
    PATCH=0
    CANDIDATE=''
elif [ "$UPDATE_TYPE" = minor ]; then
    (( MINOR += 1))
    PATCH=0
    CANDIDATE=''
elif [ "$UPDATE_TYPE" = patch ]; then
    (( PATCH += 1))
    CANDIDATE=''
fi

if [ "$UPDATE_TYPE" = candidate ]; then
    # NOTE: Without "package.json" there is no file to hold candidate numbers
    # ("pkgver" in "PKGBUILD" can not contain "-"), so the next free candidate
    # number of the current version is derived from existing git tags.
    if ! $HAS_NPM_PACKAGE_FILE; then
        CANDIDATE_NUMBER="$(
            get_tagged_versions | \
                sed \
                    --quiet \
                    --regexp-extended \
                    "s/^${MAJOR}\.${MINOR}\.${PATCH}-([0-9]+)$/\1/p" | \
                        sort --numeric-sort | \
                            tail --lines 1
        )"
        CANDIDATE="-$(( ${CANDIDATE_NUMBER:-0} + 1 ))"
    elif [ "$CANDIDATE" = '' ]; then
        CANDIDATE='-1'
    else
        CANDIDATE_NUMBER="$(
            echo "$CANDIDATE" | sed --regexp-extended 's/-(.+)/\1/'
        )"
        (( CANDIDATE_NUMBER += 1))
        CANDIDATE="-${CANDIDATE_NUMBER}"
    fi
fi

if $UPDATE_MANIFEST_FILE; then
    declare -r NEW_MANIFEST_VERSION="$(eval "echo \"${MANIFEST_FORMAT}\"")"
    if $HAS_NPM_PACKAGE_FILE; then
        node --eval "const {writeFileSync} = require('fs'); const content = require('${NPM_PACKAGE_FILE_PATH}'); content.version = '${NEW_MANIFEST_VERSION}'; writeFileSync('${NPM_PACKAGE_FILE_PATH}', JSON.stringify(content, null, 2) + '\n', {encoding: 'utf-8'})"
    fi
    # NOTE: Candidates are not published to arch's user repository so the arch
    # package version stays at the last regular release.
    if $HAS_PKGBUILD_FILE && [ "$CANDIDATE" = '' ]; then
        sed \
            --in-place \
            --regexp-extended \
            --expression "s/^pkgver=.*$/pkgver=${NEW_MANIFEST_VERSION}/" \
            --expression 's/^pkgrel=.*$/pkgrel=1/' \
            "$PKGBUILD_FILE_PATH"
    fi
fi

declare -r NEW_VERSION="$(eval "echo \"${FORMAT}\"")"

echo "$NEW_VERSION"

# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion

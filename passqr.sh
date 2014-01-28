#!/bin/bash
#
# Copyright 2014 Emil Lundberg <lundberg.emil@gmail.com>. All rights reserved.
#
# This file is part of passqr.
#
# passqr is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 2 of the License, or (at your option) any later
# version.
#
# passqr is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# passqr. If not, see <http://www.gnu.org/licenses/>.

GETOPT=getopt
PROGRAM="$(basename "$0")"
VERSION=1.0.0
CONFIG=(
    '/etc/passqr.conf'
    "${HOME}/.config/passqr.conf"
)

PIXELSIZE=6
TIMEOUT=3
VERBOSE=false
VIEWER_EXEC=''

find_viewer() {
    if hash feh 2>/dev/null; then
        VIEWER_EXEC='feh -'
    elif hash display 2>/dev/null; then
        VIEWER_EXEC='display -'
    else
        echo "Fatal: Could not find any image viewer"
        echo "Please install one and set VIEWER_EXEC in the config file."
        exit 1
    fi
}

usage() {
cat << EOF
Usage: ${PROGRAM} [options] pass-name

Options (defaults):

  -c, --config FILE
    Add FILE to the list of config files to source. Can be specified multiple
    times, later files override earlier ones.

  -h, --help
    Show this message and exit.

  -t, --timeout SECONDS (3)
    Wait SECONDS seconds before closing the image viewer. Overrides any settings
    in config files.

  -v, --verbose
    Output information about what the program is doing. This may include
    sensitive information such as pass-name.

  --version
    Output version information and exit.

  -w, --viewer 'COMMAND' ('feh -' or 'display -')
    Pipe QR code image into COMMAND for display. COMMAND is expected to read the
    image from stdin. If COMMAND is '-', then print the image to stdout instead
    of displaying it.

    If no config file specifies a viewer command and this option is not given,
    ${PROGRAM} will look for 'feh' and 'display'. If none is found, the program
    shows an error message and exits with nonzero exit code.

EOF
}

version() {
cat << EOF
Password Store QR add-on, version ${VERSION}
by Emil Lundberg <lundberg.emil@gmail.com>
EOF
}

ARGS="$($GETOPT -o c:ht:vw: -l config:,help,timeout:,verbose,version,viewer: -n "$PROGRAM" -- "$@")"
if [[ $? -ne 0 ]]; then
    usage
    exit 1
fi

eval set -- "$ARGS"
while true; do
    case $1 in
        -c|--config)
            shift
            CONFIG+=("$1")
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --version)
            version
            exit 0
            ;;
        --)
            shift
            break
            ;;
    esac
    shift
done

if [[ $# -eq 0 ]]; then
    # Must have a pass-name to pass to pass
    echo "Fatal: no pass-name given"
    usage
    exit 1
fi

for config_file in "${CONFIG[@]}"; do
    if [[ -f "$config_file" ]]; then
        if $VERBOSE; then
            echo "Sourcing config file ${config_file}"
        fi
        source "$config_file"
    fi
done

# Parse arguments again, to allow for overriding config settings
eval set -- "$ARGS"
while true; do
    case $1 in
        -t|--timeout)
            shift
            TIMEOUT=$1
            ;;
        -v|--verbose)
            VERBOSE=true
            ;;
        -w|--viewer)
            shift
            VIEWER_EXEC="$1"
            ;;
        --)
            shift
            break
            ;;
    esac
    shift
done

if [[ -z "$VIEWER_EXEC" ]]; then
    find_viewer
fi

pass_cmd="pass show $@"
if output=$($pass_cmd); then
    if $VERBOSE; then
        echo "Encoding first line of output of '${pass_cmd}'"
    fi
    output=$(echo "$output" | head -n1)
    encode_cmd="qrencode -s $PIXELSIZE -t PNG -o - $output"
    if [[ "$VIEWER_EXEC" == '-' ]]; then
        $encode_cmd
    else
        $encode_cmd | $VIEWER_EXEC &
        sleep $TIMEOUT
        kill $! 2>/dev/null
    fi
fi
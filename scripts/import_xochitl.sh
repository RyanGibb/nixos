#!/bin/sh
# adapted from https://github.com/adaerr/reMarkableScripts/blob/master/pdf2remarkable.sh

XOCHITL_DIR=${XOCHITL_DIR:-.local/share/remarkable/xochitl/}

if [ $# -lt 1 ]; then
    echo "usage: $(basename $0) [ -r ] path-to-file [path-to-file]..."
    exit 1
fi

RESTART_XOCHITL_DEFAULT=${RESTART_XOCHITL_DEFAULT:-0}
RESTART_XOCHITL=${RESTART_XOCHITL_DEFAULT}
if [ "$1" = "-r" ] ; then
    shift
    if [ $RESTART_XOCHITL_DEFAULT -eq 0 ] ; then
        echo Switching
        RESTART_XOCHITL=1
    else
        RESTART_XOCHITL=0
    fi
fi

# Create directory where we prepare the files as the reMarkable expects them
tmpdir=$(mktemp -d)

# Loop over the command line arguments,
# which we expect are paths to the files to be transferred
for filename in "$@" ; do

    # reMarkable documents appear to be identified by universally unique IDs (UUID),
    # so we generate one for the document at hand
    uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')

    extension="${filename##*.}"

    # Copy the file itself
    cp -- "$filename" "${tmpdir}/${uuid}.${extension}"

    # Add metadata
    # The lastModified item appears to contain the date in milliseconds since Epoch
    cat <<EOF >>${tmpdir}/${uuid}.metadata
{
    "deleted": false,
    "lastModified": "$(date +%s)000",
    "metadatamodified": false,
    "modified": false,
    "parent": "",
    "pinned": false,
    "synced": false,
    "type": "DocumentType",
    "version": 1,
    "visibleName": "$(basename -- "$filename" ".$extension")"
}
EOF

    if [ "$extension" = "pdf" ]; then
	# Add content information
	cat <<EOF >${tmpdir}/${uuid}.content
{
    "extraMetadata": {
    },
    "fileType": "pdf",
    "fontName": "",
    "lastOpenedPage": 0,
    "lineHeight": -1,
    "margins": 100,
    "pageCount": 1,
    "textScale": 1,
    "transform": {
        "m11": 1,
        "m12": 1,
        "m13": 1,
        "m21": 1,
        "m22": 1,
        "m23": 1,
        "m31": 1,
        "m32": 1,
        "m33": 1
    }
}
EOF

	# Add cache directory
	mkdir ${tmpdir}/${uuid}.cache

	# Add highlights directory
	mkdir ${tmpdir}/${uuid}.highlights

	# Add thumbnails directory
	mkdir ${tmpdir}/${uuid}.thumbnails

    elif [ "$extension" = "epub" ]; then

	# Add content information
	cat <<EOF >${tmpdir}/${uuid}.content
{
    "fileType": "epub"
}
EOF

    else
	echo "Unknown extension: $extension, skipping $filename"
        rm -rf ${tmpdir}/*
	continue
    fi

    # Transfer files
    echo "Transferring $filename as $uuid"
    scp -r ${tmpdir}/* "${XOCHITL_DIR}"
    rm -rf ${tmpdir}/*
done

rm -rf ${tmpdir}

if [ $RESTART_XOCHITL -eq 1 ] ; then
    echo "Restarting Xochitl..."
    systemctl restart xochitl
    echo "Done."
fi

#!/bin/bash

# Input and Output Arguments
infile=$1
outfile=$2

# Check if output file is provided
if [ "$outfile" = "" ]; then
    echo 1>&2 Usage: $(basename $0) infile outfile
    exit 2
fi

# Remove structural PDF metadata using qpdf and jq
trailer=$(qpdf --json-output --json-object=trailer $infile -)
root_obj=$(jq -r '.qpdf[1].trailer.value."/Root"' <<< "$trailer")
info_obj=$(jq -r '.qpdf[1].trailer.value."/Info"' <<< "$trailer")

# Extract root, info, and trailer objects
qpdf --json-output $infile $outfile.1.json \
     --json-object="$root_obj" --json-object="$info_obj" --json-object=trailer

# Modify the JSON to remove metadata and info
jq < $outfile.1.json > $outfile.2.json \
    "del(.qpdf[1].\"obj:$root_obj\".value.\"/Metadata\") | del(.qpdf[1].trailer.value.\"/Info\")"

# Update the PDF based on modified JSON
qpdf --update-from-json=$outfile.2.json $infile $outfile

# Use ExifTool to remove metadata from embedded images/files and suppress backup creation
exiftool -all= -overwrite_original "$outfile"

# Clean up temporary files generated during the process
rm $outfile.1.json $outfile.2.json

# Notify user
echo "All metadata removed from $outfile"

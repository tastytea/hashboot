#!/bin/sh

if [ -f "hashboot.1.adoc" ]; then
    name="hashboot"
    version="$(grep VERSION hashboot | head -n1 | cut -d\" -f2)"
    dir="$(dirname ${0})"

    sed -Ei "s/(Revision: +)[0-9]+\.[0-9]+\.[0-9]+/\1${version}/" ${name}.1.adoc
    a2x --doctype manpage --format manpage --no-xmllint ${name}.1.adoc
else
    echo "hashboot.1.adoc not found." >&2
fi

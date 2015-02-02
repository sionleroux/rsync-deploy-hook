#!/bin/sh
#
# An update hook that deploys the master branch via rsync.
# Checks if the update is a commit on the master branch, then checks out the
# files to a temporary directory and rsyncs them up to the web-server.
#
# TODO: compile SASS to CSS before rsyncing
#

# --- Command line
refname="$1"
oldrev="$2"
newrev="$3"

# --- Safety check
if [ -z "$GIT_DIR" ]; then
	echo "Don't run this script from the command line." >&2
	echo " (if you want, you could supply GIT_DIR then run" >&2
	echo "  $0 <ref> <oldrev> <newrev>)" >&2
	exit 1
fi

if [ -z "$refname" -o -z "$oldrev" -o -z "$newrev" ]; then
	echo "usage: $0 <ref> <oldrev> <newrev>" >&2
	exit 1
fi

# --- Config
wwwpath=$(git config hooks.wwwpath)

# --- Check types
# if $newrev is 0000...0000, it's a commit to delete a ref.
zero="0000000000000000000000000000000000000000"
if [ "$newrev" = "$zero" ]; then
	newrev_type=delete
else
	newrev_type=$(git cat-file -t $newrev)
fi

if [[ "$refname","$newrev_type" == "refs/heads/master","commit" ]]; then
	if [[ -z $wwwpath ]]; then
		echo "Path to web server is empty (hooks.wwwpath)" 1>&2
		exit 1
	fi

	tmpdir=`mktemp -d`
	echo "building in $tmpdir" 1>&2

	git --work-tree=$tmpdir checkout --force $newrev >/dev/null
	if [[ $? -ne 0 ]]; then
		echo "failed checking out $newrev to $tmpdir" 1>&2
		exit 1
	fi

	cd $tmpdir
	rsync --verbose --progress --stats --compress src/* $wwwpath

fi

# --- Finished
exit 0

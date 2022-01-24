#!/bin/bash

set -Eeufo pipefail

token="$1"
repo="$2"
tag="$3"

curl_path="$(which curl)"

function curl {
	$curl_path -s -f -u "token:$token" "$@"
}

function get {
	[ $# = 1 ]
	curl -X GET "https://api.github.com/repos/$repo/$1"
}

function post {
	[ $# = 2 ]
	curl -X POST "https://api.github.com/repos/$repo/$1" --data "$2"
}

function delete {
	[ $# = 1 ]
	curl -X DELETE "https://api.github.com/repos/$repo/$1"
}

function upload {
	[ $# = 1 ]
	curl -X POST -H "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$repo/$1" --data-binary @-
}

release="$(get "releases/tags/$tag" | jq -r '.id' || true)"

[ "$release" ] || release="$(post "releases" '{
	"tag_name": "'$tag'"
}' | jq -r '.id')"

while read asset_file; do
	asset_name="$(basename "$asset_file")"
	asset="$(get "releases/$release" | jq -r '.assets[] | select(.name == "'$asset_name'") | .id' || true)"
	[ ! "$asset" ] || delete "releases/assets/$asset"
	upload "releases/$release/assets?name=$asset_name" < "$asset_file" > /dev/null
	echo "uploaded $asset_file to $release"
done

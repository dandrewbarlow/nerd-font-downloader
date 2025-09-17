#! /usr/bin/env bash
# nfd.sh
#
# Author: Andrew Barlow (github.com/dandrebarlow)
#
# Description:
# Script to automatically download nerd fonts from
# https://github.com/ryanoasis/nerd-fonts.
#
# Uses github API to programatically get latest release, 
#
# Dependencies:
# fzf
# jq
# wget
# parallel


# GLOBAL VARS ##################################################

# By default, save files needed in xdg-cache location
cache_dir="$XDG_CACHE_HOME/nerd-font-downloader"

# if xdg-cache location isn't defined, default to ~/.config/nerd-font-downloader
if [ -z "$XDG_CACHE_HOME" ]; then
	cache_dir="$HOME/.cache/nerd-font-downloader"
fi

# could be hardcoded, but I might refactor this script for more general usage
author="ryanoasis"
repo="nerd-fonts"

# location of font list in github repo. technically not necessary, could just
# use releases, but this has extra info on fonts that could be nice to see.
font_list_file="bin/scripts/lib/fonts.json"

# names for json files saved to cache directory
registry_cache_file="$cache_dir/registry.json"
release_cache_file="$cache_dir/release.json"

# FUNCTIONS ##################################################

# get font registry
update_font_registry() {

	# TODO: this only checks if it exists; a nice feature could be to check
	# for updates or update after a certain amount of time; rn have to
	# remove this file to get it to refresh
	if [ ! -e "$registry_cache_file" ]; then

		echo "Downloading Font Registry"
		
		# download, extract & decode json file, filter out irrelavent data
		curl -s -L "https://api.github.com/repos/$author/$repo/contents/$font_list_file" | \
			jq -r '.content' | base64 --decode | \
			jq -r '[.fonts[] | {name: .patchedName, version: .version, isMonospaced: .isMonospaced, description: .description}]' \
			> "$registry_cache_file"
	fi
}


# get latest release info
update_releases() {

	# TODO: same as registry, this only checks for file existance
	if [ ! -e "$release_cache_file" ]; then

		echo "Downloading Release Registry"

		# download and filter out irrelavent data
		# jq gets a little complicated
		curl -s -L "https://api.github.com/repos/$author/$repo/releases/latest" | \
			jq '[.assets[] | {name: .name|rtrimstr(".tar.xz"), url: .browser_download_url}] | del(.[] | select(.name | test(".zip", "g")))' > \
			"$release_cache_file"
	fi
}


# pick which fonts to download
select_font() {
	cat "$registry_cache_file" | jq -r '.[].name' | fzf --prompt="Choose which fonts to download> "
}

# get font urls
extract_urls() {
	# BUG: creates seperate entries for .zip & .tar.xz; wanted to just use
	# tar for smaller size, but not all fonts have a tarball 
	for var in "$@"; do
		jq -r --arg fontname "$var" 'map(select(.name == $fontname)) | .[0].url' "$release_cache_file" | fzf --prompt="Confirm downloads for font: $var"
	done
}

# TODO: refactor for function; remove all 'null's from url list
verify_url() {
	# get line numbers of releases not found
	echo "$urls" | grep -n 'null' | cut -d : -f 1 | xargs -I _ echo "${fonts[_]}"
}

# download fonts in parallel
download_fonts() {
	# TODO: set download location to something sensible 
	echo "$@" | grep -v 'null' | parallel wget -q
}

# TODO: extract fonts
extract_fonts() {}

# TODO: install downloaded fonts
install_fonts() {}

# initialization
init() {
	mkdir -p "$cache_dir"
	update_font_registry
	update_releases
}

main() {
	init
	fonts="$(select_font)"
	urls="$(extract_urls $fonts)"
}


main


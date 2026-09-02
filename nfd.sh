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
# tar
# unzip


# GLOBAL VARS ##################################################
# NOTE: keeping variables you may want to change here

# By default, save files needed in xdg-cache location
cache_dir="$XDG_CACHE_HOME/nerd-font-downloader"

# if xdg-cache location isn't defined, default to ~/.cache/nerd-font-downloader
if [ -z "$XDG_CACHE_HOME" ]; then
	cache_dir="$HOME/.cache/nerd-font-downloader"
fi

# names for json files saved to cache directory
registry_cache_file="$cache_dir/registry.json"
release_cache_file="$cache_dir/release.json"

# raw API responses downloaded by wget -N (named after URL basename)
registry_raw_file="$cache_dir/fonts.json"
release_raw_file="$cache_dir/latest"

# font download location
font_download_dir="/tmp/nerd-font-downloader"

# NOTE: defaults to user installation; for system-wide installation, change
# this variable to /usr/local/share/fonts
font_install_location="$HOME/.local/share/fonts"

# Script variables: changing these will break script

# could be hardcoded, but I might refactor this script for more general usage
author="ryanoasis"
repo="nerd-fonts"

# NOTE: location of font list in github repo. technically not necessary, could
# just use releases, but this has extra info on fonts that could be nice to
# see.
font_list_file="bin/scripts/lib/fonts.json"

trap 'exit 130' INT

# FUNCTIONS ##################################################

# download and process font registry, using -N to only fetch if newer
update_font_registry() {
	echo "Updating Font Registry"
	wget -qN -P "$cache_dir" "https://api.github.com/repos/$author/$repo/contents/$font_list_file"
	jq -r '.content' "$registry_raw_file" | base64 --decode | \
		jq -r -c '[.fonts[] | {name: .patchedName, version: .version, isMonospaced: .isMonospaced, description: .description}]' \
		> "$registry_cache_file"
}

# download and process release info, using -N to only fetch if newer
update_releases() {
	echo "Updating Release Registry"
	wget -qN -P "$cache_dir" "https://api.github.com/repos/$author/$repo/releases/latest"
	# NOTE: this creates separate entries for .zip and .tar.xz downloads, merged by get_font_info
	jq -c '[.assets[] | {name: (.name | sub("(\\.tar\\.xz|\\.zip)"; "")), url: [.browser_download_url]}]' \
		"$release_raw_file" > "$release_cache_file"
}

# pick which fonts to download
select_font() {
	jq -r '.[].name' "$registry_cache_file" | fzf +m --prompt="Choose which fonts to download> "
}

# get font json for a given font
get_font_info() {
	# using some complicated jq to merge url fields
	jq -r --arg fontname "$1" 'map(select(.name == $fontname)) | [{name: .[].name, urls: [.[].url | add]}][0]' "$release_cache_file"
}

# extract & confirm which download to get
confirm_download() {
	font_name=$(echo "$1" | jq '.name')

	urls="$(echo "$1" | jq -r '.urls[]')"

	# get line numbers of releases not found
	downloadURL=$(echo "$urls" | fzf +m --prompt="Choose download for font: $font_name")
	# echo "$urls" | grep -n 'null' | cut -d : -f 1 | xargs -I _ echo "${fonts[_]}"
	#
	echo "$downloadURL"
}

# get download location based on font name making a function because I need
# this at a couple of different points and don't want to bother passing it
# around
get_extraction_location() {
	echo "$font_download_dir/$1"
}

# high level function to download a font
download_font() {
	font="$1"

	# gets release info including download urls
	font_meta=$(get_font_info "$font")

	# gets the url of the file the user wants to download
	url=$(confirm_download "$font_meta")
	[[ $? -ne 0 ]] && exit

	# provide some feedback
	echo "Downloading $font"
	echo "=================================================="

	# download the archive
	echo "$url" | wget -nv -N -i - -P "$font_download_dir"
}

# function to extract downloaded font archive
extract_font() {

	font="$1"

	font_extraction_location=$(get_extraction_location "$font")

	mkdir -p "$font_extraction_location"

	echo "Extracting $font"
	echo "=================================================="

	# handle .tar.xz archives
	find "$font_download_dir" -name "$1.tar.xz" | xargs -p -I {} tar xvf {} -C "$font_extraction_location"

	# handle .zip archives
	find "$font_download_dir" -name "$1.zip" | xargs -p -I {} unzip {} -d "$font_extraction_location"
}

# high level function for installing a font
install_font() {
	font="$1"

	font_extraction_location=$(get_extraction_location "$font")

	echo 
	read -p "Installing $font to $font_install_location  continue? [y/n]: " -n 1 -r
	echo    # (optional) move to a new line

	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		# move font files to installation location
		mv "$font_extraction_location" "$font_install_location"

		# make system update its list of fonts
		echo
		echo "Refreshing fontconfig cache"
		fc-cache
	fi

}

# initialization
init() {
	# create necessary directories for download
	mkdir -p "$cache_dir" "$font_download_dir"

	# check if there are newer releases on the github
	# I'm an arch user btw, can't miss any font updates
	update_font_registry
	update_releases
}

# main process, made it as high level as possible
main() {

	init

	font="$(select_font)"
	[[ $? -ne 0 ]] && exit

	download_font "$font"

	extract_font "$font"

	install_font "$font"
}


main


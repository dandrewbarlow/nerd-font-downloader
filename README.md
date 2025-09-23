# Nerd Font Downloader

by Andrew Barlow ([github](https://github.com/dandrewbarlow) | [website](https://a-barlow.com))

## Description

I love nerd-fonts for the terminal, I don't love manually installing them. They
have a script on their website (which I didn't realize until I finished), but
I'd rather have my own in my dotfiles, doing exactly what I want it to.

Its a pretty simple shell script, I tried my best to keep things readable. Only
arcane parts are the `jq` filters, imo. Obviously please try to read and
understand what it does before running. 

## Usage

I didn't put in a lot of error checking, and after fiddling with it, only
decided to have it download one font at a time. So intended use is to run, pick
font, let it install for each font you want. I leaned heavy on confirmations to
ensure it does exactly what I want it to and is transparent to the user. Focus
is on interactivity and ease of use over a properly unix-like program. I only
want one or two, so more than this is outside of my use case. It's a simple
enough program that I feel like someone who cares about that could adjust it
themselves.

### Configuration

I have any relevant variables (download/install locations) defined at the
beginning of the file, I think they're sensible defaults, but if you disagree
or have a different setup it should be very easy to change. Last disclaimer,
this was made on and for a (/my) Linux environment, it could probably be easily
made to work elsewhere, but it's not my priority.

## Dependencies

- `fzf`
- `jq`
- `wget`
- `tar`
- `unzip`

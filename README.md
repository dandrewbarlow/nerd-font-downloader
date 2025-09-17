# Nerd Font Downloader

by Andrew Barlow ([github](https://github.com/dandrewbarlow) | [website](https://a-barlow.com))

## Description

I love nerd-fonts for the terminal, I don't love manually installing them. So I
did the classic move of spending way too much time automating it, but it's a
learning experience and hopefully other people can enjoy the fruits of my labor
as well.

Its a pretty simple shell script, I tried my best to keep things readable. Only
arcane parts are the `jq` filters, imo. Obviously please try to read and
understand what it does before running.

## Dependencies

- `fzf`
- `jq`
- `wget`
- `parallel`

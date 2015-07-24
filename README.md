# Blocklist Freshener

This is a utility I hacked up to keep a nice, expansive list of
blacklisted IP addresses for general use (e.g. SSH, firewall).

It is meant to be set up as a cronjob to run under a unprivileged account. 
You should really only need to run it once a week at most.

It manages its own cache and keeps a history of generated blocklists. It
does its best to keep things tidy so that it may be left unattended.

You will need fish and CURL. I have included my fish logging library.

# Usage

This was originally running on an RPi which had an instance of gatling
pointed at the script output directory. As such, it links the newest list
to `blocklist_latest.gz` so that it can be reliably provided to
applications which need such a list and then left that way.

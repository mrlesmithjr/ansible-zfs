#/bin/bash

# Replaces pool-name\filesystem with pool-name/filesystem
zfs load-key "${1/'\\'/'/'}"
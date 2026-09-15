#!/usr/bin/env sh

# Check if we are already inside a screen session named 'minecraft'
# If not, restart this script inside a new screen session
if [ -z "$STY" ]; then
    exec screen -dmS minecraft "$0" "$@"
    echo "Server started in screen session 'minecraft'. Use 'screen -r' to view."
    exit
fi

# Forge requires a configured set of both JVM and program arguments.
# Add custom JVM arguments to the user_jvm_args.txt
# Add custom program arguments {such as nogui} to this file in the next line before the "$@" or
# pass them to this script directly
exec java @user_jvm_args.txt @libraries/net/neoforged/neoforge/21.1.219/unix_args.txt "$@"

#!/usr/bin/env bash

# User variables
target_hostname=""
target_destination=""
target_administrator=""
target_user=${BOOTSTRAP_USER-root} # Set BOOTSTRAP_ defaults in your shell.nix
ssh_port=${BOOTSTRAP_SSH_PORT-22}

function help_and_exit() {
	echo
	echo "Remotely installs NixOS on a target machine using this nix-config."
	echo
	echo "USAGE: $0 -n <target_hostname> -d <target_destination> [OPTIONS]"
	echo
	echo "ARGS:"
  echo "  -n <target_hostname>                    specify target_hostname of the target host to deploy the nixos config on. (default I think)"
	echo "  -d <target_destination>                 specify ip or domain to the target host."
  echo "  -a <target_administrator>               specify the name of the user that will act as the system administrator (roy)"
  echo 
	echo "OPTIONS:"
	echo "  -u <target_user>                        specify target_user with sudo access. nix-config will be cloned to their home."
	echo "                                          Default=root."
	echo "  --port <ssh_port>                       specify the ssh port to use for remote access. Default=${ssh_port}."
	echo "  --debug                                 Enable debug mode."
	echo "  -h | --help                             Print this help."
	exit 0
}

# Function to cleanup temporary directory on exit
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

# Handle command-line arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
	-n)
		shift
		target_hostname=$1
		;;
	-d)
		shift
		target_destination=$1
		;;
  -a)
    shift
    target_administrator=$1
    ;;
	-u)
		shift
		target_user=$1
		;;
	--port)
		shift
		ssh_port=$1
		;;
	--debug)
		set -x
		;;
	-h | --help) help_and_exit ;;
	*)
		echo "ERROR: Invalid option detected."
		help_and_exit
		;;
	esac
	shift
done

if [ -z "$target_hostname" ] || [ -z "$target_destination" ] || [ -z "$target_administrator" ]; then
	echo "ERROR: -n, -d, and -a are all required"
	echo
	help_and_exit
fi

# delete known hosts
sed -i "/$target_hostname/d; /$target_destination/d" ~/.ssh/known_hosts

# Install NixOS to the host system with our secrets
nix run github:nix-community/nixos-anywhere --extra-experimental-features "nix-command flakes" -- --ssh-port "$ssh_port" --post-kexec-ssh-port "$ssh_port" --generate-hardware-config nixos-generate-config ./hardware-configuration.nix --disko-mode disko --build-on local --flake .#"$target_hostname" --target-host "$target_user"@"$target_destination"

echo "Deploy Finished"


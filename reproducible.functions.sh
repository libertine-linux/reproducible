# This file is part of reproducible. It is subject to the licence terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/libertine-linux/reproducible/master/COPYRIGHT. No part of reproducible, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
# Copyright © 2019 The developers of reproducible. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/libertine-linux/reproducible/master/COPYRIGHT.


. "$(pwd)"/environment.functions.sh


reproducible_parseCommandLineArguments()
{
	local additionalArgumentsCallback="$1"
	local positionalArgumentsCallback="$2"
	shift 2

	reproducible_positionalArgumentsStartAt=0

	reproducible_configurationFolderPath="$(pwd)"/sample-configuration
	local reproducible_configurationFolderPathParsed=false

	reproducible_outputFolderPath="$(pwd)"/output
	local reproducible_outputFolderPathParsed=false

	# Parse non-positional arguments.
	local key
	local value
	while [ $# -gt 0 ]
	do
		local key="$1"

		case "$key" in

			--)
				reproducible_positionalArgumentsStartAt=$((reproducible_positionalArgumentsStartAt + 1))
				shift 1
				break
			;;

			-h|--help|-h*)
				local EXIT_SUCCESS=0
				environment_parseCommandLineArguments_printHelp $EXIT_SUCCESS
			;;

			-c|--configuration)
				environment_parseCommandLineArguments_alreadyParsed $reproducible_configurationFolderPathParsed
				environment_parseCommandLineArguments_missingArgument "$@"
				reproducible_configurationFolderPath="$value"
				reproducible_configurationFolderPathParsed=true

				reproducible_positionalArgumentsStartAt=$((reproducible_positionalArgumentsStartAt + 1))
				shift 1
			;;

			--configuration=*)
				environment_parseCommandLineArguments_alreadyParsed $reproducible_configurationFolderPathParsed
				reproducible_configurationFolderPath="${key##--configuration=}"
				reproducible_configurationFolderPathParsed=true
			;;

			-c*)
				environment_parseCommandLineArguments_alreadyParsed $reproducible_configurationFolderPathParsed
				reproducible_configurationFolderPath="${key##-c}"
				reproducible_configurationFolderPathParsed=true
			;;

			-o|--output)
				environment_parseCommandLineArguments_alreadyParsed $reproducible_outputFolderPathParsed
				environment_parseCommandLineArguments_missingArgument "$@"
				reproducible_outputFolderPath="$value"
				reproducible_outputFolderPathParsed=true

				reproducible_positionalArgumentsStartAt=$((reproducible_positionalArgumentsStartAt + 1))
				shift 1
			;;

			--output=*)
				environment_parseCommandLineArguments_alreadyParsed $reproducible_outputFolderPathParsed
				reproducible_outputFolderPath="${key##--output=}"
				reproducible_outputFolderPathParsed=true

			;;

			-o*)
				environment_parseCommandLineArguments_alreadyParsed $reproducible_outputFolderPathParsed
				reproducible_outputFolderPath="${key##-o}"
				reproducible_outputFolderPathParsed=true
			;;

			-*)
				local _additionalArgumentsCallback_shiftUp=0
				$additionalArgumentsCallback "$@"
				if [ $_additionalArgumentsCallback_shiftUp -gt 0 ]; then
					reproducible_positionalArgumentsStartAt=$((reproducible_positionalArgumentsStartAt + _additionalArgumentsCallback_shiftUp))
					shift $_additionalArgumentsCallback_shiftUp
				fi
			;;

			*)
				break
			;;

		esac

		reproducible_positionalArgumentsStartAt=$((reproducible_positionalArgumentsStartAt + 1))
		shift 1

	done

	# Parse positional arguments.
	$positionalArgumentsCallback "$@"
}

depends mkdir
reproducible_validateCommandLineArguments()
{
	if [ -z "$reproducible_configurationFolderPath" ]; then
		environment_parseCommandLineArguments_errorHelp "--configuration folder path is empty"
	fi
	if [ ! -e "$reproducible_configurationFolderPath" ]; then
		environment_parseCommandLineArguments_errorHelp "--configuration folder path '$reproducible_configurationFolderPath' does not exist"
	fi
	if [ ! -r "$reproducible_configurationFolderPath" ]; then
		environment_parseCommandLineArguments_errorHelp "--configuration folder path '$reproducible_configurationFolderPath' is not readable"
	fi
	if [ ! -d "$reproducible_configurationFolderPath" ]; then
		environment_parseCommandLineArguments_errorHelp "--configuration folder path '$reproducible_configurationFolderPath' is not a directory"
	fi
	if [ ! -x "$reproducible_configurationFolderPath" ]; then
		environment_parseCommandLineArguments_errorHelp "--configuration folder path '$reproducible_configurationFolderPath' is not searchable"
	fi
	local absoluteFolderPath
	environment_makeFolderPathAbsolute "$reproducible_configurationFolderPath"
	reproducible_configurationFolderPath="$absoluteFolderPath"

	if [ -z "$reproducible_outputFolderPath" ]; then
		environment_parseCommandLineArguments_errorHelp "--output folder path is empty"
	fi
	mkdir -m 0700 -p "$reproducible_outputFolderPath" || _reproducible_parsedCommandLineArguments_errorHelp "--output folder path '$reproducible_outputFolderPath' could not be created, is not a directory or is not accessible"
	if [ ! -r "$reproducible_outputFolderPath" ]; then
		environment_parseCommandLineArguments_errorHelp "--output folder path '$reproducible_outputFolderPath' is not readable"
	fi
	if [ ! -x "$reproducible_outputFolderPath" ]; then
		environment_parseCommandLineArguments_errorHelp "--output folder path '$reproducible_outputFolderPath' is not searchable"
	fi
	if [ ! -w "$reproducible_outputFolderPath" ]; then
		environment_parseCommandLineArguments_errorHelp "--output folder path '$reproducible_outputFolderPath' is not writable"
	fi
	local absoluteFolderPath
	environment_makeFolderPathAbsolute "$reproducible_outputFolderPath"
	reproducible_outputFolderPath="$absoluteFolderPath"
}

reproducible_setEnvironmentVariables()
{
	reproducible_temporaryFolderPath="$reproducible_outputFolderPath"/temp

	reproducible_versionFilePath="$reproducible_configurationFolderPath"/alpine-linux.version
	if [ ! -e "$reproducible_versionFilePath" ]; then
		fail "The configuration file '$reproducible_versionFilePath' does not exist"
	fi
	if [ ! -f "$reproducible_versionFilePath" ]; then
		fail "The configuration file '$reproducible_versionFilePath' is not a file"
	fi
	if [ ! -r "$reproducible_versionFilePath" ]; then
		fail "The configuration file '$reproducible_versionFilePath' is not a readable file"
	fi
	if [ ! -s "$reproducible_versionFilePath" ]; then
		fail "The configuration file '$reproducible_versionFilePath' is not a readable file with content"
	fi

	reproducible_packagesFilePath="$reproducible_configurationFolderPath"/alpine-linux.packages
	if [ ! -e "$reproducible_packagesFilePath" ]; then
		fail "The configuration file '$reproducible_packagesFilePath' does not exist"
	fi
	if [ ! -f "$reproducible_packagesFilePath" ]; then
		fail "The configuration file '$reproducible_packagesFilePath' is not a file"
	fi
	if [ ! -r "$reproducible_packagesFilePath" ]; then
		fail "The configuration file '$reproducible_packagesFilePath' is not a readable file"
	fi
	if [ ! -s "$reproducible_packagesFilePath" ]; then
		fail "The configuration file '$reproducible_packagesFilePath' is not a readable file with content"
	fi

	reproducible_busyboxStaticBinariesFilePath="$reproducible_configurationFolderPath"/alpine-linux.busybox-static-binaries
	if [ ! -e "$reproducible_busyboxStaticBinariesFilePath" ]; then
		fail "The configuration file '$reproducible_busyboxStaticBinariesFilePath' does not exist"
	fi
	if [ ! -f "$reproducible_busyboxStaticBinariesFilePath" ]; then
		fail "The configuration file '$reproducible_busyboxStaticBinariesFilePath' is not a file"
	fi
	if [ ! -r "$reproducible_busyboxStaticBinariesFilePath" ]; then
		fail "The configuration file '$reproducible_busyboxStaticBinariesFilePath' is not a readable file"
	fi
	if [ ! -s "$reproducible_busyboxStaticBinariesFilePath" ]; then
		fail "The configuration file '$reproducible_busyboxStaticBinariesFilePath' is not a readable file with content"
	fi

	reproducible_mirrorFolderPath="$reproducible_outputFolderPath"/mirror
	reproducible_mirrorVersionFilePath="$reproducible_mirrorFolderPath"/.alpine-linux.version

	reproducible_indexFolderPath="$reproducible_outputFolderPath"/index
	reproducible_indexVersionFilePath="$reproducible_indexFolderPath"/.alpine-linux.version

	reproducible_packagesFolderPath="$reproducible_outputFolderPath"/packages
	reproducible_packagesVersionFilePath="$reproducible_packagesFolderPath"/.alpine-linux.version
	reproducible_packagesPackagesFilePath="$reproducible_packagesFolderPath"/.alpine-linux.packages

	reproducible_extractFolderPath="$reproducible_outputFolderPath"/extract
	reproducible_extractVersionFilePath="$reproducible_extractFolderPath"/.alpine-linux.version
	reproducible_extractPackagesFilePath="$reproducible_extractFolderPath"/.alpine-linux.packages
	reproducible_extractBusyboxStaticBinariesFilePath="$reproducible_extractFolderPath"/.alpine-linux.busybox-static-binaries

	reproducible_mirror=https://alpine.global.ssl.fastly.net/alpine

	IFS=$'\t'' ' read -r reproducible_majorVersion reproducible_minorVersion reproducible_revisionVersion <"$reproducible_versionFilePath"
	reproducible_architecture='x86_64'

	reproducible_versionMirror="${reproducible_mirror}/v${reproducible_majorVersion}.${reproducible_minorVersion}"
	reproducible_releasesMirror="$reproducible_versionMirror"/releases/"$reproducible_architecture"
}

reproducible_netbootFolderName()
{
	netbootFolderName=netboot-"${reproducible_majorVersion}.${reproducible_minorVersion}.${reproducible_revisionVersion}"
}

reproducible_repositoryMirror()
{
	local repositoryVariant="$1"

	repositoryMirror=${reproducible_versionMirror}/${repositoryVariant}
}

depends cmp
reproducible_cachedVersion()
{
	local folderPath="$1"
	local versionFilePath="$folderPath"/.alpine-linux.version

	if [ -s "$versionFilePath" ]; then
		if cmp -s "$versionFilePath" "$reproducible_versionFilePath"; then
			return 0
		fi
	fi

	return 1
}

depends cmp
reproducible_cachedPackages()
{
	local folderPath="$1"
	local packagesFilePath="$folderPath"/.alpine-linux.packages

	if [ -s "$packagesFilePath" ]; then
		if cmp -s "$packagesFilePath" "$reproducible_packagesFilePath"; then
			return 0
		fi
	fi

	return 1
}

depends cmp
reproducible_cachedBusyboxStaticBinaries()
{
	local folderPath="$1"
	local busyboxStaticBinariesFilePath="$folderPath"/.alpine-linux.busybox-static-binaries

	if [ -s "$busyboxStaticBinariesFilePath" ]; then
		if cmp -s "$busyboxStaticBinariesFilePath" "$reproducible_busyboxStaticBinariesFilePath"; then
			return 0
		fi
	fi

	return 1
}

depends cp rm
reproducible_createChroot_copyExtract()
{
	rm -rf "$reproducible_chrootFolderPath"
	cp -a "$reproducible_extractFolderPath"/. "$reproducible_chrootFolderPath"/
	set +f
		rm -rf "$reproducible_chrootFolderPath"/.alpine-linux.*
	set -f
}

depends mkdir
reproducible_createChroot_makeCoreFolders()
{
	local folder
	for folder in dev etc home mnt opt proc root run sys tmp usr/local usr/local/bin usr/local/sbin var/cache var/run var/tmp
	do
		mkdir -m 0700 -p "$reproducible_chrootFolderPath"/"$folder"
	done
}

depends id mkdir
reproducible_createChroot_createBarebonesEtcPasswd()
{
	local currentUid="$(id -u)"
	local currentGid="$(id -g)"

	{
		_reproducible_enter_chroot_createChroot_createBarebonesEtcPasswd_entry()
		{
			local user="$1"
			local uid="$2"
			local gid="$3"
			local homeFolderPath="$4"
			local shellFilePath="$5"
			local gecos="$user"
			printf '%s:x:%s:%s:%s:%s:%s\n' "$user" "$uid" "$gid" "$gecos" "$homeFolderPath" "$shellFilePath"
		}

		_reproducible_enter_chroot_createChroot_createBarebonesEtcPasswd_entry root 0 0 /root /bin/sh

		if [ $currentUid -ne 0 ]; then
			if [ $currentGid -ne 0 ]; then
				local user='currentuser'
				_reproducible_enter_chroot_createChroot_createBarebonesEtcPasswd_entry "$user" "$currentUid" "$currentGid" /home/"$user" /bin/sh
				mkdir -m 0700 -p "$reproducible_chrootFolderPath"/home/"$user"
			fi
		fi

	} >"$reproducible_chrootFolderPath"/etc/passwd
}

depends cp rm mkdir
reproducible_createChroot()
{
	reproducible_createChroot_copyExtract

	reproducible_createChroot_makeCoreFolders

	reproducible_createChroot_createBarebonesEtcPasswd
}

depends cat chmod
reproducible_createSuCommandToRunAsCurrentUser()
{
	shift $reproducible_positionalArgumentsStartAt
	{
		cat <<-EOF
			#!/bin/sh

			set -e
			set -f
			set -u

		EOF

		printf 'exec'

		local argument
		for argument in "$@"
		do
			local escapedArgument="$(printf '%s' "$argument" | sed -e s/\'/\'\"\'\"\'/g)"
			printf " '%s'" "$escapedArgument"
		done
		printf '\n'

	} >"$reproducible_chrootFolderPath"/su-command
	chmod 0700 "$reproducible_chrootFolderPath"/su-command
}


# This file is part of libertine. It is subject to the licence terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/libertine-linux/libertine/master/COPYRIGHT. No part of libertine, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
# Copyright © 2019 The developers of libertine. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/libertine-linux/libertine/master/COPYRIGHT.


environment_parseCommandLineArguments_printHelp()
{
	local exitCode="$1"
	printf '%s' "$environment_parseCommandLineArguments_message"
	exit $exitCode
}

environment_parseCommandLineArguments_errorHelp()
{
	local cause="$1"

	# See https://man.openbsd.org/sysexits.3
	local EX_USAGE=64
	{
		printf '%s:%s\n\n' "$program_name" "${cause}."

		environment_parseCommandLineArguments_printHelp $EX_USAGE
	} 1>&2
}

environment_parseCommandLineArguments_alreadyParsed()
{
	local alreadyParsed="$1"
	if $alreadyParsed; then
		environment_parseCommandLineArguments_errorHelp "Already parsed the value for the argument '$key'"
	fi
}

environment_parseCommandLineArguments_missingArgument()
{
	if [ $# -lt 2 ]; then
		environment_parseCommandLineArguments_errorHelp "Missing value for the argument '$key'"
	fi

	value="$2"
}

depends id sudo
environment_reRunAsRootIfRequired()
{
	local currentUserIdentifier="$(id -u)"
	if [ "$currentUserIdentifier" -ne 0 ]; then
		exec sudo -p "Enter your password to run as root: " ./"${program_name}" "$@"
	fi
}

depends mount awk grep
_environment_mountCount()
{
	local toFolderPath="$1"
	set +e
		mountCount="$(mount | awk '{print $3}' | grep -c '^'"$toFolderPath"'$')"
	set -e
}

depends mount
environment_mountPseudoFileSystem()
{
	local pseudoType="$1"
	local toFolderPath="$2"

	local mountCount
	_environment_mountCount "$toFolderPath"
	if [ $mountCount -gt 0 ]; then
		return 0
	fi

	mount -t "$pseudoType" "$pseudoType" "$toFolderPath" 
}

depends mount
environment_bindMount()
{
	local fromFolderPath="$1"
	local toFolderPath="$2"
	local readOnly="$3"

	local mountCount
	_environment_mountCount "$toFolderPath"
	if [ $mountCount -gt 0 ]; then
		return 0
	fi

	mount --bind "$fromFolderPath" "$toFolderPath"

	if $readOnly; then
		local options=remount,bind,ro
	else
		local options=remount,bind
	fi

	mount -o "$options" "$fromFolderPath" "$toFolderPath"
	mount --make-slave "$toFolderPath"
}

depends mount
environment_recursivelyMount()
{
	local fromFolderPath="$1"
	local toFolderPath="$2"

	local mountCount
	_environment_mountCount "$toFolderPath"
	if [ $mountCount -gt 0 ]; then
		return 0
	fi

	mount --rbind "$fromFolderPath" "$toFolderPath"
	mount --make-rslave "$toFolderPath"
}

depends awk sort tr umount
environment_recursivelyUnmountInChroot()
{
	local chrootFolderPath="$1"

	local awkChrootFolderPath="$(printf '%s' "$chrootFolderPath" | sed 's;/;\\/;g')"

	local IFS=' '
	local mountFolderPath
	for mountFolderPath in $(awk '$2 ~/^'"$awkChrootFolderPath"'/ {print $2}' /proc/mounts | sort -u -r | tr '\n' ' ')
	do
		umount -l "$mountFolderPath"
	done
}

environment_makeFolderPathAbsolute()
{
	cd "$1" 1>/dev/null 2>/dev/null
		absoluteFolderPath="$(pwd)"
	cd - 1>/dev/null 2>/dev/null
}

depends uname awk
environment_sha256sum()
{
	local filePath="$1"
	local operatingSystem="$(uname -s)"
	
	case "$operatingSystem" in
		
		Darwin)
			depends shasum
			sha256="$(shasum --algorithm 256 --binary "$filePath" | awk '{print $1}')"
		;;
		
		Linux)
			depends sha256sum
			sha256="$(sha256sum "$filePath" | awk '{print $1}')"
		;;
		
		*)
			fail "Operating system ${operatingSystem} is unsupported."
		;;
		
	esac
}

depends uname awk
environment_sha512sum()
{
	local filePath="$1"
	local operatingSystem="$(uname -s)"
	
	case "$operatingSystem" in
		
		Darwin)
			depends shasum
			sha512="$(shasum --algorithm 512 --binary "$filePath" | awk '{print $1}')"
		;;
		
		Linux)
			depends sha512sum
			sha512="$(sha512sum "$filePath" | awk '{print $1}')"
		;;
		
		*)
			fail "Operating system ${operatingSystem} is unsupported."
		;;
		
	esac
}

depends curl
environment_download()
{
	local folder="$1"
	local url="$2"
	
	local fileName="${url##*/}"
	downloadedFile="$folder"/"$fileName"
	
	set +e
		curl --proto '=https' --tlsv1.2 --silent --show-error --fail --location "$url" --output "$downloadedFile"
		local exitCode="$?"
	set -e
	
	if [ $exitCode -ne 0 ]; then
		fail "Failed to download from $url because of curl code $exitCode."
	fi
}

depends head awk
environment_downloadWithSha256Hash()
{
	local folder="$1"
	local url="$2"
	local expectedSha256="$3"
	
	environment_download "$folder" "$url"
	
	local sha256
	environment_sha256sum "$downloadedFile"
	
	if [ "$sha256" != "$expectedSha256" ]; then
		fail "URL when downloaded was expected to have SHA-256 hash $expectedSha256 but actually had hash $sha256."
	fi
}

depends head awk
environment_downloadWithSha512Hash()
{
	local folder="$1"
	local url="$2"
	local expectedSha512="$3"
	
	environment_download "$folder" "$url"
	
	local sha512
	environment_sha512sum "$downloadedFile"
	
	if [ "$sha512" != "$expectedSha512" ]; then
		fail "URL when downloaded was expected to have SHA-512 hash $expectedSha512 but actually had hash $sha512."
	fi
}

environment_dependsOnSpecificBinaries()
{
	local binaryAbsolutePath
	for binaryAbsolutePath in "$@"
	do
		if [ ! -f "$binaryAbsolutePath" ]; then
			fail "Binary '${binaryAbsolutePath}' is not a file"
		fi
		if [ ! -r "$binaryAbsolutePath" ]; then
			fail "Binary '${binaryAbsolutePath}' is not readable"
		fi
		if [ ! -x "$binaryAbsolutePath" ]; then
			fail "Binary '${binaryAbsolutePath}' is not executable"
		fi
		if [ ! -s "$binaryAbsolutePath" ]; then
			fail "Binary '${binaryAbsolutePath}' is empty"
		fi
	done
}

environment_tac()
{
	if command -v tac 1>/dev/null 2>/dev/null; then
		tac "$@"
	else
		# Darwin (MacOS), BSDs, etc, but not BusyBox.
		depends tail
		tail -r -- "$@"
	fi
}

depends dirname
environment_relativePathFromSourceToDestination()
{
	local canonicalAbsoluteSourcePath="$1"
	local canonicalAbsoluteDestinationPath="$2"
	
	local commonPrefix="$canonicalAbsoluteSourcePath"
	local result=''

	# commonPrefix does not match; go up a folder level and reduce the extent of the commonPrefix and increase the result.
	while [ "${canonicalAbsoluteDestinationPath#"$commonPrefix"}" = "$canonicalAbsoluteDestinationPath" ]
	do
		commonPrefix="$(dirname "$commonPrefix")"
		if [ -z "$result" ]; then
			result='..'
		else
			result='..'/"$result"
		fi
	done

	# Root is a special case.
	if [ "$commonPrefix" = '/' ]; then
		result="$result"/
	fi

	local descendSuffix="${canonicalAbsoluteDestinationPath#"$commonPrefix"}"
	
	if [ -n "$result" ]; then
		if [ -n "$descendSuffix" ]; then
			relativePath="${result}${descendSuffix}"
		fi
	elif [ -n "$descendSuffix" ]; then
		# Remove slash.
		relativePath="${descendSuffix#?}"
	else
		relativePath="$result"
	fi
}

depends ln
environment_relativeSymlink()
{	
	local sourceFilePath="$1"
	local destinationFilePath="$2"
	
	local relativePath
	environment_relativePathFromSourceToDestination "$sourceFilePath" "$destinationFilePath"
	ln -s "$relativePath" "$sourceFilePath"
}

# This file is part of libertine. It is subject to the licence terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/libertine-linux/libertine/master/COPYRIGHT. No part of libertine, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
# Copyright © 2019 The developers of libertine. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/libertine-linux/libertine/master/COPYRIGHT.


. ./functions/environment-functions.sh


depends head
homebrew_setEnvironmentVariables()
{
	local homebrew_folderPath="$1"
	
	if [ -z ${homebrew_configurationFolderPath+isunset} ]; then
		export homebrew_configurationFolderPath="$homebrew_folderPath"/sample-configuration
	else
		export homebrew_configurationFolderPath="$homebrew_configurationFolderPath"
	fi
	if [ -z ${homebrew_outputFolderPath+isunset} ]; then
		export homebrew_outputFolderPath="$homebrew_folderPath"/output/homebrew
	else
		export homebrew_outputFolderPath="$homebrew_outputFolderPath"
	fi
	
	homebrew_temporaryFolderPath="$homebrew_outputFolderPath"/temp
	homebrew_binFolderPath="$homebrew_outputFolderPath"/bin
	
	homebrew_homebrewVersion="$(head -n 1 "$homebrew_configurationFolderPath"/homebrew.version)"
	homebrew_mirrorFolderPath="$homebrew_outputFolderPath"/mirror
	homebrew_cacheFolderPath="$homebrew_mirrorFolderPath"/cache
	homebrew_installedFolderPath="$homebrew_outputFolderPath"/installed
	homebrew_logsFolderPath="$homebrew_installedFolderPath"/logs
	homebrew_homebrewPackagesFilePath="$homebrew_configurationFolderPath"/homebrew-binaries-to-packages
	
	unset HOMEBREW_ARCH
	unset HOMEBREW_AWS_ACCESS_KEY_ID
	unset HOMEBREW_AWS_SECRET_ACCESS_KEY
	unset HOMEBREW_BAT
	unset HOMEBREW_BROWSER
	unset HOMEBREW_CURL_VERBOSE
	unset HOMEBREW_DEBUG
	unset HOMEBREW_DEVELOPER
	unset HOMEBREW_DISPLAY
	unset HOMEBREW_DISPLAY_INSTALL_TIMES
	unset HOMEBREW_EDITOR
	unset HOMEBREW_FORCE_BREWED_CURL
	unset HOMEBREW_FORCE_VENDOR_RUBY
	unset HOMEBREW_FORCE_BREWED_GIT
	unset HOMEBREW_GITHUB_API_TOKEN
	unset HOMEBREW_INSTALL_BADGE
	unset HOMEBREW_MAKE_JOBS
	unset HOMEBREW_NO_BOTTLE_SOURCE_FALLBACK
	unset HOMEBREW_NO_GITHUB_API
	unset HOMEBREW_NO_INSTALL_CLEANUP
	unset HOMEBREW_PRY
	unset HOMEBREW_SVN
	unset HOMEBREW_UPDATE_TO_TAG
	unset HOMEBREW_VERBOSE
	
	export HOMEBREW_LOGS="$homebrew_logsFolderPath"
	export HOMEBREW_CACHE="$(pwd)"/mirror/cache
	export HOMEBREW_BOTTLE_DOMAIN=https://homebrew.bintray.com/
	#export HOMEBREW_ARTIFACT_DOMAIN=http://localhost:8080
	#export HOMEBREW_NO_INSECURE_REDIRECT=1
	export HOMEBREW_AUTO_UPDATE_SECS=300
	export HOMEBREW_NO_COLOR=1
	export HOMEBREW_NO_ANALYTICS=1
	export HOMEBREW_NO_AUTO_UPDATE=1
	export HOMEBREW_NO_EMOJI=1
	export HOMEBREW_CURLRC=1
	export HOMEBREW_CURL_RETRIES=3
	
	export PATH="$homebrew_binFolderPath":"$PATH"
}

depends head rm mkdir mv
homebrew_mirrorHomebrew()
{
	local mirroredVersionFilePath="$homebrew_mirrorFolderPath"/.homebrew.version
	
	if [ -f "$mirroredVersionFilePath" ]; then
		if [ -r "$mirroredVersionFilePath" ]; then
			local mirroredVersion="$(head -n 1 "$mirroredVersionFilePath")"
			if [ "$mirroredVersion" = "$homebrew_homebrewVersion" ]; then
				return 0
			fi
		fi
	fi
	
	rm -rf "$homebrew_temporaryFolderPath"
	mkdir -m 0700 -p "$homebrew_temporaryFolderPath"
	environment_download "$tempFolderPath" "https://github.com/Homebrew/brew/archive/${homebrew_homebrewVersion}.tar.gz"

	mkdir -m 0700 -p "$homebrew_outputFolderPath"

	rm -rf "$homebrew_mirrorFolderPath"
	mv "$homebrew_temporaryFolderPath" "$homebrew_mirrorFolderPath"

	rm -rf "$homebrew_cacheFolderPath"
	mkdir -m 0700 -p "$homebrew_cacheFolderPath"

	rm -rf "$homebrew_logsFolderPath"
	mkdir -m 0700 -p "$homebrew_logsFolderPath"
	
	printf "$homebrew_homebrewVersion" >"$mirroredVersionFilePath"
}

homebrew_installedBrew()
{
	"$homebrew_installedFolderPath"/bin/brew "$@"
}

depends rm mkdir tar xcode-select
environment_dependsOnSpecificBinaries /usr/bin/ruby /bin/bash /usr/bin/env
homebrew_installHomebrew()
{
	local installedVersionFilePath="$homebrew_installedFolderPath"/.homebrew.version
	
	if [ -f "$installedVersionFilePath" ]; then
		if [ -r "$installedVersionFilePath" ]; then
			local installedVersion="$(head -n 1 "$installedVersionFilePath")"
			if [ "$installedVersion" = "$homebrew_homebrewVersion" ]; then
				return 0
			fi
		fi
	fi
	
	rm -rf "$homebrew_installedFolderPath"
	
	homebrew_mirrorHomebrew
	
	mkdir -m 0700 -p "$homebrew_installedFolderPath"
	
	tar xz -f "${homebrew_mirrorFolderPath}/${homebrew_homebrewVersion}.tar.gz" --strip 1 -C "$homebrew_installedFolderPath"
	
	set +e
		xcode-select --install 2>/dev/null
	set -e
	
	homebrew_installedBrew search 1>/dev/null 2>/dev/null
	
	printf "$homebrew_homebrewVersion" >"$installedVersionFilePath"
}

homebrew_readPackageInformationFile()
{
	local wrappedBinaryName="$1"
	
	homebrewBinaryName="$(awk '$1 == "'"$wrappedBinaryName"'" {print $2}' "$homebrew_homebrewPackagesFilePath")"
	if [ -z "$homebrewBinaryName" ]; then
		fail "Could not find binary '$wrappedBinaryName' (column 1, one-based) in homebrew package information file '$packageInformationFilePath'"
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
		commonPrefix=$(dirname "$commonPrefix")
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

	local descendSuffix="${canonicalAbsoluteDestinationPatht#"$commonPrefix"}"
	
	if [ -n "$result "]; then
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
	ln -s "$relativePath" "$sourceFolderPath"
}

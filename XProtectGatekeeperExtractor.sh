#!/bin/bash
#
#		XProtectGatekeeperExtractor | Version 1.3.1 | Last Updated 28/01/2016
#

# Must be run by root
if [ "$(id -u)" != 0 ]; then

	echo "This script must be run by root."
	exit 0

fi

# Tools
basename=/usr/bin/basename
cat=/bin/cat
chown=/usr/sbin/chown
chmod=/bin/chmod
cp=/bin/cp
date=/bin/date
defaults=/usr/bin/defaults
dirname=/usr/bin/dirname
find=/usr/bin/find
grep=/usr/bin/grep
head=/usr/bin/head
launchctl=/bin/launchctl
mkdir=/bin/mkdir
mv=/bin/mv
pkgutil=/usr/sbin/pkgutil
rm=/bin/rm
sed=/usr/bin/sed
sort=/usr/bin/sort
tail=/usr/bin/tail
tee=/usr/bin/tee

# Paths and information
fileName=$($basename "$0")
currentDir=$($dirname "$0")
scriptName=xprotect-gatekeeper-extractor
prettyScriptName="XProtect and Gatekeeper ConfigData Extractor"
scriptID=com.ehcho.$scriptName
version=1.2
softwareUpdateRepo=/Library/Server/Software\ Update/Data/html
extractedPackages=/tmp/$scriptID-pkgs
log=/tmp/$scriptID-log.log
installLocation=/usr/local/bin
plistName=$scriptID.plist
launchDaemonPath=/Library/LaunchDaemons/$plistName
preferencesPath=/Library/Preferences/$plistName
munkiimport=/usr/local/munki/munkiimport
localAdminUser="ladmin"

# Default settings
checkInterval=900
copyToPoint=/tmp
logLineLimit=180

function funcFindLatestVersion {

	# Only been tested with XProtect and Gatekeeper packages
	if [ "$1" == "XProtect" ] || [ "$1" == "Gatekeeper" ]; then


		# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
		#																																		#
		#		dataDump:								Where the found data will be stored  		#
		#		packageVersionNumbers:	Collection of the package's versions 		#
		#		packageLocation:				Collection of the package's locations		#
		#		i: 											Counter 																#
		#		preSortedData:					Array for storing unsorted data 				#
		#		mostUpToDatePackage:		Preference key 													#
		#		latestPackage: 					The latest package 											#
		#		latestPackageVersion:		Version number of the latest package		#
		#		currentPackageVersion:	Fetched value from the preference file 	#
		#																																		#
		# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

		dataDump="/tmp/$scriptID-$1-data-dump.txt"
		packageVersionNumbers=()
		packageLocation=()
		i="0"
		preSortedData=()
		mostUpToDatePackage=$1Latest
		latestPackage=()
		latestPackageVersion=()
		currentPackageVersion=""


		# 	Search for the appropriate packages
			funcLog "Searching for all file names containing: \"$1\""

			$find "$softwareUpdateRepo" -iname "*$1*" 2>/dev/null | $grep pkg >> "$dataDump"
		

		# 	Ensure there's a place to extract packages to		
			if [ ! -d "$extractedPackages" ]; then

				funcLog "Could not find $extractedPackages, creating it"
				$mkdir "$extractedPackages"

			fi

		
		#		Find the version of each package and put the
		#		result into an array. Also put the path to the
		#		package in a different array for use later
			if [ -f "$dataDump" ]; then

				funcLog "$dataDump found. Extracting packages and fetching version numbers"

				while read -r p; do

					# Expand the package into the extractedPacakges path
					$pkgutil --expand "$p" "$extractedPackages/$i-$1-package/"

					# Echo the current package's location
					packageLocation[$i]=$(echo "$p")

					# Get the current package's version
					packageVersionNumbers[$i]=$($grep "pkg-info" "$extractedPackages/$i-$1-package/PackageInfo" | $grep "version=\"" | $sed "s/.* version=\"\(.*\)\".*/\1/")

					# Increment counter by 1
					i=$((i+1))

				done < "$dataDump"

				funcLog "Finished getting information from the packages"

			fi


		# 	Combine package path and version number
			funcLog "Combining the arrays"

			for ((i = 0; i < ${#packageVersionNumbers[@]}; i++)); do

				preSortedData[$i]=$(echo "${packageVersionNumbers[$i]}|${packageLocation[$i]}")

			done
			

		# 	Get the latest packages path
			IFS=$'\n'
			latestPackage=$(echo "${preSortedData[*]}" | $sort -nr | $head -n1 | $sed 's/.*|//')
			latestPackageVersion=$(echo "${preSortedData[*]}" | $sort -nr | $head -n1 | $sed 's/|.*//')
			IFS=$' '

			funcLog "The latest package is: $latestPackage ($latestPackageVersion)"


		# 	Store latest version number to preference file
			if [ -f "$preferencesPath" ]; then

				currentPackageVersion=$($defaults read "$preferencesPath" "$mostUpToDatePackage")

			else

				funcLog "Could not find $preferencesPath"
				
			fi


		# 	Copy latest package to the copy point and write
		#		package's version number to the preference file
		#		and import into Munki if configured
			if [ "$currentPackageVersion" != "$latestPackageVersion" ]; then

				funcLog "A more up to date package has been found, copying"

				$cp -v "$latestPackage" "$copyToPoint/${1}-${latestPackageVersion}.pkg"

				$defaults write "$preferencesPath" "$mostUpToDatePackage" "$latestPackageVersion"


				# 	Import new packages into Munki
					if [ $($defaults read "$preferencesPath" ImportIntoMunki) == "1" ]; then

						copyToPointJoined="$copyToPoint/${1}-${latestPackageVersion}.pkg"

						funcImportPackageIntoMunki "$copyToPointJoined"

					fi

			fi


		# 	Remove dataDump files and the directory
		#		containing all extracted packages
			if [ -f "$dataDump" ]; then

				$rm "$dataDump"

			fi

			if [ -d "$extractedPackages" ]; then

				$rm -rf "$extractedPackages"

			fi

	fi

} # funcFindLatestVersion

function funcFirstRun {

	# Install the script into $installLocation
		if [ -d "$installLocation" ]; then

			funcLog "Moving script to: $installLocation"

			$cp "$currentDir/$fileName" "$installLocation"

			$chmod 755 "$installLocation/$fileName"

			$rm "$currentDir/$fileName"

		else

			funcLog "Could not find $installLocation"

		fi


	# Create preferences file
		funcLog "Writing default preferences to $preferencesPath"

		$defaults write "$preferencesPath" Version "$version"
		$defaults write "$preferencesPath" CheckInterval "$checkInterval"
		$defaults write "$preferencesPath" XProtectLatest -string ""
		$defaults write "$preferencesPath" GatekeeperLatest -string ""
		$defaults write "$preferencesPath" ExtractPath -string "$copyToPoint"
		$defaults write "$preferencesPath" LoggedLines -int "$logLineLimit"
		$defaults write "$preferencesPath" ImportIntoMunki -bool true
		$defaults write "$preferencesPath" MunkiRepoPath -string "auto"
		$defaults write "$preferencesPath" LocalAdminName -string "$localAdminUser"


	# Create LaunchDaemon that runs this script periodically
		if [ ! -f "$launchDaemonPath" ]; then

			funcLog "Writing LaunchDaemon to $launchDaemonPath"

			$defaults write "$launchDaemonPath" Label "$scriptID"
			$defaults write "$launchDaemonPath" ProgramArguments -array
			$defaults write "$launchDaemonPath" ProgramArguments -array-add "$installLocation/$fileName"
			$defaults write "$launchDaemonPath" StartInterval -int "$checkInterval"

			funcLog "Configuring $launchDaemonPath"
			# Doesn't seem to be working?
			$chmod 644 "$launchDaemonPath"

			$launchctl load -w "$launchDaemonPath"

		fi

} # firstRun

function funcReadPreferences {

	# Does the preferences file exist?
		if [ -f "$preferencesPath" ]; then

			# Setting to modify the CheckInterval
				funcLog "Ensuring CheckInterval is set correctly"
				readCheckInterval=$($defaults read "$preferencesPath" CheckInterval)

				if [[ ! "$readCheckInterval" == *"does not exist"* ]]; then

						if [ -f "$launchDaemonPath" ]; then

							# Modify the interval
								$defaults write "$launchDaemonPath" StartInterval -int "$readCheckInterval"

								$chmod 644 "$launchDaemonPath"

						fi

				fi


			# Setting to modify where the packages are saved to
				funcLog "Ensuring ExtractPath is set correctly"
				readExtractPath=$($defaults read "$preferencesPath" ExtractPath)

				if [[ ! "$readExtractPath" == *"does not exist"* ]]; then

						copyToPoint=$readExtractPath

				fi


			# Setting to modify how many lines of the log should be kept
				funcLog "Ensuring LoggedLines is set correctly"
				readLoggedLines=$($defaults read "$preferencesPath" LoggedLines)

				if [[ ! "$readLoggedLines" == *"does not exist"* ]]; then

						logLineLimit=$readLoggedLines

				fi

		fi

} # funcReadPreferences

function funcImportPackageIntoMunki {

	funcLog "Importing packages into Munki"

	# If munkiimport exists, import the package
		if [ -f "$munkiimport" ]; then

			# Find out if the repo path has been configured
				munkiRepoPathSet=$($defaults read "$preferencesPath" MunkiRepoPath)

			# Get local admin name
				getLocalAccountName=$($defaults read "$preferencesPath" LocalAdminName)

				# If it hasn't been configured, attempt to find repo-path for the user
				if [ ! "$munkiRepoPathSet" == "auto" ]; then

					funcLog "Muki Repo path appears to be set: $munkiRepoPathSet"

					$munkiimport -n --subdirectory "$scriptName" --repo_path "$munkiRepoPathSet" "$1"	
					
					$chmod 755 "$munkiRepoPathSet/pkgs/$scriptName"
					$chown "$getLocalAccountName" "$munkiRepoPathSet/pkgsinfo/$scriptName"

					$chmod 755 "$munkiRepoPathSet/pkgsinfo/$scriptName"
					$chown "$getLocalAccountName" "$munkiRepoPathSet/pkgsinfo/$scriptName"

					$chmod -R 644 "$munkiRepoPathSet/pkgs/$scriptName/"*
					$chown "$getLocalAccountName" "$munkiRepoPathSet/pkgs/$scriptName/"*

					$chmod -R 644 "$munkiRepoPathSet/pkgsinfo/$scriptName/"*
					$chown "$getLocalAccountName" "$munkiRepoPathSet/pkgsinfo/$scriptName/"*

				else

					funcLog "Munki Repo path doesn't seem to be set ($munkiRepoPathSet). Attempting to find repo-path."

					# Search all home directories for the the repo path
					for Users in "/Users"/*; do	

						if [ -f "${Users}"/Library/Preferences/com.googlecode.munki.munkiimport.plist ]; then

							autoRepoPath=$($defaults read "${Users}"/Library/Preferences/com.googlecode.munki.munkiimport.plist repo_path)

						fi

					done

					$munkiimport -n --subdirectory "$scriptName" --repo_path "$autoRepoPath" "$1"

					$chmod 755 "$autoRepoPath/pkgs/$scriptName"
					$chown "$getLocalAccountName" "$autoRepoPath/pkgs/$scriptName"

					$chmod 755 "$autoRepoPath/pkgsinfo/$scriptName"
					$chown "$getLocalAccountName" "$autoRepoPath/pkgsinfo/$scriptName"

					$chmod -R 644 "$autoRepoPath/pkgs/$scriptName/"*
					$chown "$getLocalAccountName" "$autoRepoPath/pkgs/$scriptName/"*

					$chmod -R 644 "$autoRepoPath/pkgsinfo/$scriptName/"*
					$chown "$getLocalAccountName" "$autoRepoPath/pkgsinfo/$scriptName/"*

				fi

		fi

} # funcImportPackageIntoMunki

function funcTidyLogs {

	# Limit the amount of lines in the log file
		funcLog "Tidy up the logs. Keeping $logLineLimit lines of logs"

		$cat "$log" | $tail -n "$logLineLimit" > $log-2
		$rm "$log"
		$mv "$log-2" "$log"

} # funcTidyLogs

function funcLog {

	# Send log to stout and first boot package installer log
		theDate=$($date +%Y-%m-%d\ %H:%M:%S)

		echo "$theDate  $1" | $tee -a "$log"

} # funcLog

# Starting script...
	funcLog "$prettyScriptName | Version: $version"

# Is there a preference file already created? If no, run First Setup
	if [ ! -f "$preferencesPath" ]; then

		funcLog "Detected first run. Running setup"
		funcFirstRun
		funcLog "Setup completed"

	fi

# Ensure no preferences have been changed
	funcReadPreferences

# Find the latest version of XProtect
	funcFindLatestVersion XProtect
# Find the latest version of Gatekeeper
	funcFindLatestVersion Gatekeeper

# Ensure the log file doesn't become too large
	funcTidyLogs

# Finished Script...
funcLog "Done. Exiting"
funcLog " "

exit 0
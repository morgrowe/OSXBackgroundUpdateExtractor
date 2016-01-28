# XProtectGatekeeperExtractor

XProtectGatekeeperExtractor automatically copies and optionally imports XProtect and Gatekeeper Config Data packages into your Munki repo.

OS X background security packages (XProtect and Gatekeeper) are not automatically distributed and installed on machines that use an internal Apple software update server. Some solutions have [already been found](https://managingosx.wordpress.com/2015/01/30/gatekeeper-configuration-data-and-xprotectplistconfigdata-and-munki-and-reposado-oh-my/) but this script takes a slightly different approach by extracting the latest XProtect and Gatekeeper Config Data packages into a customisable location, and optionally imports them into Munki for you.

## Download and Installation

The latest stable version can be found within the [released section](https://github.com/morgrowe/XProtectGatekeeperExtractor/releases).

Download the script and run it as root:

```
sudo /path/to/script
```

The script automatically installs itself into /usr/local/bin/, generates its own preference file into /Library/Preferences/; and creates and enables its own launchd job into /Library/LaunchDaemons/, to automatically run the script every 15 minutes.

Once you have run the script, there is no need to [manually run](#running-manually) again.

## Preferences

This tool comes with its own preferences: CheckInterval, ExtractPath, ImportIntoMunki, MunkiRepoPath and LoggedLines.

### CheckInterval

This preference allows you to change the frequency in which the LaunchDaemon runs. The default is every 15 minutes (900 seconds).

```
defaults write /Library/Preferences/com.ehcho.xprotect-gatekeeper-extractor.plist CheckInterval -int 900
```

### ExtractPath

This preference allows you to change where the most up to date packages are copied to. Default is /tmp.


Note: Do not end your path with a forward slash as the tool assumes it needs to be entered for you. For example: "/path/to/folder" is good as opposed to "/path/to/folder/" which is bad.

```
defaults write /Library/Preferences/com.ehcho.xprotect-gatekeeper-extractor.plist ExtractPath "/path/to/folder"
```

### ImportIntoMunki

This preference allows you to toggle the automatic importing of the XProtect and Gatekeeper Config Data packages into Munki. The default is true.

```
defaults write /Library/Preferences/com.ehcho.xprotect-gatekeeper-extractor.plist ImportIntoMunki -bool true
```

### MunkiRepoPath

This preference allows you to specify your Munki setup's repo-path. The script will attempt to find this for you by default.

If you find the Config Data packages are not being imported into your Munki repo, ImportIntoMunki is set to true and the packages are being copied to the ExtractPath location, which by default is /tmp, you may find you need to set this option manually.

```
defaults write /Library/Preferences/com.ehcho.xprotect-gatekeeper-extractor.plist MunkiRepoPath -string "auto"
```

### LoggedLines

In an attempt to not fill up the log file in the likely hood the server doesn't get restarted in a few weeks, the log's lines are cut to 180 lines by default. This can be changed to any value greater than 1.

```
defaults write /Library/Preferences/com.ehcho.xprotect-gatekeeper-extractor.plist ImportIntoMunki -int 180
```

### LocalAdminName

As this script runs as root, when packages are imported into Munki, they'll be owned by root. You can specify an alternate owner for these new files using this key. Default is 'ladmin'.

```
defaults write /Library/Preferences/com.ehcho.xprotect-gatekeeper-extractor.plist LocalAdminName -string "ladmin"
```

## Running manually

It is safe to run the script manually as long as it is run as root. The default locaton for the script is:

```
/usr/local/bin/XProtectGatekeeperExtractor.sh
```
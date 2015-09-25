# OS X Background Update Extractor (OSXBUE)

OS X Background Update Extractor automatically copies and optionally imports XProtect and Gatekeeper ConfigData packages into your Munki repo.

OS X background security packages (XProtect and Gatekeeper) are not automatically distributed and installed on machines that use an internal Apple software update server. Some solutions have [already been found](https://managingosx.wordpress.com/2015/01/30/gatekeeper-configuration-data-and-xprotectplistconfigdata-and-munki-and-reposado-oh-my/) but OSXBUE takes a slightly different approach by extracting the latest XProtect and Gatekeeper ConfigData packages into a customisable location, and optionally imports them into Munki for you.

## Installation

Download the script and run it as root:

```
sudo /path/to/script
```

The script automatically installs itself into /usr/local/bin/, generates its own preference file into /Library/Preferences/; and creates and enables its own LaunchDaemon into /Library/LaunchAgents/, to automatically run the script every 15 minutes.

Once you have run the script, there is no need to [manually run](#running-manually) again.

## Preferences

This tool comes with its own preferences: CheckInterval, ExtractPath, ImportIntoMunki and LoggedLines.

### CheckInterval

This preference allows you to change the frequency in which the LaunchDaemon runs. The default is every 15 minutes (900 seconds).

```
defaults write /Library/Preferences/com.github.morgrowe.osx-background-update-extractor.plist CheckInterval -int 900
```

### ExtractPath

This preference allows you to change where the most up to date packages are copied to. Default is /tmp.

```
defaults write /Library/Preferences/com.github.morgrowe.osx-background-update-extractor.plist ExtractPath "/path/to/folder"
```

Note: Do not end your path with a forward slash as the script assumes it needs to be entered for you. For example: "/path/to/folder" is good as opposed to "/path/to/folder/" which is bad.

### ImportIntoMunki

This preference allows you to toggle the automatic importing of the XProtect and Gatekeeper ConfigData packages into Munki. The default is false.

```
defaults write /Library/Preferences/com.github.morgrowe.osx-background-update-extractor.plist ImportIntoMunki -bool false
```

### LoggedLines

In an attempt to not fill up the log file in the likely hood the server doesn't get restarted in a few weeks, the log's lines are cut to 180 lines by default. This can be changed to any value greater than 1.

```
defaults write /Library/Preferences/com.github.morgrowe.osx-background-update-extractor.plist ImportIntoMunki -int 180
```

## Running manually

It is safe to run the script manually as long as it is run as root. The default locaton for the script is:

```
/usr/local/bin/OSXBackgroundUpdateExtractor.sh
```
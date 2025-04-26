# Disable Spotlight indexing
sudo mdutil -i off -a

# Create new account
sudo dscl . -create /Users/kaiden
sudo dscl . -create /Users/kaiden UserShell /bin/bash
sudo dscl . -create /Users/kaiden RealName "Kaiden"
sudo dscl . -create /Users/kaiden UniqueID 1001
sudo dscl . -create /Users/kaiden PrimaryGroupID 80
sudo dscl . -create /Users/kaiden NFSHomeDirectory /Users/kaiden
sudo dscl . -passwd /Users/kaiden $1
sudo createhomedir -c -u kaiden > /dev/null

# Enable Screen Sharing
sudo systemsetup -setremotelogin on
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist
sudo launchctl start com.apple.screensharing

# Enable Remote Management
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -allowAccessFor -allUsers -privs -all
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -clientopts -setvnclegacy -vnclegacy yes 
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -restart -agent -console
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate

# VNC password
echo $2 | perl -we 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; $_ = <>; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' | sudo tee /Library/Preferences/com.apple.VNCSettings.txt

# Enable Performance mode
sudo nvram boot-args="serverperfmode=1 $(nvram boot-args 2>/dev/null | cut -f 2-)"

# Reduce Motion and Transparency
defaults write com.apple.Accessibility DifferentiateWithoutColor -int 1
defaults write com.apple.Accessibility ReduceMotionEnabled -int 1
defaults write com.apple.universalaccess reduceMotion -int 1
defaults write com.apple.universalaccess reduceTransparency -int 1
defaults write com.apple.Accessibility ReduceMotionEnabled -int 1

# Enable Multi-Session
sudo /usr/bin/defaults write .GlobalPreferences MultipleSessionsEnabled -bool TRUE

# Install applications
brew install --cask brave-browser
brew install --cask chrome-remote-desktop-host
brew install --cask microsoft-remote-desktop

# Ensure the VNC service is running correctly
if sudo launchctl list | grep -q com.apple.RemoteManagement; then
  echo "com.apple.RemoteManagement is already loaded."
else
  sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.RemoteManagement.plist
  if [ $? -ne 0 ]; then
    echo "Failed to load com.apple.RemoteManagement. Check the logs for more details."
    exit 1
  fi
fi

# Start Pinggy tunnel
echo "Starting Pinggy tunnel..."
ssh -p 443 -R0:localhost:5900 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 gtcxZbEfnfR+tcp@us.free.pinggy.io

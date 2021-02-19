local filesystem = require('gears.filesystem')
local config_dir = filesystem.get_configuration_dir()
local utils_dir = config_dir .. 'utilities/'

return {
	-- The default applications that we will use in keybindings and widgets
	default = {
		-- Default terminal emulator
		terminal = 'alacritty',
		-- Default web browser
		web_browser = 'google-chrome-stable --force-dark-mode --enable-features=WebUIDarkMode',
		-- Default text editor
		text_editor = 'code',
		-- Default file manager
		file_manager = 'dolphin',
		-- Default media player
		multimedia = 'spotify',
		-- Default game, can be a launcher like steam
		game = 'supertuxkart',
		-- Default graphics editor
		graphics = 'gimp-2.10',
		-- Default social app
		social = 'discord',
		-- Default sandbox
		sandbox = 'virtualbox',
		-- Default IDE
		development = 'code',
		-- Default network manager
		network_manager = 'alacritty -e nmtui',
		-- Default bluetooth manager
		bluetooth_manager = 'blueman-manager',
		-- Default power manager
		power_manager = 'xfce4-power-manager',
		-- Default Pacman-based package manager
		package_manager = 'yay',
		-- Default locker
		lock = 'awesome-client "awesome.emit_signal(\'module::lockscreen_show\')"',
		-- Default clipboard manager
		clipboard_manager = 'copyq toggle',
		-- Default quake terminal
		quake = 'kitty --name QuakeTerminal',
		-- Default rofi global menu
		rofi_global = 'rofi -dpi ' .. screen.primary.dpi .. 
							' -show "Global Search" -modi "Global Search":' .. config_dir .. 
							'/configuration/rofi/global/rofi-spotlight.sh' .. 
							' -theme ' .. config_dir ..
							'/configuration/rofi/global/rofi.rasi',
		-- Default app menu
		rofi_appmenu = 'rofi -dpi ' .. screen.primary.dpi ..
							' -show drun -theme ' .. config_dir ..
							'/configuration/rofi/appmenu/rofi.rasi'

		-- You can add more default applications here
	},

	-- List of apps to start once on start-up
	run_on_start_up = {
		-- Compositor
		'picom -b --experimental-backends --dbus --config ' ..
		config_dir .. '/configuration/picom.conf',
		-- Blueman applet
		'blueman-applet',
		-- Music server
		'mpd',
		-- Polkit and keyring
		'/usr/bin/lxqt-policykit-agent &' ..
		' eval $(gnome-keyring-daemon -s --components=pkcs11,secrets,ssh,gpg)',
		-- Load X colors
		'xrdb $HOME/.Xresources',
		-- Audio equalizer
		'pulseeffects --gapplication-service',
		-- Lockscreen timer
		[[
		xidlehook --not-when-fullscreen --not-when-audio --timer 600 \
		"awesome-client 'awesome.emit_signal(\"module::lockscreen_show\")'" ""
		]],
		-- Screenshot app
		'flameshot',
		-- Clipboard manager
		'copyq'

		-- You can add more start-up applications here
	},

	-- List of binaries/shell scripts that will execute for a certain task
	utils = {
		-- Fullscreen screenshot
		full_screenshot = 'flameshot gui',
		-- Area screenshot
		area_screenshot = utils_dir .. 'snap area',
		-- Update profile picture
		update_profile  = utils_dir .. 'profile-image',
		-- Spotify CLI client
		spotify_cli = utils_dir .. 'sp'
	}
}

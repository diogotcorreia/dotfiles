local awful = require('awful')
local recorder_table = require('widget.screen-recorder.screen-recorder-ui')
require('widget.screen-recorder.screen-recorder-ui-backend')
local screen_rec_toggle_button = recorder_table.screen_rec_toggle_button

local return_button = function()
	return awful.widget.only_on_screen(screen_rec_toggle_button, 'primary')
end

return return_button

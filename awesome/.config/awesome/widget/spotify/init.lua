local gears = require('gears')
local awful = require('awful')
local wibox = require('wibox')
local apps = require('configuration.apps')
local dpi = require('beautiful').xresources.apply_dpi
local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. 'widget/spotify/icons/'
local clickable_container = require('widget.clickable-container')

local return_button = function()
	-- Avoid redownloading the same cover every 10 seconds
	local last_album_cover_url = ''

	local widget = wibox.widget {
		{
			id = 'cover',
			image = widget_icon_dir .. 'vinyl.svg',
			resize = true,
			widget = wibox.widget.imagebox,
		},
		{
			{
				id = 'title',
				markup = 'Not currently playing',
				align  = 'center',
				valign = 'center',
				ellipsize = 'middle',
				widget = wibox.widget.textbox
			},
			left = dpi(3),
			widget = wibox.container.margin,
		},
		layout = wibox.layout.align.horizontal
	}

	local widget_button = wibox.widget {
		{
			widget,
			margins = dpi(7),
			widget = wibox.container.margin
		},
		visible = false,
		widget = clickable_container
	}

	widget_button:buttons(
		gears.table.join(
			awful.button(
				{},
				1,
				nil,
				function()
					awful.spawn.easy_async_with_shell(
						apps.utils.spotify_cli .. " play", 
						function() end
					)
				end
			)
		)
	)

	local update_metadata = function()
		awful.spawn.easy_async_with_shell(
			apps.utils.spotify_cli .. " metadata | sort -r | grep -E 'title|artist' | sed -E -e 's/\\w+\\|//g' | awk 'NR%2{printf \"%s - \",$0;next;}1'",
			function(stdout)

				local title = stdout:gsub('%\n', '')
				if (utf8.len(title) > 50) then
					title = string.sub(title, 1, utf8.offset(title, 48) - 1) .. '...'
				end

				widget_button.visible = utf8.len(title) ~= 0

				local title_text = widget:get_children_by_id('title')[1]

				title_text:set_text(title)

				widget:emit_signal("widget::redraw_needed")
				widget:emit_signal("widget::layout_changed")

				collectgarbage('collect')
			end
		)

		awful.spawn.easy_async_with_shell(
			apps.utils.spotify_cli .. " art",
			function(link)
				-- Avoid redownloading the same cover every update
				if link == last_album_cover_url then
					return
				end

				last_album_cover_url = link
				
				local download_art = [[
				tmp_dir="/tmp/awesomewm/${USER}/"
				tmp_cover_path=${tmp_dir}"cover.jpg"

				if [ ! -d $tmp_dir ]; then
					mkdir -p $tmp_dir;
				fi

				if [ -f $tmp_cover_path]; then
					rm $tmp_cover_path
				fi

				wget -O $tmp_cover_path ]] ..link .. [[

				echo $tmp_cover_path
				]]

				awful.spawn.easy_async_with_shell(
					download_art,
					function(stdout)

						local album_icon = stdout:gsub('%\n', '')

						widget.cover:set_image(gears.surface.load_uncached(album_icon))

						widget:emit_signal("widget::redraw_needed")
						widget:emit_signal("widget::layout_changed")
						
						collectgarbage('collect')
					end
				)
			end
		)
	end

	local update_all_content = function()
		-- Add a delay
		gears.timer.start_new(10, function() 
			update_metadata()
			return true
		end)
	end


	update_all_content()

	return awful.widget.only_on_screen(widget_button, 'primary')

end

return return_button


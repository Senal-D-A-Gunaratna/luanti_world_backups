-- luanti_backups: gui.lua

function luanti_backups.show_config_gui(player_name)
	local interval = luanti_backups.config.interval / 60 -- show in minutes
	local retention = luanti_backups.config.retention
	
	local formspec = 
		"size[8,5]" ..
		"label[0.5,0.5;Backup Configuration]" ..
		"field[0.5,1.5;3,1;interval;Interval (minutes);" .. interval .. "]" ..
		"field[0.5,2.5;3,1;retention;Retention Limit;" .. retention .. "]" ..
		"button[0.5,3.5;2,1;save;Save Settings]" ..
		"button_exit[3,3.5;2,1;close;Close]" ..
		"button[0.5,4.2;3,0.8;now;Run Backup Now]"

	minetest.show_formspec(player_name, "luanti_backups:config", formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "luanti_backups:config" then
		return false
	end

	local name = player:get_player_name()
	
	if fields.save then
		local interval = tonumber(fields.interval)
		local retention = tonumber(fields.retention)
		
		if interval and retention then
			luanti_backups.config.interval = interval * 60
			luanti_backups.config.retention = retention
			
			local storage = minetest.get_mod_storage()
			storage:set_int("interval", luanti_backups.config.interval)
			storage:set_int("retention", luanti_backups.config.retention)
			
			minetest.chat_send_player(name, "[luanti_backups] Settings saved.")
		else
			minetest.chat_send_player(name, "[luanti_backups] Invalid input. Please enter numbers.")
		end
		return true
	end
	
	if fields.now then
		minetest.chat_send_player(name, "[luanti_backups] Triggering manual backup...")
		if luanti_backups.run_backup() then
			minetest.chat_send_player(name, "[luanti_backups] Backup complete.")
		else
			minetest.chat_send_player(name, "[luanti_backups] Backup failed. Check logs.")
		end
		return true
	end
end)

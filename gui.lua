-- world_backup: gui.lua

local FORMNAME_MAIN = "world_backup:main"
local FORMNAME_CONF = "world_backup:confirm"

local selected_row = {}
local selected_tab = {}
local pending_revert = {}

local function build_main_form(player, backups, tab)
	local W, H = 14, 9
	local name = player:get_player_name()
	tab = tonumber(tab) or 1
	
	local form = {
		"formspec_version[4]",
		string.format("size[%f,%f]", W, H),
		"bgcolor[#1a1a2e;true]",
		"tabheader[0,0;4,0.7;tabs;Snapshots,Settings;" .. tab .. ";true;false]",
		string.format("box[0,0.7;%f,0.05;#444466]", W),
	}

	if tab == 1 then
		-- Snapshots Tab
		table.insert(form, string.format("box[0,0.75;%f,0.7;#16213e]", W))
		table.insert(form, "label[0.3,1.1;Hash]")
		table.insert(form, "label[3.8,1.1;Timestamp]")
		table.insert(form, "label[10.2,1.1;Age]")
		table.insert(form, string.format("box[0,1.4;%f,0.05;#444466]", W))
		
		local entries = {}
		for _, b in ipairs(backups) do
			table.insert(entries, minetest.formspec_escape(
				string.format("%-10s  |  %-25s  |  %s", b.hash, b.timestamp, b.relative)
			))
		end
		
		local sel = selected_row[name] or 1
		table.insert(form, string.format(
			"textlist[0.3,1.5;%f,%f;backup_list;%s;%d;false]",
			W - 0.6, H - 4.5,
			table.concat(entries, ","),
			sel
		))
		
		table.insert(form, string.format("box[0,%f;%f,0.05;#444466]", H - 2.1, W))
		table.insert(form, string.format("button[0.3,%f;3.2,0.8;btn_create;  Create Backup]", H - 1.9))
		table.insert(form, string.format("button[3.8,%f;3.2,0.8;btn_revert;  Revert to Selected]", H - 1.9))
		table.insert(form, string.format("button[7.3,%f;3.2,0.8;btn_refresh;  Refresh]", H - 1.9))
		table.insert(form, string.format("button_exit[10.8,%f;2.8,0.8;btn_close;Close]", H - 1.9))
	else
		-- Settings Tab
		local interval = world_backup.config.interval / 60
		local retention = world_backup.config.retention
		
		table.insert(form, "label[0.5,1.5;Backup Configuration]")
		table.insert(form, string.format("box[0.4,1.8;%f,0.05;#444466]", W - 0.8))
		
		table.insert(form, "field[0.5,2.5;4,1;interval;Interval (minutes);" .. interval .. "]")
		table.insert(form, "field[0.5,3.7;4,1;retention;Retention Limit;" .. retention .. "]")
		
		table.insert(form, string.format("box[0.4,5.0;%f,0.05;#444466]", W - 0.8))
		table.insert(form, "button[0.5,5.5;3,0.8;btn_save;Save Settings]")
		table.insert(form, "button_exit[4.0,5.5;3,0.8;btn_close;Close]")
	end

	return table.concat(form, "")
end

local function build_confirm_form(hash, timestamp)
	local W, H = 10, 6.5
	return table.concat({
		"formspec_version[4]",
		string.format("size[%f,%f]", W, H),
		"bgcolor[#1a1a2e;true]",
		string.format("box[0,0;%f,0.8;#16213e]", W),
		"label[0.4,0.5;Confirm Revert]",
		string.format("box[0.4,1.0;%f,0.05;#aa3333]", W - 0.8),
		"label[0.4,1.4;Are you sure you want to revert to this snapshot?]",
		string.format("box[0.4,1.9;%f,1.6;#0d1b2a]", W - 0.8),
		"label[0.8,2.3;Hash:]",
		string.format("label[2.5,2.3;%s]", minetest.formspec_escape(hash)),
		"label[0.8,2.9;Time:]",
		string.format("label[2.5,2.9;%s]", minetest.formspec_escape(timestamp)),
		string.format("box[0.4,3.7;%f,0.05;#aa3333]", W - 0.8),
		"label[0.4,4.2;This will restart the server and roll back ALL world data to this point.]",
		"label[0.4,4.6;This action cannot be undone.]",
		string.format("button[0.5,%f;4.0,0.9;btn_confirm_yes;  Yes, Revert]", H - 1.1),
		string.format("button[5.5,%f;4.0,0.9;btn_confirm_no;  Cancel]", H - 1.1),
	}, "")
end

function world_backup.show_gui(player_name, tab)
	local player = minetest.get_player_by_name(player_name)
	if not player then return end
	
	selected_tab[player_name] = tonumber(tab) or selected_tab[player_name] or 1
	local ie = world_backup.ie
	local backups = world_backup.get_backups(ie)
	
	player:get_meta():set_string("world_backup_list", minetest.serialize(backups))
	
	minetest.show_formspec(player_name, FORMNAME_MAIN, build_main_form(player, backups, selected_tab[player_name]))
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()
	if not minetest.check_player_privs(name, {server = true}) then return end

	if formname == FORMNAME_MAIN then
		if fields.tabs then
			selected_tab[name] = tonumber(fields.tabs)
			world_backup.show_gui(name)
			return true
		end

		if fields.backup_list then
			local event = minetest.explode_textlist_event(fields.backup_list)
			if event.type == "CHG" or event.type == "DCL" then
				selected_row[name] = event.index
			end
		end

		if fields.btn_refresh then
			world_backup.show_gui(name)
			return true
		end

		if fields.btn_create then
			minetest.chat_send_player(name, "[world_backup] Triggering backup...")
			if world_backup.run_backup() then
				minetest.chat_send_player(name, "[world_backup] Backup complete.")
			else
				minetest.chat_send_player(name, "[world_backup] Backup failed.")
			end
			world_backup.show_gui(name)
			return true
		end

		if fields.btn_revert then
			local row = selected_row[name]
			if not row then
				minetest.chat_send_player(name, "[world_backup] Please select a backup first.")
				return true
			end

			local backups = minetest.deserialize(player:get_meta():get_string("world_backup_list")) or {}
			local snap = backups[row]
			if not snap then
				minetest.chat_send_player(name, "[world_backup] Invalid selection.")
				return true
			end

			pending_revert[name] = snap
			minetest.show_formspec(name, FORMNAME_CONF, build_confirm_form(snap.hash, snap.timestamp))
			return true
		end

		if fields.btn_save then
			local interval = tonumber(fields.interval)
			local retention = tonumber(fields.retention)
			if interval and retention then
				world_backup.config.interval = interval * 60
				world_backup.config.retention = retention
				local storage = minetest.get_mod_storage()
				storage:set_int("interval", world_backup.config.interval)
				storage:set_int("retention", world_backup.config.retention)
				minetest.chat_send_player(name, "[world_backup] Settings saved.")
			else
				minetest.chat_send_player(name, "[world_backup] Invalid input.")
			end
			world_backup.show_gui(name)
			return true
		end
		
		if fields.btn_close or fields.quit then
			selected_row[name] = nil
			return true
		end
	end

	if formname == FORMNAME_CONF then
		if fields.btn_confirm_yes then
			local snap = pending_revert[name]
			pending_revert[name] = nil
			if snap then
				world_backup.do_revert(snap.hash, snap.timestamp, name)
			end
			return true
		end

		if fields.btn_confirm_no or fields.quit then
			pending_revert[name] = nil
			world_backup.show_gui(name)
			return true
		end
	end
end)

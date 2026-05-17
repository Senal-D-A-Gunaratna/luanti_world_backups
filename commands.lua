-- luanti_backups: commands.lua

minetest.register_chatcommand("backup", {
	params = "gui | now",
	description = "Administer backups",
	privs = {server = true},
	func = function(name, param)
		if param == "" or param == "gui" then
			luanti_backups.show_config_gui(name)
			return true
		elseif param == "now" then
			minetest.chat_send_player(name, "[luanti_backups] Starting backup...")
			if luanti_backups.run_backup() then
				return true, "Backup finished successfully."
			else
				return false, "Backup failed. Check logs."
			end
		else
			return false, "Invalid subcommand. Use /backup gui or /backup now"
		end
	end,
})

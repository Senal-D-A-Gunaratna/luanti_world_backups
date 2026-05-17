-- world_backup: commands.lua

minetest.register_chatcommand("backup", {
	params = "gui | now",
	description = "Administer backups",
	privs = {server = true},
	func = function(name, param)
		if param == "" or param == "gui" then
			world_backup.show_gui(name)
			return true
		elseif param == "now" then

			minetest.chat_send_player(name, "[world_backup] Starting backup...")
			if world_backup.run_backup() then
				return true, "Backup finished successfully."
			else
				return false, "Backup failed. Check logs."
			end
		else
			return false, "Invalid subcommand. Use /backup gui or /backup now"
		end
	end,
})

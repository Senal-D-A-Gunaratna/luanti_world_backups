-- world_backup: init.lua

world_backup = {}
world_backup.path = minetest.get_modpath("world_backup")
world_backup.world_path = minetest.get_worldpath()

-- Load sub-modules
dofile(world_backup.path .. "/storage.lua")
dofile(world_backup.path .. "/gui.lua")
dofile(world_backup.path .. "/commands.lua")

-- Configuration defaults
world_backup.config = {
	interval = 3600, -- 1 hour in seconds
	retention = 10, -- keep 10 backups
}

-- Load saved config if exists
local storage = minetest.get_mod_storage()
world_backup.config.interval = storage:get_int("interval") or 3600
world_backup.config.retention = storage:get_int("retention") or 10

-- Main Backup Function
function world_backup.run_backup()
	local timestamp = os.time()
	local date_str = os.date("%Y-%m-%d_%H-%M-%S", timestamp)
	local hash_dir = world_backup.generate_hash_path(timestamp)
	local backup_dir = world_backup.world_path .. "/backups/" .. hash_dir

	-- Create directory
	minetest.mkdir(backup_dir)

	local source = world_backup.world_path .. "/map.sqlite"
	local destination = backup_dir .. "/map.sqlite"
	local log_file = backup_dir .. "/status.log"

	minetest.log("action", "[world_backup] Starting backup to " .. backup_dir)

	-- Execute VACUUM INTO using sqlite3 CLI
	-- Note: minetest doesn't expose raw sqlite handle easily for this, so we use os.execute
	local cmd = string.format("sqlite3 %s \"VACUUM INTO '%s';\"", source, destination)
	local success, exit_type, code = os.execute(cmd)

	local status_msg = ""
	if success then
		status_msg = string.format("Backup successful at %s", date_str)
		minetest.log("action", "[world_backup] " .. status_msg)
		world_backup.prune_backups()
	else
		status_msg = string.format("Backup failed at %s with code %s", date_str, tostring(code))
		minetest.log("error", "[world_backup] " .. status_msg)
	end

	-- Write status log
	local f = io.open(log_file, "w")
	if f then
		f:write(status_msg .. "\n")
		f:close()
	end

	return success
end

-- Automation timer
local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer >= world_backup.config.interval then
		timer = 0
		world_backup.run_backup()
	end
end)

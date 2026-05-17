-- world_backup: storage.lua

-- Simple hash function for directory names
local function simple_hash(str)
	local h = 5381
	for i = 1, #str do
		h = (h * 33) + string.byte(str, i)
	end
	return string.format("%08x", h)
end

function world_backup.generate_hash_path(timestamp)
	local date_part = os.date("%Y/%m/%d", timestamp)
	local time_part = os.date("%H-%M-%S", timestamp)
	local hash = simple_hash(tostring(timestamp))

	-- Structure: backups/YYYY/MM/DD/HH-MM-SS_hash
	local sub_path = date_part .. "/" .. time_part .. "_" .. hash

	-- Ensure parent directories exist
	local parts = {}
	for part in string.gmatch(date_part, "[^/]+") do
		table.insert(parts, part)
	end

	local current = world_backup.world_path .. "/backups"
	minetest.mkdir(current)
	for _, p in ipairs(parts) do
		current = current .. "/" .. p
		minetest.mkdir(current)
	end

	return sub_path
end

function world_backup.prune_backups()
	local backup_root = world_backup.world_path .. "/backups"
	-- In a real Luanti environment, we'd need a more robust way to list directories.
	-- Lua's os.execute or io.popen with 'find' or 'ls' is common for Linux-based servers.

	local retention = world_backup.config.retention

	-- We'll use a simple find command to list all map.sqlite files in the backup root,
	-- sort them by modification time, and remove the oldest ones.
	local cmd = string.format("find %s -name map.sqlite -printf '%%T@ %%p\\n' | sort -n", backup_root)
	local p = io.popen(cmd)
	if not p then return end

	local backups = {}
	for line in p:lines() do
		local time, path = line:match("([^ ]+) (.+)")
		if time and path then
			table.insert(backups, { time = tonumber(time), path = path:gsub("/map.sqlite$", "") })
		end
	end
	p:close()

	if #backups > retention then
		local to_remove = #backups - retention
		for i = 1, to_remove do
			minetest.log("action", "[world_backup] Pruning old backup: " .. backups[i].path)
			os.execute("rm -rf " .. backups[i].path)
		end
	end
end

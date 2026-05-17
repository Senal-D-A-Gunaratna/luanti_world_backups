# Luanti World Backups

A robust Luanti mod for performing consistent, point-in-time backups of your world's `map.sqlite` using the SQLite `VACUUM INTO` command.

## Features

- **Online Consistency**: Performs backups while the server is active without locking the database.
- **Hashed Storage**: Automatically organizes backups into a hierarchical directory structure: `backups/YYYY/MM/DD/HH-MM-SS_hash`.
- **Status Logs**: Every backup includes a `status.log` file verifying the operation.
- **Admin GUI**: Easy-to-use interface to configure backup frequency and retention limits.
- **Auto-Pruning**: Automatically removes old backups based on your defined retention policy.

## Usage

### Commands
- `/backup`: Opens the configuration GUI.
- `/backup gui`: Opens the configuration GUI.
- `/backup now`: Triggers an immediate manual backup.

### Privileges
Requires the `server` privilege to access commands and settings.

## Installation

1. Clone or download this mod into your Luanti `mods` folder.
2. Ensure the `sqlite3` command-line utility is installed on your server's host system.
3. Enable `luanti_backups` in your world configuration.

## License
MIT

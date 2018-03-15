local function LoadCustomLibrary(Name)
	return require(script.Parent.Modules[Name])
end

local LongPoll = LoadCustomLibrary("LongPoll")
local FolderSyncer = LoadCustomLibrary("FolderSyncer")

local Syncer = FolderSyncer.new(game.ServerScriptService.Modules)

Syncer:Pull()

print("[Plugin] - Listening for changes")
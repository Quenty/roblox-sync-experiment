local HttpService = game:GetService("HttpService")

local function LoadCustomLibrary(Name)
	return require(script.Parent[Name])
end

local Signal = LoadCustomLibrary("Signal")
local MakeMaid = LoadCustomLibrary("Maid").MakeMaid
local LongPoll = LoadCustomLibrary("LongPoll")
local Settings = LoadCustomLibrary("Settings")
local HttpPromise = LoadCustomLibrary("HttpPromise")
local FolderWatcher = LoadCustomLibrary("FolderWatcher")
local PathResolver = LoadCustomLibrary("PathResolver")
local md5 = LoadCustomLibrary("md5")

local FolderSyncer = {}
FolderSyncer.__index = FolderSyncer
FolderSyncer.ClassName = "FolderSyncer"

function FolderSyncer.new(Folder)
	local self = setmetatable({}, FolderSyncer)

	self.Maid = MakeMaid()
	self.Folder = Folder or error("No Folder")

	self.Poll = LongPoll.new(Settings.BASE_URL .. "/filechanged/poll/")

	self.PathResolver = PathResolver.new(self.Folder)
	self.Maid:GiveTask(self.Poll)

	self.Maid:GiveTask(self.Poll.Event:Connect(function(Result)
		if Result.ModifiedFiles then
			self:CheckDifference(Result.ModifiedFiles)
		else
			warn("Unknown result!")
		end
	end))


	self.FolderWatcher = FolderWatcher.new(Folder, {
		PropertyName = self:GetPropertyName();
		IsValid = function(Item)
			if Settings.USE_STRING_VALUES then
				return Item:IsA("StringValue")
			else
				return Item:IsA("ModuleScript") or Item:IsA("Script")
			end
		end;
	})

	self.Maid:GiveTask(self.FolderWatcher)
	self.Maid:GiveTask(self.FolderWatcher.FileAdded:Connect(function(Item)
		print("New script added", Item)
	end))

	return self
end



function FolderSyncer:GetSource(FilePath)
	assert(type(FilePath) == "string", "FilePath must be a string")

	return HttpPromise.Post(Settings.BASE_URL .. "/files/source", {
		filepath = FilePath;	
	}, Enum.HttpContentType.ApplicationJson, false)
end

function FolderSyncer:UpdateSource(Script)
	assert(Script and typeof(Script) == "Instance")

	local Path = self.PathResolver:GetPath(Script)

	return self:GetSource(Path):Then(function(Source)
		self:WriteSource(Script, Source)
	end, function(Error)
		warn("Unable to update source - ", Error)
	end)
end

function FolderSyncer:CheckDifference(Response)
	-- Response = [LuaPath] = Hash
	for Path, Hash in pairs(Response) do
		print(Path, Hash)

		local Script = self.PathResolver:GetItem(Path)

		if Script then
			local CurrentHash = md5.hashhex(self:ReadSource(Script))

			-- Perform update
			if CurrentHash ~= Hash then
				self:UpdateSource(Script)
			end
		else
			local FileName = self.PathResolver:GetFileName(Path)
			local Script = self:CreateSourceContainer(FileName)
			Script.Parent = self:CreateParentFolder(Path)

			self:UpdateSource(Script)
		end
	end
end

function FolderSyncer:Pull()
	HttpPromise.Json(Settings.BASE_URL .. "/files/"):Then(function(Response)
		self:CheckDifference(Response)
	end, function(...)
		warn("Failed to pull all files", ...)
	end)
end

function FolderSyncer:CreateParentFolder(Path)
	local Current = self.Folder

	for _, FolderName in pairs(self.PathResolver:GetDirectoryIter(Path)) do
		local Child = self.Folder:FindFirstChild(FolderName)
		if not Child then
			Child = Instance.new("Folder")
			Child.Name = FolderName
			Child.Parent = Current
		end

		Current = Child
	end

	return Current
end

function FolderSyncer:ReadSource(Item)
	assert(typeof(Item) == "Instance")

	return Item[self:GetPropertyName()]
end

function FolderSyncer:WriteSource(Item, Source)
	assert(typeof(Item) == "Instance")
	assert(type(Source) == "string")

	Item[self:GetPropertyName()] = Source
end


function FolderSyncer:GetPropertyName()
	if Settings.USE_STRING_VALUES then
		return "Value"
	else
		return "Source"
	end
end

function FolderSyncer:CreateSourceContainer(Name)
	assert(type(Name) == "string")
	if Settings.USE_STRING_VALUES then
		local StringValue = Instance.new("StringValue")
		StringValue.Name = Name
		return StringValue
	else
		local Script = Instance.new("ModuleScript")
		Script.Name = Name
		return Script
	end
end

function FolderSyncer:Destroy()
	self.Maid:DoCleaning()
	self.Maid = nil
end

return FolderSyncer



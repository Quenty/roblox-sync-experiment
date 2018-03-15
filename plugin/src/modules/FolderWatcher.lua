---
-- @classmod FolderWatcher

local function LoadCustomLibrary(Name)
	return require(script.Parent[Name])
end

local MakeMaid = LoadCustomLibrary("Maid").new
local Signal = LoadCustomLibrary("Signal")

local FolderWatcher = {}
FolderWatcher.__index = FolderWatcher
FolderWatcher.ClassName = "FolderWatcher"

function FolderWatcher.new(Folder, Options)
	local self = setmetatable({}, FolderWatcher)

	self.Options = Options or error("No Options")
	assert(self.Options.PropertyName)

	self.Maid = MakeMaid()
	self.Folder = Folder or error("No Folder")


	self.FolderAdded = Signal.new()
	self.FileAdded = Signal.new()

	self.FileChanged = Signal.new()
	self.NameChanged = Signal.new()

	self.FileRemoving = Signal.new()
	self.FolderRemoving = Signal.new()

	self:_connect()

	return self
end

function FolderWatcher:IsValid(Item)
	if not self.Options.IsValid then
		return true
	end

	return self.Options.IsValid(Item)
end

function FolderWatcher:_handleDescendant(Descendant, NoReplicate)
	local Maid = MakeMaid()

	local Good = false
	if Descendant:IsA("Folder") then
		self.FolderAdded:Fire(Descendant)
		Good = true
	elseif self:IsValid(Descendant) then
		self.FileAdded:Fire(Descendant)
		Good = true
		Maid:GiveTask(Descendant:GetPropertyChangedSignal(self.Options.PropertyName):Connect(function()
			self.FileChanged:Fire(Descendant)
		end))
	end

	if Good then
		Maid:GiveTask(Descendant:GetPropertyChangedSignal("Name"):Connect(function()
			self.NameChanged:Fire(Descendant)
		end))
	end

	self.Maid[Descendant] = Maid
end

function FolderWatcher:_handleDescendantRemoving(Descendant)
	if Descendant:IsA("Folder") then
		self.FolderRemoving:Fire(Descendant)
	elseif self:IsValid(Descendant) then
		self.FileRemoving:Fire(Descendant)
	end

	self.Maid[Descendant] = nil
end

function FolderWatcher:_connect()
	self.Maid:GiveTask(self.Folder.DescendantAdded:Connect(function(Descendant)
		self:_handleDescendant(Descendant)
	end))
	self.Maid:GiveTask(self.Folder.DescendantRemoving:Connect(function(Descendant)
		self:_handleDescendantRemoving(Descendant)
	end))

	for _, Item in pairs(self.Folder:GetDescendants()) do
		self:_handleDescendant(Item, true)
	end
end

function FolderWatcher:Destroy()
	self.Maid:DoCleaning()
	self.Maid = nil
end



return FolderWatcher
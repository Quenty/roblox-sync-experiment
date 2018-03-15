---
-- @classmod PathResolver





local PathResolver = {}
PathResolver.__index = PathResolver
PathResolver.ClassName = "PathResolver"

function PathResolver.new(Folder)
	local self = setmetatable({}, PathResolver)

	self.Folder = Folder or error("No Folder")

	return self
end

function PathResolver:GetPath(Item)
	assert(typeof(Item) == "Instance")

	if not Item:IsDescendantOf(self.Folder) then
		error(("Item '%s' is not descendant of '%s'"):format(Item:GetFullName(), self.Folder:GetFullName()))
	end	

	local Path = ""
	local Current = Item

	while Current ~= self.Folder do
		assert(Current)

		Path =  Current.Name .. "/" .. Path
		Current = Current.Parent
	end

	-- Strip first "/"
	Path = Path:sub(1, #Path-1)

	return Path
end

function PathResolver:GetIter(Path)
	assert(Path:sub(1, 1) ~= "/")
	assert(type(Path) == "string")

	Path = "/" .. Path

	return Path:gmatch("/(%w+)")
end

function PathResolver:GetDirectoryIter(Path)
	assert(type(Path) == "string")

	local Items = {}
	for Item in self:GetIter(Path) do
		table.insert(Items, Item)
	end
	-- Remove last one
	Items[#Items] = nil
	return Items
end

function PathResolver:GetFileName(Path)
	assert(type(Path) == "string")

	return Path:gmatch("/(%w+)$")()
end

function PathResolver:GetItem(Path)
	assert(type(Path) == "string")


	local Current = self.Folder

	for Name in self:GetIter(Path) do
		Current = Current:FindFirstChild(Name)
		if not Current then
			return nil
		end
	end

	return Current
end


return PathResolver
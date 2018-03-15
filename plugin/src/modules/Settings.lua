local function LoadCustomLibrary(Name)
	return require(script.Parent[Name])
end

local Table = LoadCustomLibrary("Table")

return Table.ErrorOnBadIndex({
	IS_DEBUG = true;
	USE_STRING_VALUES = true;
	BASE_URL = "http://localhost:3000";
})
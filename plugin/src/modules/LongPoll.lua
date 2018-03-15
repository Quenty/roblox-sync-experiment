local function LoadCustomLibrary(Name)
	return require(script.Parent[Name])
end

local Promise = LoadCustomLibrary("Promise")
local Signal = LoadCustomLibrary("Signal")
local MakeMaid = LoadCustomLibrary("Maid").MakeMaid
local HttpPromise = LoadCustomLibrary("HttpPromise")


local LongPoll = {}
LongPoll.__index = LongPoll
LongPoll.ClassName = "LongPoll"

function LongPoll.new(Url, Headers)
	local self = setmetatable({}, LongPoll)

	self.Url = Url or error("No Url")
	self.Headers = Headers or nil

	self.Event = Signal.new() -- :Fire(Result)

	self.Maid = MakeMaid()

	self._lastPollTime = 0	

	self._refresh = Signal.new()
	self._refresh:Connect(function(...)
		self:_poll(...)
	end)

	self._refresh:Fire()

	return self
end

function LongPoll:_poll(PreventLoop)
	if PreventLoop and (tick() - self._lastPollTime) <= 0.01 then
		warn("Already polled recently, yield for now")
		wait()
	end

	self._lastPollTime = tick()
	local RequestPromise = HttpPromise.Json(self.Url, true, self.Headers)
	self.Maid.RequestMaid = RequestPromise

	RequestPromise:Then(function(Result)
		self.Event:Fire(Result)
		self._refresh:Fire()
	end, function(Error)
		-- Hopefully doesn't error
		warn("Request failed.", Error)
		self._refresh:Fire(true) -- Prevent infinite loop on HttpError
	end)
end

function LongPoll:Destroy()
	self.Maid:DoCleaning()
end

return LongPoll



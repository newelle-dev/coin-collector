local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- An unpublished place can't open DataStores. In Studio only, fall back to an
-- in-memory fake so the game still runs; a live server must fail loudly instead.
local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, "Coins_v1")
if not ok then
	if not RunService:IsStudio() then
		error(store)
	end
	warn("[CoinStore] DataStore unavailable (unpublished place): coins won't persist")
	local memory = {}
	store = {
		GetAsync = function(_, key)
			return memory[key]
		end,
		SetAsync = function(_, key, value)
			memory[key] = value
		end,
	}
end

local MAX_ATTEMPTS = 3

-- Players whose coins loaded successfully. We only save for these,
-- so a failed load can never overwrite real data with 0.
local loaded: { [number]: boolean } = {}

local function withRetry(label: string, fn: () -> any): (boolean, any)
	for attempt = 1, MAX_ATTEMPTS do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn(`[CoinStore] {label} failed (attempt {attempt}/{MAX_ATTEMPTS}): {result}`)
		if attempt < MAX_ATTEMPTS then
			task.wait(2 ^ attempt)
		end
	end
	return false, nil
end

local CoinStore = {}

-- Returns the saved coin count, or nil if loading failed.
function CoinStore.load(userId: number): number?
	local ok, value = withRetry("load", function()
		return store:GetAsync(tostring(userId))
	end)
	if not ok then
		return nil
	end
	loaded[userId] = true
	return (value :: number?) or 0
end

function CoinStore.save(userId: number, coins: number)
	if not loaded[userId] then
		return
	end
	withRetry("save", function()
		store:SetAsync(tostring(userId), coins)
	end)
end

function CoinStore.release(userId: number)
	loaded[userId] = nil
end

return CoinStore

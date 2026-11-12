local DataStoreService = game:GetService("DataStoreService")
local store = DataStoreService:GetDataStore("Coins_v1")

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

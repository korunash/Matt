local ContentProvider = game:GetService("ContentProvider")

local cacheDir = "LucideIconsCache"
local sourceUrl = "https://lucide.malice.nz/%s"

local glyphs = {
	check = "✓",
	x = "✕",
	["alert-triangle"] = "⚠",
	info = "i",
	loader = "↻",
	copy = "⧉",
}

local Lucide = {}

local function getGlyph(name)
	return glyphs[name] or "•"
end

local function canUseFileCache()
	return type(isfolder) == "function"
		and type(makefolder) == "function"
		and type(isfile) == "function"
		and type(writefile) == "function"
		and type(getcustomasset) == "function"
end

local function ensureCacheDir()
	if canUseFileCache() and not isfolder(cacheDir) then
		makefolder(cacheDir)
	end
end

function Lucide.Get(name)
	ensureCacheDir()

	if canUseFileCache() then
		local path = string.format("%s/%s.png", cacheDir, name)

		if not isfile(path) then
			local ok, data = pcall(game.HttpGet, game, sourceUrl:format(name))
			if ok and type(data) == "string" then
				writefile(path, data)
			end
		end

		if isfile(path) then
			local asset = getcustomasset(path)
			pcall(function()
				ContentProvider:PreloadAsync({ asset })
			end)
			return asset
		end
	end

	return getGlyph(name)
end

setmetatable(Lucide, {
	__call = function(_, name)
		return Lucide.Get(name)
	end,
})

return Lucide

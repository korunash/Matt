--# Richie #--
--? RichText parser for Ronner ?--
--? Modified by me, made by unknown ?--

local TextService	= game:GetService("TextService");
local Players		= game:GetService("Players");
local BASE_URL		= "https://raw.githubusercontent.com/korunash/ftf-script/main/ui-library/libraries/"

local function resolveModule(path, loadedValue)
	if type(loadedValue) == "function" then
		local ok, result = pcall(loadedValue)
		if not ok then
			error(("Module runtime error in %s: %s"):format(path, tostring(result)), 0)
		end
		if result == nil then
			error(("Module returned nil in %s"):format(path), 0)
		end
		return result
	end

	return loadedValue
end

local function loadModule(name)
	local filePath = "ui-library/libraries/" .. name .. ".luau"

	if type(readfile) == "function" and type(loadstring) == "function" then
		local ok, source = pcall(readfile, filePath)
		if ok and type(source) == "string" then
			local chunk, err = loadstring(source, "@" .. filePath)
			if chunk then
				return resolveModule(filePath, chunk)
			end
			error(("loadstring failed for %s: %s"):format(filePath, tostring(err)), 0)
		end
	end

	if type(loadfile) == "function" then
		local ok, loaded = pcall(loadfile, filePath)
		if ok then
			return resolveModule(filePath, loaded)
		end
	end

	if type(loadstring) == "function" then
		local url = BASE_URL .. name .. ".luau"
		local ok, source = pcall(game.HttpGet, game, url)
		if ok and type(source) == "string" then
			local chunk, err = loadstring(source, "=" .. url)
			if chunk then
				return resolveModule(url, chunk)
			end
			error(("loadstring failed for %s: %s"):format(url, tostring(err)), 0)
		end
	end

	error(("Unable to load bundled library %s"):format(name), 0)
end

--# Easing #--
local Easing	= loadModule("Easing");
local Animate	= loadModule("Animate");
local Lucide	= loadModule("Lucide");

local Richie	= {};

Richie.Tags	= {
	{ Name = "player",				Pattern = '<player id="(%d+)"/?>' },
	{ Name = "player_named",		Pattern = '<player id="(%d+)" name="([^"]+)"/?>' },
	{ Name = "copyable",			Pattern = "<copyable>(.-)</copyable>" },
	{ Name = "bold",				Pattern = "<bold>(.-)</bold>" },
	{ Name = "b",					Pattern = "<b>(.-)</b>" },
	{ Name = "i",					Pattern = "<i>(.-)</i>" },
	{ Name = "muted",				Pattern = "<muted>(.-)</muted>" },
	{ Name = "highlight_coloured",	Pattern = '<highlight colour="([^"]+)">(.-)</highlight>' },
	{ Name = "highlight",			Pattern = "<highlight>(.-)</highlight>" },
	{ Name = "strikethrough",		Pattern = "<s>(.-)</s>" },
	{ Name = "small",				Pattern = "<small>(.-)</small>" },
	{ Name = "large",				Pattern = "<large>(.-)</large>" },
	{ Name = "badge",				Pattern = '<badge colour="([^"]+)">(.-)</badge>' },
	{ Name = "kbd",					Pattern = "<kbd>(.-)</kbd>" },
	{ Name = "time",				Pattern = '<time value="(%d+)"/?>' },
	{ Name = "time_format",			Pattern = '<time value="(%d+)" format="([^"]+)"/?>' },
	{ Name = "dot",					Pattern = '<dot colour="([^"]+)"/?>' },
	{ Name = "number",				Pattern = '<number value="([^"]+)"/?>' },
	{ Name = "number_delta",		Pattern = '<number value="([^"]+)" delta="([^"]+)"/?>' },
	{ Name = "icon",				Pattern = '<icon name="([^"]+)"/?>' },
	{ Name = "avatar_group",		Pattern = '<avatars ids="([^"]+)"/?>' },
};

--# Tag Handlers #--
local TagHandlers = {
	player				= function(S, C) S.PlayerId = C[1] end,
	player_named		= function(S, C) S.PlayerId = C[1]; S.PlayerName = C[2] end,
	highlight_coloured	= function(S, C) S.Colour = C[1]; S.Content = C[2] end,
	badge				= function(S, C) S.Colour = C[1]; S.Content = C[2] end,
	time				= function(S, C) S.Timestamp = tonumber(C[1]) end,
	time_format			= function(S, C) S.Timestamp = tonumber(C[1]); S.Format = C[2] end,
	dot					= function(S, C) S.Colour = C[1] end,
	number				= function(S, C) S.Value = C[1] end,
	number_delta		= function(S, C) S.Value = C[1]; S.Delta = C[2] end,
	icon				= function(S, C) S.IconName = C[1] end,
	avatar_group		= function(S, C) S.Ids = C[1] end,
}

function Richie.Parse(Text)
	local Segments	= {};
	local Remaining	= Text;

	while(#Remaining > 0) do
		local EarliestPos		= math.huge;
		local EarliestTag		= nil;
		local EarliestCaptures	= nil;
		local EarliestEndPos	= nil;

		for _, Tag in ipairs(Richie.Tags) do
			local StartPos, EndPos, Cap1, Cap2 = string.find(Remaining, Tag.Pattern);
			if StartPos and StartPos < EarliestPos then
				EarliestPos		= StartPos;
				EarliestEndPos	= EndPos;
				EarliestTag		= Tag;
				EarliestCaptures	= { Cap1, Cap2 };
			end
		end;

		if EarliestTag then
			if EarliestPos > 1 then
				local BeforeText = string.sub(Remaining, 1, EarliestPos - 1)
				for Word in string.gmatch(BeforeText, "%S+") do
					table.insert(Segments, { Type = "text", Content = Word })
					table.insert(Segments, { Type = "space" })
				end
				if not string.match(BeforeText, "%s$") and #Segments > 0 and Segments[#Segments].Type == "space" then
					table.remove(Segments)
				end
			end

			local Segment = { Type = EarliestTag.Name }
			local Handler = TagHandlers[EarliestTag.Name]

			if Handler then
				Handler(Segment, EarliestCaptures)
			else
				Segment.Content = EarliestCaptures[1]
			end

			table.insert(Segments, Segment)
			Remaining = string.sub(Remaining, EarliestEndPos + 1)
		else
			if #Remaining > 0 then
				for Word in string.gmatch(Remaining, "%S+") do
					table.insert(Segments, { Type = "text", Content = Word })
					table.insert(Segments, { Type = "space" })
				end
				if #Segments > 0 and Segments[#Segments].Type == "space" then
					table.remove(Segments)
				end
			end
			break
		end
	end

	return Segments
end;

function Richie.HasSpecial(Text)
	if(not Text or type(Text)~='string')then
		return false;
	end;

	for _, Tag in ipairs(Richie.Tags) do
		if(string.find(Text,Tag.Pattern))then
			return true;
		end;
	end;

	return false;
end;

local function CreateLabel(Name, Text, TextColour, FontSize, Font, Order, Parent)
	local Label					= Instance.new("TextLabel")
	Label.Name					= Name
	Label.AutomaticSize			= Enum.AutomaticSize.XY
	Label.Size					= UDim2.new(0, 0, 0, 0)
	Label.BackgroundTransparency= 1
	Label.Text					= Text
	Label.TextColor3			= TextColour
	Label.TextSize				= FontSize
	Label.Font					= Font
	Label.TextXAlignment		= Enum.TextXAlignment.Left
	Label.LayoutOrder			= Order
	Label.Parent				= Parent
	return Label
end

local function ParseColour(ColourStr, Default)
	if(not ColourStr) then return Default end;
	local Named = {
		red		= Color3.fromRGB(239, 68, 68),
		green	= Color3.fromRGB(34, 197, 94),
		blue	= Color3.fromRGB(59, 130, 246),
		yellow	= Color3.fromRGB(234, 179, 8),
		orange	= Color3.fromRGB(249, 115, 22),
		purple	= Color3.fromRGB(168, 85, 247),
		pink	= Color3.fromRGB(236, 72, 153),
		cyan	= Color3.fromRGB(6, 182, 212),
		amber	= Color3.fromRGB(245, 158, 11),
		gray	= Color3.fromRGB(113, 113, 122),
	}
	if(Named[ColourStr:lower()]) then return Named[ColourStr:lower()] end;
	local Hex = ColourStr:match("^#(%x+)$")
	if(Hex and #Hex == 6) then
		return Color3.fromRGB(tonumber(Hex:sub(1,2),16), tonumber(Hex:sub(3,4),16), tonumber(Hex:sub(5,6),16))
	end;
	return Default
end

local function IsImageSource(Value)
	return type(Value) == "string"
		and (
			string.sub(Value, 1, 11) == "rbxasset://"
			or string.sub(Value, 1, 13) == "rbxassetid://"
			or string.sub(Value, 1, 7) == "http://"
			or string.sub(Value, 1, 8) == "https://"
		)
end

local SegmentRenderers = {
	space = function(_, I, Container, _, _, FontSize)
		local Spacer						= Instance.new("Frame")
		Spacer.Name							= "Space_" .. I
		Spacer.Size							= UDim2.new(0, 4, 0, FontSize)
		Spacer.BackgroundTransparency		= 1
		Spacer.LayoutOrder					= I
		Spacer.Parent						= Container
	end,

	text = function(Seg, I, Container, TextColour, _, FontSize, Font)
		CreateLabel("Text_" .. I, Seg.Content, TextColour, FontSize, Font, I, Container)
	end,

	bold = function(Seg, I, Container, TextColour, _, FontSize)
		CreateLabel("Bold_" .. I, Seg.Content, TextColour, FontSize, Enum.Font.GothamBold, I, Container)
	end,
	b = function(Seg, I, Container, TextColour, _, FontSize)
		CreateLabel("Bold_" .. I, Seg.Content, TextColour, FontSize, Enum.Font.GothamBold, I, Container)
	end,

	i = function(Seg, I, Container, TextColour, _, FontSize)
		CreateLabel("Italic_" .. I, Seg.Content, TextColour, FontSize, Enum.Font.SourceSansItalic, I, Container)
	end,

	muted = function(Seg, I, Container, _, MutedColour, FontSize, Font)
		CreateLabel("Muted_" .. I, Seg.Content, MutedColour, FontSize, Font, I, Container)
	end,

	small = function(Seg, I, Container, _, MutedColour, FontSize, Font)
		CreateLabel("Small_" .. I, Seg.Content, MutedColour, FontSize - 2, Font, I, Container)
	end,

	large = function(Seg, I, Container, TextColour, _, FontSize)
		CreateLabel("Large_" .. I, Seg.Content, TextColour, FontSize + 2, Enum.Font.GothamBold, I, Container)
	end,

	strikethrough = function(Seg, I, Container, _, MutedColour, FontSize, Font)
		local Strike						= Instance.new("Frame")
		Strike.Name							= "Strike_" .. I
		Strike.AutomaticSize				= Enum.AutomaticSize.XY
		Strike.BackgroundTransparency		= 1
		Strike.LayoutOrder					= I
		Strike.Parent						= Container

		CreateLabel("StrikeText", Seg.Content, MutedColour, FontSize, Font, 0, Strike)

		task.defer(function()
			local Line						= Instance.new("Frame")
			Line.Size						= UDim2.new(1, 0, 0, 1)
			Line.Position					= UDim2.new(0, 0, 0.5, 0)
			Line.AnchorPoint				= Vector2.new(0, 0.5)
			Line.BackgroundColor3			= MutedColour
			Line.BackgroundTransparency		= 0.3
			Line.BorderSizePixel			= 0
			Line.Parent						= Strike
		end)
	end,

	highlight = function(Seg, I, Container, _, _, FontSize, _, Colours)
		local Colour		= Colours.warning
		local Highlight		= Instance.new("Frame")
		Highlight.Name						= "Highlight_" .. I
		Highlight.AutomaticSize				= Enum.AutomaticSize.XY
		Highlight.BackgroundColor3			= Colour
		Highlight.BackgroundTransparency	= 0.85
		Highlight.BorderSizePixel			= 0
		Highlight.LayoutOrder				= I
		Highlight.Parent					= Container

		Instance.new("UICorner", Highlight).CornerRadius = UDim.new(0, 3)
		local Pad = Instance.new("UIPadding", Highlight)
		Pad.PaddingLeft, Pad.PaddingRight = UDim.new(0, 4), UDim.new(0, 4)

		CreateLabel("HighlightText", Seg.Content, Colour, FontSize, Enum.Font.GothamMedium, 0, Highlight)
	end,

	highlight_coloured = function(Seg, I, Container, _, _, FontSize, _, Colours)
		local Colour		= ParseColour(Seg.Colour, Colours.warning)
		local Highlight		= Instance.new("Frame")
		Highlight.Name						= "Highlight_" .. I
		Highlight.AutomaticSize				= Enum.AutomaticSize.XY
		Highlight.BackgroundColor3			= Colour
		Highlight.BackgroundTransparency	= 0.85
		Highlight.BorderSizePixel			= 0
		Highlight.LayoutOrder				= I
		Highlight.Parent					= Container

		Instance.new("UICorner", Highlight).CornerRadius = UDim.new(0, 3)
		local Pad = Instance.new("UIPadding", Highlight)
		Pad.PaddingLeft, Pad.PaddingRight = UDim.new(0, 4), UDim.new(0, 4)

		CreateLabel("HighlightText", Seg.Content, Colour, FontSize, Enum.Font.GothamMedium, 0, Highlight)
	end,

	badge = function(Seg, I, Container, _, _, FontSize)
		local Colour	= ParseColour(Seg.Colour, Color3.fromRGB(59, 130, 246))
		local Badge		= Instance.new("Frame")
		Badge.Name							= "Badge_" .. I
		Badge.AutomaticSize					= Enum.AutomaticSize.XY
		Badge.BackgroundColor3				= Colour
		Badge.BackgroundTransparency		= 0.85
		Badge.BorderSizePixel				= 0
		Badge.LayoutOrder					= I
		Badge.Parent						= Container

		Instance.new("UICorner", Badge).CornerRadius = UDim.new(1, 0)
		local Pad = Instance.new("UIPadding", Badge)
		Pad.PaddingLeft, Pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
		Pad.PaddingTop, Pad.PaddingBottom = UDim.new(0, 2), UDim.new(0, 2)

		local Label = CreateLabel("BadgeText", Seg.Content, Colour, FontSize - 2, Enum.Font.GothamMedium, 0, Badge)
		Label.TextXAlignment = Enum.TextXAlignment.Center
	end,

	kbd = function(Seg, I, Container, _, _, FontSize, _, Colours)
		local IsDark					= Colours.background.R < 0.5
		local KbdBg						= IsDark and Color3.fromRGB(39, 39, 42) or Color3.fromRGB(250, 250, 250)
		local KbdBorder					= IsDark and Color3.fromRGB(63, 63, 70) or Color3.fromRGB(228, 228, 231)
		local KbdText					= IsDark and Color3.fromRGB(161, 161, 170) or Color3.fromRGB(113, 113, 122)

		local KbdFontSize				= FontSize - 2
		local TextSize					= TextService:GetTextSize(Seg.Content, KbdFontSize, Enum.Font.RobotoMono, Vector2.new(math.huge, KbdFontSize + 4))
		local KbdWidth, KbdHeight		= math.max(TextSize.X + 10, KbdFontSize + 8), KbdFontSize + 4

		local Wrapper						= Instance.new("Frame")
		Wrapper.Name						= "KbdWrapper_" .. I
		Wrapper.Size						= UDim2.new(0, KbdWidth + 4, 0, KbdHeight + 4)
		Wrapper.BackgroundTransparency		= 1
		Wrapper.LayoutOrder					= I
		Wrapper.Parent						= Container

		local Kbd						= Instance.new("Frame")
		Kbd.Size						= UDim2.new(0, KbdWidth, 0, KbdHeight)
		Kbd.Position					= UDim2.new(0.5, 0, 0.5, 0)
		Kbd.AnchorPoint					= Vector2.new(0.5, 0.5)
		Kbd.BackgroundColor3			= KbdBg
		Kbd.BorderSizePixel				= 0
		Kbd.Parent						= Wrapper

		Instance.new("UICorner", Kbd).CornerRadius = UDim.new(0, 4)
		local Stroke = Instance.new("UIStroke", Kbd)
		Stroke.Color, Stroke.Thickness = KbdBorder, 1

		local Label						= Instance.new("TextLabel", Kbd)
		Label.Size						= UDim2.new(1, 0, 1, 0)
		Label.BackgroundTransparency	= 1
		Label.Text						= Seg.Content
		Label.TextColor3				= KbdText
		Label.TextSize					= KbdFontSize
		Label.Font						= Enum.Font.RobotoMono
		Label.TextXAlignment			= Enum.TextXAlignment.Center
		Label.TextYAlignment			= Enum.TextYAlignment.Center
	end,

	copyable = function(Seg, I, Container, TextColour, _, FontSize, _, Colours)
		local TextSize		= TextService:GetTextSize(Seg.Content, FontSize - 1, Enum.Font.RobotoMono, Vector2.new(math.huge, FontSize + 8))
		local Copyable		= Instance.new("Frame")
		Copyable.Name						= "Copyable_" .. I
		Copyable.Size						= UDim2.new(0, TextSize.X + 16, 0, TextSize.Y + 6)
		Copyable.BackgroundTransparency		= 1
		Copyable.LayoutOrder				= I
		Copyable.Parent						= Container

		Instance.new("UICorner", Copyable).CornerRadius = UDim.new(0, 4)
		local Stroke = Instance.new("UIStroke", Copyable)
		Stroke.Color, Stroke.Thickness, Stroke.Transparency = Colours.border, 1, 0.3

		local Box						= Instance.new("TextBox", Copyable)
		Box.Size						= UDim2.new(1, 0, 1, 0)
		Box.BackgroundTransparency		= 1
		Box.Text						= Seg.Content
		Box.TextColor3					= TextColour
		Box.TextSize					= FontSize - 1
		Box.Font						= Enum.Font.RobotoMono
		Box.TextXAlignment				= Enum.TextXAlignment.Center
		Box.ClearTextOnFocus			= false
		Box.TextEditable				= false

		Copyable.MouseEnter:Connect(function() Animate.To(Stroke, { Transparency = 0, Thickness = 1.5 }, 0.12, Easing.Standard) end)
		Copyable.MouseLeave:Connect(function() Animate.To(Stroke, { Transparency = 0.3, Thickness = 1 }, 0.12, Easing.Standard) end)
	end,

	time = function(Seg, I, Container, _, MutedColour, FontSize)
		local function GetRelativeTime(T)
			local D = os.time() - T
			if(D < 0) then
				D = -D; local P = "in "
				if(D < 60) then return P..D.."s"
				elseif(D < 3600) then return P..math.floor(D/60).."m"
				elseif(D < 86400) then return P..math.floor(D/3600).."h"
				else return P..math.floor(D/86400).."d" end;
			else
				if(D < 60) then return D.."s ago"
				elseif(D < 3600) then return math.floor(D/60).."m ago"
				elseif(D < 86400) then return math.floor(D/3600).."h ago"
				else return math.floor(D/86400).."d ago" end;
			end;
		end
		CreateLabel("Time_" .. I, GetRelativeTime(Seg.Timestamp), MutedColour, FontSize - 1, Enum.Font.RobotoMono, I, Container)
	end,

	time_format = function(Seg, I, Container, _, MutedColour, FontSize)
		local Formats	= { date = "%b %d, %Y", time = "%H:%M", datetime = "%b %d, %H:%M", full = "%b %d, %Y %H:%M:%S" }
		local Text		= Formats[Seg.Format] and os.date(Formats[Seg.Format], Seg.Timestamp) or os.date("%b %d", Seg.Timestamp)
		CreateLabel("Time_" .. I, Text, MutedColour, FontSize - 1, Enum.Font.RobotoMono, I, Container)
	end,

	dot = function(Seg, I, Container, _, _, _, _, Colours)
		local Dot					= Instance.new("Frame")
		Dot.Name					= "Dot_" .. I
		Dot.Size					= UDim2.new(0, 6, 0, 6)
		Dot.BackgroundColor3		= ParseColour(Seg.Colour, Colours.muted)
		Dot.BorderSizePixel			= 0
		Dot.LayoutOrder				= I
		Dot.Parent					= Container
		Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
	end,

	number = function(Seg, I, Container, TextColour, _, FontSize)
		local function Fmt(N)
			N = tonumber(N);
			if(not N) then return Seg.Value end;
			if(N >= 1e6) then return string.format("%.1fM", N/1e6)
			elseif(N >= 1e3) then return string.format("%.1fK", N/1e3) end;
			return tostring(N)
		end
		CreateLabel("Number_" .. I, Fmt(Seg.Value), TextColour, FontSize, Enum.Font.RobotoMono, I, Container)
	end,

	number_delta = function(Seg, I, Container, TextColour, _, FontSize)
		local function Fmt(N)
			N = tonumber(N);
			if(not N) then return Seg.Value end;
			if(N >= 1e6) then return string.format("%.1fM", N/1e6)
			elseif(N >= 1e3) then return string.format("%.1fK", N/1e3) end;
			return tostring(N)
		end

		local Wrapper						= Instance.new("Frame")
		Wrapper.Name						= "Number_" .. I
		Wrapper.AutomaticSize				= Enum.AutomaticSize.XY
		Wrapper.BackgroundTransparency		= 1
		Wrapper.LayoutOrder					= I
		Wrapper.Parent						= Container

		local Layout					= Instance.new("UIListLayout", Wrapper)
		Layout.FillDirection			= Enum.FillDirection.Horizontal
		Layout.VerticalAlignment		= Enum.VerticalAlignment.Center
		Layout.Padding					= UDim.new(0, 4)

		CreateLabel("Value", Fmt(Seg.Value), TextColour, FontSize, Enum.Font.RobotoMono, 1, Wrapper)

		local Delta				= tonumber(Seg.Delta) or 0
		local DeltaColour		= (Delta >= 0) and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(239, 68, 68)
		CreateLabel("Delta", ((Delta >= 0) and "+" or "") .. Seg.Delta, DeltaColour, FontSize - 2, Enum.Font.GothamMedium, 2, Wrapper)
	end,

	icon = function(Seg, I, Container, _, MutedColour, FontSize, _, Colours)
		local IconName		= Seg.IconName
		local Size			= FontSize
		local IconValue		= Lucide(IconName)

		local Wrapper						= Instance.new("Frame")
		Wrapper.Name						= "Icon_" .. I
		Wrapper.Size						= UDim2.new(0, Size + 4, 0, Size + 4)
		Wrapper.BackgroundTransparency		= 1
		Wrapper.LayoutOrder					= I
		Wrapper.Parent						= Container

		if IsImageSource(IconValue) then
			local Icon						= Instance.new("ImageLabel")
			Icon.Name						= "LucideIcon"
			Icon.Size						= UDim2.new(0, Size, 0, Size)
			Icon.Position					= UDim2.new(0.5, 0, 0.5, 0)
			Icon.AnchorPoint				= Vector2.new(0.5, 0.5)
			Icon.BackgroundTransparency		= 1
			Icon.Image						= IconValue
			Icon.ImageColor3				= MutedColour
			Icon.ScaleType					= Enum.ScaleType.Fit
			Icon.Parent						= Wrapper
		else
			local Icon						= Instance.new("TextLabel")
			Icon.Name						= "LucideGlyph"
			Icon.Size						= UDim2.new(0, Size, 0, Size)
			Icon.Position					= UDim2.new(0.5, 0, 0.5, 0)
			Icon.AnchorPoint				= Vector2.new(0.5, 0.5)
			Icon.BackgroundTransparency		= 1
			Icon.Text						= tostring(IconValue or "•")
			Icon.TextColor3					= MutedColour
			Icon.TextSize					= FontSize
			Icon.Font						= Enum.Font.GothamBold
			Icon.TextXAlignment				= Enum.TextXAlignment.Center
			Icon.TextYAlignment				= Enum.TextYAlignment.Center
			Icon.Parent						= Wrapper
		end
	end,

	player = function(Seg, I, Container, _, _, FontSize, _, Colours)
		local Size			= FontSize + 4
		local Thumb			= Instance.new("ImageLabel")
		Thumb.Name						= "Player_" .. I
		Thumb.Size						= UDim2.new(0, Size, 0, Size)
		Thumb.BackgroundColor3			= Colours.border
		Thumb.BorderSizePixel			= 0
		Thumb.LayoutOrder				= I
		Thumb.Parent					= Container

		Instance.new("UICorner", Thumb).CornerRadius = UDim.new(1, 0)
		local Stroke = Instance.new("UIStroke", Thumb)
		Stroke.Color, Stroke.Thickness, Stroke.Transparency = Colours.border, 1.5, 0.4

		task.spawn(function()
			local Ok, Img = pcall(Players.GetUserThumbnailAsync, Players, tonumber(Seg.PlayerId), Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
			if(Ok and Thumb.Parent) then Thumb.Image = Img; Thumb.BackgroundTransparency = 1 end;
		end)
	end,

	player_named = function(Seg, I, Container, TextColour, _, FontSize, _, Colours)
		local Size			= FontSize + 4
		local Wrapper		= Instance.new("Frame")
		Wrapper.Name						= "PlayerWrapper_" .. I
		Wrapper.AutomaticSize				= Enum.AutomaticSize.X
		Wrapper.Size						= UDim2.new(0, 0, 0, Size)
		Wrapper.BackgroundTransparency		= 1
		Wrapper.LayoutOrder					= I
		Wrapper.Parent						= Container

		local Layout					= Instance.new("UIListLayout", Wrapper)
		Layout.FillDirection			= Enum.FillDirection.Horizontal
		Layout.VerticalAlignment		= Enum.VerticalAlignment.Center
		Layout.Padding					= UDim.new(0, 4)

		local Thumb						= Instance.new("ImageLabel", Wrapper)
		Thumb.Size						= UDim2.new(0, Size, 0, Size)
		Thumb.BackgroundColor3			= Colours.border
		Thumb.BorderSizePixel			= 0
		Thumb.LayoutOrder				= 1
		Instance.new("UICorner", Thumb).CornerRadius = UDim.new(1, 0)

		CreateLabel("PlayerName", Seg.PlayerName, TextColour, FontSize, Enum.Font.GothamMedium, 2, Wrapper)

		task.spawn(function()
			local Ok, Img = pcall(Players.GetUserThumbnailAsync, Players, tonumber(Seg.PlayerId), Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
			if(Ok and Thumb.Parent) then Thumb.Image = Img; Thumb.BackgroundTransparency = 1 end;
		end)
	end,

	avatar_group = function(Seg, I, Container, _, _, FontSize, _, Colours)
		local Ids = {}
		for Id in string.gmatch(Seg.Ids, "(%d+)") do table.insert(Ids, Id) end;

		local Size, Overlap			= FontSize + 4, 6
		local Width					= Size + (math.min(#Ids - 1, 4) * (Size - Overlap))

		local Group						= Instance.new("Frame")
		Group.Name						= "AvatarGroup_" .. I
		Group.Size						= UDim2.new(0, Width + 4, 0, Size + 4)
		Group.BackgroundTransparency	= 1
		Group.LayoutOrder				= I
		Group.Parent					= Container

		for Idx, PlayerId in ipairs(Ids) do
			if(Idx > 5) then break end;
			local Avatar					= Instance.new("ImageLabel", Group)
			Avatar.Size						= UDim2.new(0, Size, 0, Size)
			Avatar.Position					= UDim2.new(0, (Idx-1) * (Size - Overlap) + 2, 0.5, 0)
			Avatar.AnchorPoint				= Vector2.new(0, 0.5)
			Avatar.BackgroundColor3			= Colours.border
			Avatar.BorderSizePixel			= 0
			Avatar.ZIndex					= #Ids - Idx + 1

			Instance.new("UICorner", Avatar).CornerRadius = UDim.new(1, 0)
			local Stroke = Instance.new("UIStroke", Avatar)
			Stroke.Color, Stroke.Thickness = Colours.background, 2

			task.spawn(function()
				local Ok, Img = pcall(Players.GetUserThumbnailAsync, Players, tonumber(PlayerId), Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
				if(Ok and Avatar.Parent) then Avatar.Image = Img; Avatar.BackgroundTransparency = 1 end;
			end)
		end;
	end,
}

function Richie.Render(Parent, Text, TextColour, MutedColour, FontSize, Font, Colours)
	if(not Text or not Richie.HasSpecial(Text)) then return nil end;

	Colours				= Colours or {
		border				= Color3.fromRGB(63, 63, 70),
		background			= Color3.fromRGB(24, 24, 27),
		muted				= Color3.fromRGB(113, 113, 122),
		warning				= Color3.fromRGB(234, 179, 8),
	}
	local Segments			= Richie.Parse(Text)

	local Container						= Instance.new("Frame")
	Container.Name						= "RichText"
	Container.AutomaticSize				= Enum.AutomaticSize.XY
	Container.Size						= UDim2.new(1, 0, 0, 0)
	Container.BackgroundTransparency	= 1
	Container.Parent					= Parent

	local Layout						= Instance.new("UIListLayout", Container)
	Layout.SortOrder					= Enum.SortOrder.LayoutOrder
	Layout.FillDirection				= Enum.FillDirection.Horizontal
	Layout.VerticalAlignment			= Enum.VerticalAlignment.Center
	Layout.HorizontalAlignment			= Enum.HorizontalAlignment.Left
	Layout.Wraps						= true
	Layout.Padding						= UDim.new(0, 0)

	for I, Seg in ipairs(Segments) do
		local Renderer = SegmentRenderers[Seg.Type]
		if(Renderer) then
			Renderer(Seg, I, Container, TextColour, MutedColour, FontSize, Font, Colours)
		end;
	end;

	return Container
end;

return Richie

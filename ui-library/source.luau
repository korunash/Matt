-- Services
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local GuiParent = RunService:IsStudio() and PlayerGui or CoreGui

local existing = GuiParent:FindFirstChild("Matt")
if existing and existing:IsA("ScreenGui") then
	existing:Destroy()
end
-- Theme
local READY_COLOR = Color3.fromRGB(108, 214, 148)
local ERROR_COLOR = Color3.fromRGB(255, 107, 107)
local COMMAND_TITLE_COLOR = Color3.fromRGB(235, 235, 235)
local COMMAND_DESCRIPTION_COLOR = Color3.fromRGB(138, 138, 138)
local PLAYER_NAME_COLOR = Color3.fromRGB(235, 235, 235)
local PLAYER_USERNAME_COLOR = Color3.fromRGB(138, 138, 138)
local TYPE_COLORS = {
	int = Color3.fromRGB(128, 186, 255),
	number = Color3.fromRGB(128, 186, 255),
	player = Color3.fromRGB(236, 169, 255),
	param = Color3.fromRGB(255, 213, 125),
	search = Color3.fromRGB(133, 216, 255),
	key = Color3.fromRGB(255, 213, 125),
}

local BAR_HEIGHT = 64
local MAX_LIST_HEIGHT = 456
local LIST_PADDING_TOP = 18
local LIST_PADDING_BOTTOM = 18
local MENU_WIDTH = 0.65
local OPEN_MENU_POSITION = UDim2.fromScale(0.5, 0.53)
local CLOSED_MENU_POSITION = UDim2.new(OPEN_MENU_POSITION.X.Scale, OPEN_MENU_POSITION.X.Offset, OPEN_MENU_POSITION.Y.Scale, OPEN_MENU_POSITION.Y.Offset + 20)
local MENU_TWEEN_DURATION = 0.14
local LIST_TWEEN_DURATION = 0.12
local ENTRY_STAGGER_DELAY = 0.05
local ENTRY_ENTER_DURATION = 0.08
local ENTRY_EXIT_DURATION = 0.06
local ERROR_ENTRY_STAGGER_DELAY = 0.02
local ERROR_ENTRY_EXIT_DURATION = 0.03
local ENTRY_HIDDEN_SCALE = 0.96
local TYPEWRITER_STEP_DELAY = 0.012
local MIN_SCALE = 0.2
local MAX_SCALE = 2.0
local READY_DESCRIPTION = "Syntax valid. Press Enter to execute."
local TOAST_WIDTH = 320
local TOAST_GAP = 10
local TOAST_OFFSET = 18
local TOAST_DURATION = 4
local TOAST_ENTER_DURATION = 0.16
local TOAST_EXIT_DURATION = 0.12
local AUTOCOMPLETE_LIMIT = 7
local AUTOCOMPLETE_SELECTED_COLOR = Color3.fromRGB(235, 235, 235)
local AUTOCOMPLETE_IDLE_COLOR = Color3.fromRGB(128, 128, 128)
local AUTOCOMPLETE_CURSOR_OFFSET_X = 6
local AUTOCOMPLETE_CURSOR_OFFSET_Y = 4
local CAPTION_CURSOR_OFFSET_X = 14
local CAPTION_CURSOR_OFFSET_Y = 7
local CAPTION_SCREEN_PADDING = 7
local CAPTION_RIGHT_PADDING = 15
local CAPTION_HOVER_DELAY = 0.18

local layoutCfg = {
	widthScale = MENU_WIDTH,
	openY = OPEN_MENU_POSITION.Y.Scale,
	closeYOffset = 20,
	barHeight = BAR_HEIGHT,
	maxListHeight = MAX_LIST_HEIGHT,
	minWidth = 320,
	maxWidth = 870,
	listPadTop = LIST_PADDING_TOP,
	listPadBottom = LIST_PADDING_BOTTOM,
	toastWidth = TOAST_WIDTH,
	toastGap = TOAST_GAP,
	toastOffset = TOAST_OFFSET,
	phoneWidthScale = 0.94,
	tabletWidthScale = 0.78,
	phoneShortSide = 760,
	tabletShortSide = 1100,
	phoneHeightRatio = 0.34,
	tabletHeightRatio = 0.42,
	desktopHeightRatio = 0.5,
	minToastWidth = 220,
}

local motionCfg = {
	menu = MENU_TWEEN_DURATION,
	list = LIST_TWEEN_DURATION,
	entryGap = ENTRY_STAGGER_DELAY,
	entryIn = ENTRY_ENTER_DURATION,
	entryOut = ENTRY_EXIT_DURATION,
	errorGap = ERROR_ENTRY_STAGGER_DELAY,
	errorOut = ERROR_ENTRY_EXIT_DURATION,
	hiddenScale = ENTRY_HIDDEN_SCALE,
	typewriterStep = TYPEWRITER_STEP_DELAY,
	scale = 0.16,
	toastIn = TOAST_ENTER_DURATION,
	toastOut = TOAST_EXIT_DURATION,
}

local behaviorCfg = {
	responsive = true,
	closeOnBlur = true,
	closeOnSubmit = true,
	typewriterOpen = true,
	typewriterClose = true,
}

local mobileCfg = {
	enabled = true,
	useFloatingButton = false,
	buttonText = ">",
	buttonSize = 48,
	buttonRight = 18,
	buttonBottom = 28,
}

local runtimeLayout = {
	device = "desktop",
	menuWidthScale = MENU_WIDTH,
	maxListHeight = MAX_LIST_HEIGHT,
	maxMenuWidth = 870,
	maxMenuHeight = 520,
	toastWidth = TOAST_WIDTH,
	toastOffset = TOAST_OFFSET,
}

local toastDuration = TOAST_DURATION

-- Text
local function trimLeft(text)
	return string.gsub(text or "", "^%s+", "")
end

local function trimRight(text)
	return string.gsub(text or "", "%s+$", "")
end

local function trim(text)
	return trimRight(trimLeft(text or ""))
end

local function toLower(text)
	return string.lower(text or "")
end

local function startsWith(text, prefix)
	return string.sub(text or "", 1, #prefix) == prefix
end

local function escapeRichText(text)
	text = string.gsub(text or "", "&", "&amp;")
	text = string.gsub(text, "<", "&lt;")
	text = string.gsub(text, ">", "&gt;")
	text = string.gsub(text, "\"", "&quot;")
	return text
end

local function colorToHex(color)
	return string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
end

local function cloneArray(list)
	local cloned = {}
	for _, value in ipairs(list or {}) do
		cloned[#cloned + 1] = value
	end
	return cloned
end

-- Hotkey
local function normalizeHotkeyToken(raw)
	local normalized = toLower(trim(raw))
	normalized = string.gsub(normalized, "%s+", "")

	if #normalized == 2 then
		local first = string.sub(normalized, 1, 1)
		local second = string.sub(normalized, 2, 2)
		if first == second and (first == "'" or first == "\"") then
			normalized = first
		end
	end

	return normalized
end

local function getKeyCodeText(keyCode)
	if not keyCode then
		return nil
	end

	local ok, displayText = pcall(function()
		return UserInputService:GetStringForKeyCode(keyCode)
	end)

	if ok and type(displayText) == "string" and displayText ~= "" then
		return displayText
	end

	local keyName = keyCode.Name
	if string.match(keyName, "^[A-Z]$") then
		return string.lower(keyName)
	end

	local digitMap = {
		Zero = "0",
		One = "1",
		Two = "2",
		Three = "3",
		Four = "4",
		Five = "5",
		Six = "6",
		Seven = "7",
		Eight = "8",
		Nine = "9",
	}

	local punctuationMap = {
		Slash = "/",
		Semicolon = ";",
		Quote = "'",
		Backquote = "`",
		BackSlash = "\\",
		Comma = ",",
		Period = ".",
		Minus = "-",
		Equals = "=",
		LeftBracket = "[",
		RightBracket = "]",
		Space = " ",
		Tab = "tab",
	}

	return digitMap[keyName] or punctuationMap[keyName]
end

local function findKeyCodeByDisplayToken(normalizedToken)
	if normalizedToken == "" then
		return nil
	end

	for _, keyCode in ipairs(Enum.KeyCode:GetEnumItems()) do
		local displayText = getKeyCodeText(keyCode)
		if displayText and normalizeHotkeyToken(displayText) == normalizedToken then
			return keyCode
		end
	end

	return nil
end

local function resolveHotkeyName(raw)
	local normalized = normalizeHotkeyToken(raw)
	if normalized == "" then
		return false, nil, "Missing hotkey"
	end

	if normalized == "none" then
		return true, "None"
	end

	local displayMatch = findKeyCodeByDisplayToken(normalized)
	if displayMatch then
		return true, displayMatch.Name
	end

	local aliases = {
		["/"] = "Slash",
		slash = "Slash",
		[";"] = "Semicolon",
		semicolon = "Semicolon",
		["'"] = "Quote",
		["\""] = "Quote",
		quote = "Quote",
		apostrophe = "Quote",
		["`"] = "Backquote",
		backquote = "Backquote",
		grave = "Backquote",
		tilde = "Backquote",
		["\\"] = "BackSlash",
		backslash = "BackSlash",
		comma = "Comma",
		[","] = "Comma",
		period = "Period",
		["."] = "Period",
		minus = "Minus",
		["-"] = "Minus",
		equals = "Equals",
		["="] = "Equals",
		leftbracket = "LeftBracket",
		["["] = "LeftBracket",
		rightbracket = "RightBracket",
		["]"] = "RightBracket",
		tab = "Tab",
		space = "Space",
		none = "None",
	}

	local canonical = aliases[normalized]
	if not canonical and #normalized == 1 then
		local upper = string.upper(normalized)
		if string.match(upper, "^[A-Z]$") then
			canonical = upper
		else
			local digitMap = {
				["0"] = "Zero",
				["1"] = "One",
				["2"] = "Two",
				["3"] = "Three",
				["4"] = "Four",
				["5"] = "Five",
				["6"] = "Six",
				["7"] = "Seven",
				["8"] = "Eight",
				["9"] = "Nine",
			}
			canonical = digitMap[normalized]
		end
	end

	if not canonical then
		canonical = string.upper(string.sub(normalized, 1, 1)) .. string.sub(normalized, 2)
	end

	if canonical == "None" or Enum.KeyCode[canonical] then
		return true, canonical
	end

	return false, nil, "Unknown hotkey"
end

-- Command parsing
local function tokenize(text)
	local normalized = trimLeft(text or "")
	local trailingSpace = normalized ~= "" and string.match(normalized, "%s$") ~= nil
	local tokens = {}

	for token in string.gmatch(normalized, "%S+") do
		tokens[#tokens + 1] = token
	end

	return tokens, trailingSpace
end

local function isBlankCommandText(text)
	local normalized = trimLeft(text or "")
	if startsWith(normalized, "/") then
		normalized = string.sub(normalized, 2)
	end

	return trimRight(normalized) == ""
end

local function sortCommands(commands)
	table.sort(commands, function(left, right)
		return toLower(left.name) < toLower(right.name)
	end)
	return commands
end

local function sortPlayers(players)
	table.sort(players, function(left, right)
		local leftName = toLower(left.DisplayName) .. ":" .. toLower(left.Name)
		local rightName = toLower(right.DisplayName) .. ":" .. toLower(right.Name)
		return leftName < rightName
	end)
	return players
end

local function listPlayers(query)
	local normalizedQuery = toLower(trim(query))
	local results = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local name = toLower(player.Name)
		local displayName = toLower(player.DisplayName)
		if normalizedQuery == "" or string.find(name, normalizedQuery, 1, true) or string.find(displayName, normalizedQuery, 1, true) then
			results[#results + 1] = player
		end
	end

	return sortPlayers(results)
end

local function resolvePlayer(query)
	local normalizedQuery = trim(query)
	if normalizedQuery == "" then
		return false, nil, "Unspecified player"
	end

	local loweredQuery = toLower(normalizedQuery)
	local exactPlayer = nil
	local partialMatches = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local name = toLower(player.Name)
		local displayName = toLower(player.DisplayName)

		if name == loweredQuery or displayName == loweredQuery then
			exactPlayer = player
			break
		end

		if startsWith(name, loweredQuery) or startsWith(displayName, loweredQuery) then
			partialMatches[#partialMatches + 1] = player
		end
	end

	if exactPlayer then
		return true, exactPlayer
	end

	if #partialMatches == 1 then
		return true, partialMatches[1]
	end

	if #partialMatches > 1 then
		return false, nil, "Multiple players match"
	end

	return false, nil, "Unspecified player"
end

local function validateInt(raw, spec)
	local value = tonumber(raw)
	if not value or value % 1 ~= 0 then
		if spec.min then
			return false, nil, ("Please enter a valid integer >= %d"):format(spec.min)
		end
		return false, nil, "Please enter a valid integer"
	end

	if spec.min and value < spec.min then
		return false, nil, ("Please enter a valid integer >= %d"):format(spec.min)
	end

	if spec.max and value > spec.max then
		return false, nil, ("Please enter a valid integer <= %d"):format(spec.max)
	end

	return true, value
end

local function validateNumber(raw, spec)
	local value = tonumber(raw)
	if not value then
		if spec.min then
			return false, nil, ("Please enter a valid number >= %.1f"):format(spec.min)
		end
		return false, nil, "Please enter a valid number"
	end

	if spec.min and value < spec.min then
		return false, nil, ("Please enter a valid number >= %.1f"):format(spec.min)
	end

	if spec.max and value > spec.max then
		return false, nil, ("Please enter a valid number <= %.1f"):format(spec.max)
	end

	return true, value
end

local function validateParam(raw)
	local value = trim(raw)
	if value == "" then
		return false, nil, "Missing parameter"
	end

	return true, value
end

local function getSpecKind(spec)
	return toLower(type(spec.kind) == "string" and spec.kind or "param")
end

local function validateArgument(spec, raw)
	local kind = getSpecKind(spec)

	if raw == "" and spec.required == false then
		return true, nil
	end

	if kind == "int" then
		return validateInt(raw, spec)
	end

	if kind == "number" then
		return validateNumber(raw, spec)
	end

	if kind == "player" then
		return resolvePlayer(raw)
	end

	if kind == "key" then
		return resolveHotkeyName(raw)
	end

	return validateParam(raw)
end

local function getCommandTag(spec)
	return spec.tag or spec.kind or spec.name or "arg"
end

local function getTagColor(spec)
	return TYPE_COLORS[getSpecKind(spec)] or Color3.fromRGB(200, 200, 200)
end

local function getAliasesText(command)
	if not command.aliases or #command.aliases == 0 then
		return ""
	end

	return " [" .. table.concat(command.aliases, ", ") .. "]"
end

local function buildCommandTitle(command)
	local parts = { escapeRichText(command.name) }

	for _, spec in ipairs(command.syntax or {}) do
		local token = "&lt;" .. escapeRichText(getCommandTag(spec)) .. "&gt;"
		local color = colorToHex(getTagColor(spec))
		parts[#parts + 1] = string.format('<font color="%s">%s</font>', color, token)
	end

	return table.concat(parts, " ")
end

local function buildPlainCommandTitle(command)
	local parts = { command.name }

	for _, spec in ipairs(command.syntax or {}) do
		parts[#parts + 1] = "<" .. getCommandTag(spec) .. ">"
	end

	return table.concat(parts, " ")
end

local function buildCommandDescription(command)
	return (command.description or "") .. getAliasesText(command)
end

local function buildCommandCaption(command)
	local caption = trim(tostring(command.caption or ""))
	if caption ~= "" then
		return caption
	end

	return buildCommandDescription(command)
end

local function cloneSyntax(syntax)
	local cloned = {}

	for _, spec in ipairs(syntax or {}) do
		cloned[#cloned + 1] = {
			name = trim(spec.name or ""),
			kind = spec.kind or "param",
			tag = spec.tag,
			required = spec.required,
			min = spec.min,
			max = spec.max,
			caption = spec.caption or spec.description,
			suggestions = spec.suggestions or spec.autocomplete or spec.values,
		}
	end

	return cloned
end

local function normalizeAliases(aliases)
	local normalizedAliases = {}
	local seen = {}

	for _, alias in ipairs(aliases or {}) do
		local value = trim(alias)
		local lowered = toLower(value)
		if value ~= "" and not seen[lowered] then
			seen[lowered] = true
			normalizedAliases[#normalizedAliases + 1] = value
		end
	end

	return normalizedAliases
end

local function sanitizeCommandDefinition(rawCommand)
	if type(rawCommand) ~= "table" then
		return nil, "Command must be a table"
	end

	local name = trim(rawCommand.name)
	if name == "" then
		return nil, "Command name is required"
	end

	if type(rawCommand.execute) ~= "function" then
		return nil, ("Command %q is missing an execute function"):format(name)
	end

	return {
		name = name,
		aliases = normalizeAliases(rawCommand.aliases),
		description = rawCommand.description or "",
		caption = rawCommand.caption or rawCommand.Caption,
		syntax = cloneSyntax(rawCommand.syntax),
		execute = rawCommand.execute,
	}
end

local function buildCommandIndexes(commands)
	local byName = {}
	local byAlias = {}

	for _, command in ipairs(commands) do
		local loweredName = toLower(command.name)
		if byName[loweredName] then
			return nil, nil, ("Duplicate command name %q"):format(command.name)
		end

		byName[loweredName] = command

		for _, alias in ipairs(command.aliases or {}) do
			local loweredAlias = toLower(alias)
			if byName[loweredAlias] or byAlias[loweredAlias] then
				return nil, nil, ("Duplicate command alias %q"):format(alias)
			end

			byAlias[loweredAlias] = command
		end
	end

	return byName, byAlias
end

local function findCommand(byName, byAlias, query)
	local lowered = toLower(query or "")
	return byName[lowered] or byAlias[lowered]
end

local function collectCommands(commands, query)
	local loweredQuery = toLower(query or "")
	local matches = {}

	for _, command in ipairs(commands) do
		if loweredQuery == "" or startsWith(toLower(command.name), loweredQuery) then
			matches[#matches + 1] = command
		else
			for _, alias in ipairs(command.aliases or {}) do
				if startsWith(toLower(alias), loweredQuery) then
					matches[#matches + 1] = command
					break
				end
			end
		end
	end

	return sortCommands(matches)
end

local function buildReadyState(command)
	return {
		kind = "ready",
		title = buildPlainCommandTitle(command),
		description = READY_DESCRIPTION,
		command = command,
	}
end

local function getArgumentState(command, text)
	local tokens, trailingSpace = tokenize(text)
	local syntax = command.syntax or {}
	local suppliedCount = math.max(0, #tokens - 1)

	if #syntax == 0 then
		return buildReadyState(command)
	end

	if suppliedCount > #syntax then
		return {
			kind = "error",
			title = command.name,
			description = "Too many arguments",
			errorKey = "too-many-arguments",
		}
	end

	local currentIndex = trailingSpace and (suppliedCount + 1) or suppliedCount

	for argumentIndex = 1, suppliedCount do
		local spec = syntax[argumentIndex]
		local rawArgument = tokens[argumentIndex + 1] or ""

		if getSpecKind(spec) == "player" and argumentIndex == currentIndex and not trailingSpace then
			local players = listPlayers(rawArgument)
			if #players == 0 then
				return {
					kind = "error",
					title = command.name,
					description = "Unspecified player",
					errorKey = "player-not-found",
				}
			end

			return {
				kind = "players",
				command = command,
				players = players,
			}
		end

		local ok, _, reason = validateArgument(spec, rawArgument)
		if not ok then
			return {
				kind = "error",
				title = command.name,
				description = reason or "Invalid syntax",
				errorKey = "invalid-argument:" .. tostring(spec.name or argumentIndex),
			}
		end
	end

	if trailingSpace and suppliedCount == #syntax then
		return buildReadyState(command)
	end

	if currentIndex >= 1 and currentIndex <= #syntax then
		local spec = syntax[currentIndex]
		local currentRaw = trailingSpace and "" or (tokens[currentIndex + 1] or "")

		if getSpecKind(spec) == "player" then
			local players = listPlayers(currentRaw)
			if #players == 0 and currentRaw ~= "" then
				return {
					kind = "error",
					title = command.name,
					description = "Unspecified player",
					errorKey = "player-not-found",
				}
			end

			return {
				kind = "players",
				command = command,
				players = players,
			}
		end

		local ok, _, reason = validateArgument(spec, currentRaw)
		if not ok then
			return {
				kind = "error",
				title = command.name,
				description = reason or "Invalid syntax",
				errorKey = "invalid-argument:" .. tostring(spec.name or currentIndex),
			}
		end

		if suppliedCount == #syntax then
			return buildReadyState(command)
		end
	end

	return {
		kind = "commands",
		commands = { command },
	}
end

local function analyzeAgainstCommands(text, commands, byName, byAlias)
	local trimmed = trimLeft(text or "")
	if startsWith(trimmed, "/") then
		trimmed = string.sub(trimmed, 2)
	end

	local tokens, trailingSpace = tokenize(trimmed)
	local commandToken = tokens[1] or ""

	if commandToken == "" then
		return {
			kind = "commands",
			commands = sortCommands(cloneArray(commands)),
		}
	end

	local exactCommand = findCommand(byName, byAlias, commandToken)
	local suggestions = collectCommands(commands, commandToken)

	if not exactCommand then
		if #tokens == 1 and not trailingSpace and #suggestions > 0 then
			return {
				kind = "commands",
				commands = suggestions,
			}
		end

		return {
			kind = "error",
			title = commandToken,
			description = "Unknown command",
			errorKey = "unknown-command",
		}
	end

	if #tokens == 1 and not trailingSpace then
		if #(exactCommand.syntax or {}) == 0 then
			return buildReadyState(exactCommand)
		end

		return {
			kind = "commands",
			commands = { exactCommand },
		}
	end

	return getArgumentState(exactCommand, trimmed)
end

local function parseForExecution(text, byName, byAlias)
	local trimmed = trimLeft(text or "")
	if startsWith(trimmed, "/") then
		trimmed = string.sub(trimmed, 2)
	end
	trimmed = trimRight(trimmed)

	local tokens = {}
	for token in string.gmatch(trimmed, "%S+") do
		tokens[#tokens + 1] = token
	end

	local commandToken = tokens[1]
	if not commandToken then
		return false, {
			title = "",
			description = "No command provided",
			errorKey = "no-command",
		}
	end

	local command = findCommand(byName, byAlias, commandToken)
	if not command then
		return false, {
			title = commandToken,
			description = "Unknown command",
			errorKey = "unknown-command",
		}
	end

	local syntax = command.syntax or {}
	local values = {}

	if (#tokens - 1) > #syntax then
		return false, {
			title = command.name,
			description = "Too many arguments",
			errorKey = "too-many-arguments",
		}
	end

	for index, spec in ipairs(syntax) do
		local rawArgument = tokens[index + 1] or ""
		local ok, value, reason = validateArgument(spec, rawArgument)
		if not ok then
			return false, {
				title = command.name,
				description = reason or "Invalid syntax",
				errorKey = "invalid-argument:" .. tostring(spec.name or index),
			}
		end

		values[spec.name] = value
	end

	return true, {
		command = command,
		values = values,
	}
end

local function buildSuggestionDefinitions(state)
	if state.kind == "commands" then
		local definitions = {}

		for _, command in ipairs(state.commands or {}) do
			definitions[#definitions + 1] = {
				Kind = "Command",
				Key = "command:" .. toLower(command.name),
				Title = buildCommandTitle(command),
				Description = buildCommandDescription(command),
				Caption = buildCommandCaption(command),
				RichText = true,
			}
		end

		return definitions
	end

	if state.kind == "players" then
		local definitions = {}

		for _, player in ipairs(state.players or {}) do
			definitions[#definitions + 1] = {
				Kind = "Player",
				Key = "player:" .. tostring(player.UserId),
				DisplayName = player.DisplayName,
				UserName = player.Name,
				Player = player,
				Caption = "@" .. player.Name,
			}
		end

		return definitions
	end

	if state.kind == "error" then
		return {
			{
				Kind = "Error",
				Key = "error:" .. tostring(state.errorKey or state.description or "generic"),
				Title = state.title,
				Description = state.description,
				Priority = 0,
				DisableAnimation = true,
			},
		}
	end

	if state.kind == "ready" then
		return {
			{
				Kind = "Ready",
				Key = "ready:" .. toLower(state.title or ""),
				Title = state.title,
				Description = state.description,
			},
		}
	end

	return {}
end

-- UI
local Matt = Instance.new("ScreenGui")
Matt.ClipToDeviceSafeArea = true
Matt.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension
Matt.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
Matt.Archivable = true
Matt.DisplayOrder = 0
Matt.Enabled = true
Matt.IgnoreGuiInset = true
Matt.Name = "Matt"
Matt.Parent = RunService:IsStudio() and PlayerGui or CoreGui
Matt.ResetOnSpawn = false
Matt.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Matt.AutoLocalize = true
Matt.RootLocalizationTable = nil
Matt.SelectionGroup = false

local UIScale = Instance.new("UIScale")
UIScale.Archivable = true
UIScale.Scale = 1
UIScale.Parent = Matt

local Canvas = Instance.new("Frame")
Canvas.SelectionImageObject = nil
Canvas.Archivable = true
Canvas.Active = false
Canvas.AnchorPoint = Vector2.new(0.5, 0.5)
Canvas.AutomaticSize = Enum.AutomaticSize.None
Canvas.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Canvas.BackgroundTransparency = 1
Canvas.BorderColor3 = Color3.fromRGB(0, 0, 0)
Canvas.BorderMode = Enum.BorderMode.Outline
Canvas.BorderSizePixel = 0
Canvas.Interactable = true
Canvas.LayoutOrder = 0
Canvas.Name = "Canvas"
Canvas.Parent = Matt
Canvas.Position = UDim2.fromScale(0.5, 0.5)
Canvas.Rotation = 0
Canvas.Size = UDim2.fromScale(1, 1)
Canvas.SizeConstraint = Enum.SizeConstraint.RelativeXY
Canvas.Style = Enum.FrameStyle.Custom
Canvas.Visible = true
Canvas.ZIndex = 0
Canvas.ClipsDescendants = false
Canvas.AutoLocalize = true
Canvas.RootLocalizationTable = nil
Canvas.NextSelectionDown = nil
Canvas.NextSelectionLeft = nil
Canvas.NextSelectionRight = nil
Canvas.NextSelectionUp = nil
Canvas.Selectable = false
Canvas.SelectionGroup = false
Canvas.SelectionOrder = 0

local CommandsMenu = Instance.new("Frame")
CommandsMenu.SelectionImageObject = nil
CommandsMenu.Archivable = true
CommandsMenu.Active = false
CommandsMenu.AnchorPoint = Vector2.new(0.5, 0.5)
CommandsMenu.AutomaticSize = Enum.AutomaticSize.Y
CommandsMenu.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
CommandsMenu.BackgroundTransparency = 0
CommandsMenu.BorderColor3 = Color3.fromRGB(0, 0, 0)
CommandsMenu.BorderMode = Enum.BorderMode.Outline
CommandsMenu.BorderSizePixel = 0
CommandsMenu.Interactable = true
CommandsMenu.LayoutOrder = 0
CommandsMenu.Name = "CommandsMenu"
CommandsMenu.Parent = Canvas
CommandsMenu.Position = UDim2.fromScale(0.5, 0.53)
CommandsMenu.Rotation = 0
CommandsMenu.Size = UDim2.fromScale(0.65, 0)
CommandsMenu.SizeConstraint = Enum.SizeConstraint.RelativeXY
CommandsMenu.Style = Enum.FrameStyle.Custom
CommandsMenu.Visible = true
CommandsMenu.ZIndex = 1
CommandsMenu.ClipsDescendants = false
CommandsMenu.AutoLocalize = true
CommandsMenu.RootLocalizationTable = nil
CommandsMenu.NextSelectionDown = nil
CommandsMenu.NextSelectionLeft = nil
CommandsMenu.NextSelectionRight = nil
CommandsMenu.NextSelectionUp = nil
CommandsMenu.Selectable = false
CommandsMenu.SelectionGroup = false
CommandsMenu.SelectionOrder = 0

local UICorner_v1 = Instance.new("UICorner")
UICorner_v1.CornerRadius = UDim.new(0, 14)
UICorner_v1.Archivable = true
UICorner_v1.Name = "UICorner"
UICorner_v1.Parent = CommandsMenu

local UIListLayout_v1 = Instance.new("UIListLayout")
UIListLayout_v1.Padding = UDim.new(0, 0)
UIListLayout_v1.Archivable = true
UIListLayout_v1.Name = "UIListLayout"
UIListLayout_v1.Parent = CommandsMenu
UIListLayout_v1.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_v1.Wraps = false
UIListLayout_v1.HorizontalAlignment = Enum.HorizontalAlignment.Left
UIListLayout_v1.HorizontalFlex = Enum.UIFlexAlignment.None
UIListLayout_v1.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
UIListLayout_v1.VerticalAlignment = Enum.VerticalAlignment.Top
UIListLayout_v1.VerticalFlex = Enum.UIFlexAlignment.None

local UISizeConstraint_v1 = Instance.new("UISizeConstraint")
UISizeConstraint_v1.Archivable = true
UISizeConstraint_v1.Name = "UISizeConstraint"
UISizeConstraint_v1.Parent = CommandsMenu
UISizeConstraint_v1.MaxSize = Vector2.new(870, 520)
UISizeConstraint_v1.MinSize = Vector2.new(320, 0)

local UIStroke = Instance.new("UIStroke")
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.BorderOffset = UDim.new(0, 0)
UIStroke.BorderStrokePosition = Enum.BorderStrokePosition.Outer
UIStroke.Color = Color3.fromRGB(0, 0, 0)
UIStroke.LineJoinMode = Enum.LineJoinMode.Round
UIStroke.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
UIStroke.Thickness = 2
UIStroke.Transparency = 0.75
UIStroke.ZIndex = 1
UIStroke.Archivable = true
UIStroke.Enabled = true
UIStroke.Name = "UIStroke"
UIStroke.Parent = CommandsMenu

local CommandBar = Instance.new("Frame")
CommandBar.SelectionImageObject = nil
CommandBar.Archivable = true
CommandBar.Active = false
CommandBar.AnchorPoint = Vector2.new(0.5, 0)
CommandBar.AutomaticSize = Enum.AutomaticSize.None
CommandBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CommandBar.BackgroundTransparency = 1
CommandBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
CommandBar.BorderMode = Enum.BorderMode.Outline
CommandBar.BorderSizePixel = 0
CommandBar.Interactable = true
CommandBar.LayoutOrder = 0
CommandBar.Name = "CommandBar"
CommandBar.Parent = CommandsMenu
CommandBar.Position = UDim2.fromScale(0.5, 0)
CommandBar.Rotation = 0
CommandBar.Size = UDim2.new(1, 0, 0, 64)
CommandBar.SizeConstraint = Enum.SizeConstraint.RelativeXY
CommandBar.Style = Enum.FrameStyle.Custom
CommandBar.Visible = true
CommandBar.ZIndex = 2
CommandBar.ClipsDescendants = false
CommandBar.AutoLocalize = true
CommandBar.RootLocalizationTable = nil
CommandBar.NextSelectionDown = nil
CommandBar.NextSelectionLeft = nil
CommandBar.NextSelectionRight = nil
CommandBar.NextSelectionUp = nil
CommandBar.Selectable = false
CommandBar.SelectionGroup = false
CommandBar.SelectionOrder = 0

local Content = Instance.new("Frame")
Content.SelectionImageObject = nil
Content.Archivable = true
Content.Active = false
Content.AnchorPoint = Vector2.new(0, 0)
Content.AutomaticSize = Enum.AutomaticSize.None
Content.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Content.BackgroundTransparency = 1
Content.BorderColor3 = Color3.fromRGB(0, 0, 0)
Content.BorderMode = Enum.BorderMode.Outline
Content.BorderSizePixel = 0
Content.Interactable = true
Content.LayoutOrder = 0
Content.Name = "Content"
Content.Parent = CommandBar
Content.Position = UDim2.fromScale(0, 0)
Content.Rotation = 0
Content.Size = UDim2.fromScale(1, 1)
Content.SizeConstraint = Enum.SizeConstraint.RelativeXY
Content.Style = Enum.FrameStyle.Custom
Content.Visible = true
Content.ZIndex = 2
Content.ClipsDescendants = true
Content.AutoLocalize = true
Content.RootLocalizationTable = nil
Content.NextSelectionDown = nil
Content.NextSelectionLeft = nil
Content.NextSelectionRight = nil
Content.NextSelectionUp = nil
Content.Selectable = false
Content.SelectionGroup = false
Content.SelectionOrder = 0

local UIPadding_v1 = Instance.new("UIPadding")
UIPadding_v1.Archivable = true
UIPadding_v1.Name = "UIPadding"
UIPadding_v1.Parent = Content
UIPadding_v1.PaddingBottom = UDim.new(0, 12)
UIPadding_v1.PaddingLeft = UDim.new(0, 16)
UIPadding_v1.PaddingRight = UDim.new(0, 16)
UIPadding_v1.PaddingTop = UDim.new(0, 12)

local UIListLayout_v2 = Instance.new("UIListLayout")
UIListLayout_v2.Padding = UDim.new(0, 12)
UIListLayout_v2.Archivable = true
UIListLayout_v2.Name = "UIListLayout"
UIListLayout_v2.Parent = Content
UIListLayout_v2.FillDirection = Enum.FillDirection.Horizontal
UIListLayout_v2.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_v2.Wraps = false
UIListLayout_v2.HorizontalAlignment = Enum.HorizontalAlignment.Left
UIListLayout_v2.HorizontalFlex = Enum.UIFlexAlignment.None
UIListLayout_v2.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
UIListLayout_v2.VerticalAlignment = Enum.VerticalAlignment.Center
UIListLayout_v2.VerticalFlex = Enum.UIFlexAlignment.None

local Input = Instance.new("TextBox")
Input.SelectionImageObject = nil
Input.Archivable = true
Input.Active = false
Input.AnchorPoint = Vector2.new(0, 0)
Input.AutomaticSize = Enum.AutomaticSize.None
Input.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Input.BackgroundTransparency = 1
Input.BorderColor3 = Color3.fromRGB(0, 0, 0)
Input.BorderMode = Enum.BorderMode.Outline
Input.BorderSizePixel = 0
Input.ClearTextOnFocus = false
Input.CursorPosition = 1
Input.Interactable = true
Input.LayoutOrder = 1
Input.MultiLine = false
Input.Name = "Input"
Input.Parent = Content
Input.Position = UDim2.new(0, 52, 0, 12)
Input.Rotation = 0
Input.SelectionStart = -1
Input.ShowNativeInput = true
Input.Size = UDim2.fromScale(0, 1)
Input.SizeConstraint = Enum.SizeConstraint.RelativeXY
Input.TextEditable = true
Input.Visible = true
Input.ZIndex = 3
Input.ClipsDescendants = false
Input.AutoLocalize = true
Input.RootLocalizationTable = nil
Input.NextSelectionDown = nil
Input.NextSelectionLeft = nil
Input.NextSelectionRight = nil
Input.NextSelectionUp = nil
Input.Selectable = false
Input.SelectionGroup = false
Input.SelectionOrder = 0
Input.Font = Enum.Font.GothamMedium
Input.LineHeight = 1
Input.MaxVisibleGraphemes = -1
Input.PlaceholderColor3 = Color3.fromRGB(92, 92, 92)
Input.PlaceholderText = "Type a command..."
Input.RichText = false
Input.Text = ""
Input.TextColor3 = Color3.fromRGB(160, 160, 160)
Input.TextDirection = Enum.TextDirection.Auto
Input.TextScaled = false
Input.TextSize = 14
Input.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
Input.TextStrokeTransparency = 1
Input.TextTransparency = 0
Input.TextTruncate = Enum.TextTruncate.AtEnd
Input.TextWrapped = false
Input.TextXAlignment = Enum.TextXAlignment.Left
Input.TextYAlignment = Enum.TextYAlignment.Center

local UIFlexItem = Instance.new("UIFlexItem")
UIFlexItem.FlexMode = Enum.UIFlexMode.Grow
UIFlexItem.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
UIFlexItem.Archivable = true
UIFlexItem.Name = "UIFlexItem"
UIFlexItem.Parent = Input

local Icon = Instance.new("TextLabel")
Icon.SelectionImageObject = nil
Icon.Archivable = true
Icon.Active = false
Icon.AnchorPoint = Vector2.new(0, 0)
Icon.AutomaticSize = Enum.AutomaticSize.None
Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Icon.BackgroundTransparency = 1
Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
Icon.BorderMode = Enum.BorderMode.Outline
Icon.BorderSizePixel = 0
Icon.Interactable = false
Icon.LayoutOrder = 0
Icon.Name = "Icon"
Icon.Parent = Content
Icon.Position = UDim2.fromScale(0, 0)
Icon.Rotation = 0
Icon.Size = UDim2.fromOffset(24, 24)
Icon.SizeConstraint = Enum.SizeConstraint.RelativeXY
Icon.Visible = true
Icon.ZIndex = 3
Icon.ClipsDescendants = false
Icon.AutoLocalize = true
Icon.RootLocalizationTable = nil
Icon.NextSelectionDown = nil
Icon.NextSelectionLeft = nil
Icon.NextSelectionRight = nil
Icon.NextSelectionUp = nil
Icon.Selectable = false
Icon.SelectionGroup = false
Icon.SelectionOrder = 0
Icon.Font = Enum.Font.GothamMedium
Icon.LineHeight = 1
Icon.MaxVisibleGraphemes = -1
Icon.RichText = false
Icon.Text = ">"
Icon.TextColor3 = Color3.fromRGB(120, 120, 120)
Icon.TextDirection = Enum.TextDirection.Auto
Icon.TextScaled = false
Icon.TextSize = 22
Icon.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
Icon.TextStrokeTransparency = 1
Icon.TextTransparency = 0
Icon.TextTruncate = Enum.TextTruncate.None
Icon.TextWrapped = false
Icon.TextXAlignment = Enum.TextXAlignment.Center
Icon.TextYAlignment = Enum.TextYAlignment.Center

local Divider = Instance.new("Frame")
Divider.SelectionImageObject = nil
Divider.Archivable = true
Divider.Active = false
Divider.AnchorPoint = Vector2.new(0, 1)
Divider.AutomaticSize = Enum.AutomaticSize.None
Divider.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
Divider.BackgroundTransparency = 0.35
Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
Divider.BorderMode = Enum.BorderMode.Outline
Divider.BorderSizePixel = 0
Divider.Interactable = false
Divider.LayoutOrder = 0
Divider.Name = "Divider"
Divider.Parent = CommandBar
Divider.Position = UDim2.fromScale(0, 1)
Divider.Rotation = 0
Divider.Size = UDim2.new(1, 0, 0, 3)
Divider.SizeConstraint = Enum.SizeConstraint.RelativeXY
Divider.Style = Enum.FrameStyle.Custom
Divider.Visible = true
Divider.ZIndex = 3
Divider.ClipsDescendants = false
Divider.AutoLocalize = true
Divider.RootLocalizationTable = nil
Divider.NextSelectionDown = nil
Divider.NextSelectionLeft = nil
Divider.NextSelectionRight = nil
Divider.NextSelectionUp = nil
Divider.Selectable = false
Divider.SelectionGroup = false
Divider.SelectionOrder = 0

local AutoComplete = Instance.new("Frame")
AutoComplete.SelectionImageObject = nil
AutoComplete.Archivable = true
AutoComplete.Active = false
AutoComplete.AnchorPoint = Vector2.new(0, 1)
AutoComplete.AutomaticSize = Enum.AutomaticSize.XY
AutoComplete.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
AutoComplete.BackgroundTransparency = 0.2
AutoComplete.BorderColor3 = Color3.fromRGB(0, 0, 0)
AutoComplete.BorderMode = Enum.BorderMode.Outline
AutoComplete.BorderSizePixel = 0
AutoComplete.Interactable = true
AutoComplete.LayoutOrder = 0
AutoComplete.Name = "AutoComplete"
AutoComplete.Parent = CommandBar
AutoComplete.Position = UDim2.fromOffset(58, -4)
AutoComplete.Rotation = 0
AutoComplete.Size = UDim2.fromOffset(0, 0)
AutoComplete.SizeConstraint = Enum.SizeConstraint.RelativeXY
AutoComplete.Style = Enum.FrameStyle.Custom
AutoComplete.Visible = false
AutoComplete.ZIndex = 20
AutoComplete.ClipsDescendants = true
AutoComplete.AutoLocalize = true
AutoComplete.RootLocalizationTable = nil
AutoComplete.NextSelectionDown = nil
AutoComplete.NextSelectionLeft = nil
AutoComplete.NextSelectionRight = nil
AutoComplete.NextSelectionUp = nil
AutoComplete.Selectable = false
AutoComplete.SelectionGroup = false
AutoComplete.SelectionOrder = 0

local AutoCompleteCorner = Instance.new("UICorner")
AutoCompleteCorner.CornerRadius = UDim.new(0, 4)
AutoCompleteCorner.Archivable = true
AutoCompleteCorner.Name = "UICorner"
AutoCompleteCorner.Parent = AutoComplete

local AutoCompleteLayout = Instance.new("UIListLayout")
AutoCompleteLayout.Padding = UDim.new(0, 8)
AutoCompleteLayout.Archivable = true
AutoCompleteLayout.Name = "UIListLayout"
AutoCompleteLayout.Parent = AutoComplete
AutoCompleteLayout.FillDirection = Enum.FillDirection.Vertical
AutoCompleteLayout.SortOrder = Enum.SortOrder.LayoutOrder
AutoCompleteLayout.Wraps = false
AutoCompleteLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
AutoCompleteLayout.HorizontalFlex = Enum.UIFlexAlignment.None
AutoCompleteLayout.ItemLineAlignment = Enum.ItemLineAlignment.Center
AutoCompleteLayout.VerticalAlignment = Enum.VerticalAlignment.Center
AutoCompleteLayout.VerticalFlex = Enum.UIFlexAlignment.None

local AutoCompletePadding = Instance.new("UIPadding")
AutoCompletePadding.Archivable = true
AutoCompletePadding.Name = "UIPadding"
AutoCompletePadding.Parent = AutoComplete
AutoCompletePadding.PaddingBottom = UDim.new(0, 8)
AutoCompletePadding.PaddingLeft = UDim.new(0, 8)
AutoCompletePadding.PaddingRight = UDim.new(0, 8)
AutoCompletePadding.PaddingTop = UDim.new(0, 8)

local AutoCompleteSizeConstraint = Instance.new("UISizeConstraint")
AutoCompleteSizeConstraint.Archivable = true
AutoCompleteSizeConstraint.Name = "UISizeConstraint"
AutoCompleteSizeConstraint.Parent = AutoComplete
AutoCompleteSizeConstraint.MaxSize = Vector2.new(200, 180)
AutoCompleteSizeConstraint.MinSize = Vector2.new(0, 30)

local AutoCompleteStroke = Instance.new("UIStroke")
AutoCompleteStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
AutoCompleteStroke.BorderOffset = UDim.new(0, 0)
AutoCompleteStroke.BorderStrokePosition = Enum.BorderStrokePosition.Outer
AutoCompleteStroke.Color = Color3.fromRGB(100, 100, 100)
AutoCompleteStroke.LineJoinMode = Enum.LineJoinMode.Round
AutoCompleteStroke.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
AutoCompleteStroke.Thickness = 1.5
AutoCompleteStroke.Transparency = 0.75
AutoCompleteStroke.ZIndex = 5
AutoCompleteStroke.Archivable = true
AutoCompleteStroke.Enabled = true
AutoCompleteStroke.Name = "UIStroke"
AutoCompleteStroke.Parent = AutoComplete

local CommandsList = Instance.new("ScrollingFrame")
CommandsList.SelectionImageObject = nil
CommandsList.Archivable = true
CommandsList.Active = true
CommandsList.AnchorPoint = Vector2.new(0, 0)
CommandsList.AutomaticSize = Enum.AutomaticSize.Y
CommandsList.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CommandsList.BackgroundTransparency = 1
CommandsList.BorderColor3 = Color3.fromRGB(0, 0, 0)
CommandsList.BorderMode = Enum.BorderMode.Outline
CommandsList.BorderSizePixel = 0
CommandsList.Interactable = true
CommandsList.LayoutOrder = 0
CommandsList.Name = "CommandsList"
CommandsList.Parent = CommandsMenu
CommandsList.Position = UDim2.fromOffset(0, 0)
CommandsList.Rotation = 0
CommandsList.Size = UDim2.fromScale(1, 0)
CommandsList.SizeConstraint = Enum.SizeConstraint.RelativeXY
CommandsList.Visible = true
CommandsList.ZIndex = 2
CommandsList.ClipsDescendants = true
CommandsList.AutoLocalize = true
CommandsList.RootLocalizationTable = nil
CommandsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
CommandsList.BottomImage = "rbxasset://textures/ui/Scroll/scroll-bottom.png"
CommandsList.CanvasPosition = Vector2.new(0, 0)
CommandsList.CanvasSize = UDim2.fromScale(0, 0)
CommandsList.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
CommandsList.HorizontalScrollBarInset = Enum.ScrollBarInset.None
CommandsList.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
CommandsList.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
CommandsList.ScrollBarImageTransparency = 0
CommandsList.ScrollBarThickness = 6
CommandsList.ScrollingDirection = Enum.ScrollingDirection.Y
CommandsList.TopImage = "rbxasset://textures/ui/Scroll/scroll-top.png"
CommandsList.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
CommandsList.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
CommandsList.NextSelectionDown = nil
CommandsList.NextSelectionLeft = nil
CommandsList.NextSelectionRight = nil
CommandsList.NextSelectionUp = nil
CommandsList.Selectable = true
CommandsList.SelectionBehaviorDown = Enum.SelectionBehavior.Escape
CommandsList.SelectionBehaviorLeft = Enum.SelectionBehavior.Escape
CommandsList.SelectionBehaviorRight = Enum.SelectionBehavior.Escape
CommandsList.SelectionBehaviorUp = Enum.SelectionBehavior.Escape
CommandsList.SelectionGroup = true
CommandsList.SelectionOrder = 0

local Examples = Instance.new("Folder")
Examples.Archivable = true
Examples.Name = "Templates"
Examples.Parent = CommandsList

local CommandSugestion = Instance.new("Frame")
CommandSugestion.SelectionImageObject = nil
CommandSugestion.Archivable = true
CommandSugestion.Active = false
CommandSugestion.AnchorPoint = Vector2.new(0, 0)
CommandSugestion.AutomaticSize = Enum.AutomaticSize.Y
CommandSugestion.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CommandSugestion.BackgroundTransparency = 1
CommandSugestion.BorderColor3 = Color3.fromRGB(0, 0, 0)
CommandSugestion.BorderMode = Enum.BorderMode.Outline
CommandSugestion.BorderSizePixel = 0
CommandSugestion.LayoutOrder = 0
CommandSugestion.Name = "CommandSugestion"
CommandSugestion.Parent = Examples
CommandSugestion.Position = UDim2.fromOffset(0, 0)
CommandSugestion.Rotation = 0
CommandSugestion.Size = UDim2.fromScale(1, 0)
CommandSugestion.SizeConstraint = Enum.SizeConstraint.RelativeXY
CommandSugestion.Style = Enum.FrameStyle.Custom
CommandSugestion.Visible = false
CommandSugestion.ZIndex = 3
CommandSugestion.ClipsDescendants = false
CommandSugestion.AutoLocalize = true
CommandSugestion.RootLocalizationTable = nil
CommandSugestion.NextSelectionDown = nil
CommandSugestion.NextSelectionLeft = nil
CommandSugestion.NextSelectionRight = nil
CommandSugestion.NextSelectionUp = nil
CommandSugestion.Selectable = false
CommandSugestion.SelectionGroup = false
CommandSugestion.SelectionOrder = 0

local UIListLayout_v3 = Instance.new("UIListLayout")
UIListLayout_v3.Padding = UDim.new(0, 6)
UIListLayout_v3.Archivable = true
UIListLayout_v3.Name = "UIListLayout"
UIListLayout_v3.Parent = CommandSugestion
UIListLayout_v3.FillDirection = Enum.FillDirection.Vertical
UIListLayout_v3.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_v3.Wraps = false
UIListLayout_v3.HorizontalAlignment = Enum.HorizontalAlignment.Left
UIListLayout_v3.HorizontalFlex = Enum.UIFlexAlignment.None
UIListLayout_v3.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
UIListLayout_v3.VerticalAlignment = Enum.VerticalAlignment.Top
UIListLayout_v3.VerticalFlex = Enum.UIFlexAlignment.None

local Title = Instance.new("TextLabel")
Title.SelectionImageObject = nil
Title.Archivable = true
Title.Active = false
Title.AnchorPoint = Vector2.new(0, 0)
Title.AutomaticSize = Enum.AutomaticSize.Y
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
Title.BorderMode = Enum.BorderMode.Outline
Title.BorderSizePixel = 0
Title.Interactable = true
Title.LayoutOrder = 0
Title.Name = "Title"
Title.Parent = CommandSugestion
Title.Position = UDim2.fromOffset(0, 0)
Title.Rotation = 0
Title.Size = UDim2.fromScale(1, 0)
Title.SizeConstraint = Enum.SizeConstraint.RelativeXY
Title.Visible = true
Title.ZIndex = 4
Title.ClipsDescendants = false
Title.AutoLocalize = true
Title.RootLocalizationTable = nil
Title.NextSelectionDown = nil
Title.NextSelectionLeft = nil
Title.NextSelectionRight = nil
Title.NextSelectionUp = nil
Title.Selectable = false
Title.SelectionGroup = false
Title.SelectionOrder = 0
Title.Font = Enum.Font.GothamBold
Title.LineHeight = 1
Title.MaxVisibleGraphemes = -1
Title.RichText = false
Title.Text = ""
Title.TextColor3 = Color3.fromRGB(235, 235, 235)
Title.TextDirection = Enum.TextDirection.Auto
Title.TextScaled = false
Title.TextSize = 22
Title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
Title.TextStrokeTransparency = 1
Title.TextTransparency = 0
Title.TextTruncate = Enum.TextTruncate.AtEnd
Title.TextWrapped = true
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextYAlignment = Enum.TextYAlignment.Top

local Description = Instance.new("TextLabel")
Description.SelectionImageObject = nil
Description.Archivable = true
Description.Active = false
Description.AnchorPoint = Vector2.new(0, 0)
Description.AutomaticSize = Enum.AutomaticSize.Y
Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Description.BackgroundTransparency = 1
Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
Description.BorderMode = Enum.BorderMode.Outline
Description.BorderSizePixel = 0
Description.Interactable = true
Description.LayoutOrder = 0
Description.Name = "Description"
Description.Parent = CommandSugestion
Description.Position = UDim2.fromOffset(0, 0)
Description.Rotation = 0
Description.Size = UDim2.fromScale(1, 0)
Description.SizeConstraint = Enum.SizeConstraint.RelativeXY
Description.Visible = true
Description.ZIndex = 4
Description.ClipsDescendants = false
Description.AutoLocalize = true
Description.RootLocalizationTable = nil
Description.NextSelectionDown = nil
Description.NextSelectionLeft = nil
Description.NextSelectionRight = nil
Description.NextSelectionUp = nil
Description.Selectable = false
Description.SelectionGroup = false
Description.SelectionOrder = 0
Description.Font = Enum.Font.GothamMedium
Description.LineHeight = 1
Description.MaxVisibleGraphemes = -1
Description.RichText = false
Description.Text = ""
Description.TextColor3 = Color3.fromRGB(120, 120, 120)
Description.TextDirection = Enum.TextDirection.Auto
Description.TextScaled = false
Description.TextSize = 16
Description.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
Description.TextStrokeTransparency = 1
Description.TextTransparency = 0.2
Description.TextTruncate = Enum.TextTruncate.None
Description.TextWrapped = true
Description.TextXAlignment = Enum.TextXAlignment.Left
Description.TextYAlignment = Enum.TextYAlignment.Top

local PlayerSuggestion = Instance.new("Frame")
PlayerSuggestion.SelectionImageObject = nil
PlayerSuggestion.Archivable = true
PlayerSuggestion.Active = false
PlayerSuggestion.AnchorPoint = Vector2.new(0, 0)
PlayerSuggestion.AutomaticSize = Enum.AutomaticSize.Y
PlayerSuggestion.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PlayerSuggestion.BackgroundTransparency = 1
PlayerSuggestion.BorderColor3 = Color3.fromRGB(0, 0, 0)
PlayerSuggestion.BorderMode = Enum.BorderMode.Outline
PlayerSuggestion.BorderSizePixel = 0
PlayerSuggestion.LayoutOrder = 0
PlayerSuggestion.Name = "PlayerSuggestion"
PlayerSuggestion.Parent = Examples
PlayerSuggestion.Position = UDim2.fromOffset(0, 0)
PlayerSuggestion.Rotation = 0
PlayerSuggestion.Size = UDim2.fromScale(1, 0)
PlayerSuggestion.SizeConstraint = Enum.SizeConstraint.RelativeXY
PlayerSuggestion.Style = Enum.FrameStyle.Custom
PlayerSuggestion.Visible = false
PlayerSuggestion.ZIndex = 3
PlayerSuggestion.ClipsDescendants = false
PlayerSuggestion.AutoLocalize = true
PlayerSuggestion.RootLocalizationTable = nil
PlayerSuggestion.NextSelectionDown = nil
PlayerSuggestion.NextSelectionLeft = nil
PlayerSuggestion.NextSelectionRight = nil
PlayerSuggestion.NextSelectionUp = nil
PlayerSuggestion.Selectable = false
PlayerSuggestion.SelectionGroup = false
PlayerSuggestion.SelectionOrder = 0

local UIListLayout_v4 = Instance.new("UIListLayout")
UIListLayout_v4.Padding = UDim.new(0, 12)
UIListLayout_v4.Archivable = true
UIListLayout_v4.Name = "UIListLayout"
UIListLayout_v4.Parent = PlayerSuggestion
UIListLayout_v4.FillDirection = Enum.FillDirection.Horizontal
UIListLayout_v4.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_v4.Wraps = false
UIListLayout_v4.HorizontalAlignment = Enum.HorizontalAlignment.Left
UIListLayout_v4.HorizontalFlex = Enum.UIFlexAlignment.None
UIListLayout_v4.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
UIListLayout_v4.VerticalAlignment = Enum.VerticalAlignment.Center
UIListLayout_v4.VerticalFlex = Enum.UIFlexAlignment.None

local UISizeConstraint_v2 = Instance.new("UISizeConstraint")
UISizeConstraint_v2.Archivable = true
UISizeConstraint_v2.Name = "UISizeConstraint"
UISizeConstraint_v2.Parent = PlayerSuggestion
UISizeConstraint_v2.MaxSize = Vector2.new(0, 0)
UISizeConstraint_v2.MinSize = Vector2.new(0, 56)

local LabelsContainer = Instance.new("Frame")
LabelsContainer.SelectionImageObject = nil
LabelsContainer.Archivable = true
LabelsContainer.Active = false
LabelsContainer.AnchorPoint = Vector2.new(0, 0)
LabelsContainer.AutomaticSize = Enum.AutomaticSize.Y
LabelsContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
LabelsContainer.BackgroundTransparency = 1
LabelsContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
LabelsContainer.BorderMode = Enum.BorderMode.Outline
LabelsContainer.BorderSizePixel = 0
LabelsContainer.Interactable = true
LabelsContainer.LayoutOrder = 0
LabelsContainer.Name = "LabelsContainer"
LabelsContainer.Parent = PlayerSuggestion
LabelsContainer.Position = UDim2.fromOffset(0, 0)
LabelsContainer.Rotation = 0
LabelsContainer.Size = UDim2.new(1, -52, 0, 0)
LabelsContainer.SizeConstraint = Enum.SizeConstraint.RelativeXY
LabelsContainer.Style = Enum.FrameStyle.Custom
LabelsContainer.Visible = true
LabelsContainer.ZIndex = 5
LabelsContainer.ClipsDescendants = false
LabelsContainer.AutoLocalize = true
LabelsContainer.RootLocalizationTable = nil
LabelsContainer.NextSelectionDown = nil
LabelsContainer.NextSelectionLeft = nil
LabelsContainer.NextSelectionRight = nil
LabelsContainer.NextSelectionUp = nil
LabelsContainer.Selectable = false
LabelsContainer.SelectionGroup = false
LabelsContainer.SelectionOrder = 0

local UIListLayout_v5 = Instance.new("UIListLayout")
UIListLayout_v5.Padding = UDim.new(0, 2)
UIListLayout_v5.Archivable = true
UIListLayout_v5.Name = "UIListLayout"
UIListLayout_v5.Parent = LabelsContainer
UIListLayout_v5.FillDirection = Enum.FillDirection.Vertical
UIListLayout_v5.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_v5.Wraps = false
UIListLayout_v5.HorizontalAlignment = Enum.HorizontalAlignment.Left
UIListLayout_v5.HorizontalFlex = Enum.UIFlexAlignment.None
UIListLayout_v5.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
UIListLayout_v5.VerticalAlignment = Enum.VerticalAlignment.Center
UIListLayout_v5.VerticalFlex = Enum.UIFlexAlignment.None

local DisplayName = Instance.new("TextLabel")
DisplayName.SelectionImageObject = nil
DisplayName.Archivable = true
DisplayName.Active = false
DisplayName.AnchorPoint = Vector2.new(0, 0)
DisplayName.AutomaticSize = Enum.AutomaticSize.Y
DisplayName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DisplayName.BackgroundTransparency = 1
DisplayName.BorderColor3 = Color3.fromRGB(0, 0, 0)
DisplayName.BorderMode = Enum.BorderMode.Outline
DisplayName.BorderSizePixel = 0
DisplayName.Interactable = true
DisplayName.LayoutOrder = 0
DisplayName.Name = "DisplayName"
DisplayName.Parent = LabelsContainer
DisplayName.Position = UDim2.fromOffset(0, 0)
DisplayName.Rotation = 0
DisplayName.Size = UDim2.fromScale(1, 0)
DisplayName.SizeConstraint = Enum.SizeConstraint.RelativeXY
DisplayName.Visible = true
DisplayName.ZIndex = 6
DisplayName.ClipsDescendants = false
DisplayName.AutoLocalize = true
DisplayName.RootLocalizationTable = nil
DisplayName.NextSelectionDown = nil
DisplayName.NextSelectionLeft = nil
DisplayName.NextSelectionRight = nil
DisplayName.NextSelectionUp = nil
DisplayName.Selectable = false
DisplayName.SelectionGroup = false
DisplayName.SelectionOrder = 0
DisplayName.Font = Enum.Font.GothamBold
DisplayName.LineHeight = 1
DisplayName.MaxVisibleGraphemes = -1
DisplayName.RichText = false
DisplayName.Text = ""
DisplayName.TextColor3 = Color3.fromRGB(235, 235, 235)
DisplayName.TextDirection = Enum.TextDirection.Auto
DisplayName.TextScaled = false
DisplayName.TextSize = 22
DisplayName.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
DisplayName.TextStrokeTransparency = 1
DisplayName.TextTransparency = 0
DisplayName.TextTruncate = Enum.TextTruncate.None
DisplayName.TextWrapped = true
DisplayName.TextXAlignment = Enum.TextXAlignment.Left
DisplayName.TextYAlignment = Enum.TextYAlignment.Top

local UserName = Instance.new("TextLabel")
UserName.SelectionImageObject = nil
UserName.Archivable = true
UserName.Active = false
UserName.AnchorPoint = Vector2.new(0, 0)
UserName.AutomaticSize = Enum.AutomaticSize.Y
UserName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
UserName.BackgroundTransparency = 1
UserName.BorderColor3 = Color3.fromRGB(0, 0, 0)
UserName.BorderMode = Enum.BorderMode.Outline
UserName.BorderSizePixel = 0
UserName.Interactable = true
UserName.LayoutOrder = 0
UserName.Name = "UserName"
UserName.Parent = LabelsContainer
UserName.Position = UDim2.fromOffset(0, 0)
UserName.Rotation = 0
UserName.Size = UDim2.fromScale(1, 0)
UserName.SizeConstraint = Enum.SizeConstraint.RelativeXY
UserName.Visible = true
UserName.ZIndex = 6
UserName.ClipsDescendants = false
UserName.AutoLocalize = true
UserName.RootLocalizationTable = nil
UserName.NextSelectionDown = nil
UserName.NextSelectionLeft = nil
UserName.NextSelectionRight = nil
UserName.NextSelectionUp = nil
UserName.Selectable = false
UserName.SelectionGroup = false
UserName.SelectionOrder = 0
UserName.Font = Enum.Font.GothamMedium
UserName.LineHeight = 1
UserName.MaxVisibleGraphemes = -1
UserName.RichText = false
UserName.Text = ""
UserName.TextColor3 = Color3.fromRGB(120, 120, 120)
UserName.TextDirection = Enum.TextDirection.Auto
UserName.TextScaled = false
UserName.TextSize = 20
UserName.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
UserName.TextStrokeTransparency = 1
UserName.TextTransparency = 0.2
UserName.TextTruncate = Enum.TextTruncate.None
UserName.TextWrapped = true
UserName.TextXAlignment = Enum.TextXAlignment.Left
UserName.TextYAlignment = Enum.TextYAlignment.Top

local Avatar = Instance.new("ImageLabel")
Avatar.SelectionImageObject = nil
Avatar.Archivable = true
Avatar.AnchorPoint = Vector2.new(0, 0)
Avatar.AutomaticSize = Enum.AutomaticSize.None
Avatar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Avatar.BackgroundTransparency = 1
Avatar.BorderColor3 = Color3.fromRGB(0, 0, 0)
Avatar.Interactable = true
Avatar.LayoutOrder = 0
Avatar.Name = "Avatar"
Avatar.Parent = PlayerSuggestion
Avatar.Position = UDim2.fromOffset(0, 0)
Avatar.Rotation = 0
Avatar.Size = UDim2.fromOffset(40, 40)
Avatar.SizeConstraint = Enum.SizeConstraint.RelativeXY
Avatar.Visible = true
Avatar.ZIndex = 6
Avatar.ClipsDescendants = false
Avatar.Image = ""
Avatar.ImageColor3 = Color3.fromRGB(255, 255, 255)
Avatar.ImageRectOffset = Vector2.new(0, 0)
Avatar.ImageRectSize = Vector2.new(0, 0)
Avatar.ImageTransparency = 0
Avatar.ResampleMode = Enum.ResamplerMode.Default
Avatar.ScaleType = Enum.ScaleType.Stretch
Avatar.AutoLocalize = true
Avatar.RootLocalizationTable = nil
Avatar.NextSelectionDown = nil
Avatar.NextSelectionLeft = nil
Avatar.NextSelectionRight = nil
Avatar.NextSelectionUp = nil
Avatar.Selectable = false
Avatar.SelectionGroup = false
Avatar.SelectionOrder = 0

local UICorner_v2 = Instance.new("UICorner")
UICorner_v2.CornerRadius = UDim.new(1, 0)
UICorner_v2.Archivable = true
UICorner_v2.Name = "UICorner"
UICorner_v2.Parent = Avatar

local CommandCaption = Instance.new("Frame")
CommandCaption.SelectionImageObject = nil
CommandCaption.Archivable = true
CommandCaption.Active = false
CommandCaption.AnchorPoint = Vector2.new(0, 0)
CommandCaption.AutomaticSize = Enum.AutomaticSize.XY
CommandCaption.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
CommandCaption.BackgroundTransparency = 0.2
CommandCaption.BorderColor3 = Color3.fromRGB(0, 0, 0)
CommandCaption.BorderMode = Enum.BorderMode.Outline
CommandCaption.BorderSizePixel = 0
CommandCaption.Interactable = false
CommandCaption.LayoutOrder = 0
CommandCaption.Name = "CommandCaption"
CommandCaption.Parent = Examples
CommandCaption.Position = UDim2.fromOffset(0, 0)
CommandCaption.Rotation = 0
CommandCaption.Size = UDim2.fromOffset(0, 0)
CommandCaption.SizeConstraint = Enum.SizeConstraint.RelativeXY
CommandCaption.Style = Enum.FrameStyle.Custom
CommandCaption.Visible = false
CommandCaption.ZIndex = 60
CommandCaption.ClipsDescendants = false
CommandCaption.AutoLocalize = true
CommandCaption.RootLocalizationTable = nil
CommandCaption.NextSelectionDown = nil
CommandCaption.NextSelectionLeft = nil
CommandCaption.NextSelectionRight = nil
CommandCaption.NextSelectionUp = nil
CommandCaption.Selectable = false
CommandCaption.SelectionGroup = false
CommandCaption.SelectionOrder = 0

local CommandCaptionSizeConstraint = Instance.new("UISizeConstraint")
CommandCaptionSizeConstraint.Archivable = true
CommandCaptionSizeConstraint.Name = "UISizeConstraint"
CommandCaptionSizeConstraint.Parent = CommandCaption
CommandCaptionSizeConstraint.MaxSize = Vector2.new(700, 50)
CommandCaptionSizeConstraint.MinSize = Vector2.new(0, 0)

local CommandCaptionStroke = Instance.new("UIStroke")
CommandCaptionStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
CommandCaptionStroke.BorderOffset = UDim.new(0, 0)
CommandCaptionStroke.BorderStrokePosition = Enum.BorderStrokePosition.Outer
CommandCaptionStroke.Color = Color3.fromRGB(0, 0, 0)
CommandCaptionStroke.LineJoinMode = Enum.LineJoinMode.Round
CommandCaptionStroke.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
CommandCaptionStroke.Thickness = 2
CommandCaptionStroke.Transparency = 0.75
CommandCaptionStroke.ZIndex = 5
CommandCaptionStroke.Archivable = true
CommandCaptionStroke.Enabled = true
CommandCaptionStroke.Name = "UIStroke"
CommandCaptionStroke.Parent = CommandCaption

local CommandCaptionLabel = Instance.new("TextLabel")
CommandCaptionLabel.SelectionImageObject = nil
CommandCaptionLabel.Archivable = true
CommandCaptionLabel.Active = false
CommandCaptionLabel.AnchorPoint = Vector2.new(0, 0)
CommandCaptionLabel.AutomaticSize = Enum.AutomaticSize.XY
CommandCaptionLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CommandCaptionLabel.BackgroundTransparency = 1
CommandCaptionLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
CommandCaptionLabel.BorderMode = Enum.BorderMode.Outline
CommandCaptionLabel.BorderSizePixel = 0
CommandCaptionLabel.Interactable = false
CommandCaptionLabel.LayoutOrder = 0
CommandCaptionLabel.Name = "TextLabel"
CommandCaptionLabel.Parent = CommandCaption
CommandCaptionLabel.Position = UDim2.fromOffset(0, 0)
CommandCaptionLabel.Rotation = 0
CommandCaptionLabel.Size = UDim2.fromOffset(0, 0)
CommandCaptionLabel.SizeConstraint = Enum.SizeConstraint.RelativeXY
CommandCaptionLabel.Visible = true
CommandCaptionLabel.ZIndex = 61
CommandCaptionLabel.ClipsDescendants = false
CommandCaptionLabel.AutoLocalize = true
CommandCaptionLabel.RootLocalizationTable = nil
CommandCaptionLabel.NextSelectionDown = nil
CommandCaptionLabel.NextSelectionLeft = nil
CommandCaptionLabel.NextSelectionRight = nil
CommandCaptionLabel.NextSelectionUp = nil
CommandCaptionLabel.Selectable = false
CommandCaptionLabel.SelectionGroup = false
CommandCaptionLabel.SelectionOrder = 0
CommandCaptionLabel.Font = Enum.Font.GothamMedium
pcall(function()
	CommandCaptionLabel.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
end)
CommandCaptionLabel.LineHeight = 1
CommandCaptionLabel.MaxVisibleGraphemes = -1
CommandCaptionLabel.RichText = false
CommandCaptionLabel.Text = ""
CommandCaptionLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
CommandCaptionLabel.TextDirection = Enum.TextDirection.Auto
CommandCaptionLabel.TextScaled = false
CommandCaptionLabel.TextSize = 12
CommandCaptionLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
CommandCaptionLabel.TextStrokeTransparency = 1
CommandCaptionLabel.TextTransparency = 0
CommandCaptionLabel.TextTruncate = Enum.TextTruncate.None
CommandCaptionLabel.TextWrapped = true
CommandCaptionLabel.TextXAlignment = Enum.TextXAlignment.Left
CommandCaptionLabel.TextYAlignment = Enum.TextYAlignment.Top

local CommandCaptionPadding = Instance.new("UIPadding")
CommandCaptionPadding.Archivable = true
CommandCaptionPadding.Name = "UIPadding"
CommandCaptionPadding.Parent = CommandCaptionLabel
CommandCaptionPadding.PaddingBottom = UDim.new(0, 7)
CommandCaptionPadding.PaddingLeft = UDim.new(0, 7)
CommandCaptionPadding.PaddingRight = UDim.new(0, 7)
CommandCaptionPadding.PaddingTop = UDim.new(0, 7)

local UIListLayout_v6 = Instance.new("UIListLayout")
UIListLayout_v6.Padding = UDim.new(0, 16)
UIListLayout_v6.Archivable = true
UIListLayout_v6.Name = "UIListLayout"
UIListLayout_v6.Parent = CommandsList
UIListLayout_v6.FillDirection = Enum.FillDirection.Vertical
UIListLayout_v6.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_v6.Wraps = false
UIListLayout_v6.HorizontalAlignment = Enum.HorizontalAlignment.Left
UIListLayout_v6.HorizontalFlex = Enum.UIFlexAlignment.None
UIListLayout_v6.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
UIListLayout_v6.VerticalAlignment = Enum.VerticalAlignment.Top
UIListLayout_v6.VerticalFlex = Enum.UIFlexAlignment.None

local UIPadding_v2 = Instance.new("UIPadding")
UIPadding_v2.Archivable = true
UIPadding_v2.Name = "UIPadding"
UIPadding_v2.Parent = CommandsList
UIPadding_v2.PaddingBottom = UDim.new(0, 18)
UIPadding_v2.PaddingLeft = UDim.new(0, 20)
UIPadding_v2.PaddingRight = UDim.new(0, 14)
UIPadding_v2.PaddingTop = UDim.new(0, 18)

local UISizeConstraint_v3 = Instance.new("UISizeConstraint")
UISizeConstraint_v3.Archivable = true
UISizeConstraint_v3.Name = "UISizeConstraint"
UISizeConstraint_v3.Parent = CommandsList
UISizeConstraint_v3.MaxSize = Vector2.new(math.huge, math.huge)
UISizeConstraint_v3.MinSize = Vector2.new(0, 0)

local ToastLayer = Instance.new("Frame")
ToastLayer.SelectionImageObject = nil
ToastLayer.Archivable = true
ToastLayer.Active = false
ToastLayer.AnchorPoint = Vector2.new(1, 0)
ToastLayer.AutomaticSize = Enum.AutomaticSize.Y
ToastLayer.BackgroundTransparency = 1
ToastLayer.BorderSizePixel = 0
ToastLayer.Name = "ToastLayer"
ToastLayer.Parent = Matt
ToastLayer.Position = UDim2.new(1, -layoutCfg.toastOffset, 0, layoutCfg.toastOffset)
ToastLayer.Size = UDim2.new(0, layoutCfg.toastWidth, 0, 0)
ToastLayer.Visible = true
ToastLayer.ZIndex = 50

local ToastListLayout = Instance.new("UIListLayout")
ToastListLayout.Padding = UDim.new(0, layoutCfg.toastGap)
ToastListLayout.Parent = ToastLayer
ToastListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToastListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ToastListLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.AnchorPoint = Vector2.new(1, 1)
OpenButton.AutoButtonColor = false
OpenButton.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
OpenButton.BorderSizePixel = 0
OpenButton.Parent = Matt
OpenButton.Position = UDim2.new(1, -mobileCfg.buttonRight, 1, -mobileCfg.buttonBottom)
OpenButton.Size = UDim2.fromOffset(mobileCfg.buttonSize, mobileCfg.buttonSize)
OpenButton.Text = mobileCfg.buttonText
OpenButton.TextColor3 = Color3.fromRGB(235, 235, 235)
OpenButton.TextSize = 22
OpenButton.TextTransparency = 0.05
OpenButton.Font = Enum.Font.GothamMedium
OpenButton.Visible = false
OpenButton.ZIndex = 40

local OpenButtonCorner = Instance.new("UICorner")
OpenButtonCorner.CornerRadius = UDim.new(1, 0)
OpenButtonCorner.Parent = OpenButton

local OpenButtonStroke = Instance.new("UIStroke")
OpenButtonStroke.Color = Color3.fromRGB(0, 0, 0)
OpenButtonStroke.Thickness = 1
OpenButtonStroke.Transparency = 0.55
OpenButtonStroke.Parent = OpenButton

local ScreenGui = Matt
local MenuStroke = UIStroke
local CommandsListLayout = UIListLayout_v6
local basePlaceholderText = Input.PlaceholderText
local ActiveCommandCaption = CommandCaption:Clone()
ActiveCommandCaption.Name = "ActiveCommandCaption"
ActiveCommandCaption.Parent = Canvas
ActiveCommandCaption.Visible = false

CommandsMenu.AutomaticSize = Enum.AutomaticSize.None
CommandsList.AutomaticSize = Enum.AutomaticSize.None
AutoComplete.BackgroundTransparency = 1
AutoCompleteStroke.Transparency = 1

function createCommandEntry()
	local entry = CommandSugestion:Clone()
	entry.Name = "CommandEntry"
	entry.Visible = true
	entry.Parent = nil
	return entry
end

function createPlayerEntry()
	local entry = PlayerSuggestion:Clone()
	entry.Name = "PlayerEntry"
	entry.Visible = true
	entry.Parent = nil
	return entry
end

-- Runtime state
local activeEntryTweens = setmetatable({}, { __mode = "k" })
local cachedEntryVisuals = setmetatable({}, { __mode = "k" })
local cachedAvatarImages = {}
local autoCompleteItems = {}
local autoCompleteSelectedIndex = 1
local autoCompleteVisible = false
local autoCompleteVersion = 0
local autoCompleteSuppressText = nil
local autoCompleteConsumeFocusLost = false
local autoCompleteFrameTween = nil
local autoCompleteStrokeTween = nil
local captionHoverVersion = 0
local captionSource = nil
local captionPositionConnection = nil

local registry = {}
local registryByName = {}
local registryByAlias = {}
local commandContext = {}
local currentState = nil

local currentHotkeyName = "Slash"
local currentHotkey = Enum.KeyCode.Slash
local isOpen = false
local isFocused = false
local isClosing = false
local suppressTextRender = false
local inputTypewriterVersion = 0
local renderVersion = 0
local openVersion = 0
local closeVersion = 0
local pendingResize = false
local lastListHeight = -1
local menuStateTween = nil
local menuStrokeTween = nil
local dividerTween = nil
local listHeightTween = nil
local menuHeightTween = nil
local connections = {}
local toastOrder = 0
local nextToastId = 0
local toastMap = {}
local toastConfig = {
	startup = true,
	updates = true,
	errors = true,
}
local didNotifyReady = false
local updateListHeight = function() end

local function clampNumber(value, minValue, maxValue)
	if type(value) ~= "number" then
		return nil
	end

	return math.clamp(value, minValue, maxValue)
end

local function getViewportSize()
	local size = Canvas.AbsoluteSize
	if size.X > 0 and size.Y > 0 then
		return size
	end

	local camera = workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end

	return Vector2.new(1280, 720)
end

local function getDeviceProfile(viewportSize)
	local shortSide = math.min(viewportSize.X, viewportSize.Y)
	if shortSide <= layoutCfg.phoneShortSide then
		return "phone"
	end

	if shortSide <= layoutCfg.tabletShortSide then
		return "tablet"
	end

	return "desktop"
end

local function getOpenMenuPosition()
	return UDim2.fromScale(0.5, layoutCfg.openY)
end

local function getClosedMenuPosition()
	return UDim2.new(0.5, 0, layoutCfg.openY, layoutCfg.closeYOffset)
end

local function getListPaddingHeight()
	return layoutCfg.listPadTop + layoutCfg.listPadBottom
end

local function cancelTween(tween)
	if tween then
		pcall(function()
			tween:Cancel()
		end)
	end
end

local function playTween(instance, tweenInfo, properties, completed)
	local tween = TweenService:Create(instance, tweenInfo, properties)
	if completed then
		local connection
		connection = tween.Completed:Connect(function(playbackState)
			if connection then
				connection:Disconnect()
				connection = nil
			end
			completed(playbackState)
		end)
	end
	tween:Play()
	return tween
end

local function cancelEntryAnimations(entry)
	local tweens = activeEntryTweens[entry]
	if not tweens then
		return
	end

	for _, tween in ipairs(tweens) do
		cancelTween(tween)
	end

	activeEntryTweens[entry] = nil
end

local function ensureEntryScale(entry)
	local scale = entry:FindFirstChild("EntryScale")
	if scale and scale:IsA("UIScale") then
		return scale
	end

	scale = Instance.new("UIScale")
	scale.Name = "EntryScale"
	scale.Scale = 1
	scale.Parent = entry

	return scale
end

local function collectEntryVisuals(entry)
	if cachedEntryVisuals[entry] then
		return cachedEntryVisuals[entry]
	end

	local visuals = {}

	local function register(instance, property)
		local ok, value = pcall(function()
			return instance[property]
		end)

		if ok and type(value) == "number" then
			visuals[#visuals + 1] = {
				instance = instance,
				property = property,
				visibleValue = value,
			}
		end
	end

	local function registerInstance(instance)
		if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
			register(instance, "TextTransparency")
			register(instance, "TextStrokeTransparency")
		elseif instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
			register(instance, "ImageTransparency")
			register(instance, "BackgroundTransparency")
		elseif instance:IsA("UIStroke") then
			register(instance, "Transparency")
		end
	end

	registerInstance(entry)

	for _, descendant in ipairs(entry:GetDescendants()) do
		registerInstance(descendant)
	end

	cachedEntryVisuals[entry] = visuals
	return visuals
end

local function setEntryVisible(entry, visible)
	cancelEntryAnimations(entry)
	entry:SetAttribute("SuggestionRemoving", false)
	entry:SetAttribute("SuggestionVisualState", visible and "visible" or "hidden")

	local visuals = collectEntryVisuals(entry)
	local scale = ensureEntryScale(entry)
	scale.Scale = visible and 1 or motionCfg.hiddenScale

	for _, visual in ipairs(visuals) do
		if visual.instance.Parent ~= nil then
			visual.instance[visual.property] = visible and visual.visibleValue or 1
		end
	end
end

local function animateEntry(entry, visible, duration, completed)
	cancelEntryAnimations(entry)
	entry:SetAttribute("SuggestionVisualState", visible and "animating-in" or "animating-out")
	entry:SetAttribute("SuggestionRemoving", not visible)

	local visuals = collectEntryVisuals(entry)
	local scale = ensureEntryScale(entry)
	local groupedProperties = {}
	local tweens = {}

	activeEntryTweens[entry] = tweens

	local scaleTween = playTween(scale, TweenInfo.new(duration, visible and Enum.EasingStyle.Quint or Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Scale = visible and 1 or motionCfg.hiddenScale,
	}, function(playbackState)
		if activeEntryTweens[entry] ~= tweens then
			return
		end

		if playbackState ~= Enum.PlaybackState.Completed then
			return
		end

		activeEntryTweens[entry] = nil
		entry:SetAttribute("SuggestionVisualState", visible and "visible" or "hidden")
		if visible then
			entry:SetAttribute("SuggestionRemoving", false)
		end
		if completed then
			completed()
		end
	end)
	tweens[#tweens + 1] = scaleTween

	for _, visual in ipairs(visuals) do
		if visual.instance.Parent ~= nil then
			local properties = groupedProperties[visual.instance]
			if not properties then
				properties = {}
				groupedProperties[visual.instance] = properties
			end

			properties[visual.property] = visible and visual.visibleValue or 1
		end
	end

	for instance, properties in pairs(groupedProperties) do
		tweens[#tweens + 1] = playTween(instance, TweenInfo.new(duration, visible and Enum.EasingStyle.Quint or Enum.EasingStyle.Sine, Enum.EasingDirection.Out), properties)
	end
end

local function getRootScale()
	return math.max(UIScale.Scale, 0.001)
end

local function applyMontserratSemiBold(textObject)
	pcall(function()
		textObject.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	end)
end

local function getCaptionLabel()
	return ActiveCommandCaption:FindFirstChild("TextLabel")
end

local function stopCaptionPositioning()
	if captionPositionConnection then
		captionPositionConnection:Disconnect()
		captionPositionConnection = nil
	end
end

local function updateCommandCaptionPosition()
	if not ActiveCommandCaption.Visible then
		return
	end

	local scale = getRootScale()
	local mouse = UserInputService:GetMouseLocation()
	local canvasPosition = Canvas.AbsolutePosition
	local canvasSize = Vector2.new(Canvas.AbsoluteSize.X / scale, Canvas.AbsoluteSize.Y / scale)
	local captionSize = Vector2.new(ActiveCommandCaption.AbsoluteSize.X / scale, ActiveCommandCaption.AbsoluteSize.Y / scale)
	local x = ((mouse.X - canvasPosition.X) / scale) + CAPTION_CURSOR_OFFSET_X
	local y = ((mouse.Y - canvasPosition.Y) / scale) + CAPTION_CURSOR_OFFSET_Y

	x = math.clamp(x, CAPTION_SCREEN_PADDING, math.max(CAPTION_SCREEN_PADDING, canvasSize.X - captionSize.X - CAPTION_RIGHT_PADDING))
	y = math.clamp(y, CAPTION_SCREEN_PADDING, math.max(CAPTION_SCREEN_PADDING, canvasSize.Y - captionSize.Y - CAPTION_SCREEN_PADDING))

	ActiveCommandCaption.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
end

local function hideCommandCaption(source)
	if source and captionSource ~= source then
		return
	end

	captionHoverVersion = captionHoverVersion + 1
	captionSource = nil
	ActiveCommandCaption.Visible = false
	stopCaptionPositioning()
end

local function showCommandCaption(text, source)
	text = trim(text)
	if text == "" then
		hideCommandCaption(source)
		return
	end

	local label = getCaptionLabel()
	if label and label:IsA("TextLabel") then
		label.Text = text
	end

	captionSource = source
	ActiveCommandCaption.BackgroundTransparency = 0.2
	ActiveCommandCaption.Visible = true
	updateCommandCaptionPosition()
	task.defer(updateCommandCaptionPosition)

	if not captionPositionConnection then
		captionPositionConnection = RunService.RenderStepped:Connect(updateCommandCaptionPosition)
	end
end

local function bindSuggestionHover(entry)
	if entry:GetAttribute("CaptionHoverBound") == true then
		return
	end

	entry:SetAttribute("CaptionHoverBound", true)

	entry.MouseEnter:Connect(function()
		local captionText = trim(entry:GetAttribute("CaptionText") or "")
		if captionText == "" then
			return
		end

		captionHoverVersion = captionHoverVersion + 1
		local version = captionHoverVersion
		captionSource = entry

		task.delay(CAPTION_HOVER_DELAY, function()
			if version ~= captionHoverVersion or captionSource ~= entry or entry.Parent == nil then
				return
			end

			showCommandCaption(entry:GetAttribute("CaptionText") or "", entry)
		end)
	end)

	entry.MouseLeave:Connect(function()
		hideCommandCaption(entry)
	end)

	entry.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			hideCommandCaption(entry)
		end
	end)
end

local function collectTextTokensWithBounds(text)
	local tokens = {}
	local searchIndex = 1

	while searchIndex <= #text do
		local startIndex, endIndex = string.find(text, "%S+", searchIndex)
		if not startIndex then
			break
		end

		tokens[#tokens + 1] = {
			text = string.sub(text, startIndex, endIndex),
			startIndex = startIndex,
			endIndex = endIndex,
		}
		searchIndex = endIndex + 1
	end

	return tokens
end

local function getInputCursorPosition(text)
	local cursor = Input.CursorPosition
	if type(cursor) ~= "number" or cursor < 1 then
		cursor = #text + 1
	end

	return math.clamp(cursor, 1, #text + 1)
end

local function getCurrentTokenContext(text)
	local cursor = getInputCursorPosition(text)
	local tokens = collectTextTokensWithBounds(text)
	local currentToken = nil
	local currentIndex = 1

	for index, token in ipairs(tokens) do
		if cursor >= token.startIndex and cursor <= token.endIndex + 1 then
			currentToken = token
			currentIndex = index
			break
		end

		if cursor > token.endIndex + 1 then
			currentIndex = index + 1
		elseif cursor < token.startIndex then
			currentIndex = index
			break
		end
	end

	if not currentToken then
		currentToken = {
			text = "",
			startIndex = cursor,
			endIndex = cursor - 1,
		}
	end

	return {
		cursor = cursor,
		tokens = tokens,
		currentToken = currentToken,
		currentIndex = currentIndex,
	}
end

local function getAutoCompleteContext(text)
	local tokenContext = getCurrentTokenContext(text)
	local tokens = tokenContext.tokens
	local currentToken = tokenContext.currentToken
	local currentIndex = tokenContext.currentIndex
	local commandToken = tokens[1]

	if currentIndex <= 1 or not commandToken then
		local tokenStart = currentToken.startIndex
		local tokenText = currentToken.text
		if startsWith(tokenText, "/") then
			tokenStart = tokenStart + 1
			tokenText = string.sub(tokenText, 2)
		end

		return {
			mode = "commands",
			partial = tokenText,
			tokenStart = tokenStart,
			tokenEnd = currentToken.endIndex + 1,
		}
	end

	local commandText = commandToken.text
	if startsWith(commandText, "/") then
		commandText = string.sub(commandText, 2)
	end

	local command = findCommand(registryByName, registryByAlias, commandText)
	if not command then
		return nil
	end

	local syntax = command.syntax or {}
	local argumentIndex = currentIndex - 1
	if argumentIndex < 1 or argumentIndex > #syntax then
		return nil
	end

	return {
		mode = "parameters",
		command = command,
		syntax = syntax,
		spec = syntax[argumentIndex],
		argumentIndex = argumentIndex,
		partial = currentToken.text,
		tokenStart = currentToken.startIndex,
		tokenEnd = currentToken.endIndex + 1,
	}
end

local function scoreTextCandidate(candidate, query)
	candidate = toLower(tostring(candidate or ""))
	query = toLower(tostring(query or ""))

	if query == "" then
		return 1000 + #candidate
	end

	if candidate == query then
		return 0
	end

	if startsWith(candidate, query) then
		return 10 + (#candidate - #query)
	end

	local containsIndex = string.find(candidate, query, 1, true)
	if containsIndex then
		return 40 + containsIndex + (#candidate - #query)
	end

	local queryIndex = 1
	local gap = 0
	for candidateIndex = 1, #candidate do
		if string.sub(candidate, candidateIndex, candidateIndex) == string.sub(query, queryIndex, queryIndex) then
			queryIndex = queryIndex + 1
			if queryIndex > #query then
				return 70 + gap + (#candidate - #query)
			end
		else
			gap = gap + 1
		end
	end

	return nil
end

local function pushAutoCompleteItem(items, seen, item)
	local value = tostring(item.value or "")
	if value == "" then
		return
	end

	local key = toLower(item.mode or "") .. ":" .. toLower(value) .. ":" .. tostring(item.tokenStart or "")
	if seen[key] then
		return
	end

	seen[key] = true
	items[#items + 1] = item
end

local function sortAutoCompleteItems(items)
	table.sort(items, function(left, right)
		if left.score ~= right.score then
			return (left.score or 1000) < (right.score or 1000)
		end

		return toLower(left.label or left.value or "") < toLower(right.label or right.value or "")
	end)

	return items
end

local function limitAutoCompleteItems(items)
	local limited = {}
	for index, item in ipairs(items) do
		if index > AUTOCOMPLETE_LIMIT then
			break
		end

		limited[#limited + 1] = item
	end

	return limited
end

local function formatRemainingSyntax(syntax, argumentIndex)
	local parts = {}
	for index = argumentIndex + 1, #syntax do
		local spec = syntax[index]
		local token = "<" .. getCommandTag(spec)
		if spec.required == false then
			token = token .. "?"
		end
		parts[#parts + 1] = token .. ">"
	end

	return table.concat(parts, " ")
end

local function formatParameterAutoCompleteLabel(value, syntax, argumentIndex, appendSyntax)
	local label = tostring(value or "")
	if appendSyntax == false then
		return label
	end

	local remaining = formatRemainingSyntax(syntax, argumentIndex)
	if remaining == "" then
		return label
	end

	return label .. " " .. remaining
end

local function getSpecSuggestionSource(spec, partial, command)
	local source = spec.suggestions
	if type(source) ~= "function" then
		return source
	end

	local ok, result = pcall(source, {
		partial = partial,
		text = Input.Text,
		command = command,
		argument = spec,
		context = commandContext,
		player = LocalPlayer,
	})

	if ok then
		return result
	end

	return nil
end

local function readSuggestionValue(raw)
	if raw == nil then
		return nil
	end

	if type(raw) ~= "table" then
		local text = tostring(raw)
		return text, text, "", true
	end

	local value = raw.value
	if value == nil then value = raw.Value end
	if value == nil then value = raw.name end
	if value == nil then value = raw.Name end
	if value == nil then value = raw[1] end
	if value == nil then
		return nil
	end

	local label = raw.label
	if label == nil then label = raw.Label end
	if label == nil then label = raw.title end
	if label == nil then label = raw.Title end
	if label == nil then label = value end

	local caption = raw.caption
	if caption == nil then caption = raw.Caption end
	if caption == nil then caption = raw.description end
	if caption == nil then caption = raw.Description end
	if caption == nil then caption = "" end

	local appendSyntax = raw.appendSyntax
	if appendSyntax == nil then
		appendSyntax = true
	else
		appendSyntax = appendSyntax ~= false
	end

	return tostring(value), tostring(label), tostring(caption), appendSyntax
end

local function buildCommandAutoCompleteItems(context)
	local query = trim(context.partial or "")
	if query == "" then
		return {}
	end

	local items = {}
	local seen = {}
	local loweredQuery = toLower(query)

	for _, command in ipairs(registry) do
		local bestScore = scoreTextCandidate(command.name, query)
		for _, alias in ipairs(command.aliases or {}) do
			local aliasScore = scoreTextCandidate(alias, query)
			if aliasScore and (not bestScore or aliasScore + 5 < bestScore) then
				bestScore = aliasScore + 5
			end
		end

		if bestScore then
			pushAutoCompleteItem(items, seen, {
				mode = "commands",
				label = command.name,
				value = command.name,
				caption = buildCommandCaption(command),
				score = bestScore,
				tokenStart = context.tokenStart,
				tokenEnd = context.tokenEnd,
				appendSpace = #(command.syntax or {}) > 0,
			})
		end
	end

	sortAutoCompleteItems(items)
	if #items == 1 and toLower(items[1].value) == loweredQuery then
		return {}
	end

	return limitAutoCompleteItems(items)
end

local function addOneCustomParameterSuggestion(items, seen, context, raw)
	local value, label, caption, appendSyntax = readSuggestionValue(raw)
	if not value then
		return
	end

	local partial = context.partial or ""
	local score = scoreTextCandidate(value, partial) or scoreTextCandidate(label, partial)
	if not score then
		return
	end

	local effectiveCaption = caption
	if effectiveCaption == "" then
		effectiveCaption = tostring(context.spec.caption or "")
	end

	pushAutoCompleteItem(items, seen, {
		mode = "parameters",
		label = formatParameterAutoCompleteLabel(label, context.syntax, context.argumentIndex, appendSyntax),
		value = value,
		caption = effectiveCaption,
		score = score,
		tokenStart = context.tokenStart,
		tokenEnd = context.tokenEnd,
		appendSpace = context.argumentIndex < #context.syntax,
	})
end

local function addCustomParameterSuggestions(items, seen, context, source)
	if type(source) ~= "table" then
		return
	end

	for _, raw in ipairs(source) do
		addOneCustomParameterSuggestion(items, seen, context, raw)
	end
end

local function addPlayerParameterSuggestions(items, seen, context)
	local partial = context.partial or ""
	local players = listPlayers(partial)
	for _, player in ipairs(players) do
		local displayName = player.DisplayName
		local userName = player.Name
		local label = displayName
		if displayName ~= userName then
			label = displayName .. " @" .. userName
		end

		local score = scoreTextCandidate(userName, partial) or scoreTextCandidate(displayName, partial) or 1000
		pushAutoCompleteItem(items, seen, {
			mode = "parameters",
			label = formatParameterAutoCompleteLabel(label, context.syntax, context.argumentIndex, false),
			value = userName,
			caption = "@" .. userName,
			score = score,
			tokenStart = context.tokenStart,
			tokenEnd = context.tokenEnd,
			appendSpace = context.argumentIndex < #context.syntax,
		})

		if #items >= AUTOCOMPLETE_LIMIT then
			return
		end
	end
end

local function valueWithinSpecRange(value, spec)
	local numberValue = tonumber(value)
	if not numberValue then
		return false
	end

	if spec.min and numberValue < spec.min then
		return false
	end

	if spec.max and numberValue > spec.max then
		return false
	end

	return true
end

local function addNumberParameterSuggestions(items, seen, context)
	local spec = context.spec
	local candidates = {}

	if spec.min then
		candidates[#candidates + 1] = spec.min
	end
	candidates[#candidates + 1] = 0
	candidates[#candidates + 1] = 1
	candidates[#candidates + 1] = 10
	if spec.max then
		candidates[#candidates + 1] = spec.max
	end

	for _, value in ipairs(candidates) do
		if valueWithinSpecRange(value, spec) then
			local text = tostring(value)
			local score = scoreTextCandidate(text, context.partial)
			if score then
				pushAutoCompleteItem(items, seen, {
					mode = "parameters",
					label = formatParameterAutoCompleteLabel(text, context.syntax, context.argumentIndex, true),
					value = text,
					caption = spec.caption or getCommandTag(spec),
					score = score,
					tokenStart = context.tokenStart,
					tokenEnd = context.tokenEnd,
					appendSpace = context.argumentIndex < #context.syntax,
				})
			end
		end
	end
end

local function addKeyParameterSuggestions(items, seen, context)
	for _, keyCode in ipairs(Enum.KeyCode:GetEnumItems()) do
		if keyCode.Name ~= "Unknown" then
			local display = getKeyCodeText(keyCode) or keyCode.Name
			local score = scoreTextCandidate(keyCode.Name, context.partial) or scoreTextCandidate(display, context.partial)
			if score then
				pushAutoCompleteItem(items, seen, {
					mode = "parameters",
					label = formatParameterAutoCompleteLabel(display, context.syntax, context.argumentIndex, false),
					value = keyCode.Name,
					caption = keyCode.Name,
					score = score,
					tokenStart = context.tokenStart,
					tokenEnd = context.tokenEnd,
					appendSpace = context.argumentIndex < #context.syntax,
				})
			end
		end
	end
end

local function addPlaceholderParameterSuggestion(items, seen, context)
	local value = getCommandTag(context.spec)
	if value == "" then
		return
	end

	local score = scoreTextCandidate(value, context.partial)
	if not score then
		return
	end

	pushAutoCompleteItem(items, seen, {
		mode = "parameters",
		label = formatParameterAutoCompleteLabel(value, context.syntax, context.argumentIndex, true),
		value = value,
		caption = context.spec.caption or context.spec.name or value,
		score = score,
		tokenStart = context.tokenStart,
		tokenEnd = context.tokenEnd,
		appendSpace = context.argumentIndex < #context.syntax,
	})
end

local function buildParameterAutoCompleteItems(context)
	local items = {}
	local seen = {}
	local source = getSpecSuggestionSource(context.spec, context.partial or "", context.command)

	addCustomParameterSuggestions(items, seen, context, source)

	local kind = getSpecKind(context.spec)
	if kind == "player" then
		addPlayerParameterSuggestions(items, seen, context)
	elseif kind == "int" or kind == "number" then
		addNumberParameterSuggestions(items, seen, context)
	elseif kind == "key" then
		addKeyParameterSuggestions(items, seen, context)
	else
		addPlaceholderParameterSuggestion(items, seen, context)
	end

	return limitAutoCompleteItems(sortAutoCompleteItems(items))
end

local function getAutoCompleteRows()
	local rows = {}
	for _, child in ipairs(AutoComplete:GetChildren()) do
		if child:IsA("GuiObject") and child:GetAttribute("AutoCompleteEntry") == true then
			rows[#rows + 1] = child
		end
	end

	table.sort(rows, function(left, right)
		return left.LayoutOrder < right.LayoutOrder
	end)

	return rows
end

local function destroyAutoCompleteRow(row)
	cancelEntryAnimations(row)
	cachedEntryVisuals[row] = nil
	if row and row.Parent ~= nil then
		row:Destroy()
	end
end

local function clearAutoCompleteRows()
	for _, row in ipairs(getAutoCompleteRows()) do
		destroyAutoCompleteRow(row)
	end
end

local function updateAutoCompleteSelection()
	local rows = getAutoCompleteRows()
	for _, row in ipairs(rows) do
		local index = row:GetAttribute("AutoCompleteIndex")
		if row:IsA("TextButton") then
			row.TextColor3 = index == autoCompleteSelectedIndex and AUTOCOMPLETE_SELECTED_COLOR or AUTOCOMPLETE_IDLE_COLOR
		end
	end
end

local function updateAutoCompletePosition()
	if not AutoComplete.Visible then
		return
	end

	local scale = getRootScale()
	local cursor = getInputCursorPosition(Input.Text)
	local textBeforeCursor = string.sub(Input.Text, 1, math.max(0, cursor - 1))
	local textWidth = 0

	local ok, bounds = pcall(function()
		return TextService:GetTextSize(textBeforeCursor, Input.TextSize, Input.Font, Vector2.new(10000, Input.AbsoluteSize.Y))
	end)

	if ok and bounds then
		textWidth = bounds.X
	end

	local inputLocalX = (Input.AbsolutePosition.X - CommandBar.AbsolutePosition.X) / scale
	local inputLocalY = (Input.AbsolutePosition.Y - CommandBar.AbsolutePosition.Y) / scale
	local commandBarWidth = CommandBar.AbsoluteSize.X / scale
	local autoCompleteWidth = AutoComplete.AbsoluteSize.X / scale
	local x = inputLocalX + textWidth + AUTOCOMPLETE_CURSOR_OFFSET_X
	local y = inputLocalY - AUTOCOMPLETE_CURSOR_OFFSET_Y

	x = math.clamp(x, 6, math.max(6, commandBarWidth - autoCompleteWidth - 6))
	AutoComplete.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
	task.defer(function()
		if AutoComplete.Visible then
			local width = AutoComplete.AbsoluteSize.X / getRootScale()
			local maxX = (CommandBar.AbsoluteSize.X / getRootScale()) - width - 6
			local clampedX = math.clamp(x, 6, math.max(6, maxX))
			AutoComplete.Position = UDim2.fromOffset(math.floor(clampedX + 0.5), math.floor(y + 0.5))
		end
	end)
end

local function createAutoCompleteRow(item, index)
	local row = Instance.new("TextButton")
	row.Name = "AutoCompleteEntry"
	row.AutoButtonColor = false
	row.AutomaticSize = Enum.AutomaticSize.XY
	row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.LayoutOrder = index
	row.Parent = AutoComplete
	row.Size = UDim2.fromOffset(0, 15)
	row.Text = item.label or item.value or ""
	row.TextColor3 = index == autoCompleteSelectedIndex and AUTOCOMPLETE_SELECTED_COLOR or AUTOCOMPLETE_IDLE_COLOR
	row.TextSize = 12
	row.Font = Enum.Font.GothamMedium
	applyMontserratSemiBold(row)
	row.LineHeight = 1
	row.RichText = false
	row.TextStrokeTransparency = 1
	row.TextTransparency = 0
	row.TextTruncate = Enum.TextTruncate.AtEnd
	row.TextWrapped = false
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.TextYAlignment = Enum.TextYAlignment.Center
	row.ZIndex = 21
	row:SetAttribute("AutoCompleteEntry", true)
	row:SetAttribute("AutoCompleteIndex", index)

	row.MouseEnter:Connect(function()
		autoCompleteSelectedIndex = index
		updateAutoCompleteSelection()
	end)

	row.MouseButton1Click:Connect(function()
		autoCompleteConsumeFocusLost = true
		if not acceptAutoComplete() then
			autoCompleteConsumeFocusLost = false
		end
	end)

	return row
end

function hideAutoComplete(animate)
	autoCompleteVersion = autoCompleteVersion + 1
	local version = autoCompleteVersion
	autoCompleteItems = {}
	autoCompleteSelectedIndex = 1
	autoCompleteVisible = false

	cancelTween(autoCompleteFrameTween)
	cancelTween(autoCompleteStrokeTween)

	if not AutoComplete.Visible then
		clearAutoCompleteRows()
		return
	end

	local rows = getAutoCompleteRows()
	if not animate or #rows == 0 then
		clearAutoCompleteRows()
		AutoComplete.Visible = false
		AutoComplete.BackgroundTransparency = 1
		AutoCompleteStroke.Transparency = 1
		return
	end

	autoCompleteFrameTween = playTween(AutoComplete, TweenInfo.new(motionCfg.entryOut, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	})
	autoCompleteStrokeTween = playTween(AutoCompleteStroke, TweenInfo.new(motionCfg.entryOut, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Transparency = 1,
	})

	table.sort(rows, function(left, right)
		return left.LayoutOrder > right.LayoutOrder
	end)

	for index, row in ipairs(rows) do
		task.delay((index - 1) * motionCfg.errorGap, function()
			if version ~= autoCompleteVersion or row.Parent == nil then
				return
			end

			animateEntry(row, false, motionCfg.entryOut, function()
				if version == autoCompleteVersion then
					destroyAutoCompleteRow(row)
				end
			end)
		end)
	end

	task.delay((#rows * motionCfg.errorGap) + motionCfg.entryOut, function()
		if version == autoCompleteVersion then
			clearAutoCompleteRows()
			AutoComplete.Visible = false
		end
	end)
end

local function renderAutoCompleteItems(items)
	if #items == 0 then
		hideAutoComplete(true)
		return
	end

	autoCompleteVersion = autoCompleteVersion + 1
	local version = autoCompleteVersion
	autoCompleteItems = items
	autoCompleteSelectedIndex = 1
	autoCompleteVisible = true

	cancelTween(autoCompleteFrameTween)
	cancelTween(autoCompleteStrokeTween)
	clearAutoCompleteRows()

	AutoComplete.Visible = true
	AutoComplete.BackgroundTransparency = 1
	AutoCompleteStroke.Transparency = 1

	for index, item in ipairs(items) do
		local row = createAutoCompleteRow(item, index)
		setEntryVisible(row, false)
		task.delay((index - 1) * motionCfg.entryGap, function()
			if version ~= autoCompleteVersion or not AutoComplete.Visible or row.Parent == nil then
				return
			end

			animateEntry(row, true, motionCfg.entryIn)
		end)
	end

	autoCompleteFrameTween = playTween(AutoComplete, TweenInfo.new(motionCfg.entryIn, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.2,
	})
	autoCompleteStrokeTween = playTween(AutoCompleteStroke, TweenInfo.new(motionCfg.entryIn, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Transparency = 0.75,
	})

	updateAutoCompleteSelection()
	updateAutoCompletePosition()
	task.defer(updateAutoCompletePosition)
end

function syncAutoComplete()
	if not isOpen or isClosing or not isFocused or UserInputService:GetFocusedTextBox() ~= Input then
		hideAutoComplete(true)
		return
	end

	if autoCompleteSuppressText ~= nil then
		if autoCompleteSuppressText == Input.Text then
			hideAutoComplete(false)
			return
		end

		autoCompleteSuppressText = nil
	end

	local context = getAutoCompleteContext(Input.Text)
	if not context then
		hideAutoComplete(true)
		return
	end

	local items = {}
	if context.mode == "commands" then
		items = buildCommandAutoCompleteItems(context)
	elseif context.mode == "parameters" then
		items = buildParameterAutoCompleteItems(context)
	end

	renderAutoCompleteItems(items)
end

function moveAutoCompleteSelection(direction)
	if not autoCompleteVisible or #autoCompleteItems == 0 then
		return false
	end

	autoCompleteSelectedIndex = autoCompleteSelectedIndex + direction
	if autoCompleteSelectedIndex > #autoCompleteItems then
		autoCompleteSelectedIndex = 1
	elseif autoCompleteSelectedIndex < 1 then
		autoCompleteSelectedIndex = #autoCompleteItems
	end

	updateAutoCompleteSelection()
	return true
end

function acceptAutoComplete()
	if not autoCompleteVisible or #autoCompleteItems == 0 then
		return false
	end

	local item = autoCompleteItems[autoCompleteSelectedIndex]
	if not item then
		return false
	end

	local text = Input.Text
	local tokenStart = math.clamp(item.tokenStart or 1, 1, #text + 1)
	local tokenEnd = math.clamp(item.tokenEnd or tokenStart, tokenStart, #text + 1)
	local before = string.sub(text, 1, tokenStart - 1)
	local after = string.sub(text, tokenEnd)
	local insertText = tostring(item.value or "")

	if item.appendSpace and not startsWith(after, " ") then
		insertText = insertText .. " "
	end

	local nextText = before .. insertText .. after
	autoCompleteSuppressText = nextText
	hideAutoComplete(false)

	suppressTextRender = true
	Input.Text = nextText
	suppressTextRender = false
	Input.CursorPosition = #before + #insertText + 1
	renderCurrentState(false)

	task.defer(function()
		if isOpen and not isClosing then
			Input:CaptureFocus()
			isFocused = true
		end
	end)

	task.delay(0.2, function()
		autoCompleteConsumeFocusLost = false
	end)

	return true
end

local function updateTouchButtonVisibility()
	local shouldShow = mobileCfg.enabled
		and mobileCfg.useFloatingButton
		and UserInputService.TouchEnabled
		and not UserInputService.KeyboardEnabled
		and not isOpen
		and not isClosing

	OpenButton.Visible = shouldShow
end

local function refreshLayout(instant)
	if not behaviorCfg.responsive then
		runtimeLayout.device = "desktop"
		runtimeLayout.menuWidthScale = layoutCfg.widthScale
		runtimeLayout.maxListHeight = layoutCfg.maxListHeight
		runtimeLayout.maxMenuWidth = layoutCfg.maxWidth
		runtimeLayout.maxMenuHeight = layoutCfg.barHeight + layoutCfg.maxListHeight
		runtimeLayout.toastWidth = layoutCfg.toastWidth
		runtimeLayout.toastOffset = layoutCfg.toastOffset
	else
		local viewport = getViewportSize()
		local profile = getDeviceProfile(viewport)
		local widthScale = layoutCfg.widthScale
		local listRatio = layoutCfg.desktopHeightRatio

		if profile == "phone" then
			widthScale = layoutCfg.phoneWidthScale
			listRatio = layoutCfg.phoneHeightRatio
		elseif profile == "tablet" then
			widthScale = layoutCfg.tabletWidthScale
			listRatio = layoutCfg.tabletHeightRatio
		end

		local maxMenuWidth = math.max(260, math.min(layoutCfg.maxWidth, viewport.X - 24))
		local maxMenuHeight = math.max(layoutCfg.barHeight + 120, math.floor(viewport.Y * 0.82))
		local maxListHeight = math.max(120, math.min(layoutCfg.maxListHeight, math.floor(viewport.Y * listRatio)))
		local toastWidth = math.max(layoutCfg.minToastWidth, math.min(layoutCfg.toastWidth, viewport.X - 24))

		runtimeLayout.device = profile
		runtimeLayout.menuWidthScale = widthScale
		runtimeLayout.maxListHeight = maxListHeight
		runtimeLayout.maxMenuWidth = maxMenuWidth
		runtimeLayout.maxMenuHeight = maxMenuHeight
		runtimeLayout.toastWidth = toastWidth
		runtimeLayout.toastOffset = layoutCfg.toastOffset
	end

	UISizeConstraint_v1.MinSize = Vector2.new(math.min(layoutCfg.minWidth, runtimeLayout.maxMenuWidth), 0)
	UISizeConstraint_v1.MaxSize = Vector2.new(runtimeLayout.maxMenuWidth, runtimeLayout.maxMenuHeight)
	ToastLayer.Size = UDim2.new(0, runtimeLayout.toastWidth, 0, 0)
	ToastLayer.Position = UDim2.new(1, -runtimeLayout.toastOffset, 0, runtimeLayout.toastOffset)
	ToastListLayout.Padding = UDim.new(0, layoutCfg.toastGap)
	OpenButton.Size = UDim2.fromOffset(mobileCfg.buttonSize, mobileCfg.buttonSize)
	OpenButton.Position = UDim2.new(1, -mobileCfg.buttonRight, 1, -mobileCfg.buttonBottom)
	OpenButton.Text = mobileCfg.buttonText
	OpenButton.TextSize = math.floor(mobileCfg.buttonSize * 0.46)
	if not isOpen or isClosing then
		CommandsMenu.Position = getClosedMenuPosition()
	else
		CommandsMenu.Position = getOpenMenuPosition()
	end
	lastListHeight = -1
	updateTouchButtonVisibility()
	updateListHeight(instant == true)
end

local function applyListHeight(height, instant)
	local listGoal = UDim2.new(1, 0, 0, height)
	local menuGoal = UDim2.new(runtimeLayout.menuWidthScale, 0, 0, layoutCfg.barHeight + height)

	cancelTween(listHeightTween)
	cancelTween(menuHeightTween)

	if instant then
		CommandsList.Size = listGoal
		CommandsMenu.Size = menuGoal
		return
	end

	listHeightTween = playTween(CommandsList, TweenInfo.new(motionCfg.list, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = listGoal,
	})
	menuHeightTween = playTween(CommandsMenu, TweenInfo.new(motionCfg.list, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = menuGoal,
	})
end

updateListHeight = function(instant)
	local contentHeight = (CommandsListLayout.AbsoluteContentSize.Y / getRootScale()) + getListPaddingHeight()
	local visibleHeight = math.clamp(contentHeight, 0, runtimeLayout.maxListHeight)

	if math.abs(visibleHeight - lastListHeight) < 0.5 and not instant then
		return
	end

	lastListHeight = visibleHeight
	applyListHeight(visibleHeight, instant == true)
end

local function scheduleListHeightUpdate()
	if pendingResize then
		return
	end

	pendingResize = true
	task.defer(function()
		pendingResize = false
		updateListHeight(false)
	end)
end

local function setMenuVisualState(opened, instant, completed)
	cancelTween(menuStateTween)
	cancelTween(menuStrokeTween)
	cancelTween(dividerTween)

	local goalPosition = opened and getOpenMenuPosition() or getClosedMenuPosition()
	local goalBackgroundTransparency = opened and 0 or 1
	local goalStrokeTransparency = opened and 0.75 or 1
	local goalDividerTransparency = opened and 0.35 or 1

	if opened then
		CommandsMenu.Visible = true
	end

	if instant then
		CommandsMenu.Position = goalPosition
		CommandsMenu.BackgroundTransparency = goalBackgroundTransparency
		MenuStroke.Transparency = goalStrokeTransparency
		Divider.BackgroundTransparency = goalDividerTransparency
		if not opened then
			CommandsMenu.Visible = false
		end
		if completed then
			completed()
		end
		return
	end

	menuStateTween = playTween(CommandsMenu, TweenInfo.new(motionCfg.menu, opened and Enum.EasingStyle.Quint or Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Position = goalPosition,
		BackgroundTransparency = goalBackgroundTransparency,
	}, function(playbackState)
		if playbackState == Enum.PlaybackState.Completed and not opened then
			CommandsMenu.Visible = false
		end
		if playbackState == Enum.PlaybackState.Completed and completed then
			completed()
		end
	end)

	menuStrokeTween = playTween(MenuStroke, TweenInfo.new(motionCfg.menu, opened and Enum.EasingStyle.Quint or Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Transparency = goalStrokeTransparency,
	})

	dividerTween = playTween(Divider, TweenInfo.new(motionCfg.menu, opened and Enum.EasingStyle.Quint or Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		BackgroundTransparency = goalDividerTransparency,
	})
end

local function cancelInputTypewriter(restorePlaceholder)
	inputTypewriterVersion = inputTypewriterVersion + 1
	if restorePlaceholder then
		Input.PlaceholderText = basePlaceholderText
	end
end

local function playPlaceholderTypewriterIn()
	cancelInputTypewriter(false)

	if not behaviorCfg.typewriterOpen then
		Input.PlaceholderText = basePlaceholderText or ""
		return
	end

	local target = basePlaceholderText or ""
	if target == "" then
		Input.PlaceholderText = ""
		return
	end

	local version = inputTypewriterVersion
	Input.PlaceholderText = ""

	task.spawn(function()
		for index = 1, #target do
			if version ~= inputTypewriterVersion or isClosing or not isOpen then
				return
			end

			Input.PlaceholderText = string.sub(target, 1, index)
			task.wait(motionCfg.typewriterStep)
		end
	end)
end

local function playInputTypewriterOut(onComplete)
	cancelInputTypewriter(false)

	if not behaviorCfg.typewriterClose then
		suppressTextRender = true
		Input.Text = ""
		suppressTextRender = false
		Input.PlaceholderText = ""
		if onComplete then
			onComplete()
		end
		return
	end

	local version = inputTypewriterVersion
	local currentText = Input.Text
	local placeholderText = Input.PlaceholderText ~= "" and Input.PlaceholderText or basePlaceholderText
	local sourceText = currentText ~= "" and currentText or placeholderText
	local isTextSource = currentText ~= ""

	if sourceText == "" then
		Input.PlaceholderText = ""
		if onComplete then
			onComplete()
		end
		return
	end

	task.spawn(function()
		for remaining = #sourceText - 1, 0, -1 do
			if version ~= inputTypewriterVersion then
				return
			end

			local partial = string.sub(sourceText, 1, remaining)
			if isTextSource then
				suppressTextRender = true
				Input.Text = partial
				suppressTextRender = false
			else
				Input.PlaceholderText = partial
			end

			task.wait(motionCfg.typewriterStep)
		end

		if version ~= inputTypewriterVersion then
			return
		end

		suppressTextRender = true
		Input.Text = ""
		suppressTextRender = false
		Input.PlaceholderText = ""

		if onComplete then
			onComplete()
		end
	end)
end

function getToastTheme(kind)
	if kind == "success" then
		return READY_COLOR, Color3.fromRGB(18, 54, 33)
	end

	if kind == "error" then
		return ERROR_COLOR, Color3.fromRGB(56, 24, 24)
	end

	if kind == "warning" then
		return Color3.fromRGB(255, 213, 125), Color3.fromRGB(56, 43, 18)
	end

	if kind == "info" then
		return Color3.fromRGB(128, 186, 255), Color3.fromRGB(21, 41, 68)
	end

	return Color3.fromRGB(160, 160, 160), Color3.fromRGB(24, 24, 27)
end

function getToastIcon(kind)
	if kind == "success" then
		return "+"
	end

	if kind == "error" then
		return "x"
	end

	if kind == "warning" then
		return "!"
	end

	if kind == "info" then
		return "i"
	end

	return "."
end

function cancelTaskSafe(thread)
	if thread then
		pcall(task.cancel, thread)
	end
end

function canToast(kind)
	return toastConfig[kind] ~= false
end

function getHotkeyLabel()
	if not currentHotkey then
		return "none"
	end

	local keyText = getKeyCodeText(currentHotkey)
	if keyText and keyText ~= "" then
		return keyText
	end

	return currentHotkeyName or "unknown"
end

function normalizeToastData(messageOrOptions, options)
	local data = {}

	if type(messageOrOptions) == "table" then
		for key, value in pairs(messageOrOptions) do
			data[key] = value
		end
	else
		data.title = messageOrOptions
	end

	for key, value in pairs(options or {}) do
		data[key] = value
	end

	data.type = toLower(tostring(data.type or "default"))
	data.title = tostring(data.title or data.message or "")
	data.description = data.description ~= nil and tostring(data.description) or nil
	data.duration = type(data.duration) == "number" and data.duration or toastDuration

	if data.title == "" then
		data.title = "Notification"
	end

	return data
end

function destroyToast(id)
	local toast = toastMap[id]
	if not toast then
		return
	end

	toastMap[id] = nil
	if toast.timer then
		cancelTaskSafe(toast.timer)
		toast.timer = nil
	end
	if toast.group and toast.group.Parent then
		toast.group:Destroy()
	end
end

function dismissToast(id)
	local toast = toastMap[id]
	if not toast or toast.closing then
		return
	end

	toast.closing = true
	if toast.timer then
		cancelTaskSafe(toast.timer)
		toast.timer = nil
	end

	playTween(toast.group, TweenInfo.new(motionCfg.toastOut, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		GroupTransparency = 1,
	})
	playTween(toast.scale, TweenInfo.new(motionCfg.toastOut, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Scale = 0.96,
	}, function(playbackState)
		if playbackState == Enum.PlaybackState.Completed then
			destroyToast(id)
		end
	end)
end

function showToast(messageOrOptions, options)
	local data = normalizeToastData(messageOrOptions, options)
	local accent, border = getToastTheme(data.type)

	nextToastId = nextToastId + 1
	toastOrder = toastOrder - 1
	local id = nextToastId

	local group = Instance.new("CanvasGroup")
	group.Name = "Toast"
	group.AutomaticSize = Enum.AutomaticSize.Y
	group.BackgroundTransparency = 1
	group.BorderSizePixel = 0
	group.GroupTransparency = 1
	group.LayoutOrder = toastOrder
	group.Parent = ToastLayer
	group.Size = UDim2.new(1, 0, 0, 0)
	group.ZIndex = 51

	local scale = Instance.new("UIScale")
	scale.Name = "Scale"
	scale.Scale = 0.96
	scale.Parent = group

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
	card.BorderSizePixel = 0
	card.Parent = group
	card.Size = UDim2.new(1, 0, 0, 0)
	card.ZIndex = 52

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = border
	stroke.Thickness = 1
	stroke.Transparency = 0.15
	stroke.Parent = card

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = card

	local row = Instance.new("Frame")
	row.Name = "Row"
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.BackgroundTransparency = 1
	row.Parent = card
	row.Size = UDim2.new(1, 0, 0, 0)
	row.ZIndex = 53

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.Padding = UDim.new(0, 10)
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	rowLayout.Parent = row

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.new(0, 16, 0, 18)
	icon.Font = Enum.Font.GothamBold
	icon.Text = getToastIcon(data.type)
	icon.TextColor3 = accent
	icon.TextSize = 15
	icon.Parent = row
	icon.ZIndex = 54

	local textWrap = Instance.new("Frame")
	textWrap.Name = "Text"
	textWrap.AutomaticSize = Enum.AutomaticSize.Y
	textWrap.BackgroundTransparency = 1
	textWrap.Parent = row
	textWrap.Size = UDim2.new(1, -26, 0, 0)
	textWrap.ZIndex = 53

	local textLayout = Instance.new("UIListLayout")
	textLayout.Padding = UDim.new(0, 4)
	textLayout.SortOrder = Enum.SortOrder.LayoutOrder
	textLayout.Parent = textWrap

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamMedium
	title.RichText = false
	title.Text = data.title
	title.TextColor3 = Color3.fromRGB(235, 235, 235)
	title.TextSize = 13
	title.TextWrapped = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Top
	title.Parent = textWrap
	title.Size = UDim2.new(1, 0, 0, 0)
	title.ZIndex = 54

	if data.description and data.description ~= "" then
		local desc = Instance.new("TextLabel")
		desc.Name = "Description"
		desc.AutomaticSize = Enum.AutomaticSize.Y
		desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.Gotham
		desc.RichText = false
		desc.Text = data.description
		desc.TextColor3 = Color3.fromRGB(138, 138, 138)
		desc.TextSize = 12
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.Parent = textWrap
		desc.Size = UDim2.new(1, 0, 0, 0)
		desc.ZIndex = 54
	end

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.AnchorPoint = Vector2.new(1, 0)
	close.AutoButtonColor = false
	close.BackgroundTransparency = 1
	close.Font = Enum.Font.GothamBold
	close.Position = UDim2.new(1, 0, 0, 0)
	close.Size = UDim2.new(0, 18, 0, 18)
	close.Text = "x"
	close.TextColor3 = Color3.fromRGB(120, 120, 120)
	close.TextSize = 12
	close.TextTransparency = 0.2
	close.Parent = card
	close.ZIndex = 55

	close.MouseEnter:Connect(function()
		playTween(close, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			TextTransparency = 0,
		})
	end)

	close.MouseLeave:Connect(function()
		playTween(close, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			TextTransparency = 0.2,
		})
	end)

	close.MouseButton1Click:Connect(function()
		dismissToast(id)
	end)

	toastMap[id] = {
		group = group,
		scale = scale,
		closing = false,
	}

	playTween(group, TweenInfo.new(motionCfg.toastIn, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		GroupTransparency = 0,
	})
	playTween(scale, TweenInfo.new(motionCfg.toastIn, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Scale = 1,
	})

	if data.duration > 0 and data.duration ~= math.huge then
		toastMap[id].timer = task.delay(data.duration, function()
			dismissToast(id)
		end)
	end

	return id
end

setMenuVisualState(false, true)
refreshLayout(true)

function normalizeUserName(userName)
	if string.sub(userName or "", 1, 1) == "@" then
		return userName
	end

	return "@" .. tostring(userName or "")
end

-- Suggestions
function resolveAvatarImage(data)
	if type(data.Avatar) == "string" and data.Avatar ~= "" then
		return data.Avatar
	end

	local player = data.Player
	if typeof(player) == "Instance" and player:IsA("Player") then
		local cacheKey = tostring(player.UserId)
		if cachedAvatarImages[cacheKey] then
			return cachedAvatarImages[cacheKey]
		end

		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)

		if ok and type(image) == "string" then
			cachedAvatarImages[cacheKey] = image
			return image
		end
	end

	return ""
end

function buildSuggestionKey(kind, data)
	if type(data.Key) == "string" and data.Key ~= "" then
		return data.Key
	end

	if kind == "Player" then
		local player = data.Player
		if typeof(player) == "Instance" and player:IsA("Player") then
			return "player:" .. tostring(player.UserId)
		end

		return "player:" .. tostring(data.UserName or data.DisplayName or "unknown")
	end

	return toLower(kind) .. ":" .. tostring(data.Title or "") .. ":" .. tostring(data.Description or "")
end

function buildSuggestionSignature(kind, data, layoutOrder)
	if kind == "Player" then
		return table.concat({
			tostring(kind),
			tostring(data.DisplayName or ""),
			tostring(data.UserName or ""),
			tostring(data.Avatar or ""),
			tostring(data.Caption or ""),
			tostring(layoutOrder or 0),
		}, "\30")
	end

	return table.concat({
		tostring(kind),
		tostring(data.Title or ""),
		tostring(data.Description or ""),
		tostring(data.Caption or ""),
		tostring(layoutOrder or 0),
	}, "\30")
end

function getSuggestionEntries()
	local entries = {}
	for _, child in ipairs(CommandsList:GetChildren()) do
		if child:IsA("GuiObject") and child:GetAttribute("SuggestionEntry") == true then
			entries[#entries + 1] = child
		end
	end

	table.sort(entries, function(left, right)
		return left.LayoutOrder < right.LayoutOrder
	end)

	return entries
end

function findSuggestionEntryByKey(key)
	for _, entry in ipairs(getSuggestionEntries()) do
		if entry:GetAttribute("SuggestionKey") == key then
			return entry
		end
	end

	return nil
end

function findReusableErrorEntry(currentByKey)
	for _, entry in ipairs(getSuggestionEntries()) do
		local existingKey = entry:GetAttribute("SuggestionKey")
		if currentByKey[existingKey] == entry
			and entry:GetAttribute("SuggestionKind") ~= "Error"
			and entry:GetAttribute("SuggestionRemoving") ~= true
		then
			currentByKey[existingKey] = nil
			return entry
		end
	end

	return nil
end

function destroySuggestionEntry(entry)
	cancelEntryAnimations(entry)
	cachedEntryVisuals[entry] = nil
	if entry and entry.Parent ~= nil then
		entry:Destroy()
	end
	scheduleListHeightUpdate()
end

function destroySuggestionEntries(entries)
	local list = entries or getSuggestionEntries()
	for _, entry in ipairs(list) do
		destroySuggestionEntry(entry)
	end
	scheduleListHeightUpdate()
end

function createSuggestionEntry(kind, data, layoutOrder)
	local entry
	if kind == "Player" then
		entry = createPlayerEntry()
	else
		entry = createCommandEntry()
	end

	entry.Parent = CommandsList
	entry.Visible = true
	entry.Active = true
	entry.LayoutOrder = layoutOrder or 0
	entry:SetAttribute("SuggestionEntry", true)
	entry:SetAttribute("SuggestionRemoving", false)
	entry:SetAttribute("SuggestionVisualState", "visible")
	bindSuggestionHover(entry)
	return entry
end

function applySuggestionData(entry, kind, data)
	local key = buildSuggestionKey(kind, data)
	entry:SetAttribute("SuggestionKey", key)
	entry:SetAttribute("SuggestionKind", kind)
	entry:SetAttribute("CaptionText", trim(tostring(data.Caption or "")))

	if kind == "Player" then
		entry.Name = "PlayerEntry"
		local content = entry:FindFirstChild("Content")
		local labels = (content and content:FindFirstChild("LabelsContainer")) or entry:FindFirstChild("LabelsContainer")
		local avatar = (content and content:FindFirstChild("Avatar")) or entry:FindFirstChild("Avatar")
		local displayName = labels and labels:FindFirstChild("DisplayName")
		local userName = labels and labels:FindFirstChild("UserName")

		if displayName and displayName:IsA("TextLabel") then
			local displayText = tostring(data.DisplayName or "")
			displayName.Text = displayText
			displayName.Visible = trim(displayText) ~= ""
			displayName.TextColor3 = PLAYER_NAME_COLOR
			displayName.TextTransparency = 0
		end

		if userName and userName:IsA("TextLabel") then
			local userText = normalizeUserName(data.UserName or "")
			userName.Text = userText
			userName.Visible = trim(userText) ~= "@"
			userName.TextColor3 = PLAYER_USERNAME_COLOR
			userName.TextTransparency = 0.08
		end

		if avatar and avatar:IsA("ImageLabel") then
			avatar.Image = resolveAvatarImage(data)
			avatar.ImageTransparency = 0
		end

		if captionSource == entry and ActiveCommandCaption.Visible then
			showCommandCaption(entry:GetAttribute("CaptionText") or "", entry)
		end

		return
	end

	entry.Name = "CommandEntry"
	local title = entry:FindFirstChild("Title")
	local description = entry:FindFirstChild("Description")

	if title and title:IsA("TextLabel") then
		local titleText = tostring(data.Title or "")
		title.RichText = data.RichText == true
		title.Text = titleText
		title.Visible = trim(titleText) ~= ""
		title.TextColor3 = data.TitleColor or ((kind == "Error") and ERROR_COLOR or (kind == "Ready" and READY_COLOR or COMMAND_TITLE_COLOR))
		title.TextTransparency = data.TitleTransparency or 0
	end

	if description and description:IsA("TextLabel") then
		local descriptionText = tostring(data.Description or "")
		description.RichText = data.DescriptionRichText == true
		description.Text = descriptionText
		description.Visible = trim(descriptionText) ~= ""
		description.TextColor3 = data.DescriptionColor or ((kind == "Error") and ERROR_COLOR or (kind == "Ready" and READY_COLOR or COMMAND_DESCRIPTION_COLOR))
		description.TextTransparency = data.DescriptionTransparency or ((kind == "Error" or kind == "Ready") and 0 or 0.08)
	end

	if captionSource == entry and ActiveCommandCaption.Visible then
		showCommandCaption(entry:GetAttribute("CaptionText") or "", entry)
	end
end

function collectSuggestionMap()
	local byKey = {}
	local duplicates = {}

	for _, entry in ipairs(getSuggestionEntries()) do
		local key = entry:GetAttribute("SuggestionKey")
		if type(key) ~= "string" or key == "" then
			duplicates[#duplicates + 1] = entry
		elseif byKey[key] == nil then
			byKey[key] = entry
		else
			duplicates[#duplicates + 1] = entry
		end
	end

	return byKey, duplicates
end

function animateEntriesIn(pendingAdditions, version)
	if #pendingAdditions == 0 then
		return
	end

	local function step(index)
		if version ~= renderVersion or isClosing or not isOpen then
			return
		end

		local pending = pendingAdditions[index]
		if not pending then
			if index < #pendingAdditions then
				step(index + 1)
			end
			return
		end

		local key = pending.key or buildSuggestionKey(pending.kind, pending.definition)
		local existing = findSuggestionEntryByKey(key)

		local entry = existing
		if not entry then
			entry = createSuggestionEntry(pending.kind, pending.definition, pending.layoutOrder)
		else
			entry.LayoutOrder = pending.layoutOrder or entry.LayoutOrder
		end

		local previousSignature = entry:GetAttribute("SuggestionSignature")
		local visualState = entry:GetAttribute("SuggestionVisualState")
		local shouldAnimate = not existing
			or visualState == nil
			or visualState == "hidden"
			or visualState == "animating-out"
			or entry:GetAttribute("SuggestionRemoving") == true

		if previousSignature ~= pending.signature then
			applySuggestionData(entry, pending.kind, pending.definition)
			entry:SetAttribute("SuggestionSignature", pending.signature)
		end

		if shouldAnimate then
			setEntryVisible(entry, false)
			scheduleListHeightUpdate()
			animateEntry(entry, true, motionCfg.entryIn)
		elseif visualState ~= "visible" and visualState ~= "animating-in" then
			setEntryVisible(entry, true)
		end

		if index < #pendingAdditions then
			task.delay(motionCfg.entryGap, function()
				step(index + 1)
			end)
		end
	end

	step(1)
end

function sequentialRemoveEntries(entries, token, delayTime, exitDuration, onComplete, closing)
	local sortedEntries = {}
	for _, entry in ipairs(entries or {}) do
		if entry and entry.Parent ~= nil then
			sortedEntries[#sortedEntries + 1] = entry
		end
	end

	table.sort(sortedEntries, function(left, right)
		return left.LayoutOrder > right.LayoutOrder
	end)

	for _, entry in ipairs(sortedEntries) do
		entry:SetAttribute("SuggestionRemoving", true)
	end

	if #sortedEntries == 0 then
		if onComplete then
			onComplete()
		end
		return
	end

	local function isCancelled()
		if closing then
			return token ~= closeVersion
		end

		return token ~= renderVersion or isClosing
	end

	local function step(index)
		if isCancelled() then
			return
		end

		local entry = sortedEntries[index]
		if not entry then
			if onComplete then
				onComplete()
			end
			return
		end

		if entry.Parent == nil then
			if index < #sortedEntries then
				step(index + 1)
			elseif onComplete then
				onComplete()
			end
			return
		end

		animateEntry(entry, false, exitDuration or motionCfg.entryOut, function()
			if isCancelled() then
				return
			end

			destroySuggestionEntry(entry)

			if index < #sortedEntries then
				task.delay(delayTime or motionCfg.entryGap, function()
					step(index + 1)
				end)
			elseif onComplete then
				onComplete()
			end
		end)
	end

	step(1)
end

function normalizeDefinitionsForRender(definitions)
	local normalized = cloneArray(definitions or {})

	table.sort(normalized, function(left, right)
		local leftPriority = left.Priority or ((left.Kind or left.kind) == "Error" and 0 or 1000)
		local rightPriority = right.Priority or ((right.Kind or right.kind) == "Error" and 0 or 1000)
		if leftPriority ~= rightPriority then
			return leftPriority < rightPriority
		end

		local leftKey = tostring(left.Key or "")
		local rightKey = tostring(right.Key or "")
		return leftKey < rightKey
	end)

	return normalized
end

function renderSuggestionDefinitions(definitions, options)
	renderVersion = renderVersion + 1
	local version = renderVersion
	local normalizedDefinitions = normalizeDefinitionsForRender(definitions)
	local currentByKey, duplicateEntries = collectSuggestionMap()
	local removals = duplicateEntries
	local staggeredRemovals = {}
	local instantRemovals = {}
	local additions = {}
	options = options or {}

	for index, definition in ipairs(normalizedDefinitions) do
		local kind = definition.Kind or definition.kind or "Command"
		local key = buildSuggestionKey(kind, definition)
		local layoutOrder = definition.LayoutOrder or ((kind == "Error") and 0 or index)
		local signature = buildSuggestionSignature(kind, definition, layoutOrder)
		local disableAnimation = definition.DisableAnimation == true or kind == "Error"
		local entry = currentByKey[key]

		if not entry and kind == "Error" then
			entry = findReusableErrorEntry(currentByKey)
		end

		if entry then
			currentByKey[key] = nil
			local previousSignature = entry:GetAttribute("SuggestionSignature")
			local visualState = entry:GetAttribute("SuggestionVisualState")
			local wasRemoving = entry:GetAttribute("SuggestionRemoving") == true

			entry.LayoutOrder = layoutOrder

			if previousSignature ~= signature then
				applySuggestionData(entry, kind, definition)
				entry:SetAttribute("SuggestionSignature", signature)
			end

			if wasRemoving or visualState == "hidden" or visualState == "animating-out" then
				setEntryVisible(entry, true)
			end

			entry:SetAttribute("SuggestionRemoving", false)
		else
			if options.AnimateAdded and not disableAnimation then
				additions[#additions + 1] = {
					kind = kind,
					definition = definition,
					key = key,
					signature = signature,
					layoutOrder = layoutOrder,
				}
			else
				entry = createSuggestionEntry(kind, definition, layoutOrder)
				applySuggestionData(entry, kind, definition)
				entry:SetAttribute("SuggestionSignature", signature)
				setEntryVisible(entry, true)
			end
		end
	end

	for _, entry in pairs(currentByKey) do
		removals[#removals + 1] = entry
	end

	if #removals > 0 then
		for _, entry in ipairs(removals) do
			if entry:GetAttribute("SuggestionKind") == "Error" then
				instantRemovals[#instantRemovals + 1] = entry
			else
				staggeredRemovals[#staggeredRemovals + 1] = entry
			end
		end

		if #instantRemovals > 0 then
			destroySuggestionEntries(instantRemovals)
		end

		if #staggeredRemovals > 0 and options.StaggerRemoved then
			sequentialRemoveEntries(
				staggeredRemovals,
				version,
				options.RemoveDelay or motionCfg.entryGap,
				options.RemoveDuration or motionCfg.entryOut,
				function()
				if version == renderVersion and not isClosing then
					scheduleListHeightUpdate()
				end
				end,
				false
			)
		elseif #staggeredRemovals > 0 then
			destroySuggestionEntries(staggeredRemovals)
		end
	end

	scheduleListHeightUpdate()

	if options.AnimateAdded and #additions > 0 then
		animateEntriesIn(additions, version)
	end
end

local library = {
	Name = "Matt",
	Version = "1.0.0",
	Gui = ScreenGui,
	Refs = {
		Canvas = Canvas,
		CommandsMenu = CommandsMenu,
		CommandBar = CommandBar,
		AutoComplete = AutoComplete,
		Content = Content,
		Input = Input,
		UIScale = UIScale,
		CommandsList = CommandsList,
		Templates = {
			Folder = Examples,
			CommandSugestion = CommandSugestion,
			CommandSuggestion = CommandSugestion,
			PlayerSuggestion = PlayerSuggestion,
			CommandCaption = CommandCaption,
		},
		ActiveCommandCaption = ActiveCommandCaption,
	},
}

commandContext.UI = library

function executeCommand(text)
	local ok, result = parseForExecution(text or Input.Text, registryByName, registryByAlias)
	if not ok then
		return false, result
	end

	local success, reason = pcall(function()
		result.command.execute(commandContext, result.values)
	end)

	if not success then
		return false, {
			title = result.command.name,
			description = tostring(reason),
		}
	end

	return true, result
end

function analyzeText(text)
	return analyzeAgainstCommands(text or Input.Text, registry, registryByName, registryByAlias)
end

function renderCurrentState(animateAdded)
	if isClosing then
		return
	end

	currentState = analyzeText(Input.Text)
	local shouldAnimateAdded = animateAdded == true or currentState.kind == "commands" or currentState.kind == "players"
	local shouldStaggerRemoved = currentState.kind == "commands" or currentState.kind == "players" or currentState.kind == "error"

	renderSuggestionDefinitions(buildSuggestionDefinitions(currentState), {
		AnimateAdded = shouldAnimateAdded,
		StaggerRemoved = shouldStaggerRemoved,
		RemoveDelay = currentState.kind == "error" and motionCfg.errorGap or motionCfg.entryGap,
		RemoveDuration = currentState.kind == "error" and motionCfg.errorOut or motionCfg.entryOut,
	})
	syncAutoComplete()
end

function waitForKeyRelease(keyCode, token)
	if not keyCode then
		return true
	end

	while UserInputService:IsKeyDown(keyCode) do
		if token ~= openVersion or isClosing then
			return false
		end
		RunService.Heartbeat:Wait()
	end

	return true
end

function finishClose(token)
	if token ~= closeVersion then
		return
	end

	cancelInputTypewriter(false)
	hideAutoComplete(false)
	hideCommandCaption()
	suppressTextRender = true
	Input.Text = ""
	suppressTextRender = false
	Input.PlaceholderText = ""
	currentState = nil
	destroySuggestionEntries()
	lastListHeight = -1
	applyListHeight(0, true)
	setMenuVisualState(false, false, function()
		if token ~= closeVersion then
			return
		end
		isClosing = false
		updateTouchButtonVisibility()
	end)
end

function startClose()
	if isClosing then
		return
	end

	if not isOpen and not CommandsMenu.Visible then
		return
	end

	isOpen = false
	isFocused = false
	isClosing = true
	hideAutoComplete(true)
	hideCommandCaption()
	updateTouchButtonVisibility()
	renderVersion = renderVersion + 1
	openVersion = openVersion + 1
	closeVersion = closeVersion + 1
	local token = closeVersion
	local textFinished = false
	local entriesFinished = false

	local function tryFinish()
		if token ~= closeVersion then
			return
		end

		if textFinished and entriesFinished then
			finishClose(token)
		end
	end

	playInputTypewriterOut(function()
		textFinished = true
		tryFinish()
	end)

	local entries = getSuggestionEntries()
	if #entries == 0 then
		entriesFinished = true
		tryFinish()
		return
	end

	sequentialRemoveEntries(entries, token, motionCfg.entryGap, motionCfg.entryOut, function()
		entriesFinished = true
		tryFinish()
	end, true)
end

-- Registry
function syncContext()
	commandContext.UI = library
	return commandContext
end

function syncView()
	if isOpen and not isClosing then
		renderCurrentState(false)
	end
end

function normalizeCommands(items)
	local out = {}

	for _, item in ipairs(items or {}) do
		local cmd, reason = sanitizeCommandDefinition(item)
		if not cmd then
			return nil, reason
		end

		out[#out + 1] = cmd
	end

	return out
end

function applyRegistry(nextRegistry)
	sortCommands(nextRegistry)

	local byName, byAlias, reason = buildCommandIndexes(nextRegistry)
	if not byName then
		return false, reason
	end

	registry = nextRegistry
	registryByName = byName
	registryByAlias = byAlias
	syncView()
	return true
end

local maybeNotifyReady

function addCommands(items)
	local nextRegistry = cloneArray(registry)
	local commands, reason = normalizeCommands(items)
	if not commands then
		return false, reason
	end

	for _, cmd in ipairs(commands) do
		nextRegistry[#nextRegistry + 1] = cmd
	end

	local ok, applyReason = applyRegistry(nextRegistry)
	if not ok then
		return false, applyReason
	end

	maybeNotifyReady()

	if #commands == 1 then
		return true, commands[1]
	end

	return true, commands
end

function replaceCommands(items)
	local commands, reason = normalizeCommands(items)
	if not commands then
		return false, reason
	end

	local ok, applyReason = applyRegistry(commands)
	if not ok then
		return false, applyReason
	end

	maybeNotifyReady()
	return true
end

maybeNotifyReady = function()
	if didNotifyReady or not canToast("startup") or #registry == 0 then
		return
	end

	didNotifyReady = true
	showToast({
		type = "info",
		title = "Matt loaded",
		description = ("%d command(s) ready. Press %s to open."):format(#registry, getHotkeyLabel()),
		duration = 3.2,
	})
end

function applyNotifyOptions(options)
	if type(options) == "boolean" then
		toastConfig.startup = options
		toastConfig.updates = options
		toastConfig.errors = options
		return true
	end

	if type(options) ~= "table" then
		return false
	end

	local changed = false
	local flags = toastConfig
	for key, value in pairs(options) do
		if flags[key] ~= nil and type(value) == "boolean" then
			flags[key] = value
			changed = true
		end
	end

	return changed
end

function applyLayoutOptions(options)
	if type(options) ~= "table" then
		return false
	end

	local changed = false

	local function setNumber(target, key, minValue, maxValue)
		local raw = options[key]
		if raw == nil then
			return
		end

		local value = clampNumber(raw, minValue, maxValue)
		local write = target
		if value and write[key] ~= value then
			write[key] = value
			changed = true
		end
	end

	setNumber(layoutCfg, "widthScale", 0.35, 1)
	setNumber(layoutCfg, "openY", 0.2, 0.8)
	setNumber(layoutCfg, "closeYOffset", 0, 120)
	setNumber(layoutCfg, "barHeight", 48, 96)
	setNumber(layoutCfg, "maxListHeight", 140, 800)
	setNumber(layoutCfg, "minWidth", 220, 720)
	setNumber(layoutCfg, "maxWidth", 320, 1200)
	setNumber(layoutCfg, "listPadTop", 0, 48)
	setNumber(layoutCfg, "listPadBottom", 0, 48)
	setNumber(layoutCfg, "toastWidth", 220, 520)
	setNumber(layoutCfg, "toastGap", 0, 24)
	setNumber(layoutCfg, "toastOffset", 0, 40)
	setNumber(layoutCfg, "phoneWidthScale", 0.65, 1)
	setNumber(layoutCfg, "tabletWidthScale", 0.55, 1)
	setNumber(layoutCfg, "phoneShortSide", 480, 900)
	setNumber(layoutCfg, "tabletShortSide", 700, 1400)
	setNumber(layoutCfg, "phoneHeightRatio", 0.2, 0.7)
	setNumber(layoutCfg, "tabletHeightRatio", 0.2, 0.7)
	setNumber(layoutCfg, "desktopHeightRatio", 0.2, 0.8)
	setNumber(layoutCfg, "minToastWidth", 160, 400)

	if changed then
		CommandBar.Size = UDim2.new(1, 0, 0, layoutCfg.barHeight)
		UIPadding_v2.PaddingTop = UDim.new(0, layoutCfg.listPadTop)
		UIPadding_v2.PaddingBottom = UDim.new(0, layoutCfg.listPadBottom)
	end

	return changed
end

function applyMotionOptions(options)
	if type(options) ~= "table" then
		return false
	end

	local changed = false
	local cfg = motionCfg

	local function setNumber(key, minValue, maxValue)
		local raw = options[key]
		if raw == nil then
			return
		end

		local value = clampNumber(raw, minValue, maxValue)
		if value and cfg[key] ~= value then
			cfg[key] = value
			changed = true
		end
	end

	setNumber("menu", 0, 1)
	setNumber("list", 0, 1)
	setNumber("entryGap", 0, 0.5)
	setNumber("entryIn", 0, 0.5)
	setNumber("entryOut", 0, 0.5)
	setNumber("errorGap", 0, 0.2)
	setNumber("errorOut", 0, 0.2)
	setNumber("hiddenScale", 0.8, 1)
	setNumber("typewriterStep", 0, 0.1)
	setNumber("scale", 0, 0.6)
	setNumber("toastIn", 0, 0.6)
	setNumber("toastOut", 0, 0.6)

	return changed
end

function applyBehaviorOptions(options)
	if type(options) ~= "table" then
		return false
	end

	local changed = false
	local cfg = behaviorCfg

	local function setFlag(key)
		local value = options[key]
		if type(value) == "boolean" and cfg[key] ~= value then
			cfg[key] = value
			changed = true
		end
	end

	setFlag("responsive")
	setFlag("closeOnBlur")
	setFlag("closeOnSubmit")
	setFlag("typewriterOpen")
	setFlag("typewriterClose")

	return changed
end

function applyMobileOptions(options)
	if type(options) ~= "table" then
		return false
	end

	local changed = false
	local cfg = mobileCfg

	local function setFlag(key)
		local value = options[key]
		if type(value) == "boolean" and cfg[key] ~= value then
			cfg[key] = value
			changed = true
		end
	end

	local function setNumber(key, minValue, maxValue)
		local raw = options[key]
		if raw == nil then
			return
		end

		local value = clampNumber(raw, minValue, maxValue)
		if value and cfg[key] ~= value then
			cfg[key] = value
			changed = true
		end
	end

	setFlag("enabled")
	setFlag("useFloatingButton")
	setNumber("buttonSize", 36, 72)
	setNumber("buttonRight", 8, 60)
	setNumber("buttonBottom", 8, 120)

	if type(options.buttonText) == "string" and options.buttonText ~= mobileCfg.buttonText then
		mobileCfg.buttonText = options.buttonText
		changed = true
	end

	return changed
end

function exportConfig()
	return {
		hotkey = currentHotkeyName,
		placeholder = basePlaceholderText,
		scale = UIScale.Scale,
		notifications = {
			startup = toastConfig.startup,
			updates = toastConfig.updates,
			errors = toastConfig.errors,
		},
		layout = {
			widthScale = layoutCfg.widthScale,
			openY = layoutCfg.openY,
			closeYOffset = layoutCfg.closeYOffset,
			barHeight = layoutCfg.barHeight,
			maxListHeight = layoutCfg.maxListHeight,
			minWidth = layoutCfg.minWidth,
			maxWidth = layoutCfg.maxWidth,
			listPadTop = layoutCfg.listPadTop,
			listPadBottom = layoutCfg.listPadBottom,
			toastWidth = layoutCfg.toastWidth,
			toastGap = layoutCfg.toastGap,
			toastOffset = layoutCfg.toastOffset,
			phoneWidthScale = layoutCfg.phoneWidthScale,
			tabletWidthScale = layoutCfg.tabletWidthScale,
			phoneShortSide = layoutCfg.phoneShortSide,
			tabletShortSide = layoutCfg.tabletShortSide,
			phoneHeightRatio = layoutCfg.phoneHeightRatio,
			tabletHeightRatio = layoutCfg.tabletHeightRatio,
			desktopHeightRatio = layoutCfg.desktopHeightRatio,
			minToastWidth = layoutCfg.minToastWidth,
		},
		animations = {
			menu = motionCfg.menu,
			list = motionCfg.list,
			entryGap = motionCfg.entryGap,
			entryIn = motionCfg.entryIn,
			entryOut = motionCfg.entryOut,
			errorGap = motionCfg.errorGap,
			errorOut = motionCfg.errorOut,
			hiddenScale = motionCfg.hiddenScale,
			typewriterStep = motionCfg.typewriterStep,
			scale = motionCfg.scale,
			toastIn = motionCfg.toastIn,
			toastOut = motionCfg.toastOut,
			toastDuration = toastDuration,
		},
		behavior = {
			responsive = behaviorCfg.responsive,
			closeOnBlur = behaviorCfg.closeOnBlur,
			closeOnSubmit = behaviorCfg.closeOnSubmit,
			typewriterOpen = behaviorCfg.typewriterOpen,
			typewriterClose = behaviorCfg.typewriterClose,
		},
		mobile = {
			enabled = mobileCfg.enabled,
			useFloatingButton = mobileCfg.useFloatingButton,
			buttonText = mobileCfg.buttonText,
			buttonSize = mobileCfg.buttonSize,
			buttonRight = mobileCfg.buttonRight,
			buttonBottom = mobileCfg.buttonBottom,
		},
		runtime = {
			device = runtimeLayout.device,
			menuWidthScale = runtimeLayout.menuWidthScale,
			maxListHeight = runtimeLayout.maxListHeight,
			maxMenuWidth = runtimeLayout.maxMenuWidth,
			maxMenuHeight = runtimeLayout.maxMenuHeight,
			toastWidth = runtimeLayout.toastWidth,
			toastOffset = runtimeLayout.toastOffset,
		},
	}
end

-- Public API
function library:GetText()
	return Input.Text
end

function library:SetText(text)
	cancelInputTypewriter(true)
	suppressTextRender = true
	Input.Text = text or ""
	suppressTextRender = false
	if isOpen and not isClosing then
		renderCurrentState(false)
	end
end

function library:GetPlaceholder()
	return basePlaceholderText
end

function library:SetPlaceholder(text)
	basePlaceholderText = text or ""
	if Input.Text == "" then
		Input.PlaceholderText = basePlaceholderText
	end
end

function library:GetScale()
	return UIScale.Scale
end

function library:SetScale(scale, instant)
	if type(scale) ~= "number" then
		return false, "Scale must be a number"
	end

	if scale < MIN_SCALE or scale > MAX_SCALE then
		return false, ("Scale must be between %.1f and %.1f"):format(MIN_SCALE, MAX_SCALE)
	end

	if instant then
		UIScale.Scale = scale
		refreshLayout(true)
		if didNotifyReady and canToast("updates") then
			self:Info({
				title = "Scale updated",
				description = ("UI scale set to %.2f"):format(scale),
				duration = 2.2,
			})
		end
		return true
	end

	playTween(UIScale, TweenInfo.new(motionCfg.scale, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Scale = scale,
	})
	lastListHeight = -1
	refreshLayout(false)
	if didNotifyReady and canToast("updates") then
		self:Info({
			title = "Scale updated",
			description = ("UI scale set to %.2f"):format(scale),
			duration = 2.2,
		})
	end
	return true
end

function library:GetHotkey()
	return currentHotkeyName
end

function library:GetConfig()
	return exportConfig()
end

function library:SetHotkey(keyName)
	local ok, canonicalName, reason = resolveHotkeyName(keyName or "")
	if not ok then
		return false, reason
	end

	currentHotkeyName = canonicalName
	currentHotkey = canonicalName ~= "None" and Enum.KeyCode[canonicalName] or nil
	if didNotifyReady and canToast("updates") then
		self:Info({
			title = "Hotkey updated",
			description = ("Palette hotkey: %s"):format(getHotkeyLabel()),
			duration = 2.2,
		})
	end
	return true
end

function library:Config(options)
	options = options or {}
	local shouldRefreshLayout = false

	applyNotifyOptions(options.notifications)
	if applyLayoutOptions(options.layout) then
		shouldRefreshLayout = true
	end
	if applyMotionOptions(options.animations) then
		shouldRefreshLayout = true
	end
	if applyBehaviorOptions(options.behavior) then
		shouldRefreshLayout = true
	end
	if applyMobileOptions(options.mobile) then
		shouldRefreshLayout = true
	end

	if type(options.toast) == "table" then
		local toastLayout = {
			toastWidth = options.toast.width,
			toastGap = options.toast.gap,
			toastOffset = options.toast.offset,
		}
		if applyLayoutOptions(toastLayout) then
			shouldRefreshLayout = true
		end
		if type(options.toast.duration) == "number" then
			toastDuration = math.max(0, options.toast.duration)
		end
	end

	if type(options.toastDuration) == "number" then
		toastDuration = math.max(0, options.toastDuration)
	end

	if options.context ~= nil then
		self:SetContext(options.context)
	end

	if options.hotkey ~= nil then
		local ok, reason = self:SetHotkey(options.hotkey)
		if not ok then
			return false, reason
		end
	end

	if options.scale ~= nil then
		local ok, reason = self:SetScale(options.scale, options.instant == true or options.instantScale == true)
		if not ok then
			return false, reason
		end
	end

	if options.placeholder ~= nil then
		self:SetPlaceholder(tostring(options.placeholder))
	end

	if options.text ~= nil then
		self:SetText(tostring(options.text))
	end

	if options.commands ~= nil then
		local ok, reason = self:SetCommands(options.commands)
		if not ok then
			return false, reason
		end
	end

	if shouldRefreshLayout then
		refreshLayout(options.instant == true or options.instantLayout == true)
	end

	if options.open == true then
		self:Open(options.text, nil)
	elseif options.close == true then
		self:Close()
	end

	return true, self
end

function library:Notify(messageOrOptions, options)
	return showToast(messageOrOptions, options)
end

function library:Toast(messageOrOptions, options)
	return self:Notify(messageOrOptions, options)
end

function library:Success(messageOrOptions, options)
	options = options or {}
	options.type = "success"
	return self:Notify(messageOrOptions, options)
end

function library:Error(messageOrOptions, options)
	options = options or {}
	options.type = "error"
	return self:Notify(messageOrOptions, options)
end

function library:Warning(messageOrOptions, options)
	options = options or {}
	options.type = "warning"
	return self:Notify(messageOrOptions, options)
end

function library:Info(messageOrOptions, options)
	options = options or {}
	options.type = "info"
	return self:Notify(messageOrOptions, options)
end

function library:DismissNotification(id)
	dismissToast(id)
end

function library:DismissNotifications()
	for id in pairs(toastMap) do
		dismissToast(id)
	end
end

function library:GetCommands()
	return cloneArray(registry)
end

function library:GetCommand(name)
	local lowered = toLower(trim(name))
	if lowered == "" then
		return nil
	end

	return registryByName[lowered] or registryByAlias[lowered]
end

function library:HasCommand(name)
	return self:GetCommand(name) ~= nil
end

function library:GetContext()
	return syncContext()
end

function library:SetContext(context)
	commandContext = context or {}
	return syncContext()
end

function library:MergeContext(context)
	for key, value in pairs(context or {}) do
		commandContext[key] = value
	end

	return syncContext()
end

function library:GetState()
	return currentState
end

function library:GetViewport()
	return getViewportSize()
end

function library:RefreshLayout(instant)
	refreshLayout(instant == true)
	return true
end

function library:SetNotifications(options)
	applyNotifyOptions(options)
	return true
end

function library:SetLayout(options)
	if applyLayoutOptions(options) then
		refreshLayout(true)
	end
	return true
end

function library:SetAnimations(options)
	applyMotionOptions(options)
	return true
end

function library:SetBehavior(options)
	if applyBehaviorOptions(options) then
		refreshLayout(true)
	end
	return true
end

function library:SetMobile(options)
	if applyMobileOptions(options) then
		refreshLayout(true)
	end
	return true
end

function library:NewCommand(commandDefinition)
	local command, reason = sanitizeCommandDefinition(commandDefinition)
	if not command then
		return nil, reason
	end

	return command
end

function library:RegisterCommand(commandDefinition)
	return addCommands({ commandDefinition })
end

function library:RegisterCommands(commands)
	local ok, result = addCommands(commands)
	if not ok then
		return false, result
	end

	return true, result
end

function library:SetCommands(commands)
	return replaceCommands(commands)
end

function library:UnregisterCommand(name)
	local lowered = toLower(trim(name))
	if lowered == "" then
		return false, "Missing command name"
	end

	local nextRegistry = {}
	local removed = false

	for _, command in ipairs(registry) do
		if toLower(command.name) ~= lowered then
			nextRegistry[#nextRegistry + 1] = command
		else
			removed = true
		end
	end

	if not removed then
		return false, "Command not found"
	end

	return applyRegistry(nextRegistry)
end

function library:ClearCommands()
	registry = {}
	registryByName = {}
	registryByAlias = {}
	syncView()
	return true
end

function library:Analyze(text)
	return analyzeText(text)
end

function library:Execute(text)
	return executeCommand(text)
end

function library:GetDisplayLabel(command)
	return buildCommandTitle(command)
end

function library:GetDisplayDescription(command)
	return buildCommandDescription(command)
end

function library:ClearSuggestions(options)
	options = options or {}
	local entries = getSuggestionEntries()

	if options.Stagger then
		renderVersion = renderVersion + 1
		local version = renderVersion
		sequentialRemoveEntries(
			entries,
			version,
			options.Delay or motionCfg.entryGap,
			options.Duration or motionCfg.entryOut,
			options.OnComplete,
			false
		)
		return
	end

	destroySuggestionEntries(entries)
end

function library:CreateSuggestion(kind, data)
	local entry = createSuggestionEntry(kind, data, #getSuggestionEntries() + 1)
	applySuggestionData(entry, kind, data)
	setEntryVisible(entry, true)
	scheduleListHeightUpdate()
	return entry
end

function library:RenderSuggestions(definitions, options)
	renderSuggestionDefinitions(definitions, {
		AnimateAdded = options and options.AnimateAdded == true,
		StaggerRemoved = not (options and options.StaggerRemoved == false),
		RemoveDelay = options and options.RemoveDelay or motionCfg.entryGap,
		RemoveDuration = options and options.RemoveDuration or motionCfg.entryOut,
	})
end

function library:Render()
	renderCurrentState(false)
end

function library:Command(commandDefinition)
	local ok, commandOrReason = self:RegisterCommand(commandDefinition)
	if not ok then
		return nil, commandOrReason
	end

	return commandOrReason
end

function library:Commands(commands)
	local ok, resultOrReason = self:RegisterCommands(commands)
	if not ok then
		return nil, resultOrReason
	end

	return resultOrReason
end

function library:Open(prefillText, waitForKeyCode)
	openVersion = openVersion + 1
	closeVersion = closeVersion + 1
	local token = openVersion

	isOpen = true
	isClosing = false
	autoCompleteSuppressText = nil
	CommandsMenu.Visible = true
	updateTouchButtonVisibility()

	setMenuVisualState(true, false)
	cancelInputTypewriter(false)

	suppressTextRender = true
	Input.Text = prefillText ~= nil and tostring(prefillText) or ""
	suppressTextRender = false
	Input.PlaceholderText = Input.Text == "" and "" or basePlaceholderText

	destroySuggestionEntries()
	renderCurrentState(true)

	task.defer(function()
		if token ~= openVersion or isClosing then
			return
		end

		if not waitForKeyRelease(waitForKeyCode, token) then
			return
		end

		if token ~= openVersion or isClosing then
			return
		end

		Input:CaptureFocus()
		isFocused = true
		if Input.Text == "" then
			playPlaceholderTypewriterIn()
		end
		Input.CursorPosition = #Input.Text + 1
		syncAutoComplete()
	end)
end

function library:Close()
	if not isOpen and not CommandsMenu.Visible and not isClosing then
		return
	end

	if UserInputService:GetFocusedTextBox() == Input then
		Input:ReleaseFocus()
		task.defer(function()
			if not isClosing then
				startClose()
			end
		end)
		return
	end

	startClose()
end

function library:Toggle()
	if isOpen or isClosing then
		self:Close()
	else
		self:Open("", nil)
	end
end

function library:Focus(prefillText, waitForKeyCode)
	self:Open(prefillText, waitForKeyCode)
end

function library:IsFocused()
	return isFocused
end

function library:ClearText()
	cancelInputTypewriter(true)
	suppressTextRender = true
	Input.Text = ""
	suppressTextRender = false
	if isOpen and not isClosing then
		renderCurrentState(false)
		playPlaceholderTypewriterIn()
	end
end

function library:Submit(_submitKeyCode)
	local text = Input.Text
	hideAutoComplete(false)

	if not isBlankCommandText(text) then
		local ok, result = self:Execute(text)
		if not ok and canToast("errors") then
			self:Error({
				title = result and result.title or "Command error",
				description = result and result.description or "Unable to execute command",
				duration = 3.5,
			})
		end
	end

	if UserInputService:GetFocusedTextBox() == Input then
		Input:ReleaseFocus()
	end

	if behaviorCfg.closeOnSubmit then
		startClose()
	end
end

function library:Destroy()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end

	connections = {}
	for id in pairs(toastMap) do
		destroyToast(id)
	end
	hideAutoComplete(false)
	hideCommandCaption()
	destroySuggestionEntries()
	cancelTween(menuStateTween)
	cancelTween(menuStrokeTween)
	cancelTween(dividerTween)
	cancelTween(listHeightTween)
	cancelTween(menuHeightTween)
	cancelTween(autoCompleteFrameTween)
	cancelTween(autoCompleteStrokeTween)

	if ScreenGui and ScreenGui.Parent ~= nil then
		ScreenGui:Destroy()
	end
end

library.Configure = library.Config
library.Setup = library.Config
library.BuildCommand = library.NewCommand
library.CreateCommand = library.Command
library.CreateCommands = library.Commands
library.Bind = library.SetHotkey
library.Scale = library.SetScale
library.Placeholder = library.SetPlaceholder
library.Notifications = library.SetNotifications
library.Layout = library.SetLayout
library.Animations = library.SetAnimations
library.Behavior = library.SetBehavior
library.Mobile = library.SetMobile
library.Refresh = library.RefreshLayout
library.Alert = library.Notify
library.Notification = library.Notify
library.Show = library.Open
library.Hide = library.Close

-- Events
connections[#connections + 1] = CommandsListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scheduleListHeightUpdate()
end)

connections[#connections + 1] = UIScale:GetPropertyChangedSignal("Scale"):Connect(function()
	lastListHeight = -1
	scheduleListHeightUpdate()
	updateAutoCompletePosition()
end)

connections[#connections + 1] = Canvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	refreshLayout(true)
	updateAutoCompletePosition()
end)

connections[#connections + 1] = Input:GetPropertyChangedSignal("Text"):Connect(function()
	if suppressTextRender or not isOpen or isClosing then
		return
	end

	cancelInputTypewriter(true)
	renderCurrentState(false)
end)

connections[#connections + 1] = Input:GetPropertyChangedSignal("CursorPosition"):Connect(function()
	if not isOpen or isClosing then
		return
	end

	syncAutoComplete()
	updateAutoCompletePosition()
end)

connections[#connections + 1] = Input.Focused:Connect(function()
	isFocused = true
	syncAutoComplete()
end)

connections[#connections + 1] = Input.FocusLost:Connect(function(enterPressed, inputObject)
	isFocused = false

	if enterPressed and autoCompleteVisible and #autoCompleteItems > 0 then
		autoCompleteConsumeFocusLost = true
		acceptAutoComplete()
		return
	end

	hideAutoComplete(true)

	if autoCompleteConsumeFocusLost then
		autoCompleteConsumeFocusLost = false
		task.defer(function()
			if isOpen and not isClosing then
				Input:CaptureFocus()
				isFocused = true
			end
		end)
		return
	end

	if enterPressed then
		local submitKeyCode = nil
		if inputObject and inputObject.UserInputType == Enum.UserInputType.Keyboard then
			submitKeyCode = inputObject.KeyCode
		end

		library:Submit(submitKeyCode)
		return
	end

	if behaviorCfg.closeOnBlur then
		startClose()
	end
end)

connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	if isOpen and isFocused and autoCompleteVisible then
		if input.KeyCode == Enum.KeyCode.Down then
			moveAutoCompleteSelection(1)
			return
		end

		if input.KeyCode == Enum.KeyCode.Up then
			moveAutoCompleteSelection(-1)
			return
		end

		if input.KeyCode == Enum.KeyCode.Tab
			or input.KeyCode == Enum.KeyCode.Return
			or input.KeyCode == Enum.KeyCode.KeypadEnter
		then
			autoCompleteConsumeFocusLost = true
			if acceptAutoComplete() then
				return
			end
			autoCompleteConsumeFocusLost = false
		end
	end

	if input.KeyCode == Enum.KeyCode.Escape and (isOpen or isClosing or isFocused) then
		library:Close()
		return
	end

	if gameProcessed and not isOpen then
		return
	end

	local focusedTextBox = UserInputService:GetFocusedTextBox()
	if focusedTextBox and focusedTextBox ~= Input then
		return
	end

	if not currentHotkey or input.KeyCode ~= currentHotkey then
		return
	end

	if isOpen or isClosing then
		return
	end

	library:Open("", input.KeyCode)
end)

connections[#connections + 1] = OpenButton.MouseButton1Click:Connect(function()
	library:Toggle()
end)

return library

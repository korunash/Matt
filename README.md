# Matt

`Matt` is a command palette UI library for Roblox executors and local scripts.

This library is meant to be distributed as an obfuscated/private build and loaded via `HttpGet` (not local files). The supported way to extend and integrate it is through the public API documented below (Config, Command, Commands, etc.). Editing the library source is not part of the public workflow.

The goal is simple: load one file, register your commands, and let the library handle the rest:

- command suggestions
- player suggestions
- argument validation
- cascading list animations
- responsive layout for desktop, tablet, and phone
- built-in notifications
- runtime configuration without forcing extra modules into the user's script

If you want something that feels clean to use from an executor script, this is the shape:

```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/korunash/Matt/refs/heads/main/ui-library/source.luau"))()

library:Command({
	name = "speed",
	description = "Set your walkspeed",
	syntax = {
		{ name = "value", kind = "int", tag = "int", min = 1, max = 100 },
	},
	execute = function(_, args)
		local player = game:GetService("Players").LocalPlayer
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = args.value
		end
	end,
})
```

## Quick Start

### 1. Load the library

```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/korunash/Matt/refs/heads/main/ui-library/source.luau"))()
```

`https://raw.githubusercontent.com/korunash/Matt/refs/heads/main/ui-library/source.luau` should point to the obfuscated build you want to distribute (GitHub raw, a paste/CDN link, etc.). Local usage (readfile/loadfile) is intentionally not supported in the public workflow.

### 2. Configure the basics

```lua
library:Config({
	hotkey = "Backquote",
	placeholder = "Type a command...",
	scale = 1,
})
```

### 3. Register one or more commands

```lua
library:Commands({
	{
		name = "speed",
		aliases = { "ws", "walkspeed" },
		description = "Set your walkspeed",
		syntax = {
			{ name = "value", kind = "int", tag = "int", min = 1, max = 100 },
		},
		execute = function(_, args)
			local player = game:GetService("Players").LocalPlayer
			local character = player.Character or player.CharacterAdded:Wait()
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = args.value
			end
		end,
	},
	{
		name = "bind",
		aliases = { "hotkey", "keybind" },
		description = "Change the palette hotkey",
		syntax = {
			{ name = "key", kind = "key", tag = "key" },
		},
		execute = function(context, args)
			context.UI:SetHotkey(args.key)
		end,
	},
})
```

That is enough to get a working palette.

## Command Definition

Every command is just a table. The library sanitizes it before registration.

```lua
{
	name = "teleport",
	aliases = { "tp" },
	description = "Teleport to another player",
	syntax = {
		{ name = "target", kind = "player", tag = "player" },
	},
	execute = function(context, args)
		-- your logic here
	end,
}
```

### Supported command fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | `string` | yes | Main command name. |
| `aliases` | `{string}` | no | Alternative names. |
| `description` | `string` | no | Shown in the suggestion list. |
| `syntax` | `{table}` | no | Argument list. |
| `execute` | `function` | yes | Called when the command is submitted. |

### Supported argument kinds

| Kind | What it does |
| --- | --- |
| `param` | Plain string parameter. |
| `int` | Integer validation. |
| `number` | Decimal/integer validation. |
| `player` | Player lookup with live suggestions. |
| `key` | Hotkey validation using Roblox `Enum.KeyCode`. |

### Argument fields

| Field | Type | Notes |
| --- | --- | --- |
| `name` | `string` | Used as the parsed argument key. |
| `kind` | `string` | `param`, `int`, `number`, `player`, or `key`. |
| `tag` | `string` | The visual label shown in the command title. |
| `required` | `boolean` | Optional arguments are allowed when set to `false`. |
| `min` | `number` | Works for `int` and `number`. |
| `max` | `number` | Works for `int` and `number`. |

## Everyday API

These are the methods most users will touch often.

| Method | What it does |
| --- | --- |
| `library:Command(definition)` | Register a single command. |
| `library:Commands(definitions)` | Register many commands at once. |
| `library:Config(options)` | Apply the main runtime configuration. |
| `library:Open(text?)` | Open the palette. |
| `library:Close()` | Close the palette. |
| `library:Toggle()` | Toggle the palette. |
| `library:Notify(...)` | Show a notification. |

## Full API Reference

### Text and input

| Method | Returns | Notes |
| --- | --- | --- |
| `GetText()` | `string` | Current input text. |
| `SetText(text)` | `nil` | Replaces input text and refreshes suggestions if the palette is open. |
| `ClearText()` | `nil` | Clears input text and restores suggestion rendering. |
| `GetPlaceholder()` | `string` | Base placeholder text, not the temporary typewriter state. |
| `SetPlaceholder(text)` | `nil` | Updates the placeholder text. |
| `Submit()` | `nil` | Executes the current command flow and closes the palette if enabled. |

### Scale and hotkey

| Method | Returns | Notes |
| --- | --- | --- |
| `GetScale()` | `number` | Current `UIScale` value. |
| `SetScale(scale, instant?)` | `boolean, reason?` | Changes UI scale. |
| `GetHotkey()` | `string` | Current hotkey name. |
| `SetHotkey(keyName)` | `boolean, reason?` | Changes the palette hotkey. |

### Runtime configuration

| Method | Returns | Notes |
| --- | --- | --- |
| `Config(options)` | `true, library` or `false, reason` | Main configuration entrypoint. |
| `GetConfig()` | `table` | Snapshot of the current runtime configuration. |
| `RefreshLayout(instant?)` | `true` | Recomputes responsive layout values. |
| `SetNotifications(options)` | `true` | Notification preferences only. |
| `SetLayout(options)` | `true` | Layout and viewport settings only. |
| `SetAnimations(options)` | `true` | Animation timings only. |
| `SetBehavior(options)` | `true` | Interaction behavior only. |
| `SetMobile(options)` | `true` | Mobile button and mobile-related options only. |

### Commands and registry

| Method | Returns | Notes |
| --- | --- | --- |
| `NewCommand(definition)` | `command` or `nil, reason` | Sanitizes a command without registering it. |
| `RegisterCommand(definition)` | `true, command` or `false, reason` | Safe single registration. |
| `RegisterCommands(definitions)` | `true, commands` or `false, reason` | Safe batch registration. |
| `SetCommands(definitions)` | `true` or `false, reason` | Replaces the entire registry. |
| `UnregisterCommand(name)` | `true` or `false, reason` | Removes a command by name. |
| `ClearCommands()` | `true` | Clears the registry. |
| `GetCommands()` | `{command}` | Returns a shallow copy of the registry. |
| `GetCommand(name)` | `command?` | Finds by name or alias. |
| `HasCommand(name)` | `boolean` | Checks if a command exists. |

### Context and execution

| Method | Returns | Notes |
| --- | --- | --- |
| `GetContext()` | `table` | Returns the shared execution context. |
| `SetContext(context)` | `table` | Replaces the context and keeps `context.UI`. |
| `MergeContext(context)` | `table` | Merges values into the existing context. |
| `Analyze(text?)` | `table` | Returns the internal analysis state. |
| `Execute(text?)` | `boolean, result` | Executes a command programmatically. |
| `GetState()` | `table?` | Returns the current view state. |
| `GetViewport()` | `Vector2` | Returns the current palette viewport size. |

### UI control

| Method | Returns | Notes |
| --- | --- | --- |
| `Open(prefillText?, waitForKeyCode?)` | `nil` | Opens the palette and focuses the input. |
| `Close()` | `nil` | Closes the palette with cascading removal. |
| `Toggle()` | `nil` | Opens or closes depending on the current state. |
| `Focus(prefillText?, waitForKeyCode?)` | `nil` | Alias of `Open`. |
| `IsFocused()` | `boolean` | Whether the input is focused. |
| `Destroy()` | `nil` | Disconnects events and destroys the UI. |

### Suggestions and advanced rendering

These are mostly useful if you want to drive the list manually.

| Method | Returns | Notes |
| --- | --- | --- |
| `ClearSuggestions(options?)` | `nil` | Removes visible entries. |
| `CreateSuggestion(kind, data)` | `GuiObject` | Creates a visible entry immediately. |
| `RenderSuggestions(definitions, options?)` | `nil` | Renders custom suggestion definitions. |
| `Render()` | `nil` | Re-renders from the current input state. |
| `GetDisplayLabel(command)` | `string` | Rich text command label. |
| `GetDisplayDescription(command)` | `string` | Command description with aliases. |

### Notifications

| Method | Returns | Notes |
| --- | --- | --- |
| `Notify(messageOrOptions, options?)` | `id` | Base notification method. |
| `Toast(messageOrOptions, options?)` | `id` | Alias of `Notify`. |
| `Success(...)` | `id` | Success toast. |
| `Error(...)` | `id` | Error toast. |
| `Warning(...)` | `id` | Warning toast. |
| `Info(...)` | `id` | Info toast. |
| `DismissNotification(id)` | `nil` | Closes a single toast. |
| `DismissNotifications()` | `nil` | Closes every active toast. |

## Aliases

The library includes a few convenience aliases (quality-of-life names).

| Alias | Real method |
| --- | --- |
| `Configure` / `Setup` | `Config` |
| `BuildCommand` | `NewCommand` |
| `CreateCommand` | `Command` |
| `CreateCommands` | `Commands` |
| `Bind` | `SetHotkey` |
| `Scale` | `SetScale` |
| `Placeholder` | `SetPlaceholder` |
| `Notifications` | `SetNotifications` |
| `Layout` | `SetLayout` |
| `Animations` | `SetAnimations` |
| `Behavior` | `SetBehavior` |
| `Mobile` | `SetMobile` |
| `Refresh` | `RefreshLayout` |
| `Alert` / `Notification` | `Notify` |
| `Show` | `Open` |
| `Hide` | `Close` |

## Advanced Configuration

`Config()` is designed to be the single setup method for most users, but it also accepts optional advanced sections.

```lua
library:Config({
	hotkey = "Backquote",
	placeholder = "Type a command...",
	scale = 1,
	notifications = {
		startup = true,
		updates = true,
		errors = true,
	},
	layout = {
		widthScale = 0.65,
		maxListHeight = 456,
		minWidth = 320,
		maxWidth = 870,
		phoneWidthScale = 0.94,
		tabletWidthScale = 0.78,
	},
	animations = {
		menu = 0.14,
		list = 0.12,
		entryGap = 0.05,
		entryIn = 0.08,
		entryOut = 0.06,
		errorGap = 0.02,
		errorOut = 0.03,
		typewriterStep = 0.012,
	},
	behavior = {
		responsive = true,
		closeOnBlur = true,
		closeOnSubmit = true,
		typewriterOpen = true,
		typewriterClose = true,
	},
	mobile = {
		enabled = true,
		useFloatingButton = false,
		buttonText = ">",
		buttonSize = 48,
	},
	toast = {
		width = 320,
		gap = 10,
		offset = 18,
		duration = 4,
	},
})
```

### Config sections

#### `notifications`

```lua
notifications = {
	startup = true,
	updates = true,
	errors = true,
}
```

Controls which built-in toasts the library is allowed to show.

#### `layout`

Useful when you want to reshape the palette without rewriting internals.

- `widthScale`
- `openY`
- `closeYOffset`
- `barHeight`
- `maxListHeight`
- `minWidth`
- `maxWidth`
- `listPadTop`
- `listPadBottom`
- `toastWidth`
- `toastGap`
- `toastOffset`
- `phoneWidthScale`
- `tabletWidthScale`
- `phoneShortSide`
- `tabletShortSide`
- `phoneHeightRatio`
- `tabletHeightRatio`
- `desktopHeightRatio`
- `minToastWidth`

#### `animations`

Useful when you want the palette to feel snappier or more relaxed.

- `menu`
- `list`
- `entryGap`
- `entryIn`
- `entryOut`
- `errorGap`
- `errorOut`
- `hiddenScale`
- `typewriterStep`
- `scale`
- `toastIn`
- `toastOut`

#### `behavior`

Useful when your project wants slightly different UX rules.

- `responsive`
- `closeOnBlur`
- `closeOnSubmit`
- `typewriterOpen`
- `typewriterClose`

#### `mobile`

Useful when the palette is used on touch devices.

- `enabled`
- `useFloatingButton`
- `buttonText`
- `buttonSize`
- `buttonRight`
- `buttonBottom`

## Notifications

Notifications are built in. You do not need another module to use them from the public API.

```lua
library:Notify("Saved")

library:Success({
	title = "Done",
	description = "Walkspeed updated.",
})

library:Error({
	title = "Bind",
	description = "Missing hotkey",
	duration = 5,
})
```

The library also uses notifications internally for startup, hotkey updates, scale updates, and command errors when those notification flags are enabled.

## Mobile and Tablet Notes

This library is not desktop-only.

It already includes:

- responsive menu width
- responsive maximum list height
- responsive toast width
- support for smaller viewports

For touch-first setups, you have two practical options:

### Option 1. Open the palette from your own button

```lua
MyButton.MouseButton1Click:Connect(function()
	library:Open()
end)
```

### Option 2. Let the library show a floating mobile button

```lua
library:Config({
	mobile = {
		enabled = true,
		useFloatingButton = true,
		buttonText = ">",
		buttonSize = 48,
	},
})
```

This is useful on phone/tablet where a keyboard hotkey is not practical.

## Real Examples

### Example: player command

```lua
library:Command({
	name = "goto",
	description = "Teleport to a player",
	syntax = {
		{ name = "target", kind = "player", tag = "player" },
	},
	execute = function(_, args)
		local player = game:GetService("Players").LocalPlayer
		local character = player.Character or player.CharacterAdded:Wait()
		local root = character:FindFirstChild("HumanoidRootPart")
		local targetCharacter = args.target.Character
		local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
		if root and targetRoot then
			root.CFrame = targetRoot.CFrame + Vector3.new(2, 0, 0)
		end
	end,
})
```

### Example: context usage

```lua
library:SetContext({
	prefix = "[Matt]",
})

library:Command({
	name = "echo",
	syntax = {
		{ name = "message", kind = "param", tag = "text" },
	},
	execute = function(context, args)
		print(context.prefix, args.message)
	end,
})
```

### Example: replace the entire command list

```lua
library:SetCommands({
	{
		name = "hello",
		description = "Simple test command",
		execute = function()
			print("hello")
		end,
	},
})
```

### Example: build a command first, register later

```lua
local kickCommand, reason = library:NewCommand({
	name = "kick",
	description = "Demo command",
	syntax = {
		{ name = "target", kind = "player", tag = "player" },
	},
	execute = function(_, args)
		print("Would kick", args.target.Name)
	end,
})

if kickCommand then
	library:RegisterCommand(kickCommand)
else
	warn(reason)
end
```

Users should be able to copy a tiny setup snippet, register commands, and move on with their project. That is the standard this library is aiming for.

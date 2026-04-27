--# Animate #--
--? Alternative to Tween ?--

local RunService		= game:GetService("RunService")

local Animate	= {};
local Active	= {};

function Animate.To(Instance, Properties, Duration, Easing, Completed)
	Easing		= Easing or function(x) return x end;
	Duration	= Duration or 0.3;

	if(Active[Instance]) then
		for _, Track in pairs(Active[Instance]) do
			Track.Cancelled = true;
		end;
	end;

	Active[Instance]	= {};
	local StartValues	= {};

	for Property, _ in pairs(Properties) do
		StartValues[Property]	= Instance[Property];
	end;

	local StartTime	= tick();
	local AnimData	= { Cancelled = false };

	local Connection; Connection = RunService.PreRender:Connect(function()
		if(AnimData.Cancelled) then
			Connection:Disconnect();
			return;
		end;

		local Elapsed	= tick() - StartTime;
		local Progress	= math.min(Elapsed / Duration, 1);
		local Eased		= Easing(Progress);

		for Property, TargetValue in pairs(Properties) do
			local StartValue = StartValues[Property]

			if typeof(TargetValue) == "UDim2" then
				Instance[Property] = UDim2.new(
					StartValue.X.Scale + (TargetValue.X.Scale - StartValue.X.Scale) * Eased,
					StartValue.X.Offset + (TargetValue.X.Offset - StartValue.X.Offset) * Eased,
					StartValue.Y.Scale + (TargetValue.Y.Scale - StartValue.Y.Scale) * Eased,
					StartValue.Y.Offset + (TargetValue.Y.Offset - StartValue.Y.Offset) * Eased
				)
			elseif typeof(TargetValue) == "Color3" then
				Instance[Property] = Color3.new(
					StartValue.R + (TargetValue.R - StartValue.R) * Eased,
					StartValue.G + (TargetValue.G - StartValue.G) * Eased,
					StartValue.B + (TargetValue.B - StartValue.B) * Eased
				)
			elseif typeof(TargetValue) == "Vector2" then
				Instance[Property] = Vector2.new(
					StartValue.X + (TargetValue.X - StartValue.X) * Eased,
					StartValue.Y + (TargetValue.Y - StartValue.Y) * Eased
				)
			elseif type(TargetValue) == "number" then
				Instance[Property] = StartValue + (TargetValue - StartValue) * Eased
			end;
		end;

		if(Progress >= 1) then
			Connection:Disconnect();
			Active[Instance] = nil;
			if Completed then Completed() end;
		end;
	end);

	Active[Instance][Connection] = AnimData;

	return {
		Cancel = function()
			AnimData.Cancelled = true;
			Connection:Disconnect();
		end;
	};
end;

function Animate.Stagger(Instances, Properties, Duration, Easing, Delay, Completed)
	Delay	= Delay or 0.02;

	local Completed	= 0;
	local Total		= Instances;

	for i, Instance in pairs(Instances) do
		task.delay((i - 1) * Delay, function()
			Animate.To(Instance, Properties, Duration, Easing, function()
				Completed = Completed + 1
				if Completed >= Total and Completed then
					Completed()
				end
			end)
		end)
	end
end;

return Animate
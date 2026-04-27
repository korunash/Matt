--# Easing #--
--? Used for Animate and other ?--
local Easing = {}
do
	function Easing.CubicBezier(X1, Y1, X2, Y2)
		if X1 == Y1 and X2 == Y2 then return function(T) return T end end

		local Samples = 11
		local Step = 1 / (Samples - 1)
		local Cache = {}

		local Cx, Bx, Ax = 3 * X1, 3 * (X2 - X1) - 3 * X1, 1 - 3 * X2 + 3 * X1
		local Cy, By, Ay = 3 * Y1, 3 * (Y2 - Y1) - 3 * Y1, 1 - 3 * Y2 + 3 * Y1

		local function SampleX(T) return ((Ax * T + Bx) * T + Cx) * T end
		local function SampleY(T) return ((Ay * T + By) * T + Cy) * T end
		local function SlopeX(T) return (3 * Ax * T + 2 * Bx) * T + Cx end

		for I = 0, Samples - 1 do Cache[I] = SampleX(I * Step) end

		local function Solve(X)
			local Lo, Hi = 0, Samples - 2
			while Lo <= Hi do
				local Mid = math.floor((Lo + Hi) / 2)
				if Cache[Mid] > X then Hi = Mid - 1 else Lo = Mid + 1 end
			end
			local Idx = math.max(0, Lo - 1)

			local T0 = Idx * Step
			local D = Cache[Idx + 1] - Cache[Idx]
			local T = D > 1e-9 and T0 + ((X - Cache[Idx]) / D) * Step or T0

			for _ = 1, 4 do
				local Slope = SlopeX(T)
				if math.abs(Slope) < 1e-7 then break end
				T = T - (SampleX(T) - X) / Slope
			end

			return T
		end

		return function(X)
			if X <= 0 then return 0 end
			if X >= 1 then return 1 end
			return SampleY(Solve(X))
		end
	end
end

--# Easing Styles #--
Easing.Linear		= function(t) return t end;
Easing.Ease			= Easing.CubicBezier(0.25, 0.1, 0.25, 1.0);
Easing.EaseIn		= Easing.CubicBezier(0.42, 0, 1, 1);
Easing.EaseOut		= Easing.CubicBezier(0, 0, 0.58, 1);
Easing.EaseInOut	= Easing.CubicBezier(0.42, 0, 0.58, 1);

--? Sine ?--
Easing.SineIn		= function(t) return 1 - math.cos((t * math.pi) / 2) end;
Easing.SineOut		= function(t) return math.sin((t * math.pi) / 2) end;
Easing.SineInOut	= function(t) return -0.5 * (math.cos(math.pi * t) - 1) end;

--? Quad ?--
Easing.QuadIn		= function(t) return t * t end;
Easing.QuadOut		= function(t) return t * (2 - t) end;
Easing.QuadInOut	= function(t) if t < 0.5 then return 2 * t * t else return -1 + (4 - 2 * t) * t end end;

--? Cubic ?--
Easing.CubicIn		= function(t) return t * t * t end;
Easing.CubicOut		= function(t) local f = t - 1; return f * f * f + 1 end;
Easing.CubicInOut	= function(t) if t < 0.5 then return 4 * t * t * t else local f = (2 * t) - 2; return 0.5 * f * f * f + 1 end end;

--? Quart ?--
Easing.QuartIn		= function(t) return t * t * t * t end;
Easing.QuartOut		= function(t) local f = t - 1; return 1 - f * f * f * f end;
Easing.QuartInOut	= function(t) if t < 0.5 then return 8 * t * t * t * t else local f = t - 1; return 1 - 8 * f * f * f * f end end;

--? Quint ?--
Easing.QuintIn		= function(t) return t * t * t * t * t end;
Easing.QuintOut		= function(t) local f = t - 1; return f * f * f * f * f + 1 end;
Easing.QuintInOut	= function(t) if t < 0.5 then return 16 * t * t * t * t * t else local f = (2 * t) - 2; return 0.5 * f * f * f * f * f + 1 end end;

--? Back ?--
Easing.BackIn		= function(t) local s = 1.70158; return t * t * ((s + 1) * t - s) end;
Easing.BackOut		= function(t) local s = 1.70158; local f = t - 1; return f * f * ((s + 1) * f + s) + 1 end;
Easing.BackInOut	= function(t) local s = 1.70158; if t < 0.5 then local f = 2 * t; return 0.5 * (f * f * (( (s * 1.525) + 1) * f - s * 1.525)) else local f = (2 * t) - 2; return 0.5 * (f * f * (( (s * 1.525) + 1) * f + s * 1.525) + 2) end end;

--? Bounce ?--
Easing.BounceOut	= function(t)
	if t < 1 / 2.75 then
		return 7.5625 * t * t;
	elseif t < 2 / 2.75 then
		local f = t - (1.5 / 2.75);
		return 7.5625 * f * f + 0.75;
	elseif t < 2.5 / 2.75 then
		local f = t - (2.25 / 2.75);
		return 7.5625 * f * f + 0.9375;
	else
		local f = t - (2.625 / 2.75);
		return 7.5625 * f * f + 0.984375;
	end
end;

Easing.BounceIn		= function(t) return 1 - Easing.BounceOut(1 - t) end;
Easing.BounceInOut	= function(t)
	if t < 0.5 then
		return Easing.BounceIn(t * 2) * 0.5;
	else
		return Easing.BounceOut(t * 2 - 1) * 0.5 + 0.5;
	end
end;

--? Elastic ?--
Easing.ElasticIn	= function(t) if t == 0 or t == 1 then return t else return -math.pow(2, 10 * (t - 1)) * math.sin(( (t - 1) - 0.075) * (2 * math.pi) / 0.3) end end;
Easing.ElasticOut	= function(t) if t == 0 or t == 1 then return t else return math.pow(2, -10 * t) * math.sin(( t - 0.075) * (2 * math.pi) / 0.3) + 1 end end;
Easing.ElasticInOut	= function(t) if t == 0 or t == 1 then return t elseif t < 0.5 then return -0.5 * math.pow(2, 20 * t - 10) * math.sin(( (20 * t - 11.125) * (2 * math.pi)) / 0.45) else return math.pow(2, -20 * t + 10) * math.sin(( (20 * t - 11.125) * (2 * math.pi)) / 0.45) * 0.5 + 1 end end;

--? Expo ?--
Easing.ExpoIn		= function(t) return (t == 0) and 0 or math.pow(2, 10 * (t - 1)) end;
Easing.ExpoOut		= function(t) return (t == 1) and 1 or 1 - math.pow(2, -10 * t) end;
Easing.ExpoInOut	= function(t) if t == 0 then return 0 elseif t == 1 then return 1 elseif t < 0.5 then return 0.5 * math.pow(2, (20 * t) - 10) else return -0.5 * math.pow(2, -20 * t + 10) + 1 end end;

--? Anticipate ?--
Easing.AnticipateIn		= function(t) local s = 1.70158; return t * t * ((s + 1) * t - s) end;
Easing.AnticipateOut	= function(t) local s = 1.70158; local f = t - 1; return f * f * ((s + 1) * f + s) + 1 end;
Easing.AnticipateInOut	= function(t) local s = 1.70158; if t < 0.5 then local f = 2 * t; return 0.5 * (f * f * (( (s * 1.525) + 1) * f - s * 1.525)) else local f = (2 * t) - 2; return 0.5 * (f * f * (( (s * 1.525) + 1) * f + s * 1.525) + 2) end end;

--? Sigmoid ?--
Easing.Sigmoid		= function(t) return 1 / (1 + math.exp( -12 * (t - 0.5))) end;

--? Smoothstep ?--
Easing.Smoothstep	= function(t) return t * t * (3 - 2 * t) end;
Easing.Smoothstep2	= function(t) return t * t * t * (t * (6 * t - 15) + 10) end;

--? Impulse ?--
Easing.Impulse	= function(t, k) k = k or 5; local h = k * t; return h * math.exp(1 - h) end;

--? Modulated ?--
Easing.Gaussian	= function(t) return math.exp(-((t - 0.5) ^ 2) / 0.08) end;
Easing.Perlin	= function(t) return t * t * t * (t * (t * 6 - 15) + 10) + (math.noise(t * 10) - 0.5) * 0.1 end;

--? Steps ?--
Easing.Steps		= function(t, s) s=s or 5; return t / s * 1000 % 1 end;

--? Unstable ?--
Easing.BounceNoFloor	= function(t) return math.abs(math.sin(6.28 * t) * (1 - t)) end;
Easing.Wobble			= function(t) return math.sin(12.5664 * t) * (1 - t) + t end;
Easing.ReverseExpo		= function(t) return (t == 1) and 1 or 1 - math.pow(2, 10 * (t - 1)) end;
Easing.Quantise			= function(t, n) n = n or 5; return math.floor(t * n + 0.5) / n end;

--? From Sonner ?--
Easing.EaseEnter	= Easing.CubicBezier(0.21, 1.02, 0.73, 1);
Easing.EaseExit		= Easing.CubicBezier(0.06, 0.71, 0.55, 1);

--? M3 ?-- 
Easing.Emphasised			= Easing.CubicBezier(0.2, 0, 0, 1);
Easing.EmphasisedDecelerate	= Easing.CubicBezier(0.05, 0.7, 0.1, 1);
Easing.EmphasisedAccelerate	= Easing.CubicBezier(0.3, 0, 0.8, 0.15);

Easing.Standard				= Easing.CubicBezier(0.2, 0, 0, 1);
Easing.StandardDecelerate	= Easing.CubicBezier(0, 0, 0, 1);
Easing.StandardAccelerate	= Easing.CubicBezier(0.3, 0, 1, 1);

--? Spring ?--
Easing.Spring = function(Tension, Friction)
	Tension		= Tension or 170;
	Friction	= Friction or 26;

	return function(t)
		local Speed		= 0;
		local Value		= 0;
		local Target 	= 1;

		local Delta	= 1 / 60;
		local Steps	= math.floor(t * 60);

		for i = 1, Steps do
			local Spring	= -Tension * (Value - Target);
			local Damper	= -Friction * Speed;
			local Acceleration = Spring + Damper;
			Speed		= Speed + Acceleration * Delta;
			Value		= Value + Speed * Delta;
		end

		return Value;
	end
end

return Easing
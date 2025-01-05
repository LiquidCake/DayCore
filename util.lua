function DAYCORE_print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("DayCore: " .. msg);
end

function DAYCORE_printClean(msg)
	DEFAULT_CHAT_FRAME:AddMessage(msg);
end

function DAYCORE_printDebug(msg)
	if DAYCORE_DEBUG then
		DEFAULT_CHAT_FRAME:AddMessage("DayCore DEBUG: " .. msg);
	end
end

function DAYCORE_sanitizeString(s)
    return string.lower(
		string.gsub(s, "%s+", "")
    );
end

local TIMER_FRAME = CreateFrame("FRAME");

function DAYCORE_setTimer(delaySec, func)
	local endTime = GetTime() + delaySec;
	
	TIMER_FRAME:SetScript("OnUpdate", function()
		if (endTime < GetTime()) then
			func();
			this:SetScript("OnUpdate", nil);
		end
	end);
end

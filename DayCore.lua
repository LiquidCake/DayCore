--- configuration

local DEATH_FRAME_BACKGROUND_DELAY_SEC = 30; --for how long death screen background is not shown

local ALLOW_IGNORED_ZONES = true; --change to false to prevent ignoring some zones like battlegrounds
local IGNORED_ZONES = { --can be extended, including same zone names in different languages
	["Warsong Gulch"] = 1,
	["Arathi Basin"] = 1,
	["Alterac Valley"] = 1,
	["Sunnyglade Valley"] = 1,
	["Blood Ring"] = 1,
};

local APPEAL_TEXT = "i died because of lag or pvp or other thing i allow this character to die from"; --self-appeal captcha text, change to whatever you want

-----------------

DAYCORE_DEBUG = false;

local DAYCORE_VERSION = "1.0.0";

local DEATH_DELAY_HOURS_DEFAULT = 12;
local LIFE_RESET_NOT_SET = 0;

local MSG_DEATH_TRACKING_IN_PARTY_ENABLED = "death tracking while in party is ENABLED. To disable: /daycore disableinparty";
local MSG_DEATH_TRACKING_IN_PARTY_DISABLED = "death tracking while in party is DISABLED. To enable: /daycore enableinparty";

local mainFrame = MainFrame;
local trackingDisabledInCurrentZone = false;
local playerIsInParty = false;


AppealDescrString:SetText("To self-appeal type: \"" .. APPEAL_TEXT .. "\"");

StaticPopupDialogs["BAD_APPEAL_INPUT"] = {
	text = "Wrong appeal text",
	button1 = "Ok",
	OnAccept = function()
 	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
};


--- main logic

function mainFrame:initPersistentVarsWithDefaults()
	if deathDelayHours == nil then
		deathDelayHours = DEATH_DELAY_HOURS_DEFAULT;
	end

	if lifeResetAt == nil then
		lifeResetAt = LIFE_RESET_NOT_SET;
	end

	if unappealedDeathCount == nil then
		unappealedDeathCount = 0;
	end
	
	if allowAppeal == nil then
		allowAppeal = true;
	end
	
	if enableInParty == nil then
		enableInParty = false;
	end
end

function mainFrame:getDeathDelaySeconds()
	return deathDelayHours * 3600;
end

function mainFrame:syncAppealFeatureAvailability()
	if allowAppeal == true then
		AppealWrapper:Show();
	else
		AppealWrapper:Hide();
	end
end

function mainFrame:isInIgnoredZone(zoneName)
	return nil ~= IGNORED_ZONES[zoneName];
end

function mainFrame:isInParty()
	return GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0;
end

function mainFrame:updatePlayerPartyStatus()
	playerIsInParty = mainFrame:isInParty();
end

function mainFrame:printUnappealedDeathsCount()
	DAYCORE_printClean("unappealed deaths count: " .. tostring(unappealedDeathCount));
end

function mainFrame:printPreferences()
	DAYCORE_printClean("death blocks character for " .. tostring(deathDelayHours) .. " hours");
	DAYCORE_printClean("death tracking while in party is " .. (enableInParty == true and "enabled" or "disabled"));
	DAYCORE_printClean("self-appeal is " .. (allowAppeal == true and "enabled" or "disabled"));
end

function mainFrame:showDeathFrame(showBackground)
	mainFrame:Show();
	
	if (showBackground == true) then
		BackgroundFrame:Show();
	else
		BackgroundFrame:Hide();
	end
	
	DAYCORE_printDebug("showed death frame");
end

function mainFrame:resetDeathState()
	mainFrame:Hide();
	
	lifeResetAt = LIFE_RESET_NOT_SET;
	
	DAYCORE_printDebug("resetting death state");
end


--- events

function mainFrame:ADDON_LOADED()
	if arg1 ~= "DayCore" then
		return;
	end

	mainFrame:initPersistentVarsWithDefaults();
	
	DAYCORE_print("v" .. DAYCORE_VERSION .. " loaded - /daycore");
	
	mainFrame:printPreferences();
	
	if ALLOW_IGNORED_ZONES == true then
		DAYCORE_printClean("ignored zones list is enabled");
	
		mainFrame:ZONE_CHANGED_NEW_AREA(true);
	else
		DAYCORE_printClean("ignored zones list is disabled");
	end
	
	DAYCORE_printDebug("enableInParty= " .. tostring(enableInParty));
	DAYCORE_printDebug("allowAppeal= " .. tostring(allowAppeal));
	DAYCORE_printDebug("deathDelayHours= " .. tostring(deathDelayHours));
	DAYCORE_printDebug("lifeResetAt= " .. tostring(lifeResetAt));
	DAYCORE_printDebug("unappealedDeathCount= " .. tostring(unappealedDeathCount));
	DAYCORE_printDebug("trackingDisabledInCurrentZone= " .. tostring(trackingDisabledInCurrentZone));
	
	mainFrame:syncAppealFeatureAvailability();
	
	mainFrame:updatePlayerPartyStatus(); --just to syncronize for case when interface reloaded w/o relog

	if lifeResetAt > time() then
		mainFrame:showDeathFrame(true);
	else
		if lifeResetAt ~= LIFE_RESET_NOT_SET then
			unappealedDeathCount = unappealedDeathCount + 1;
			
			DAYCORE_printDebug("increased unappealed death count to " .. tostring(unappealedDeathCount));
		end

		mainFrame:resetDeathState();
	end
	
	mainFrame:printUnappealedDeathsCount();
	DAYCORE_printClean("  ");
end

function mainFrame:PLAYER_DEAD()
	if trackingDisabledInCurrentZone == true then
		DAYCORE_printDebug("player died but tracking is disabled in this zone");

	elseif enableInParty ~= true and playerIsInParty == true then
		DAYCORE_printDebug("player died but tracking is disabled in party");

	else
		lifeResetAt = time() + mainFrame:getDeathDelaySeconds();
		
		mainFrame:showDeathFrame(false);
		
		DAYCORE_setTimer(DEATH_FRAME_BACKGROUND_DELAY_SEC, function() BackgroundFrame:Show(); end);
		
		DAYCORE_print("You died! Come back in " .. tostring(deathDelayHours) .. " hours");
		DAYCORE_print("Your vision will fade in " .. tostring(DEATH_FRAME_BACKGROUND_DELAY_SEC) .. " seconds");
		
		if allowAppeal == true then
			DAYCORE_print("this would be a death #" .. tostring(unappealedDeathCount + 1) .. " if you dont appeal");
		else
			DAYCORE_print("this is a death #" .. tostring(unappealedDeathCount + 1));
		end

		DAYCORE_printDebug("player died, setting timestamp to " .. tostring(lifeResetAt));
	end
end

-- event wont be registered if ignored zones functionality is not enabled
function mainFrame:ZONE_CHANGED_NEW_AREA(skipPlayerNotification)
	local zoneName = GetZoneText();
	
	if mainFrame:isInIgnoredZone(zoneName) then
		DAYCORE_printDebug("player entered ignored zone: " .. zoneName);

		if skipPlayerNotification ~= true then
			DAYCORE_print("entering ignored zone. Tracking is disabled");
		end
		
		trackingDisabledInCurrentZone = true;

		mainFrame:resetDeathState();
	else
		DAYCORE_printDebug("player entered zone: " .. zoneName);
		
		if trackingDisabledInCurrentZone == true then
			if skipPlayerNotification ~= true then
				DAYCORE_print("exiting ignored zone. Tracking is re-enabled");
			end
			
			trackingDisabledInCurrentZone = false;
		end
	end
end

function mainFrame:RAID_ROSTER_UPDATE()
	mainFrame:PARTY_MEMBERS_CHANGED();
end

function mainFrame:PARTY_MEMBERS_CHANGED()
	local playerWasInParty = playerIsInParty;
	
	mainFrame:updatePlayerPartyStatus();
	
	if playerWasInParty == false and playerIsInParty == true then
		DAYCORE_printDebug("player joined the party/raid");
		
		DAYCORE_print(
			enableInParty == true and MSG_DEATH_TRACKING_IN_PARTY_ENABLED or MSG_DEATH_TRACKING_IN_PARTY_DISABLED
		);

	elseif playerWasInParty == true and playerIsInParty == false then
		DAYCORE_printDebug("player left party/raid");
		
		if enableInParty ~= true then
			DAYCORE_print("leaving party, death tracking is resumed");
		end
	end
end


mainFrame:SetScript('OnEvent', function()
	this[event]();
end);

mainFrame:RegisterEvent("ADDON_LOADED");
mainFrame:RegisterEvent("PLAYER_DEAD");
mainFrame:RegisterEvent("RAID_ROSTER_UPDATE")
mainFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")

if ALLOW_IGNORED_ZONES == true then
	mainFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA");
end

AppealInput:SetScript("OnEnterPressed", function()
	this:ClearFocus();

	if DAYCORE_sanitizeString(this:GetText()) == DAYCORE_sanitizeString(APPEAL_TEXT) then
		DAYCORE_print("self-appeal accepted");
		
		mainFrame:resetDeathState();
	else
		StaticPopup_Show("BAD_APPEAL_INPUT");
	end
end);


-- chat commands

function DAYCORE_processChatCommand(msg)
	if msg == "enableinparty" then
		enableInParty = true;
		
		DAYCORE_print("tracking in party - enabled");

	elseif msg == "disableinparty" then
		enableInParty = false;
		
		DAYCORE_print("tracking in party - disabled");

	elseif msg == "enableappeal" then
		allowAppeal = true;
		
		mainFrame:syncAppealFeatureAvailability();
		
		DAYCORE_print("self-appeal - enabled");
	
	elseif msg == "disableappeal" then
		allowAppeal = false;
		
		mainFrame:syncAppealFeatureAvailability();
		
		DAYCORE_print("self-appeal - disabled");
	
	elseif string.find(msg, "changeblockhours") then
		local hoursValStr = DAYCORE_sanitizeString(
			string.gsub(msg, "changeblockhours", "")
		);

		if string.len(hoursValStr) < 1 then
			DAYCORE_print("error: empty hours value");
			
			return;
		end
		
		local hoursVal = tonumber(hoursValStr);

		if hoursVal == nil or hoursVal < 1 or hoursVal > 9999999 then
			DAYCORE_print("error: bad hours value - must be a number between 1 and 9999999");
			
			return;
		end
		
		deathDelayHours = hoursVal;
		
		DAYCORE_print("changed death block hours amount to " .. tostring(deathDelayHours));

	else
		DAYCORE_print("semi-hardcore addon");
		DAYCORE_printClean("commands:");
		DAYCORE_printClean("  /daycore help - print this help");
		DAYCORE_printClean("  /daycore enableinparty - enable death tracking while in party");
		DAYCORE_printClean("  /daycore disableinparty - disable death tracking while in party");
		DAYCORE_printClean("  /daycore enableappeal - enable self-appeal on death screen");
		DAYCORE_printClean("  /daycore disableappeal - disable self-appeal on death screen");
		DAYCORE_printClean("  /daycore changeblockhours XXX - set death block hours value");
		DAYCORE_printClean("  ");
		mainFrame:printPreferences();
		mainFrame:printUnappealedDeathsCount();
	end
end

SLASH_DAYCORE1 = "/daycore";
SlashCmdList["DAYCORE"] = DAYCORE_processChatCommand;

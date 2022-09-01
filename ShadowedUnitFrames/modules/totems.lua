local Totems = {}
local totemColors = {}
local MAX_TOTEMS = MAX_TOTEMS

-- Death Knights untalented ghouls are guardians and are considered totems........... so set it up for them
local playerClass = select(2, UnitClass("player"))
ShadowUF:RegisterModule(Totems, "totemBar", ShadowUF.L["Totem bar"], true, "SHAMAN")

ShadowUF.BlockTimers:Inject(Totems, "TOTEM_TIMER")
ShadowUF.DynamicBlocks:Inject(Totems)

function Totems:SecureLockable()
	return MAX_TOTEMS > 1
end

function Totems:OnEnable(frame)
	if( not frame.totemBar ) then
		frame.totemBar = CreateFrame("Frame", nil, frame)
		frame.totemBar.totems = {}
		frame.totemBar.blocks = frame.totemBar.totems

		local priorities = SHAMAN_TOTEM_PRIORITIES

		for id=1, MAX_TOTEMS do
			local totem = ShadowUF.Units:CreateBar(frame.totemBar)
			totem:SetMinMaxValues(0, 1)
			totem:SetValue(0)
			totem.id = MAX_TOTEMS == 1 and 1 or priorities[id]
			totem.parent = frame

			if( id > 1 ) then
				totem:SetPoint("TOPLEFT", frame.totemBar.totems[id - 1], "TOPRIGHT", 1, 0)
			else
				totem:SetPoint("TOPLEFT", frame.totemBar, "TOPLEFT", 0, 0)
			end

			table.insert(frame.totemBar.totems, totem)
		end

		totemColors[1] = {r = 1, g = 0, b = 0.4}
		totemColors[2] = {r = 0, g = 1, b = 0.4}
		totemColors[3] = {r = 0, g = 0.4, b = 1}
		totemColors[4] = {r = 0.90, g = 0.90, b = 0.90}
	end

	frame:RegisterNormalEvent("PLAYER_TOTEM_UPDATE", self, "Update")
	frame:RegisterUpdateFunc(self, "Update")
end

function Totems:OnDisable(frame)
	frame:UnregisterAll(self)
	frame:UnregisterUpdateFunc(self, "Update")

	for _, totem in pairs(frame.totemBar.totems) do
	    totem:Hide()
    end
end

function Totems:OnLayoutApplied(frame)
	if( not frame.visibility.totemBar ) then return end

	local barWidth = (frame.totemBar:GetWidth() - (MAX_TOTEMS - 1)) / MAX_TOTEMS
	local config = ShadowUF.db.profile.units[frame.unitType].totemBar

	for _, totem in pairs(frame.totemBar.totems) do
		totem:SetHeight(frame.totemBar:GetHeight())
		totem:SetWidth(barWidth)
		totem:SetOrientation(ShadowUF.db.profile.units[frame.unitType].totemBar.vertical and "VERTICAL" or "HORIZONTAL")
		totem:SetReverseFill(ShadowUF.db.profile.units[frame.unitType].totemBar.reverse and true or false)
		totem:SetStatusBarTexture(ShadowUF.Layout.mediaPath.statusbar)
		totem:GetStatusBarTexture():SetHorizTile(false)

		totem.background:SetTexture(ShadowUF.Layout.mediaPath.statusbar)

		if( config.background or config.invert ) then
			totem.background:Show()
		else
			totem.background:Hide()
		end

		if( not ShadowUF.db.profile.units[frame.unitType].totemBar.icon ) then
			frame:SetBlockColor(totem, "totemBar", totemColors[totem.id].r, totemColors[totem.id].g, totemColors[totem.id].b)
		end

		if( config.secure ) then
			totem.secure = totem.secure or CreateFrame("Button", frame:GetName() .. "Secure" .. totem.id, totem, "SecureUnitButtonTemplate")
			totem.secure:RegisterForClicks("RightButtonUp")
			totem.secure:SetAllPoints(totem)
			totem.secure:SetAttribute("type2", "destroytotem")
			totem.secure:SetAttribute("*totem-slot*", totem.id)
			totem.secure:Show()

		elseif( totem.secure ) then
			totem.secure:Hide()
		end
	end

	self:Update(frame)
end

local function totemMonitor(self, elapsed)
	local time = GetTime()
	self:SetValue(self.endTime - time)

	if( time >= self.endTime ) then
		self:SetValue(0)
		self:SetScript("OnUpdate", nil)
		self.endTime = nil

		if( MAX_TOTEMS == 1 ) then
			ShadowUF.Layout:SetBarVisibility(self.parent, "totemBar", false)
		end
	end

	if( self.fontString ) then
		self.fontString:UpdateTags()
	end
end

function Totems:Update(frame)
	local totalActive = 0
	for _, indicator in pairs(frame.totemBar.totems) do
		local have, _name, start, duration, icon
		if MAX_TOTEMS == 1 and indicator.id == 1 then
			local id = 1
			while not have and id <= 4 do
				have, _name, start, duration, icon = GetTotemInfo(id)
				id = id + 1
			end
		else
			have, _name, start, duration, icon = GetTotemInfo(indicator.id)
		end
		if( have and start > 0 ) then
			if( ShadowUF.db.profile.units[frame.unitType].totemBar.icon ) then
				indicator:SetStatusBarTexture(icon)
			end

			indicator.have = true
			indicator.endTime = start + duration
			indicator:SetMinMaxValues(0, duration)
			indicator:SetValue(indicator.endTime - GetTime())
			indicator:SetScript("OnUpdate", totemMonitor)
			indicator:SetAlpha(1.0)
			frame:SetBlockColor(indicator,
								"totemBar",
								totemColors[indicator.id].r,
								totemColors[indicator.id].g,
								totemColors[indicator.id].b)

			totalActive = totalActive + 1

		elseif( indicator.have ) then
			indicator.have = nil
			indicator:SetScript("OnUpdate", nil)
			indicator:SetMinMaxValues(0, 1)
			indicator:SetValue(0)
			indicator.endTime = nil
		end

		if( indicator.fontString ) then
			indicator.fontString:UpdateTags()
		end
	end
end

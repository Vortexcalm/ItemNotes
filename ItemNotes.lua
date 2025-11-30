local events = {}
local IN_item
local editMode = ""
local editBox

--------------------------------------------------------------------
function events:ADDON_LOADED(...)
	local addonName = ...
	if addonName == "ItemNotes" then
		IN_Init()
		IN_Frame:UnregisterEvent("ADDON_LOADED")
	end
end

IN_Frame:SetScript("OnEvent", function(self, event, ...)
	events[event](self, ...)
end)

for i, v in pairs(events) do
	IN_Frame:RegisterEvent(i)
end

--------------------------------------------------------------------
SLASH_ITEMNOTE1 = "/inote"
SLASH_ITEMNOTE2 = "/itemnote"
function SlashCmdList.ITEMNOTE(msg, editbox)
	local taArgv, _ = SecureCmdOptionParse(msg)
	if (taArgv == nil) then return end

	IN_process(msg)
end

--------------------------------------------------------------------
function IN_Init()
	editBox = IN_Frame_ebxContent
	editBox:SetTextInsets(8,5,5,16)

	if not ITEM_NOTES then
		ITEM_NOTES = {}
		ITEM_NOTES.items = {}
	end
end
--------------------------------------------------------------------
function IN_process(msg)
	IN_Frame:Show()
	local infoType, itemID = GetCursorInfo()

	if (infoType == "item") then
		IN_setupIfEmpty(itemID)
		local itemName = GetItemInfo(itemID)
		ITEM_NOTES.items[itemID].name = itemName

		IN_Frame_Title:SetText("Item Note for " .. itemName)
		IN_item = itemID
		IN_setView("item")
		editBox:SetText(ITEM_NOTES.items[itemID].note)
	else
		IN_setView("")
		--IN_echo("ItemNote requires an item to be on cursor.")
	end
end

--------------------------------------------------------------------
function IN_setupIfEmpty(id)
	if not ITEM_NOTES then ITEM_NOTES = {} end
	if not ITEM_NOTES.items then ITEM_NOTES.items = {} end
	if not ITEM_NOTES.items[id] then
		ITEM_NOTES.items[id] = {}
		ITEM_NOTES.items[id].note = ""
		local itemName = GetItemInfo(id)
		ITEM_NOTES.items[id].name = itemName
	end
end

--------------------------------------------------------------------
function IN_escapePressed()
	IN_Frame:Hide()
end

--------------------------------------------------------------------
function IN_scrollFrameClick()
	editBox:SetCursorPosition(editBox:GetNumLetters())
	editBox:SetFocus()
end

--------------------------------------------------------------------
function IN_echo(msg)
	if not msg then
		DEFAULT_CHAT_FRAME:AddMessage("nil")
	else
		DEFAULT_CHAT_FRAME:AddMessage(msg)
	end
end

--------------------------------------------------------------------
function IN_ButtonClick(btn)
	local btnName = btn:GetName()

	if btnName == "IN_Frame_btnOK" then
		if editMode == "item" then
			local note = editBox:GetText()
			local itemName = GetItemInfo(IN_item)
			ITEM_NOTES.items[IN_item].note = note
			IN_Frame:Hide()
		elseif editMode == "import" then
			local toImport = editBox:GetText()
			local toImportArray = IN_stringSplit(toImport,"~~")

			for importCount = 1, getn(toImportArray) do
				local itemInfoArray = IN_stringSplit(toImportArray[importCount], "__")
				local itemId = itemInfoArray[1]
				local itemName = itemInfoArray[2]
				if not itemName or itemName == "nil" then itemName = "" end
				local itemNote = itemInfoArray[3]

				if itemId ~= "" and itemNote ~= "" then
					if not ITEM_NOTES.items[itemId] then ITEM_NOTES.items[itemId] = {} end
					ITEM_NOTES.items[itemId].name = itemName
					ITEM_NOTES.items[itemId].note = itemNote
				end
			end

			IN_setView("")
		else
			IN_Frame:Hide()
		end
	elseif btnName == "IN_Frame_btnImport" then
		editBox:Show()
		editBox:SetText("")
		IN_setView("import")
	elseif btnName == "IN_Frame_btnExport" then
		local exportString = ""
		-- 2Do create export string
		for k, v in pairs(ITEM_NOTES.items) do
			if exportString ~= "" then exportString = exportString .. "~~" end
			local itemName = v.name or "nil"
			local itemNote = v.note
			if itemNote == "" then itemNote = "nil" end
			exportString = exportString .. k .. "__" .. itemName .. "__" .. v.note
			IN_echo(k .. ": " .. itemName)
			IN_echo("  " .. v.note)
		end

		editBox:Show()
		editBox:SetText(exportString)
		IN_setView("export")
	elseif btnName == "IN_Frame_btnCancel" then
		if editMode == "import" or editMode == "export" then
			IN_setView("")
		elseif editMode == "item" or editMode == "" then
			IN_Frame:Hide()
		end
	elseif btnName == "IN_Frame_btnX" then
		IN_Frame:Hide()
	end
end

--------------------------------------------------------------------
function IN_stringSplit(str, delim)
	local outputArray = {}

	while str ~= "" do
		local delimStart = string.find(str, delim)
		outputArray[getn(outputArray) + 1] = (delimStart ~= nil and string.sub(str,1,delimStart - 1) or str)
		str = (delimStart ~= nil and string.sub(str,delimStart + string.len(delim)) or "")
	end
	
	return outputArray
end

--------------------------------------------------------------------
function IN_setView(view)
	editMode = view

	if editMode == "" then
		IN_Frame_sfContent:Hide()
		IN_Frame_btnOK:Hide()
		IN_Frame_btnImport:Show()
		IN_Frame_btnExport:Show()
	elseif editMode == "item" then
		IN_Frame_sfContent:Show()
		IN_Frame_btnOK:Show()
		IN_Frame_btnImport:Hide()
		IN_Frame_btnExport:Hide()
	elseif editMode == "import" then
		IN_Frame_sfContent:Show()
		IN_Frame_btnOK:Show()
		IN_Frame_btnImport:Hide()
		IN_Frame_btnExport:Hide()
		editBox:SetText("")
	elseif editMode == "export" then
		IN_Frame_sfContent:Show()
		IN_Frame_btnOK:Show()
		IN_Frame_btnImport:Hide()
		IN_Frame_btnExport:Hide()
	end
end

--------------------------------------------------------------------
function IN_TooltipSetItem(self)
	local itemName = self:GetItem()

	for i, item in pairs(ITEM_NOTES.items) do
		if item.name == itemName then
			GameTooltip:AddLine(item.note, 0, .5, 1, 1, true)
		end
	end
end

--------------------------------------------------------------------
GameTooltip:HookScript("OnTooltipSetItem",IN_TooltipSetItem)
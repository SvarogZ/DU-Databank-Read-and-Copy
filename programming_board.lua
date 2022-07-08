------------------------------
---- CUSTOM VARIABLES ---------
-------------------------------
local update_time = 0.05 --export: cycle for the package of data
local startPattern = "[s]" --export: pattern to indicate the start of the package
local stopPattern = "[e]" --export: pattern to indicate the end of the package
local stringMax = 1024 --export: max string lengh to transmite in one cycle


local function initiateSlots()
	for _, slot in pairs(unit) do
		if type(slot) == "table" and type(slot.export) == "table" and slot.getClass then
			local elementClass = slot.getClass():lower()
			if elementClass == "databankunit" then
				table.insert(databanks,slot)
			elseif elementClass == "screenunit" then
				table.insert(screens,slot)
			end
		end
	end
	
	if #databanks < 1 then
		error("No databank connected!")
	end

	if #screens < 1 then
		--system.print("No screen connected!")
		error("No screen connected!")
	end
	
	table.sort(screens, function (a, b) return (a.getLocalId() < b.getLocalId()) end)
	table.sort(databanks, function (a, b) return (a.getLocalId() < b.getLocalId()) end)
end

initiateSlots()


local data = {}
local dataKeyStings = {}

for _, databank in ipairs(databanks) do
	local keyList = databank.databank.getKeyList()
	local databankId = databank.getLocalId()
	for _, key in ipairs(keyList) do
		table.insert(dataKeyStings,table.concat({databankId,key,databank.getStringValue(key)},","))
	end
end

dataString = table.concat(dataKeyStings,";")


unit.setTimer("transmission", update_time)

function transmission()
	if not isTransmissionInProgress then
		if dataString ~= "" then
			stringToTransmit = startPattern .. dataString .. stopPattern
			--system.print("stringToTransmit = "..stringToTransmit)
			isTransmissionInProgress = true
		else
			unit.stopTimer("transmission")
		end
	end
	
	local function sendToScreen(stringData)
		for _, screen in ipairs(screens) do
			screen.setScriptInput(stringData)
		end
	end
	
	if #stringToTransmit > stringMax then
		local stringPart = string.sub(stringToTransmit,1,stringMax)
		sendToScreen(stringPart)
		stringToTransmit = string.sub(stringToTransmit,stringMax+1)
	else
		sendToScreen(stringToTransmit)
		isTransmissionInProgress = false
		unit.stopTimer("transmission")
		system.print("transmission complete")
	end
end


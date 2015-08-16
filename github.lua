--Github Client for ComputerCraft
--Created by CraftedCart

--Colour Preferences
uiCol = {
	["bg"] = colors.white,
	["txt"] = colors.black,
	["sidetxt"] = colors.lightGray,
	["heading"] = colors.red,
	["sideheading"] = colors.pink,
	["username"] = colors.blue,
	["textboxBg"] = colors.lightGray,
	["textboxTxt"] = colors.black,
	["repository"] = colors.purple,
	["navbarBg"] = colors.blue,
	["navbarTxt"] = colors.white,
	["btnBg"] = colors.lightBlue,
	["btnTxt"] = colors.black,
}

--[[
PARAMETERS
str - String - Required
	Converts the 1st letter of any string to uppercase

RETURNS
String
	The corrected string
]]
function firstToUpper(str)
	return (str:gsub("^%l", string.upper))
end

--[[
PARAMETERS
str - String - Required
	Only allows permitted characters, prevents CC from crashing with non printable characters
RETURNS
	The amended string without non printable characters
]]
function safeString(text)
	local newText = {}
	for i = 1, #text do
			local val = text:byte(i)
			newText[i] = (val > 31 and val < 127) and val or 63
	end
	return string.char(unpack(newText))
end

--Loads the JSON parser
--It the JSON parser doesn't exist, it downloads it
function getDependencies()
	--Get JSON Parser
	--TODO: Dependencies - Change URL to use stable branch once that exists
	if not fs.exists("CraftedCart/dependencies/jsonParser.lua")then
		showLoading("Downloading jf-json dependency")
		webData = http.get("https://raw.githubusercontent.com/CraftedCart/Gitter-Github-client-for-ComputerCraft/dev/CraftedCart/dependencies/jsonParser.lua")
		file = fs.open("CraftedCart/dependencies/jsonParser.lua", "w")
		file.write(webData.readAll())
		file.close()
	end

	if not fs.exists("CraftedCart/images/octocat")then
		showLoading("Downloading octocat image")
		webData = http.get("https://raw.githubusercontent.com/CraftedCart/Gitter-Github-client-for-ComputerCraft/dev/CraftedCart/images/octocat")
		file = fs.open("CraftedCart/images/octocat", "w")
		file.write(webData.readAll())
		file.close()
	end

	json = (loadfile "CraftedCart/dependencies/jsonParser.lua")()
end

w, h = term.getSize()

function showBg()
	term.setBackgroundColor(uiCol["bg"])
	term.setTextColor(uiCol["txt"])
	term.clear()

	term.setCursorPos(2, 1)
	term.setBackgroundColor(uiCol["navbarBg"])
	term.setTextColor(uiCol["navbarTxt"])
	term.clearLine()
	term.setBackgroundColor(uiCol["btnBg"])
	term.setTextColor(uiCol["btnTxt"])
	term.write("Search")

	--Change to default colours
	term.setBackgroundColor(uiCol["bg"])
	term.setTextColor(uiCol["txt"])
end

--[[
PARAMETERS
msg - String - Optional
	Will replace the default message is present
]]
function showLoading(msg)
	term.setBackgroundColor(uiCol["bg"])
	term.setTextColor(uiCol["txt"])
	term.clear()
	term.setCursorPos(2, 2)
	if msg then
		term.write(msg)
	else
		term.write("Fetching data... Hold on for a few moments")
	end
end

--[[
PARAMETERS
username - String - Required
	The username of the profile you want to get
]]
--TODO: Profile - Add clickable repos
function showProfile(username)
	showLoading()

	function getData()
		--Get profile data from Github's API
		webData = http.get("https://api.github.com/users/" .. username)
		if webData then
			profileData = json:decode(webData.readAll())
			profileResCode = webData.getResponseCode()
			webData.close()
		else
			showError("Unknown, probably 404")
			return
		end

		--Check if the response is ok
		if profileResCode ~= 200 then
			--Error
			showError(profileResCode)
			return
		end

		--Get profile repo data from Github's API
		webData = http.get("https://api.github.com/users/" .. username .. "/repos")
		if webData then
			repoData = json:decode(webData.readAll())
			repoResCode = webData.getResponseCode()
			webData.close()
		else
			showError("Unknown, probably 404")
			return
		end

		--Check if the response is ok
		if repoResCode ~= 200 then
			--Error
			showError(repoResCode)
			return
		end
	end

	showBg()

	term.setCursorPos(2, 3)
	term.setTextColor(uiCol["username"])
	term.write(profileData["login"])
	if profileData["name"] then
		term.setTextColor(uiCol["heading"])
		term.write(" " .. profileData["name"])
	end
	term.setCursorPos(2, 4)
	term.setTextColor(uiCol["sidetxt"])
	if profileData["location"] then
		term.write(profileData["location"])
	else
		term.write("Location Hidden")
	end

	--Display Repos
	term.setTextColor(uiCol["heading"])
	term.setCursorPos(2, 6)
	term.write("Repositories")

	for k, v in pairs(repoData) do
		if k + 6 == h - 1 then
			break
		end
		term.setCursorPos(2, k + 6)
		term.setTextColor(uiCol["txt"])
		term.write(v["name"])
		term.setTextColor(uiCol["sidetxt"])
		if v["description"] then
			if string.len(v["description"]) < w - string.len(v["name"]) - 3 then
				term.write(" " .. v["description"])
			else
				term.write(" " .. string.sub(v["description"], 1, w - string.len(v["name"]) - 6) .. "...")
			end
		end
	end
end

--[[
PARAMETERS
query - String - Required
	The string of text you want to search Github for
kind - String - Required
	The kind of search you want to do - Can be "repositories", "code", "issues", "users"
]]
--TODO: Search - Add issues search
--TODO: Search - Add users search
--TODO: Search - Add pages/scrolling
--TODO: Search - Make results clickable
function showSearch(query, kind)
	showLoading()

	--Get profile data from Github's API
	webData = http.get("https://api.github.com/search/" .. kind .. "?q=" .. textutils.urlEncode(query))
	if webData then
		searchData = json:decode(webData.readAll())
		searchResCode = webData.getResponseCode()
		webData.close()
	else
		showError("Unknown")
		return
	end

	--Check if the response is ok
	if searchResCode ~= 200 then
		--Error
		showError(searchResCode)
		return
	end

	showBg()

	term.setCursorPos(2, 3)
	term.setTextColor(uiCol["heading"])
	term.write(firstToUpper(kind) .. " Search: " .. query)
	term.setTextColor(uiCol["sideheading"])
	term.write(" " .. tostring(searchData["total_count"]) .. " results")

	--Display Repos
	for k, v in pairs(searchData["items"]) do
		if k + 3 == h - 1 then
			break
		end

		if kind == "repositories" then --Repo Search
			term.setCursorPos(2, k + 3)
			term.setTextColor(uiCol["username"])
			term.write(v["owner"]["login"]) --Display Username
			term.setTextColor(uiCol["sidetxt"])
			term.write("/")
			term.setTextColor(uiCol["repository"])
			term.write(v["name"]) --Display Repo Name
			term.setTextColor(uiCol["sidetxt"])
			if v["description"] then --Display Repo Description
				if string.len(v["description"]) < w - string.len(v["name"]) - string.len(v["owner"]["login"]) - 4 then
					term.write(" " .. v["description"])
				else
					term.write(" " .. string.sub(v["description"], 1, w - string.len(v["name"]) - string.len(v["owner"]["login"]) - 7) .. "...")
				end
			end
		elseif kind == "code" then --Code Search
			term.setCursorPos(2, k + 3)
			term.setTextColor(uiCol["username"])
			term.write(v["repository"]["owner"]["login"]) --Display Username
			term.setTextColor(uiCol["sidetxt"])
			term.write("/")
			term.setTextColor(uiCol["repository"])
			term.write(v["repository"]["name"]) --Display Repo Name
			term.setTextColor(uiCol["txt"])
			term.write("/" .. v["path"])
		end
	end
end

function askSearch(kind)
	showBg()
	if kind then
		term.setCursorPos(2, 3)
		term.setTextColor(uiCol["heading"])
		term.write("Search " .. firstToUpper(kind))
		term.setCursorPos(1, 4)
		term.setBackgroundColor(uiCol["textboxBg"])
		term.setTextColor(uiCol["textboxTxt"])
		term.clearLine()
		query = read()
		showSearch(query, kind)
	else
		--TODO: Search - Menu system for selecting kind of search
	end
end

--[[
PARAMETERS
resCode - String/Number - Required
	The error code given should be inserted here. If no error code is given, you can insert a string
]]
function showError(resCode)
	showBg()

	term.setCursorPos(2, 3)
	term.write("Oh No!")
	term.setCursorPos(2, 5)
	term.write("Error " .. tostring(resCode))
end

function homeMenu()
	showBg()
	octocat = paintutils.loadImage("CraftedCart/images/octocat")
	paintutils.drawImage(octocat, 2, 3)
	term.setBackgroundColor(colors.white)
	term.setTextColor(uiCol["heading"])
	term.setCursorPos(10, 17)
	term.write("Octocat")
	term.setCursorPos(26, 4)
	term.write("Gitter")
	term.setCursorPos(26, 5)
	term.write("Github client")
	term.setCursorPos(26, 7)
	term.setBackgroundColor(uiCol["btnBg"])
	term.setTextColor(uiCol["btnTxt"])
	term.write(" Search for Repos ")
	term.setCursorPos(26, 9)
	term.write(" Search for Users ")

	--Get user input
	while true do
		e, btn, x, y = os.pullEvent()
		if e == "mouse_click" then
			--Detect if button was clicked on
			if x >= 26 and x <= 43 and y == 7 then
				--User clicked on search for repos
				askSearch("repositories")
			elseif x >= 26 and x <= 43 and y == 9 then
				askSearch("users")
			end
		end
	end
end

function main()
	getDependencies()
	homeMenu()
end

--Prevent non printable characters from crashing the program
oldTermWrite = term.write
function term.write(text)
	oldTermWrite(safeString(text))
end

--Start the whole program
main()
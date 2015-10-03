--Github Client for ComputerCraft
--Created by CraftedCart

--Colour Preferences
local uiCol = {
	["bg"] = colors.white,
	["txt"] = colors.black,
	["sidetxt"] = colors.lightGray,
	["heading"] = colors.red,
	["username"] = colors.blue,
	["textboxBg"] = colors.lightGray,
	["textboxTxt"] = colors.black,
	["repository"] = colors.purple,
	["navbarBg"] = colors.blue,
	["navbarTxt"] = colors.white,
	["btnBg"] = colors.lightBlue,
	["btnTxt"] = colors.black,
	["alertBg"] = colors.yellow,
	["alertTxt"] = colors.black,
}

--Other Variables
local versionNumber = 10 --TODO: Change whenever I push out a new commit
local appName = "GitByte"
local version = "Public Alpha"
local branch = "dev"
local owner = "CraftedCart"
local website = "github.com/CraftedCart/GitByte-ComputerCraft"
local contributors = {
	"Jeffrey Friedl for providing jf-json"
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
	--Get Downloader
	--TODO: Dependencies - Change URL to use stable branch once that exists
	if not fs.exists("CraftedCart/api/downloader.lua")then
		showLoading("Downloading downloader API")
		webData = http.get("https://raw.githubusercontent.com/CraftedCart/GitByte-ComputerCraft/dev/CraftedCart/api/downloader.lua")
		file = fs.open("CraftedCart/api/downloader.lua", "w")
		file.write(webData.readAll())
		file.close()
	end

	os.loadAPI("CraftedCart/api/downloader.lua")
	downloader = _G["downloader.lua"]
	downloader.getAndInstall({
	  {"jf-json", "https://raw.githubusercontent.com/CraftedCart/GitByte-ComputerCraft/dev/CraftedCart/api/jsonParser.lua", "CraftedCart/api/jsonParser.lua"},
	  {"Octocat Image", "https://raw.githubusercontent.com/CraftedCart/GitByte-ComputerCraft/dev/CraftedCart/img/octocat", "CraftedCart/img/octocat"},
	  {"User Image", "https://raw.githubusercontent.com/CraftedCart/GitByte-ComputerCraft/dev/CraftedCart/img/user", "CraftedCart/img/user"},
	  {"Repo image", "https://raw.githubusercontent.com/CraftedCart/GitByte-ComputerCraft/dev/CraftedCart/img/repo", "CraftedCart/img/repo"}
	}, 2  )


	json = (loadfile "CraftedCart/api/jsonParser.lua")()
end

function showBg()
	term.setBackgroundColor(uiCol["bg"])
	term.setTextColor(uiCol["txt"])
	term.clear()

	term.setCursorPos(2, 1)
	term.setBackgroundColor(uiCol["navbarBg"])
	term.setTextColor(uiCol["navbarTxt"])
	term.clearLine()
	term.write(appName .. " ")
	term.setBackgroundColor(uiCol["btnBg"])
	term.setTextColor(uiCol["btnTxt"])
	term.write("Home")
	term.setCursorPos(15, 1)
	term.write("Search Repos")
	term.setCursorPos(28, 1)
	term.write("Search Users")

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
	term.setBackgroundColor(uiCol["alertBg"])
	term.setTextColor(uiCol["alertTxt"])
	term.setCursorPos(2, h)
	term.clearLine()
	if msg then
		term.write(msg)
	else
		term.write("Fetching data... Hold on for a few moments")
	end

	term.setBackgroundColor(uiCol["bg"])
	term.setTextColor(uiCol["txt"])
end

--[[
PARAMETERS
username - String - Required
	The username of the profile you want to get
]]
--TODO: Profile - Add clickable repos
function showProfile(username)
	showLoading()

	--Get profile data from Github's API
	webData = http.get("https://api.github.com/users/" .. username)
	if webData then
		profileData = json:decode(webData.readAll())
		profileResCode = webData.getResponseCode()
		webData.close()
	else
		showError("Unknown")
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
		showError("Unknown")
		return
	end

	--Check if the response is ok
	if repoResCode ~= 200 then
		--Error
		showError(repoResCode)
		return
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

	while true do
		e, btn, x, y = os.pullEvent()
		interceptAction(e, btn, x, y)
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
--TODO: Search - Add pages/scrolling
--TODO: Search - Make results clickable - Done for users
function showSearch(query, kind)
	showLoading()

	--Get 100 entries of search data from Github's API
	webData = http.get("https://api.github.com/search/" .. kind .. "?per_page=100&q=" .. textutils.urlEncode(query))
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

	--Define some variables for pagination
	local itemsPerPage = h - 6
	local offset = 0

	term.setCursorPos(2, 3)
	term.setTextColor(uiCol["heading"])
	term.write(firstToUpper(kind) .. " Search: " .. query)

	term.setCursorPos(2, h)
	term.setBackgroundColor(uiCol["navbarBg"])
	term.setTextColor(uiCol["navbarTxt"])
	term.clearLine()

	term.write("Showing items ")
	if searchData["total_count"] < offset + 1 then
		term.write(tostring(searchData["total_count"]))
	else
		term.write(tostring(offset + 1))
	end
	term.write(" - ")
	if searchData["total_count"] < offset + itemsPerPage + 1 then
		term.write(tostring(searchData["total_count"]))
	else
		term.write(tostring(offset + itemsPerPage + 1))
	end
	term.write(" / " .. tostring(searchData["total_count"]))

	term.setBackgroundColor(uiCol["bg"])

	--Display search results
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
		elseif kind == "users" then --User Search
			term.setCursorPos(2, k + 3)
			term.setTextColor(uiCol["username"])
			term.write(v["login"]) --Display Username
		end
	end

	while true do
		e, btn, x, y = os.pullEvent()
		interceptAction(e, btn, x, y)
		if e == "mouse_click" then
			if x >=2 and x <= w - 1 and y >= 4 and y <= h - 3 then
				--User clicked an entry
				if kind == "users" and searchData["items"][y - 3] then
					--If users search and entry exists
					showProfile(searchData["items"][y - 3]["login"])
					break
				end
			end
		end
	end
end

function askSearch(kind)
	showBg()
	if kind then
		term.setCursorPos(2, 3)
		term.setTextColor(uiCol["heading"])
		term.write("Search " .. firstToUpper(kind))
		if kind == "repositories" then
			paintutils.drawImage(repoIcon, 2, 6)
		elseif kind == "users" then
			paintutils.drawImage(userIcon, 2, 6)
		end
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

	while true do
		e, btn, x, y = os.pullevent()
		interceptAction(e, btn, x, y)
	end
end

function showAbout() --The about page
	showBg()
	term.setCursorPos(2, 3)
	term.setTextColor(uiCol["heading"])
	term.write(appName .. " " .. version)
	term.setTextColor(uiCol["sidetxt"])
	term.write(" #" .. versionNumber)
	term.setCursorPos(2, 4)
	term.setTextColor(uiCol["txt"])
	term.write("Branch: " .. branch)
	term.setCursorPos(2, 5)
	term.write(website)
	term.setCursorPos(2, 7)
	term.write("By " .. owner)
	term.setCursorPos(2, 9)
	term.setTextColor(uiCol["heading"])
	term.write("Contributors")
	term.setTextColor(uiCol["txt"])
	for k, v in pairs(contributors) do
		term.setCursorPos(2, k + 9)
		term.write(v)
	end
	while true do
		e, btn, x, y = os.pullEvent()
		interceptAction(e, btn, x, y)
	end
end

--[[
PARAMETERS
e
	The event that happened - Required
btn
	The mouse button that was clicked - Pointless at the moment
x
	The x pos of the mouse - Required
y
	The y pos of the mouse - Required
--Basically, pass it the variables that os.pullEvent() does
]]
function interceptAction(e, btn, x, y)
	if e == "mouse_click" then
		if x >= 10 and x <= 13 and y == 1 then
			--User clicked the home button
			homeMenu()
		elseif x >= 15 and x <= 26 and y == 1 then
			--User clicked the search repos button
			askSearch("repositories")
		elseif x >= 28 and x <= 39 and y == 1 then
			--User clicked the search users button
			askSearch("users")
		end
	end
end

function loadImages()
	octocat = paintutils.loadImage("CraftedCart/img/octocat")
	userIcon = paintutils.loadImage("CraftedCart/img/user")
	repoIcon = paintutils.loadImage("CraftedCart/img/repo")
end

function homeMenu()
	showBg()
	paintutils.drawImage(octocat, 2, 3)
	term.setBackgroundColor(colors.white)
	term.setTextColor(uiCol["heading"])
	term.setCursorPos(10, 17)
	term.write("Octocat")
	term.setCursorPos(26, 4)
	term.write(appName)
	term.setCursorPos(26, 5)
	term.write("Github client")
	term.setCursorPos(26, 7)
	term.setBackgroundColor(uiCol["btnBg"])
	term.setTextColor(uiCol["btnTxt"])
	term.write(" Search for Repos ")
	term.setCursorPos(26, 9)
	term.write(" Search for Users ")
	term.setCursorPos(26, h - 1)
	term.write(" About " .. appName .. "    ")

	--Get user input
	while true do
		e, btn, x, y = os.pullEvent()
		interceptAction(e, btn, x, y)
		if e == "mouse_click" then
			--Detect if button was clicked on
			if x >= 26 and x <= 43 and y == 7 then
				--User clicked on search for repos
				askSearch("repositories")
			elseif x >= 26 and x <= 43 and y == 9 then
				--User clicked on search for repos
				askSearch("users")
			elseif x >= 26 and x <= 43 and y == h - 1 then
				--User clicked on about GitByte
				showAbout()
			end
		end
	end
end

function main()
	w, h = term.getSize()

	term.setBackgroundColor(uiCol["bg"])
	term.clear()
	getDependencies()
	loadImages()
	homeMenu()
end

--Prevent non printable characters from crashing the program
if not oldTermWrite then
	oldTermWrite = term.write
end
function term.write(text)
	oldTermWrite(safeString(text))
end

--Start the whole program
main()

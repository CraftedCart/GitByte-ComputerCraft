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
	["progBarActive"] = colors.lime,
	["progBarBg"] = colors.gray,
	["progBarOutline"] = colors.lightGray,
	["progBarTxt"] = colors.black,
}

--Other Preferences
local prefs = {
	["dlLocation"] = "/Downloads"
}

--Other Variables
local versionNumber = 14 --TODO: Change whenever I push out a new commit
local appName = "GitByte"
local version = "Public Alpha"
local branch = "dev"
local owner = "CraftedCart"
local website = "github.com/CraftedCart/GitByte-ComputerCraft"
local contributors = {
	"Jeffrey Friedl for providing the jf-json API",
	"Minebuild02 for providing the base64 API"
}
local authUsername
local authToken
local isAuthed = false


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
	if not fs.exists("CraftedCart/api/downloader.lua") then
		showLoading("Downloading downloader API")
		webData = http.get("https://raw.githubusercontent.com/CraftedCart/GitByte-ComputerCraft/dev/CraftedCart/api/downloader.lua")
		file = fs.open("CraftedCart/api/downloader.lua", "w")
		file.write(webData.readAll())
		file.close()
	end

	os.loadAPI("CraftedCart/api/downloader.lua")
	downloader = _G["downloader.lua"]
	downloader.getAndInstall({
	  {"jf-json API", "https://raw.githubusercontent.com/CraftedCart/GitByte-ComputerCraft/dev/CraftedCart/api/jsonParser.lua", "CraftedCart/api/jsonParser.lua"},
	  {"Octocat Image", "https://raw.githubusercontent.com/CraftedCart/GitByte-ComputerCraft/dev/CraftedCart/img/octocat", "CraftedCart/img/octocat"},
	  {"User Image", "https://raw.githubusercontent.com/CraftedCart/GitByte-ComputerCraft/dev/CraftedCart/img/user", "CraftedCart/img/user"},
	  {"Repo Image", "https://raw.githubusercontent.com/CraftedCart/GitByte-ComputerCraft/dev/CraftedCart/img/repo", "CraftedCart/img/repo"},
		{"Base64 API", "https://raw.githubusercontent.com/CraftedCart/GitByte-ComputerCraft/dev/CraftedCart/api/base64.lua", "CraftedCart/api/base64.lua"}
	}, 2  )


	json = (loadfile "CraftedCart/api/jsonParser.lua")()
	os.loadAPI("CraftedCart/api/base64.lua")
	base64 = _G["base64.lua"]
end

function checkRateLimit()
	showLoading()
	web = http.get("https://api.github.com/rate_limit", {["Authorization"] = authToken})
	data = json:decode(web.readAll())
	coreReset = json:decode(http.get("http://www.convert-unix-time.com/api?timestamp=" .. tostring(data["resources"]["core"]["reset"])).readAll())
	searchReset = json:decode(http.get("http://www.convert-unix-time.com/api?timestamp=" .. tostring(data["resources"]["search"]["reset"])).readAll())
	return data, coreReset, searchReset
end

function hitRateLimit()
	showError("You've hit the rate limit\n\n " ..
	"The GitHub API enforces a limit to the amount of\n " ..
	"actions that you can do within a certain\n " ..
	"time frame\n\n " ..
	"You've hit the limit, so you need to wait\n " ..
	"before using " .. appName .. " again")
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
	term.setCursorPos(w, 1)
	term.write("X")

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
fullName - String - Required
	The full name of the repo to download (Eg: CraftedCart/GitByte-ComputerCraft)
branch - String - Required
	Which branch to download
]]
function downloadRepo(fullName, branch)
	local files = {}
	local dirs = {}
	local size = 0
	local freeSpace = fs.getFreeSpace(prefs["dlLocation"])
	local data

	local web = http.get("https://api.github.com/repos/" .. fullName .. "/git/trees/" .. branch .. "?recursive=1", {["Authorization"] = authToken})
	if web then
		data = json:decode(web.readAll())
	else
		return showError("Couldn't access the file tree\n You might have hit the resoucre limit")
	end

	for k, v in pairs(data["tree"]) do
	  if v["type"] == "tree" then
	    table.insert(dirs, prefs["dlLocation"] .. "/" .. fullName .. "/" .. v["path"])
	  elseif v["type"] == "blob" then
	    table.insert(files,{v["path"], "https://raw.githubusercontent.com/" .. fullName .. "/" .. branch .. "/" .. v["path"], prefs["dlLocation"] .. "/" .. fullName .. "/" .. v["path"]})
			size = size + v["size"]
	  end
	end

	if size > freeSpace then
		return showError("Not enough free space\n\n " ..
		"Free space avaliable: " .. tostring(freeSpace) .. " bytes\n " ..
		"Size of repo: " .. tostring(size) .. " bytes\n\n " ..
		"That's " .. tostring(size - freeSpace) .. " more bytes that what you have")
	end

	for k, v in pairs(dirs) do
	  fs.makeDir(v)
	end

	downloader.getAndInstall(files, 4)

	return homeMenu()

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
	webData = http.get("https://api.github.com/users/" .. username, {["Authorization"] = authToken})
	if webData then
		profileData = json:decode(webData.readAll())
		profileResCode = webData.getResponseCode()
		webData.close()
	else
		local rate = checkRateLimit()
		if rate["resources"]["core"]["remaining"] == 0 then
			return hitRateLimit()
		else
			return showError("Unknown")
		end
	end

	--Check if the response is ok
	if profileResCode ~= 200 then
		--Error
		return showError(profileResCode)
	end

	--Get profile repo data from Github's API
	webData = http.get("https://api.github.com/users/" .. username .. "/repos?per_page=100", {["Authorization"] = authToken})
	if webData then
		repoData = json:decode(webData.readAll())
		repoResCode = webData.getResponseCode()
		webData.close()
	else
		local rate = checkRateLimit()
		if rate["resources"]["core"]["remaining"] == 0 then
			return hitRateLimit()
		else
			return showError("Unknown")
		end
	end

	--Check if the response is ok
	if repoResCode ~= 200 then
		--Error
		return showError(repoResCode)
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

	local function displayUserRepos(offset, length)
		--Display Repos
		term.setBackgroundColor(uiCol["bg"])
		term.setTextColor(uiCol["heading"])
		term.setCursorPos(2, 6)
		term.write("Repositories")

		for k, v in pairs(repoData) do
			if k + 6 == h - 1 then
				break
			end

			if repoData[k + offset] then
				term.setCursorPos(2, k + 6)
				term.setTextColor(uiCol["txt"])
				term.clearLine()
				term.write(repoData[k + offset]["name"])
				term.setTextColor(uiCol["sidetxt"])
				if repoData[k + offset]["description"] then
					if string.len(repoData[k + offset]["description"]) < w - string.len(repoData[k + offset]["name"]) - 3 then
						term.write(" " .. repoData[k + offset]["description"])
					else
						term.write(" " .. string.sub(repoData[k + offset]["description"], 1, w - string.len(repoData[k + offset]["name"]) - 6) .. "...")
					end
				end
			end
		end

		term.setCursorPos(2, h)
		term.setBackgroundColor(uiCol["navbarBg"])
		term.setTextColor(uiCol["navbarTxt"])
		term.clearLine()
		if h - 8 + offset > length then
			term.write("Showing items " .. tostring(offset + 1) .. " - " .. tostring(length) .. " / " .. tostring(length))
		else
			term.write("Showing items " .. tostring(offset + 1) .. " - " .. tostring(h - 8 + offset) .. " / " .. tostring(length))
		end

		term.setCursorPos(w - 5, h)
		term.setBackgroundColor(uiCol["btnBg"])
		term.setTextColor(uiCol["btnTxt"])
		term.write("/\\")

		term.setCursorPos(w - 2, h)
		term.setBackgroundColor(uiCol["btnBg"])
		term.setTextColor(uiCol["btnTxt"])
		term.write("\\/")
	end

	local scrollOffset = 0
	local length = table.getn(repoData)
	while true do
		displayUserRepos(scrollOffset, length)

		e, btn, x, y = os.pullEvent()

		interceptAction(e, btn, x, y)
		if e == "mouse_click" then
			if x >= w - 5 and x <= w - 4 and y == h then
				--Scroll up clicked
				if scrollOffset ~= 0 then
					scrollOffset = scrollOffset - 1
				end

			elseif x >= w - 2 and x <= w - 1 and y == h then
				--Scroll down clicked
				if h - 8 + scrollOffset < length then
					scrollOffset = scrollOffset + 1
				end
			end
		elseif e == "mouse_scroll" then
			if btn == -1 then
				--Scroll up clicked
				if scrollOffset ~= 0 then
					scrollOffset = scrollOffset - 1
				end
			elseif btn == 1 then
				--Scroll down clicked
				if h - 8 + scrollOffset < length then
					scrollOffset = scrollOffset + 1
				end
			end
		end
	end
end

--[[
PARAMETERS
query - String - Required
	The string of text you want to search Github for
kind - String - Required
	The kind of search you want to do - Can be "repositories", "users", "code", "issues"
]]
--TODO: Search - Add issues search
--TODO: Search - Add pages/scrolling
--TODO: Search - Make results clickable - Done for users
function showSearch(query, kind)
	showLoading()

	--Get 100 entries of search data from Github's API
	webData = http.get("https://api.github.com/search/" .. kind .. "?per_page=100&q=" .. textutils.urlEncode(query), {["Authorization"] = authToken})
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
					return showProfile(searchData["items"][y - 3]["login"])
				elseif kind == "repositories" and searchData["items"][y - 3] then
					return downloadRepo(searchData["items"][y - 3]["full_name"], searchData["items"][y - 3]["default_branch"]) --TODO: Change to ask for a branch, and maybe show readme and info
					--TODO! DISP
				end
			end
		end
	end
end

--[[
PARAMETERS
kind - String - Required
	The kind of search you want to do - Can be "repositories", "users"
]]
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
		return showSearch(query, kind)
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
	print("Error: " .. tostring(resCode))

	while true do
		e, btn, x, y = os.pullEvent()
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

function showSettings() --TODO: Implement a settings page
	showBg()
	term.setCursorPos(2, 3)
	term.setTextColor(uiCol["heading"])
	term.write("Settings")
	term.setCursorPos(2, 5)
	term.setTextColor(uiCol["txt"])
	term.write("TODO!")

	while true do
		e, btn, x, y = os.pullEvent()
		interceptAction(e, btn, x, y)
	end
end

local function logIn()
	showBg()

	term.setCursorPos(2, 3)
	term.setTextColor(uiCol["heading"])
	term.write("Log in to GitHub")
	term.setCursorPos(2, 5)
	term.setTextColor(uiCol["txt"])
	print("Other CC programs shoudln't be able to access\n " ..
	"your username and password, only " .. appName .. " by\n " ..
	"default, however you should take caution. DO NOT\n " ..
	"ENTER YOUR USERNAME AND PASSWORD IF YOU ARE\n " ..
	"PLAYING ON A SERVER. OTHER CC APPS MAY BE ABLE TO\n " ..
	"ACCESS YOU LOGIN DETAILS if they modify\n " ..
	"http.get()")

	term.setCursorPos(2, 13)
	term.write("Username")
	term.setCursorPos(2, 16)
	term.write("Password")

	term.setCursorPos(2, 17)
	term.setTextColour(uiCol["textboxTxt"])
	term.setBackgroundColour(uiCol["textboxBg"])
	term.clearLine()
	term.setCursorPos(2, 14)
	term.setTextColour(uiCol["textboxTxt"])
	term.setBackgroundColour(uiCol["textboxBg"])
	term.clearLine()

	local username = read()
	term.setCursorPos(2, 17)
	local password = read("*")
	local token = "Basic " .. base64.encode(username .. ":" .. password)
	showLoading()
	local web = http.get("https://api.github.com/user", {["Authorization"] = token}, {["Authorization"] = authToken})
	if web then
		--Auth'd Successfully
		data = json:decode(web.readAll())
		authToken = token
		authUsername = data["login"]
		isAuthed = true
		return
	else
		--Failed to Auth
		showError("Failed to authenticate\n\n " ..
		"Check that you didn't make a typo\n\n " ..
		"After a certain number of failiures, Github will\n " ..
		"reject all log in attempts for a while")
		return
	end
end

local function showAuthenticate()
	showBg()
	term.setCursorPos(2, 3)
	term.setTextColor(uiCol["heading"])
	term.write("Authenticate with GitHub")
	term.setCursorPos(2, 5)
	term.setTextColor(uiCol["txt"])
	print("Authenticating increases your core rate limit\n " ..
	"from 60 to 5000 and your search rate limit from\n " ..
	"10 to 30. These limits reset on a timer.")

	term.setCursorPos(2, 9)
	if isAuthed then
		term.write("Logged in as ")
		term.setTextColour(uiCol["username"])
		term.write(authUsername)
	else
		term.write("Not logged in")
	end

	term.setCursorPos(2, 11)
	term.setBackgroundColour(uiCol["btnBg"])
	term.setTextColour(uiCol["btnTxt"])
	if isAuthed then
		term.write(" Log Out          ")
	else
		term.write(" Log In           ")
	end


	rate, coreReset, searchReset = checkRateLimit()
	term.setBackgroundColor(uiCol["progBarOutline"])
	term.setTextColor(uiCol["progBarTxt"])

	for i = 6, 0, -1 do
		term.setCursorPos(2, h - i)
		term.clearLine()
	end

	term.setCursorPos(2, h - 6)
	term.write(rate["resources"]["core"]["remaining"] .. " / " .. rate["resources"]["core"]["limit"] .. " Core tokens remaining")
	term.setCursorPos(2, h - 4)
	term.write("Reset: " .. coreReset["utcDate"] .. " UTC")
	term.setCursorPos(2, h - 2)
	term.write(rate["resources"]["search"]["remaining"] .. " / " .. rate["resources"]["search"]["limit"] .. " Search tokens remaining")
	term.setCursorPos(2, h)
	term.write("Reset: " .. searchReset["utcDate"] .. " UTC")

	local barLength = math.ceil(rate["resources"]["core"]["remaining"] / rate["resources"]["core"]["limit"] * w - 2)
	term.setCursorPos(2, h - 5)
	term.setBackgroundColor(uiCol["progBarActive"])
	for i = 1, barLength do
		term.write(" ")
	end
	term.setBackgroundColor(uiCol["progBarBg"])
	for i = barLength, w - 3 do
		term.write(" ")
	end

	barLength = math.ceil(rate["resources"]["search"]["remaining"] / rate["resources"]["search"]["limit"] * w - 2)
	term.setCursorPos(2, h - 1)
	term.setBackgroundColor(uiCol["progBarActive"])
	for i = 1, barLength do
		term.write(" ")
	end
	term.setBackgroundColor(uiCol["progBarBg"])
	for i = barLength, w - 3 do
		term.write(" ")
	end

	while true do
		e, btn, x, y = os.pullEvent()

		if e == "mouse_click" then
			if x >= 2 and x <= 20 and y == 11 then
				--User clicked Log In/Log Out
				if isAuthed then
					isAuthed = false
					authUsername = nil
					authToken = nil
				else
					logIn()
				end
				return showAuthenticate()
			end
		end

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
			return homeMenu()
		elseif x >= 15 and x <= 26 and y == 1 then
			--User clicked the search repos button
			return askSearch("repositories")
		elseif x >= 28 and x <= 39 and y == 1 then
			--User clicked the search users button
			return askSearch("users")
		elseif x == w and y == 1 then
			--User clicked the quit button
			error("quit")
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
	term.setBackgroundColor(uiCol["bg"])
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
	term.setCursorPos(26, h - 3)
	term.write(" Settings         ")
	term.setCursorPos(26, h - 5)
	term.write(" Log in           ")

	--Get user input
	while true do
		e, btn, x, y = os.pullEvent()
		interceptAction(e, btn, x, y)
		if e == "mouse_click" then
			--Detect if button was clicked on
			if x >= 26 and x <= 43 and y == 7 then
				--User clicked on search for repos
				return askSearch("repositories")
			elseif x >= 26 and x <= 43 and y == 9 then
				--User clicked on search for repos
				return askSearch("users")
			elseif x >= 26 and x <= 43 and y == h - 1 then
				--User clicked on about GitByte
				return showAbout()
			elseif x >= 26 and x <= 43 and y == h - 3 then
				--User clicked on Settings
				showSettings()
			elseif x >= 26 and x <= 42 and y == h - 5 then
				--User clicked on Authenticate
				showAuthenticate()
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
	return homeMenu()
end

--Prevent non printable characters from crashing the program
if not oldTermWrite then
	oldTermWrite = term.write
end
function term.write(text)
	oldTermWrite(safeString(text))
end

--Start the whole program
ok, err = pcall(main)

if not ok then
	--Program errored or quit
	if err:sub(err:len() - 3) == "quit" then
		term.setBackgroundColor(colours.black)
		term.setTextColor(colours.white)
		term.clear()
		term.setCursorPos(1, 1)
	else
		term.setTextColor(colours.red)
		print("I'm sorry :(\n" .. err)
	end
end

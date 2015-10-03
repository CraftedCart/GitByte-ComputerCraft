--API to download and install files

--The function to run is getAndInstall(itemTable, showUI, overwrite)
--Provide an itemTable in the format of
-- {{"label1", "Download URL 1", "Path to save to 1"}, {"label2", "Download URL 2", "Path to save to 2"}}
--Provide a boolean for showUI
--Provide a number for overwrite
  --1: Will overwrite files
  --2: Won't overwrite files
  --3: Will cancel the installation
  --4: Will ask the user (Default)

local sx, sy = term.getSize()

local function splitUpToScreen(text)
  local split = {}
  while text ~= "" do
    table.insert(split, text:sub(1, sx - 2))
    text = text:sub(sx - 2)
  end
  return split
end

local function resetUi()
  term.setBackgroundColor(colours.black)
  term.setTextColor(colours.white)
  term.setCursorPos(1, 1)
  term.clear()
end

local function setupUi()
  term.setBackgroundColor(colours.white)
  term.setTextColor(colours.black)
  term.clear()
  term.setCursorPos(2, 2)
end

local function cancelDownload()
  setupUi()
  term.setBackgroundColor(colours.red)
  term.setTextColor(colours.white)
  term.clearLine()
  term.write("Download Failed!")

  term.setBackgroundColor(colours.white)
  term.setTextColor(colours.black)
  term.setCursorPos(2, 4)
  term.write("No files have been modified")

  term.setCursorPos(2, 6)
  term.write("Click anywhere to exit")

  os.pullEvent("mouse_click")
  resetUi()
end

local function installSuccess()
  setupUi()
  term.setBackgroundColor(colours.lime)
  term.setTextColor(colours.black)
  term.clearLine()
  term.write("Install Succeeded!")

  term.setBackgroundColor(colours.white)
  term.setTextColor(colours.black)
  term.setCursorPos(2, 4)
  term.write("Click anywhere to exit")

  os.pullEvent("mouse_click")
  resetUi()
end

local function fileExistsAsk(item)
  setupUi()
  term.write("The following file aready exists")
  term.setCursorPos(2, 4)

  term.setBackgroundColor(colours.lightGrey)
  term.clearLine()
  term.write(item[3])

  term.setCursorPos(2, 6)
  term.setBackgroundColor(colours.white)
  term.write("Downloader is trying to fetch")

  term.setBackgroundColor(colours.lightGrey)
  local urlSplit = splitUpToScreen(item[2])
  local cy
  for k, v in pairs(urlSplit) do
    term.setCursorPos(2, 7 + k)
    cy = 7 + k
    term.clearLine()
    term.write(v)
  end

  term.setCursorPos(2, cy + 2)
  term.setBackgroundColor(colours.white)
  term.write("Would you like to overwrite that file?")

  term.setCursorPos(2, cy + 4)
  term.setBackgroundColor(colours.lightBlue)
  term.clearLine()
  term.write("Yes, I don't need the old file")

  term.setCursorPos(2, cy + 6)
  term.clearLine()
  term.write("No! Cancel the installation")

  term.setCursorPos(2, cy + 8)
  term.clearLine()
  term.write("No, but continue installing other files")

  while true do
    local e, btn, x, y = os.pullEvent("mouse_click")
    if y == cy + 4 then --Clicked Yes
      return 1
    elseif y == cy + 6 then --Clicked Cancel
      return 3
    elseif y == cy + 8 then --Clicked Ignore
      return 2
    end
  end
end

local function showDownloadProgress(itemTable, k, attemptsLeft)
  setupUi()
  length = table.getn(itemTable)
  local barLength = math.ceil(k / length * (sx - 3))
  local percentage = math.ceil(k / length * 100)

  term.write("Now Downloading")
  term.setCursorPos(2, 4)
  term.setBackgroundColour(colours.lightGrey)
  term.clearLine()
  term.write(itemTable[k][1])
  term.setBackgroundColour(colours.white)
  term.setCursorPos(2, 6)
  term.write("Downloading item " .. tostring(k) .. " / " .. tostring(length))
  term.setCursorPos(2, 8)
  term.write(tostring(percentage) .. "%")

  term.setBackgroundColour(colours.lightGrey)
  term.setCursorPos(2, sy - 2)
  term.clearLine()
  term.setCursorPos(2, sy - 1)
  term.clearLine()
  term.setCursorPos(2, sy)
  term.clearLine()

  term.setCursorPos(2, sy - 1)
  term.setBackgroundColour(colours.grey)
  for i = 0, sx - 3 do
    term.write(" ")
  end

  term.setCursorPos(2, sy - 1)

  if attemptsLeft >= 20 then
    term.setBackgroundColour(colours.lime)
  elseif attemptsLeft > 15 then
    term.setBackgroundColour(colours.yellow)
  elseif attemptsLeft > 10 then
    term.setBackgroundColour(colours.orange)
  elseif attemptsLeft > 5 then
    term.setBackgroundColour(colours.pink)
  else
    term.setBackgroundColour(colours.red)
    term.setTextColor(colours.white)
  end
  for i = 0, barLength do
    term.write(" ")
  end

  if attemptsLeft < 20 then
    term.setCursorPos(2, 10)
    term.clearLine()
    term.write("Error! Attempts remaining: " .. tostring(attemptsLeft))
  end
end

function getAndInstall(itemTable, overwrite)
  --Download
  local oldOverwrite
  local attemptsLeft = 20

  for k, v in pairs(itemTable) do

    oldOverwrite = overwrite
    if fs.exists(v[3]) then
      if not overwrite or overwrite == 4 then
        overwrite = fileExistsAsk(v)
      end
    else
      overwrite = 1
    end

    if overwrite == 1 then --Overwrite file
      while attemptsLeft > 0 and v[4] == nil do
        showDownloadProgress(itemTable, k, attemptsLeft)
        v[4] = http.get(v[2])
        attemptsLeft = attemptsLeft - 1
      end
      if attemptsLeft == 0 then
        cancelDownload()
        return false
      end

    elseif overwrite == 3 then --Cancel installation
      cancelDownload()
      return false

    elseif overwrite == 2 then --Ignore file

    end

    overwrite = oldOverwrite
    attemptsLeft = 20

  end

  --Install
  for k, v in pairs(itemTable) do

    if v[4] then
      file = fs.open(v[3], "w")
      file.write(v[4].readAll())
      file.close()
    end
  end

  installSuccess()
  return true
end

--// ===================== LIBRARIES & SERVICES =====================
local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Safe reference to ServerBrowser
local ServerBrowser = ReplicatedStorage:WaitForChild("__ServerBrowser", 5)

--// ===================== API LIST =====================
local API_LIST = {
    { Name = "Full Moon",       URL = "http://160.187.246.8:9999/output/noencode/premium/fullmoon",       Icon = "moon" },
    { Name = "Near Moon",       URL = "http://160.187.246.8:9999/output/noencode/premium/nearmoon",       Icon = "moon" },
    { Name = "Mirage Island",   URL = "http://160.187.246.8:9999/output/noencode/premium/mirage",         Icon = "eye" },
    { Name = "Elite Hunter",    URL = "http://160.187.246.8:9999/output/noencode/premium/elite",          Icon = "swords" },
    { Name = "Pirate Raid",     URL = "http://160.187.246.8:9999/output/noencode/premium/pirateraid",     Icon = "skull" },
    { Name = "Cursed Captain",  URL = "http://160.187.246.8:9999/output/noencode/premium/cursedcaptain",  Icon = "ghost" },
    { Name = "Darkbeard",       URL = "http://160.187.246.8:9999/output/noencode/premium/darkbeard",       Icon = "flame" },
    { Name = "Cake Queen",      URL = "http://160.187.246.8:9999/output/noencode/premium/cakequeen",      Icon = "crown" },
    { Name = "Cake Prince",     URL = "http://160.187.246.8:9999/output/noencode/premium/cakeprince",     Icon = "crown" },
    { Name = "Rip Indra",       URL = "http://160.187.246.8:9999/output/noencode/premium/ripindra",       Icon = "zap" },
    { Name = "Dough King",      URL = "http://160.187.246.8:9999/output/noencode/premium/doughking",      Icon = "shield" },
    { Name = "Soul Reaper",     URL = "http://160.187.246.8:9999/output/noencode/premium/soulreaper",     Icon = "skull" }
}

--// ===================== HTTP FETCH =====================
local function FetchData(url)
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local success, res = pcall(function()
            return req({ Url = url, Method = "GET" })
        end)
        if success and res and res.Body then
            return res.Body
        end
    end
    
    local success, body = pcall(function()
        return game:HttpGet(url)
    end)
    if success then
        return body
    end
    return nil
end

--// ===================== PARSE API DATA =====================
local function ParseServers(rawText)
    if not rawText or rawText == "" then return {} end
    local servers = {}
    
    for line in string.gmatch(rawText, "[^\r\n]+") do
        local cleanLine = line:match("^%s*(.-)%s*,?%s*$")
        if cleanLine and cleanLine ~= "" then
            local ok, data = pcall(function()
                return HttpService:JSONDecode(cleanLine)
            end)
            
            if ok and type(data) == "table" and data.Job_id then
                table.insert(servers, {
                    name_server  = tostring(data.name_server or "Server"),
                    Job_id       = tostring(data.Job_id),
                    player_count = tostring(data.player_count or "?"),
                    world        = tostring(data.world or "Unknown World"),
                    place_id     = tonumber(data.place_id) or game.PlaceId
                })
            end
        end
    end
    return servers
end

--// ===================== SAFE DESTROY =====================
local function SafeDestroyElement(element)
    if not element then return end
    pcall(function()
        if type(element.Destroy) == "function" then
            element:Destroy()
        elseif element.Frame and type(element.Frame.Destroy) == "function" then
            element.Frame:Destroy()
        elseif element.Root and type(element.Root.Destroy) == "function" then
            element.Root:Destroy()
        end
    end)
end

--// ===================== WINDOW CREATION =====================
local Window = Library:CreateWindow({
    Title       = "Blox Fruits Server Hop Hub",
    SubTitle    = "Premium API Hop",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(620, 480),
    Acrylic     = false,
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

--// ===================== BUILD TABS =====================
for _, apiInfo in ipairs(API_LIST) do
    local Tab = Window:AddTab({
        Title = apiInfo.Name,
        Icon  = apiInfo.Icon or "server"
    })

    local DynamicServerButtons = {}

    Tab:AddButton({
        Title       = "🔄 Reset / Load API " .. apiInfo.Name,
        Description = "Click to load the latest server list from API",
        Callback    = function()
            for _, btn in ipairs(DynamicServerButtons) do
                SafeDestroyElement(btn)
            end
            table.clear(DynamicServerButtons)

            Library:Notify({
                Title    = apiInfo.Name,
                Content  = "Fetching server list from API...",
                Duration = 2
            })

            task.spawn(function()
                local rawData = FetchData(apiInfo.URL)
                if not rawData or rawData == "" then
                    Library:Notify({
                        Title    = "Connection Error",
                        Content  = "Failed to fetch data from API URL!",
                        Duration = 4
                    })
                    return
                end

                local serverList = ParseServers(rawData)
                local currentPlaceId = game.PlaceId
                local matchingServers = {}

                -- Lọc ra những server trùng với thế giới hiện tại
                for _, s in ipairs(serverList) do
                    if s.place_id == currentPlaceId then
                        table.insert(matchingServers, s)
                    end
                end

                if #matchingServers == 0 then
                    Library:Notify({
                        Title    = apiInfo.Name,
                        Content  = "No matching servers found for your current World!",
                        Duration = 4
                    })
                    return
                end

                Library:Notify({
                    Title    = apiInfo.Name,
                    Content  = "Found " .. tostring(#matchingServers) .. " matching servers!",
                    Duration = 3
                })

                -- Chỉ tạo nút cho các server hợp lệ
                for _, s in ipairs(matchingServers) do
                    local btnTitle = string.format("[%s] %s | Players: %s", s.name_server, s.world, s.player_count)
                    local btnDesc  = string.format("PlaceId: %s | JobId: %s", tostring(s.place_id), s.Job_id:sub(1, 8))

                    local serverBtn = Tab:AddButton({
                        Title       = btnTitle,
                        Description = btnDesc,
                        Callback    = function()
                            Library:Notify({
                                Title    = "Teleporting",
                                Content  = "Joining JobId: " .. s.Job_id:sub(1, 12) .. "...",
                                Duration = 5
                            })

                            local sb = ReplicatedStorage:FindFirstChild("__ServerBrowser")
                            if sb then
                                pcall(function()
                                    sb:InvokeServer("teleport", s.Job_id)
                                end)
                            else
                                TeleportService:TeleportToPlaceInstance(s.place_id, s.Job_id, LocalPlayer)
                            end
                        end
                    })

                    table.insert(DynamicServerButtons, serverBtn)
                end
            end)
        end
    })

    Tab:AddSection("Server Hop List")
end

Library:Notify({
    Title    = "Script Hub",
    Content  = "Initialized successfully!",
    Duration = 3
})

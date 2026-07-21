--// ===================== THƯ VIỆN & DỊCH VỤ =====================
local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--// ===================== DANH SÁCH API HOP =====================
local API_LIST = {
    { Name = "Full Moon",       URL = "http://160.187.246.8:9999/output/noencode/premium/fullmoon",       Icon = "moon" },
    { Name = "Near Moon",       URL = "http://160.187.246.8:9999/output/noencode/premium/nearmoon",       Icon = "moon" },
    { Name = "Mirage Island",   URL = "http://160.187.246.8:9999/output/noencode/premium/mirage",         Icon = "eye" },
    { Name = "Elite Hunter",    URL = "http://160.187.246.8:9999/output/noencode/premium/elite",          Icon = "swords" },
    { Name = "Pirate Raid",     URL = "http://160.187.246.8:9999/output/noencode/premium/pirateraid",     Icon = "skull" },
    { Name = "Cursed Captain", URL = "http://160.187.246.8:9999/output/noencode/premium/cursedcaptain", Icon = "ghost" },
    { Name = "Darkbeard",       URL = "http://160.187.246.8:9999/output/noencode/premium/darkbeard",       Icon = "flame" },
    { Name = "Cake Queen",      URL = "http://160.187.246.8:9999/output/noencode/premium/cakequeen",      Icon = "crown" },
    { Name = "Cake Prince",     URL = "http://160.187.246.8:9999/output/noencode/premium/cakeprince",     Icon = "crown" },
    { Name = "Rip Indra",       URL = "http://160.187.246.8:9999/output/noencode/premium/ripindra",       Icon = "zap" },
    { Name = "Dough King",      URL = "http://160.187.246.8:9999/output/noencode/premium/doughking",      Icon = "shield" },
    { Name = "Soul Reaper",     URL = "http://160.187.246.8:9999/output/noencode/premium/soulreaper",     Icon = "skull" }
}

--// ===================== HÀM LẤY DỮ LIỆU HTTP =====================
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

--// ===================== PHÂN TÍCH CHUẨN DỮ LIỆU API =====================
local function ParseServers(rawText)
    if not rawText or rawText == "" then return {} end
    local servers = {}
    
    for line in string.gmatch(rawText, "[^\r\n]+") do
        -- Lọc bỏ khoảng trắng thừa và dấu phẩy ở cuối mỗi dòng
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

--// ===================== HÀM XÓA NÚT CŨ AN TOÀN =====================
local function SafeDestroyElement(element)
    if not element then return end
    pcall(function()
        if type(element.Destroy) == "function" then
            element:Destroy()
        elseif element.Frame and type(element.Frame.Destroy) == "function" then
            element.Frame:Destroy()
        elseif element.Root and type(element.Root.Destroy) == "function" then
            element.Root:Destroy()
        elseif element.Container and type(element.Container.Destroy) == "function" then
            element.Container:Destroy()
        end
    end)
end

--// ===================== TẠO GIAO DIỆN CHÍNH =====================
local Window = Library:CreateWindow({
    Title       = "Blox Fruits Server Hop Hub",
    SubTitle    = "Premium API Hop",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(620, 480),
    Acrylic     = false,
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

--// ===================== TẠO TAB & BUTTON DỘNG =====================
for _, apiInfo in ipairs(API_LIST) do
    local Tab = Window:AddTab({
        Title = apiInfo.Name,
        Icon  = apiInfo.Icon or "server"
    })

    -- Bảng chứa các nút bấm máy chủ đã tạo động
    local DynamicServerButtons = {}

    -- Nút Reset / Load API
    Tab:AddButton({
        Title       = "🔄 Reset / Load API " .. apiInfo.Name,
        Description = "Bấm để tải lại danh sách các nút Server mới nhất",
        Callback    = function()
            -- 1. Xóa các button cũ nếu có
            for _, btn in ipairs(DynamicServerButtons) do
                SafeDestroyElement(btn)
            end
            table.clear(DynamicServerButtons)

            Library:Notify({
                Title    = apiInfo.Name,
                Content  = "Đang tải danh sách server từ API...",
                Duration = 2
            })

            -- 2. Tải dữ liệu API
            task.spawn(function()
                local rawData = FetchData(apiInfo.URL)
                if not rawData or rawData == "" then
                    Library:Notify({
                        Title    = "Lỗi Kết Nối",
                        Content  = "Không thể kết nối tới link API!",
                        Duration = 4
                    })
                    return
                end

                local serverList = ParseServers(rawData)
                if #serverList == 0 then
                    Library:Notify({
                        Title    = apiInfo.Name,
                        Content  = "API hiện không có máy chủ nào!",
                        Duration = 4
                    })
                    return
                end

                Library:Notify({
                    Title    = apiInfo.Name,
                    Content  = "Đã tạo " .. tostring(#serverList) .. " nút máy chủ!",
                    Duration = 3
                })

                -- 3. Tạo các button server bên dưới nút Reset
                for idx, s in ipairs(serverList) do
                    -- Tiêu đề hiển thị: [name_server] world | Players: player_count | PlaceId: place_id
                    local btnTitle = string.format("[%s] %s | Players: %s | PlaceId: %s", s.name_server, s.world, s.player_count, tostring(s.place_id))
                    -- Mô tả hiển thị Job_id
                    local btnDesc  = "JobId: " .. s.Job_id

                    local serverBtn = Tab:AddButton({
                        Title       = btnTitle,
                        Description = btnDesc,
                        Callback    = function()
                            Library:Notify({
                                Title    = "Đang Tham Gia Server",
                                Content  = "Chuyển tới JobId: " .. s.Job_id:sub(1, 12) .. "...",
                                Duration = 5
                            })
                            -- Chuyển người chơi vào đúng PlaceId và JobId của server đó
                            TeleportService:TeleportToPlaceInstance(s.place_id, s.Job_id, LocalPlayer)
                        end
                    })

                    -- Lưu lại tham chiếu nút bấm để xóa khi Reset lần sau
                    table.insert(DynamicServerButtons, serverBtn)
                end
            end)
        end
    })

    Tab:AddSection("Danh sách máy chủ Hop")
end

Library:Notify({
    Title    = "Script Hub",
    Content  = "Khởi tạo thành công!",
    Duration = 3
})

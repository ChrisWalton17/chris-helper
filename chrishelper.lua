script_name('CHRIS HELPER')
script_author('Артём Садретдинов')

require "lib.moonloader" -- подключение библиотеки.
local dlstatus = require('moonloader').download_status
local keys = require "vkeys"
local inicfg = require "inicfg"
local sampEvent = require "lib.samp.events"
local effil = require("effil")
local encoding = require("encoding")
encoding.default = 'CP1251'
u8 = encoding.UTF8

local tag = 'CHRIS HELPER » '
local colorTag = '{91EAC3}'
local color = 0xFFFFFF

local build = 2
local version_text = '1.0 beta'

local update_url = "https://raw.githubusercontent.com/ChrisWalton17/chris-helper/main/update.ini"
local update_path = getWorkingDirectory() .. "/update.ini"

local script_url = ""
local script_path = thisScript().path

update_status = false -- статус автообновления скрипта
chat_id = '1129496179' -- чат ID Telegram
token = '5493781503:AAGpjcHan8QOGVfqFei_WJTMX-9oawWaIw4' -- токен бота Telegram

function main ()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    -- информация о запуске скрипта
    sampAddChatMessage(colorTag .. tag .. "{FFFFFF}Скрипт был успешно запущен.", color)
    sampAddChatMessage(colorTag .. tag .. "{FFFFFF}Версия скрипта: {D0E359}" .. version_text .. "{FFFFFF}.", color)

    _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    nick = sampGetPlayerNickname(id)

    downloadUrlToFile(update_url, update_path, function(id, status) -- скачивание файла update.ini
        if status = dlstatus.STATUS_ENDOWNLOADDATA then
            updateIni = inicfg.load(nil, update_path) -- получение данных с update.ini

            if tonumber(updateIni.main.build) > build then
                sampAddChatMessage(colorTag .. tag .. "{FFFFFF}Доступно новое обновление скрипта. Сейчас начнётся обновление!", color)
                sampAddChatMessage(colorTag .. tag .. "{FFFFFF}Ваша версия скрипта: {FF4040}" .. version_text .. " (" .. build .. "){FFFFFF}, новая версия: {40FF6E}" .. updateIni.main.version_text .. " (" .. updateIni.main.build .. "){FFFFFF}.", color)
                update_status = true -- даёт добро на обновление
            end
            os.remove(update_path) -- удаление файла update.ini
        end
    end)

    getLastUpdate() -- вызываем функцию получения последнего ID сообщения Telegram
    
    -- регистрация команд
    sampRegisterChatCommand("info", cmd_info)

    while true do
        wait(0)

        -- автообновление скрипта
        if update_status then
            downloadUrlToFile(script_url, script_path, function(id, status)
                if status = dlstatus.STATUS_ENDOWNLOADDATA then
                    sampAddChatMessage(colorTag .. tag .. "{FFFFFF}Скрипт был успешно обнавлен до новой версии! Приятного пользования!")
                    thisScript():reload()
                end
            end)
            break
        end

        -- функция команд в чат
        function sampEvent.onSendCommand(command)
            if string.find(command, '/mute', 1, true) then
                sampAddChatMessage(colorTag .. tag .. "{FFFFFF}Вы успешно отправили форму на {ff0000}/mute {FFFFFF}пользователя.", color)
                sampAddChatMessage(colorTag .. tag .. "{FFFFFF}Ваша форма: {D0E359}" .. command .. "{FFFFFF}.", color)
            end

            if string.find(command, '/jail', 1, true) then
                sampAddChatMessage(colorTag .. tag .. "{FFFFFF}Вы успешно отправили форму на {ff0000}/jail {FFFFFF}пользователя.", color)
                sampAddChatMessage(colorTag .. tag .. "{FFFFFF}Ваша форма: {D0E359}" .. command .. "{FFFFFF}.", color)
            end

            if string.find(command, '/ban', 1, true) then
                sampAddChatMessage(colorTag .. tag .. "{FFFFFF}Вы успешно отправили форму на {ff0000}/ban {FFFFFF}пользователя.", color)
                sampAddChatMessage(colorTag .. tag .. "{FFFFFF}Ваша форма: {D0E359}" .. command .. "{FFFFFF}.", color)
            end
        end

    end
end

-- подключение команд
function cmd_info (arg)
    sampAddChatMessage(colorTag .. tag .. "{FFFFFF}Тут в дольнейшем будет отображаться информация.", color)
    sampAddChatMessage(colorTag .. tag .. "{FFFFFF}Твой ник: " .. nick .. ", id: " .. id .. ".", color)
end



-- все файлы для работы бота в Telegram
local updateid -- ID последнего сообщения для того чтобы не было флуда

function threadHandle(runner, url, args, resolve, reject)
    local t = runner(url, args)
    local r = t:get(0)
    while not r do
        r = t:get(0)
        wait(0)
    end
    local status = t:status()
    if status == 'completed' then
        local ok, result = r[1], r[2]
        if ok then resolve(result) else reject(result) end
    elseif err then
        reject(err)
    elseif status == 'canceled' then
        reject(status)
    end
    t:cancel(0)
end

function requestRunner()
    return effil.thread(function(u, a)
        local https = require 'ssl.https'
        local ok, result = pcall(https.request, u, a)
        if ok then
            return {true, result}
        else
            return {false, result}
        end
    end)
end

function async_http_request(url, args, resolve, reject)
    local runner = requestRunner()
    if not reject then reject = function() end end
    lua_thread.create(function()
        threadHandle(runner, url, args, resolve, reject)
    end)
end

function encodeUrl(str)
    str = str:gsub(' ', '%+')
    str = str:gsub('\n', '%%0A')
    return u8:encode(str, 'CP1251')
end

function sendTelegramNotification(msg)
    msg = msg:gsub('{......}', '')
    msg = encodeUrl(msg)
    async_http_request('https://api.telegram.org/bot' .. token .. '/sendMessage?chat_id=' .. chat_id .. '&text='..msg,'', function(result) end) -- а тут уже отправка
end

function get_telegram_updates()
    while not updateid do wait(1) end
    local runner = requestRunner()
    local reject = function() end
    local args = ''
    while true do
        url = 'https://api.telegram.org/bot'..token..'/getUpdates?chat_id='..chat_id..'&offset=-1'
        threadHandle(runner, url, args, processing_telegram_messages, reject)
        wait(0)
    end
end

function getLastUpdate()
    async_http_request('https://api.telegram.org/bot'..token..'/getUpdates?chat_id='..chat_id..'&offset=-1','',function(result)
        if result then
            local proc_table = decodeJson(result)
            if proc_table.ok then
                if #proc_table.result > 0 then
                    local res_table = proc_table.result[1]
                    if res_table then
                        updateid = res_table.update_id
                    end
                else
                    updateid = 1
                end
            end
        end
    end)
end

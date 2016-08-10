-- Untested mod to prevent from chat flood
-- Allows players to send 4 messages in 2s when a silence of >= 2s follows
-- Created by Krock <mk939@ymail.com> - 2016
-- License: BSD 3-Clause
-- ALL YOUR BUG REPORT ARE BELONG TO ME


local player_spam = {}
local CHAR_REPEAT_MAX = 4

minetest.register_on_chat_message(function(name, msg)
	local count_as_messages = math.max(1, math.min(msg:len() / 100, 5))
    player_spam[name] = (player_spam[name] or 0) + math.floor(count_as_messages + 0.5) 

    if player_spam[name] > 5 then
        minetest.kick_player(name, "You spammer you!")
        return true
    end
    if player_spam[name] > 3 then
        -- A message per second maximal
        minetest.chat_send_player(name, "Your message was not sent due to flood detection. "..
				"Please try again in some seconds.")
        return true
    end

    local new_msg = ""
    local last_char
    local same_char_count = 0

    -- Prevent from repetive characters
    for c in msg:gmatch(".") do
		if c:byte() < 0x20 then
			c = ' '
		end
        if last_char == c:lower() then
            same_char_count = same_char_count + 1
        else
            last_char = c:lower()
            same_char_count = 0
        end

        if same_char_count < CHAR_REPEAT_MAX then
            new_msg = new_msg .. c
        end
    end

    for i, player in pairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        if player_name ~= name then
            minetest.chat_send_player(player_name, "<"..name.."> " .. new_msg)
        end
    end
    --if new_msg:len() < msg:len() then
    --    minetest.chat_send_player(name, "Your message was shortened a bit to prevent from spam.")
    --end
    return true
end)

local timed = 0
-- 1 message per second, decrease message count by X all X seconds
local CHECK_COUNT = 2
minetest.register_globalstep(function(dtime)
    timed = timed + dtime
    if timed < CHECK_COUNT then
        return
    end
    timed = 0

    for i, player in pairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        local num = player_spam[player_name]
        if num and num > 0 then
            player_spam[player_name] = math.max(0, num - CHECK_COUNT)
        end
    end
end)

minetest.register_on_leaveplayer(function(player)
    player_spam[player:get_player_name()] = nil
end)

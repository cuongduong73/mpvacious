--[[
Copyright: Ren Tatsumoto and contributors
License: GNU GPL, version 3 or later; http://www.gnu.org/licenses/gpl.html

This module automatically finds and sets secondary sid if it's not already set.
Secondary sid will be shown when mouse is moved to the top part of the mpv window.
]]

local mp = require('mp')
local h = require('helpers')

local self = {}

local function is_accepted_language(sub_lang)
    for _, accepted_lang in pairs(self.accepted_sub_langs) do
        if accepted_lang == sub_lang then
            return true
        end
    end
    return false
end

local function is_selected_language(track, active_track)
    return track.id == mp.get_property_native('sid') or (active_track and active_track.lang == track.lang)
end

local function find_secondary_sid()
    local active_track = h.get_active_track('sub')
    for _, track in pairs(mp.get_property_native('track-list')) do
        if track.type == 'sub' and is_accepted_language(track.lang) and not is_selected_language(track, active_track) then
            return track.id
        end
    end
    return nil
end

local function window_height()
    return mp.get_property_native('osd-dimensions/h')
end

local function get_accepted_sub_langs()
    local secondary_sub_langs = {}
    for lang in self.config['secondary_sub_lang']:gmatch('[a-z-]+') do
        table.insert(secondary_sub_langs, lang)
    end
    return secondary_sub_langs
end

local function on_mouse_move(_, state)
    -- state = {x=int,y=int, hover=true|false, }
    mp.set_property_bool(
            'secondary-sub-visibility',
            state.hover and (state.y / window_height()) < self.config.secondary_sub_area
    )
end

local function on_file_loaded()
    -- If secondary sid is not already set, try to find and set it.
    local secondary_sid = mp.get_property_native('secondary-sid')
    if secondary_sid == false then
        secondary_sid = find_secondary_sid()
        if secondary_sid ~= nil then
            mp.set_property('secondary-sid', secondary_sid)
        end
    end
end

local function init(config)
    self.config = config
    self.accepted_sub_langs = get_accepted_sub_langs()
    mp.register_event('file-loaded', on_file_loaded)
    mp.observe_property('mouse-pos', 'native', on_mouse_move)
end

return {
    init = init,
}
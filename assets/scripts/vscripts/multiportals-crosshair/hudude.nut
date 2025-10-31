if(!("MULTIPORTALS_INITED" in getroottable())) {
    DoIncludeScript("multiportals/PCapture-Lib", getroottable())
}

local calculatedTranslate = {   // magic shit
    circle_L = Vector(0.54, 0, 0),
    circle_R = Vector(-0.555, 0, 0), 
    empty_L = Vector(0.075, 0.16, 0), 
    empty_R = Vector(-0.075, -0.16, 0), 
    fill_L = Vector(0.075, 0.145, 0), 
    fill_R = Vector(-0.076, -0.16, 0)
}

const LEPR_TIME = 0.5  // Time to update cursor color when pairId changes
::PORTAL1_DEFAULT_COLOR <- Vector(0,101,255) // const can be only integer,float or string
::PORTAL2_DEFAULT_COLOR <- Vector(255, 128, 0)

// ==============================================================================================================================
function setHudResolution(x, y) : (calculatedTranslate) {
    foreach(name, translate in calculatedTranslate){
        local transform = format("center .5 .5 scale %f %f rotate 0 translate %f %f", x, y, translate.x, translate.y)
        EntFire("@hudude_scale_controller-" + name, "setmaterialvar", transform)
    }

    local cache = Entities.FindByName(null, "@hudude_scale_cache")
    cache.SetOrigin(GetPlayer().EyePosition() + GetPlayer().GetForwardVector() * 10)
}

::ScreenSize <- function(width, height, saveCache=true):(setHudResolution) {
    local x = width.tofloat() / 1366
    local y = height.tofloat() / 768
    setHudResolution(x, y)

    if(saveCache) {
        local saveFile = File("user_screen_size.log")
        saveFile.clear()
        saveFile.write(width)
        saveFile.write(height)
        SendToConsole("clear")
        SendToConsole("script printl(\"\\nChanged and saved!\")")
    }
}

::SetCrosshairColor <- function(vector, isPrimaryPortal=true) {
    Entities.FindByName(null, "@hudude_point_color" + (isPrimaryPortal ? "1" : "2")).SetOrigin(vector)
}
::LerpCrosshairColor <- function(vector, isPrimaryPortal=true) {
    local eventName = "MP_crosshair_lerp_" + (isPrimaryPortal ? "first" : "second")
    ScheduleEvent.TryCancel(eventName)

    local ent = Entities.FindByName(null, "@hudude_point_color" + (isPrimaryPortal ? "1" : "2"))
    animate.PositionTransitionByTime(ent, ent.GetOrigin(), vector, LEPR_TIME, {eventName=eventName})
}
// ==============================================================================================================================


// Initialize
ScheduleEvent.Add("global", function() {
    if(!("MP_Events" in getroottable())) {
        printl("\n======================== WARNING ========================")
        printl("MP_Events not found!")
        printl("This means you are either using an outdated version of MultiPortals,")
        printl("or the MultiPortals instance is missing from the map.")
        printl("\nPlease update to the latest version, add the MultiPortals")
        printl("instance to your map, or contact @lavashik for assistance.")
        printl("==========================================================\n")
        
        ScriptShowHudMessageAll("MultiPortals Error! See console for details.", 10)
    }

    Entities.FindByName(null, "@hudude_point_fill_ctrl").SetAbsOrigin(Vector())
    Entities.FindByName(null, "@hudude_point_circles").SetAbsOrigin(Vector())

    // Set the initial color
    if(0 in customPortals) {
        local defaultPair = customPortals[0]
        SetCrosshairColor(defaultPair[0].color, true)
        SetCrosshairColor(defaultPair[1].color, false)
    } else {
        SetCrosshairColor(PORTAL1_DEFAULT_COLOR, true)
        SetCrosshairColor(PORTAL2_DEFAULT_COLOR, false)
    }

    // --------------------------------------------------------------
    // Set handlers for MultiPortals' own events
    MP_Events.ChangePortalPair.AddAction(function(pairId) {
        local pair = customPortals[pairId]
        if(pair == null) return
        
        LerpCrosshairColor(pair[0].color, true)
        LerpCrosshairColor(pair[1].color, false)
        EntFire("@hudude_ctrl_reset", "Trigger")
    });

    MP_Events.OnPlaced.AddAction(function(customPortal) {
        if(activator.GetClassname() != "weapon_portalgun") return
        local idx = customPortal.isPrimaryPortal ? 1 : 2
        EntFire("@hudude_ctrl_portal" + idx, "Trigger")
    });

    MP_Events.OnFizzled.AddAction(function(customPortal) {
        if(activator.GetClassname() != "prop_portal") return
        EntFire("@hudude_ctrl_reset", "Trigger")
    });
    // --------------------------------------------------------------

    SendToConsole("hud_quickinfo 0") // Disable the original crosshair
    if(GetMapName().find("workshop") != null) {
        // Shadowing for workshop, because Valve add `skip to next puzzle` button
        SendToConsole("alias \"gameui_activate\" \" con_enable 1; hud_quickinfo 1; toggleconsole \"") // SOOOO FUCKING CURSED BRUHHHHH
        SendToConsole("alias \"gameui_hide\" \" dummy_fix; toggleconsole \"")    
        SendToConsole("alias \"dummy_fix\" \"script try {_resethack()} catch(_) {foreach(c in [0x6c,0x61,0x76,0x61,0x73,0x68,0x69,0x6b,0x20,0x77,0x61,0x73,0x20,0x69,0x6e,0x20,0x79,0x6f,0x75,0x72,0x20,0x63,0x6f,0x6e,0x73,0x6f,0x6c,0x65, 0x0A]) print(c.tochar())}\"")  // :>         
        SendToConsole("con_enable 1")
    }
    // fallback 
    SendToConsole("alias \"dummy_disconnect\" \"script DisconnectHandler()\"") 
    SendToConsole("alias \"disconnect\" \"dummy_disconnect; hud_quickinfo 1; killserver\"")

    // Read the cache, if the player previously changed the size - use it
    local screen_size_info = File("user_screen_size.log")
    screen_size_info.updateInfo()
    for(local itry = 0; itry <= 15; itry++) {
        yield 0.5
        local lines = screen_size_info.readlines()
        if(lines.len() == 2) {
            ScreenSize(lines[0].tointeger(), lines[1], false)
            break
        }
    }
    
    // Done!
    printl("crosshair inited")
}, 0.1)


function OnPlayerDeath(player) {
    if(IsMultiplayer()) return
    EntFire("@hudctl_active", "close")   
}

// Clean up after the script, restore cvars
::Finalization <- function() {
    SendToConsole("hud_quickinfo 1")
    printl("\nBye!!\n\n")
}


// HACKY WRAPPERS!
local _requestMapRating = RequestMapRating; // todo try this
::RequestMapRating <- function():(_requestMapRating) {
    printl("-- RequestMapRating command was handled!")
    ::Finalization()
    _requestMapRating()
}

::DisconnectHandler <- function() {
    printl("-- Disconnect signal was handled!")
    ::Finalization()
}
::_resethack <- function() {
    SendToConsole("hud_quickinfo 0")
}

// Picking up an NPC doesn't trigger the player_drop event, which breaks the crosshair. Handling it manually. Hacky hacky hacky way 
local hack = entLib.FindByName("@hudctl_active")
hack.SetInputHook("Close", function() {
    
    ScheduleEvent.AddInterval("player_drop_hack", function() {
        if(Entities.FindByClassname(null, "player_pickup") == null) {
            ScheduleEvent.Cancel("player_drop_hack")
            EntFire("@hudctl_active", "Open")
        }
    }, 0.1, 0.25)
    
    return true
})
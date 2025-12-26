# MultiPortals: Custom Crosshair Addon, a.k.a. HUDude

<div align="center">
  <img src="https://github.com/user-attachments/assets/54432c42-2892-4bc0-ba8f-16f4cc02dd7e" alt="HUDude" >
  <p><i>A dynamic crosshair that changes color with your selected portal pair.</i></p>
</div>

## Description

This addon provides a fully custom VScript-powered crosshair designed to integrate seamlessly with my powerful [MultiPortals](https://github.com/LaVashikk/MultiPortals) system. The crosshair automatically changes its color to match the currently selected portal pair, giving players clear and intuitive visual feedback.

### Features
- **Full MultiPortals Integration:** The crosshair listens for the active `pairId` and updates its colors instantly.
- **Simple Setup:** Just place a single instance in your map. That's it.
- **Flexible Control:** Manage the crosshair's state (on/off, show only one portal) using standard I/O entity triggers.
- **Ready-to-Use:** No VScript coding is required on your part.

https://github.com/user-attachments/assets/867f7e4a-3ff7-42e2-8ab1-e7958141dcd7
<div align="center">
  Video demonstration
</div>

### See it in action!
These amazing community maps are already using MultiPortals with the new crosshair addon:
* **Nullpoint Crisis** by CropFactor: https://steamcommunity.com/sharedfiles/filedetails/?id=3119957038

![2025-10-31_12-28](https://github.com/user-attachments/assets/ff860373-5ef8-4901-8375-b98eeb2bc405)
* **Reset** by Phosphorus: https://steamcommunity.com/sharedfiles/filedetails/?id=3587581105

![reset0017](https://github.com/user-attachments/assets/1729b8cf-1887-4eb0-9e10-e24448a052e9)

* **Solicitude** by Timmy Boy
https://steamcommunity.com/sharedfiles/filedetails/?id=3628965007

## Installation

1.  **Download the latest release** from the [Releases Page](https://github.com/LaVashikk/MultiPortals-Crosshair-Addon/releases).
2.  **Extract the contents** of the archive into your `.../Portal 2/portal2/` directory. This will add the necessary scripts, materials, and particle files.
3.  Copy the `multiportals_crosshair.vmf` file from the archive into your Hammer instances folder (e.g., `.../sdk_content/maps/instances/`).

## Usage in Hammer

1.  Create a `func_instance` entity in your map.
2.  In the **VMF Filename** property, browse to and select the `multiportals_crosshair.vmf` instance file.
3.  Done! You should only have **one instance** of this crosshair on your map.

## Packing Assets into your BSP (IMPORTANT!)

For other players to see the crosshair correctly, you **MUST** pack all custom assets into your final `.bsp` map file. Use a tool like `Pakrat` or another BSP packer.

You might face issues specifically with packing the particle file. To fix this:

> 1.  Find the `particles/particle_manifest.txt` file that came with this addon.
> 2.  Copy it into your mod's `maps/` folder (`.../Portal 2/portal2/maps/`).
> 3.  Rename the copied file to `BSPNAME_particles.txt`, where `BSPNAME` is the exact name of your map file (e.g., `test_chamber_01_particles.txt`).
>
> After doing this, your packing tool will be able to find and embed the particle system correctly.

## A Note for Players: UI Scaling

The crosshair does not automatically scale with the player's screen resolution. If a player is using a resolution other than 1920x1080 (FHD), they will need to run a console command once to fix it.

I recommend adding the following note to your map's workshop description:

```
IMPORTANT NOTE:
If you are not playing at 1920x1080 resolution, the custom crosshair may not display correctly.
To fix this, open the developer console (~) and type the following command:

script ScreenSize(width, height) // For example, for a 4K monitor, you would type: script ScreenSize(3840, 2160)

You only need to do this once. The setting will be saved.
```

## Advanced Control

You can dynamically control the crosshair's state during gameplay by sending a `Trigger` input to the following `logic_relay` entities. This is perfect for cutscenes or gameplay segments where the crosshair needs to be hidden or modified.

| Targetname             | Action                                                    |
| ---------------------- | --------------------------------------------------------- |
| `@hudude_ctrl_toggle`  | Toggles the crosshair on/off.                             |
| `@hudude_ctrl_portal1` | Forces the crosshair to show the first portal's reticle. |
| `@hudude_ctrl_portal2` | Forces the crosshair to show the second portal's reticle.|
| `@hudude_ctrl_reset`   | Resets the crosshair to its default, clean state. |

You can also inspect the other entities within the `multiportals_crosshair.vmf` instance for even more fine-grained control.

## Credits & License

This addon was created by me, [LaVashik](https://lavashik.dev/) and [@Electrodynamite12](https://github.com/Electrodynamite12).

When using this addon in your projects, **you must give credit** and link back to this repository in your map's description.

This project is protected by the MIT License :]

## How We Did It

On the path to creating a fully custom and moddable crosshair for Portal 2, [@Electrodynamite12](https://github.com/Electrodynamite12) and I ran into a series of technical challenges. This section is for the nerds out there who are curious about the problems we faced and how we solved them.

### TL;DR
The main challenge was making the custom crosshair scale correctly for any screen resolution, instead of just stretching like a simple overlay. The Source engine has no straightforward way to do this for custom HUD elements.
Our solution is a chain of engine workarounds: we use a particle system that renders a 3D model as the crosshair. This trick gives us access to material proxies to control its scale. To force the engine to actually update the material after a resolution change, we teleport an invisible object in front of the player's camera for a single frame. It's a hack, but it works. On top of that, we also had to hijack the game's core disconnect command to ensure the vanilla crosshair is always restored when you leave our map.


<details>
<summary>Click to expand the technical breakdown</summary>

### Problem: Managing the Vanilla Crosshair

**The Challenge:** We needed a way to disable the vanilla crosshair when a player enters a custom map and, more importantly, reliably re-enable it when they leave to avoid ruining their gameplay experience.

**Solution:** Disabling the crosshair was easy enough with the `hud_quickinfo 0` command. However, forcing it to re-enable automatically on exit was trickier. We solved this by creating wrappers around the standard game commands responsible for leaving a map.

We overrode the `disconnect` command and "shadowed" the `RequestMapRating` method. Now, when a player tries to leave the map, our cleanup script runs first, which resets `hud_quickinfo 1`, and only then is the original exit command executed.

```js
// Override the disconnect command via an alias to run our handler first
SendToConsole("alias \"dummy_disconnect\" \"script DisconnectHandler()\"") 
SendToConsole("alias \"disconnect\" \"dummy_disconnect; hud_quickinfo 1; killserver\"")

// Hook the map completion event to call our finalization function
local _requestMapRating = RequestMapRating;
::RequestMapRating <- function():(_requestMapRating) {
    printl("-- RequestMapRating command was handled!")
    ::Finalization() // Our cleanup function
    _requestMapRating()
}
```

-----

### Problem: Creating and Scaling a Custom HUD Element

**The Challenge:** We needed to do more than just overlay an image on the screen. We needed to create an element that would:

1.  Not stretch with resolution changes, unlike `r_screenoverlay`.
2.  Scale correctly, mimicking the behavior of the original crosshair.
3.  Allow for flexible control over its individual parts (color, transparency).

**Solution:** Our solution was to use **screen overlay particles**, as they allow us to use Control Points (CPs) to manage the color and other parameters of the individual sprites that make up the crosshair. However, we immediately hit two major obstacles:

*   **Obstacle #1:** By default, particles stupidly stretch to fit the screen resolution.
*   **Obstacle #2:** We could have scaled the texture using the `$basetexturetransform` material parameter and controlled it with `Proxies`. However, the engine doesn't allow `Proxies` in materials used for particle sprites.

The breakthrough came from one of the particle system's features: the **"render_models"** renderer type/function. Instead of rendering flat sprites, we forced the particle system to render a full 3D model (in our case, a flat model of the crosshair) at the desired screen position. This granted us access to `Proxies` in its material.

To pass the screen resolution data to `$basetexturetransform`, we first tried a `ConVar` proxy, but it wasn't suitable because we needed to pass a pre-formatted string to 6 different materials, which this proxy couldn't handle. We ended up using a combination of the `MaterialModify` proxy and a `material_modify_control` entity. But another catch awaited us: due to Valve's optimizations, the material would only update if the player could physically see the source model in the world. A particle on the screen didn't count as "seeing" it.

Our solution was hacky: we created an invisible `func_illusionary` brush with our crosshair material on every face. Each time the player changes their screen resolution, we teleport this brush directly in front of their camera for a single frame. The player never notices, but the engine registers that the model has been "seen" and obediently updates the material.

```js
// This function applies the transformation to the crosshair materials
function setHudResolution(x, y) : (calculatedTranslate) {
    foreach(name, translate in calculatedTranslate){
        local transform = format("center .5 .5 scale %f %f rotate 0 translate %f %f", x, y, translate.x, translate.y)
        EntFire("@hudude_scale_controller-" + name, "setmaterialvar", transform)
    }
    
    // Teleport the "cache brush" in front of the player to force an update
    local cache = Entities.FindByName(null, "@hudude_scale_cache")
    cache.SetOrigin(GetPlayer().EyePosition() + GetPlayer().GetForwardVector() * 10)
}

// Called when the resolution changes
::ScreenSize <- function(width, height, saveCache=true):(setHudResolution) {
    local x = width.tofloat() / 1366
    local y = height.tofloat() / 768
    setHudResolution(x, y)
    // ... saving code ...
}
```
Yes, VScript has no built-in way to get the player's screen resolution. This is why the player must run `script ScreenSize(w, h)` once. The data is then saved permanently in the game's files and used whenever a map with this custom crosshair is launched. This involves its own set of hacks that are part of the PCapture-Lib, so I won't break them down here.

The initial positions of the crosshair elements (`calculatedTranslate`) were adjusted manually by eye for a 1366x768 resolution.

```js
// These "magic values" define the offset for each part of the crosshair
local calculatedTranslate = {
    circle_L = Vector(0.54, 0, 0),
    circle_R = Vector(-0.555, 0, 0), 
    empty_L = Vector(0.075, 0.16, 0), 
    empty_R = Vector(-0.075, -0.16, 0), 
    fill_L = Vector(0.075, 0.145, 0), 
    fill_R = Vector(-0.076, -0.16, 0)
}
```

-----

### Problem: Making crosshair responding to in-game events

**The Challenge:** The crosshair needed to change color based on the active portal and disappear when the player picks up an object.

**Solution:** This turned out to be the easiest part.

*   **To control colors and fill states** for each part of the crosshair, we used `func_door` entities controlled by VScript. The script changes their position (`origin`) in the world, and the particle system reads these coordinates to drive its CPs (like color or alpha).
*   **To track when objects are picked up/dropped** and when the portal gun is acquired, we used the little-known `logic_eventlistener` entity. It allows us to listen for game events (like `player_pickup`) and call our scripts accordingly.

-----
</details>

Needless to say, there were no guides or documentation for any of these hacks. Everything here was discovered by [@Electrodynamite12](https://github.com/Electrodynamite12) and myself through a month of experimentation. It was a meticulous process built on a lot of workarounds, so if you encounter any bugs, please report them in the issues.

Fog-of-War Chips
================

Script for chips for [Tabletop Simulator](https://www.tabletopsimulator.com/) for which store the state of a Fog-of-War zone. Pull a chip from the bag, click "Setup", click the nice red button which just appeared in the FoW zone, and you're ready to go!

The FoW zone will then be automatically removed when the chip is placed in a bag, and automatically recreated when pulled out from the bag again. The zone will keep its state! Areas which were revealed before being put in the bag will still be revealed.

The chips are One Wold compatible! Put a FoW zone on your map, link it to a chip on the map, and pack it. The FoW zone will be automatically reconstructed once you build the map again! Note that you will need to pack the map after each use to save the FoW zone's state

Thanks to [Fog of War - on a Tray](https://steamcommunity.com/sharedfiles/filedetails/?id=2195642328) for showing me FoW zones are actually objects, and therefore can be stored and retrieved.

This is my first ever Lua script, so it is probably quite improvable, but it works! The script is available on github: https://github.com/Suppen/Fog-of-War-Chips/



Technical details
-----------------

[Fog of War - on a Tray](https://steamcommunity.com/sharedfiles/filedetails/?id=2195642328) showed me FoW zones can be stored in bags, which told me they can probably be serialized, and I was right!

The chips store the state of the FoW zones in their own GM notes. When a chip is loaded, it checks its GM notes. If nothing is there, it just shows the setup button. If there is something there, the chip attempts to parse it as JSON, and create a FoW zone from it. If it works, Great! The chip then links itself with the zone. If it does not work, the user will be notified, and the chip will show the setup button.

Clicking the setup button scans the entire scene for FoW zones, and paints a button over them. Clicking this button links the chip to the zone.

Once a zone has been linked to the chip, a timer starts. Every 3 seconds, the chip gets the FoW zone's data as JSON, and writes it to the chip's GM notes.

If the FoW zone is deleted, the chip will notice, and tell the user. This will also stop the save timer. There is currently no easy way to reset the chip, but it could just be deleted to get rid of it, or it could be copied to recreate the zone.

When the chip is placed in a bag (technically destroyed, so deleting it also works), it also destroys the linked FoW zone. Pulling it out of the bag again runs the init script, which is explained further up.

# qb-sheriffjob
Sheriff Job for QB-Core Framework developed in only 1 hour 

## Dependencies
- [qb-core]
- [qb-garages]
- [qb-clothing]
- [qb-phone]
- [qb-moneysafe]
- [qb-log]

## Features
- Classical requirements like on duty/off duty, clothing, vehicle, stash etc.
- Citizen ID based armory (Whitelisted)
- Fingerprint test ---you have to change the location according to your MLO.
- Evidence locker (stash) --you have to change the location according to your MLO.
- vehicles garage --you have to change the location according to your MLO.
- Integrated jail system
- Bullet casings
- GSR
- Blood drop
- Evidence bag & Money bag
- Handcuff as an item 
- Emergency services can see each other on map

### Commands
- /spikestrip - Places spike strip on ground.
- /pobject [pion/barier/schotten/tent/light/delete] - Places or deletes an object on/from ground.
- /cuff - Cuffs/Uncuffs nearby player
- /palert [text] - Sends an alert.
- /escort - Escorts nearby plyer.
- /mdt - Opens the MDT.
- /callsign [text] - Sets the player a callsign on database.
- /clearcasings - Clears nearby bullet casings.
- /jail [id] [time] - Sends a player to the jail.
- /unjail [id] - Takes the player out of jail.
- /clearblood - Clears nearby blood drops.
- /seizecash - Seizes nearby player's cash. (Puts in money bag)
- /sc - Puts soft cuff on nearby player.
- /cam [cam] - Shows the selected security cam display.
- /flagplate [plate] [reason] - Flags the vehicle.
- /unflagplate [plate] - Removes the flag of a vehicle.
- /plateinfo [plate] - Displays if a vehicle is marked or not.
- /depot [price] - Depots nearby vehicle. Player can take it after paying the cost.
- /impound - Impounds nearby vehicle permanently.
- /paytow [id] - Makes payment to the tow driver.
- /paylawyer [id] - Makes payment to the lawyer.
- /radar - Toggles the police radar.
- /911 [message] - Sends a report to emergency services.
- /911r [id] - Used to respond the emergency alerts.
- /911a [message] - Sends an anonymous report to emergency services (gives no location).
- /anklet - Places anklet (tracking device) on nearby player.
- /removeanklet [citizenid] - Removes the anklet from player.
- /ebutton - Used to respond an emergency alert.
- /takedrivinglicense - Takes the driving license from nearby player.
- /takedna [id] - Takes a DNA sample from the player.

## Installation
### Manual
- Download the script and put it in the `[qb]` directory.
- Add the following code to your server.cfg/resouces.cfg
```
ensure qb-core
ensure qb-sheriffjob
```

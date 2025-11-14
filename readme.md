# Auto Quest Tracker Mk III

Auto Quest Tracker Mk III started out as the continuation of a [continuation](https://github.com/gamer-angel05/AutoQuestTracker) (last version: Jan 2021) of the [original Auto Quest Tracker](https://www.curseforge.com/wow/addons/auto-quest-tracker) addon (last version: Jan 2018).

But in the meantime, and especially since version 4, it would be an understatement to call AQT Mk III a "continuation" of the original. It has gained so many new features and improvements, and not even the core function has remained unchanged.

_If you're not familiar with the original Auto Quest Tracker:_  

What it does is basically move the quests that belong to your current zone into the quest tracker, and move them out when you leave the zone. If you manually add a quest to the tracker (Shift-click in the quest log), AQT will respect that and leave the quest in the tracker.  

The addon works with most known quest trackers, like [Quester](https://www.curseforge.com/wow/addons/quester), [Kaliel's Tracker](https://www.curseforge.com/wow/addons/kaliels-tracker) and of course Blizz's built-in quest tracker. If using with Kaliel's Tracker, make sure to have Kaliel's Auto Zone feature disabled.

I have updated Auto Quest Tracker, because – in my experience – it works better than all other similarly featured addons I've tried over the last years. For example, it's the only one – again: in my experience – that properly handles Callings and account-wide pet quests. (When I'm in Shadowlands, I do _not_ want to see my Pandaria Beasts of Fable pet dailies popping up in the tracker, and when I'm pet battling in Pandaria I'm not interested in seeing my Maldraxxus Callings, …)

_Quester + Auto Quest Tracker_ is my preferred combo.

---

*If you’re having trouble reading this description on CurseForge, you might want to try switching to the [Repo Page](https://github.com/tflo/Auto-Quest-Tracker-MkIII?tab=readme-ov-file#auto-quest-tracker-mk-iii). You’ll find the exact same text there, but it’s much easier to read and free from CurseForge’s rendering errors.*

---

## New features of "Mk III"

### General

- Loading message (at login/reload) that shows the current state (enabled/disabled) of AQT. This can be disabled/enabled with `/aqt loadingmessage` (account-wide setting).
- The `/aqt` slash command now shows the current state of AQT (enabled/disabled and other settings if applicable).  
- For a complete list of slash commands, type `/aqt help` or `/aqt h`.
- Automatic throttling of the tracker update for 3 seconds in case of multiple zone changes in a row.

### Enable/Disable AQT

- You can now disable/enable AQT with the slash commands `/aqt off` or `/aqt on` (or shorter `/aqt d` or `/aqt e`) This is a per-char setting.

Temporarily disabling AQT can be useful for example if you have a bunch of quests that you want to keep focused as you move back and forth between adjacent zones. You could also just re-track the quests manually (AQT allows this and keeps them tracked), but this can get tedious.
It can also be useful if you simply have too many quests that technically belong to your zone, but you're not interested in at the moment.

New since version 3.0, there are now 3 modes of disabling AQT:

- Disable AQT for the duration of the current session: `/aqt off` or `/aqt d`
  - This is the new default since v3.0. The point of this is to make it (almost) impossible to disable AQT and then forget to re-enable it in the next session. (There's nothing worse than missing half of your quest log just because the zone-related quests weren't auto-tracked!)
  - AQT is smart enough not to confuse a /reload or a disconnect with the start of a new session. A new session will start if you are logged out for 20 minutes or more. AQT will then re-enable itself the next time you log in.
- Disable AQT permanently: `/aqt offp` or `/aqt dp`
  - This was the default before v3.0.
  - AQT will stay disabled on the char until you manually enable it again (`/aqt e`).
- Disable AQT for the current map instance: `/aqt offi` or `/aqt di`
  - A map instance usually is everything that is separated by a loading screen. So, for example, an instance change happens when you use a portal or when you enter/leave a dungeon instance, etc.
  - AQT will re-enable itself automatically as soon as you have left the map instance.

### Exceptions

New in v4 is a sophisticated __Exceptions__ system:

- You can now assign the following account-wide exceptions to quests:
  - Ignore (as if AQT was disabled for a specific quest).
  - Track always and everywhere.
  - Never track (disable auto tracking and remove from quest tracker).
- Exceptions can be assigned via modifier keys while click-tracking/untracking a quest in the QuestMap frame.
- Exceptions can be assigned via slash commands to entire quest groups or types, or to all quests under a given header.
- See the brand new [AQT wiki](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki), namely the [Exceptions section](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki/Exceptions), for how to do. It's too much new stuff to list here.
- Print Exceptions report with `/aqt x`.
- Slash commands to clear Exceptions (see Wiki!).

This opens up endless possibilites, for example:

- Set all (current and future) dungeon quests to Never Track: `/aqt n dung`.
- Set all variations of 'Aiding the Accord' to Always Track: `/aqt a ata`.
- Set all Dragonriding Race quests to Ignore: `/aqt i dr`.

… and so on. Again, check the [Wiki](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki/Exceptions) for detailed instructions and examples!

### Mini API

You can now enable/disable AQT in your scripts with the __global function__ `addon_aqt_enable()`:

- Enable with `addon_aqt_enable(true)`
- Disable with `addon_aqt_enable(false)`
- Toggle with `addon_aqt_enable(not AQT_CharDB.enabled)`

On wago.io you will find an (exemplary) [companion WeakAura](https://wago.io/3sHwNATna) using this function that you can place onto your Quest Tracker:

- The Aura's icon shows the current state of AQT (on/off)
- Left click: toggle AQT
- Right click: toggle Quest Log

More info on the Aura download page.

### Addon Compartment Button

- Shows the activation status.
- Available click actions:
  - Left-click: Print status text; same as `/aqt`.
  - Command-left-click: Print help text (use Control-left-click on Windows); same as `/aqt h` or `/aqt help`.
  - Right-click: Toggle AQT for the current session; same as `/aqt d` / `/aqt e` or `/aqt off` / `/aqt on`.

### Compatibility with Classic Quest Log

If you are using [Classic Quest Log](https://www.curseforge.com/wow/addons/classic-quest-log), you will need to patch it to set the correct quest watch type (1) when you Shift-click on a quest to add it to the tracker. Otherwise, AQT will not be able to recognize the quest as "manually added" and will untrack it when you zone out, which is usually not what you want when you add a quest manually.

You can download a plugin-style addon that will do this for you [in this GitHub thread](https://github.com/tflo/Auto-Quest-Tracker-MkIII/issues/2).  

---

Feel free to share your suggestions or report issues on the [GitHub Issues](https://github.com/tflo/Auto-Quest-Tracker-MkIII/issues) page of the repository.  
__Please avoid posting suggestions or issues in the comments on Curseforge.__

---

__Other addons by me:__

- [___PetWalker___](https://www.curseforge.com/wow/addons/petwalker): Never lose your pet again (…or randomly summon a new one).
- [___Move 'em All___](https://www.curseforge.com/wow/addons/move-em-all): Mass move items/stacks from your bags to wherever. Works also fine with most bag addons.
- [___Auto Discount Repair___](https://www.curseforge.com/wow/addons/auto-discount-repair): Automatically repair your gear – where it’s cheap.
- [___Auto-Confirm Equip___](https://www.curseforge.com/wow/addons/auto-confirm-equip): Less (or no) confirmation prompts for BoE and BtW gear.
- [___Slip Frames___](https://www.curseforge.com/wow/addons/slip-frames): Unit frame transparency and click-through on demand – for Player, Pet, Target, and Focus frame.
- [___Action Bar Button Growth Direction___](https://www.curseforge.com/wow/addons/action-bar-button-growth-direction): Fix the button growth direction of multi-row action bars to what is was before Dragonflight (top --> bottom).
- [___EditBox Font Improver___](https://www.curseforge.com/wow/addons/editbox-font-improver): Better fonts and font size for the macro/script edit boxes of many addons, incl. Blizz's. Comes with 70+ preinstalled monospaced fonts.

__WeakAuras:__

- [___Stats Mini___](https://wago.io/S4023p3Im): A *very* compact but beautiful and feature-loaded stats display: primary/secondary stats, *all* defensive stats (also against target), GCD, speed (rating/base/actual/Skyriding), iLevel (equipped/overall/difference), char level +progress.

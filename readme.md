# Auto Quest Tracker Mk III

Auto Quest Tracker Mk III is the continuation of a [continuation](https://github.com/gamer-angel05/AutoQuestTracker) (last version: Jan 2021) of the [original Auto Quest Tracker](https://www.curseforge.com/wow/addons/auto-quest-tracker) addon (last version: Jan 2018).

The addon works with most known quest trackers, like [Quester](https://www.curseforge.com/wow/addons/quester), [Kaliel's Tracker](https://www.curseforge.com/wow/addons/kaliels-tracker) and of course Blizz's built-in quest tracker. If using with Kaliel's Tracker, make sure to have Kaliel's Auto Zone feature disabled.

I have updated Auto Quest Tracker, because – in my experience – it works better than all other similarly featured addons I've tried in the last years. For example, it's the only one – again: in my experience – that properly handles Callings and account-wide pet quests. (When I'm in Shadowlands, I do _not_ want to see my Pandaria Beasts of Fable pet dailies popping up in the tracker, and when I'm pet battling in Pandaria I'm not interested in seeing my Maldraxxus Callings, …)

_Quester + Auto Quest Tracker_ is my preferred combo.

## New in version 2.0 ("Mk III"):

Besides an updated version number in the toc file, Mk III also brings you a new feature:
 
- You can now disable/enable AQT with the slash commands `/aqt off` / `/aqt on`. This is a per-char setting.
  - Loading message (at login/reload) that shows the current state (enabled/disabled) of AQT. This can be disabled/enabled with `/aqt toggleloadingmessage` (account-wide setting).
  - The `/aqt` slash command now shows the current state of AQT (enabled/disabled). As before, it also shows all available slash commands.

Temporarily disabling AQT can be useful if you have a bunch of related quests and breadcrumbs that you want to keep focused as you move back and forth between adjacent zones (like leveling in Dragon Isles). You could also just re-track the quests manually (AQT allows that), but that can get tedious.  
What happens when you disable AQT is that the two main events become unregistered, i.e. this is close to unloading the addon, but without the need to reload.

For more slash commands, enter `/aqt` in the chat. These are unchanged from the previous versions and are self-explanatory.

Feel free to post suggestions or issues in the [GitHub Issues](https://github.com/tflo/PetWalker/issues) of the repo!
__Please do not post issues or suggestions in the comments on Curseforge.__




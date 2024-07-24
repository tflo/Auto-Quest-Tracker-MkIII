#### 4.2.10-beta-1 (2024-07-24)

- This is a *temporary* compatibility update for TWW 110000.
- They removed a function I was hooking. Thus, removing a quest ID from "Always Tracked" via modified Shift-click on the quest in the quest log is currently disabled (adding a quest this way still works).
- There is currently no way to remove individual quest IDs from "Always Tracked". (You can use `/aqt xcleari` to remove *all* exceptions assigned to quest IDs, or edit the SavedVariables data.)
- I hope to get this fixed soon, sorry for the inconvenience.
- toc updated for TWW 110000.

#### 4.2.9 (2024-05-08)

- toc bump only (100207). Addon update will follow as needed.

#### 4.2.8 (2024-04-26)

- Added “Last Hurrah” quest group (argument: `lh`; e.g. to always track all “Last Hurrah” quests: `/aqt a lh`).
- Updated the [Wiki](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki/Exceptions) accordingly.

#### 4.2.7 (2024-03-19)

- toc bump only. If necessary, the addon will be updated in the next days.

#### 4.2.6 (2024-01-16)

- Updated readme.
- toc bump for 10.2.5. Compatibility update will follow if needed.

#### 4.2.5 (2023-11-30)

- Added 'The Storm Race Tour' to the Dragonriding Races group (to always track all Dragonriding Race quests: `/aqt a dr`)

#### 4.2.4 (2023-11-19)

- Added 78447 'Aiding the Accord: Emerald Bounty' to the AtA group (to always track all AtA quests: `/aqt a ata`).

#### 4.2.3.1 (2023-11-15)

- Curseforge build failed, attempt no. 2.
- Fixed typo in slash command example in 4.2.3 changes.
- For the latest changes, see 4.2.3 below.

#### 4.2.3 (2023-11-15)

- Two new groups that you can add to your exceptions:
  - `awadw`: A Worthy Ally: Dream Wardens (single-quest group).
  - `awa`: A Worthy Ally (Loamm Niffen & Dream Wardens). So, for example, `/aqt a awa` will now set both Worthy Ally weeklies to 'always tracked'.
- Changed keyword for 'A Worthy Ally: Loamm Niffen' from `awa` to `awaln`.
- Updated the [Wiki](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki/Exceptions) accordingly.

#### 4.2.2 (2023-11-08)

- Added Superbloom to the Aiding the Accord quest group.
- Added Challenge Tour to the Dragonriding Races quest group. (If there is a new 10.2 tour, it will be added shortly.)
- toc update to 100200.

#### 4.2.1 (2023-09-06)

- Added quest ID of new Dreamsurge AidingTheAccord to the AtA exceptions group.
- Output of the exceptions report is now sorted by quest ID.
- Wording of chat feedback.
- toc bump 100107.

#### 4.2.0 (2023-08-26)

- Colorized the exceptions report (`x`) and confirmation messages.
- Optimized many messages; minor code cleanup.
- __New:__ Exceptions by quest header!
  - Example: `/aqt a h Tournament` will apply the Always Track exception (`a`) to all quests listed (now or in the future) under the "Tournament" quest header.
  - Fully documented in the [Exceptions section](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki/Exceptions) of the [AQT wiki](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki).
- Together with the previously implemented exceptions via modifier-click (v4.0) by ID group and by type (v4.1), the core of the new exception system is now complete. Expect some bugs to still run free ;)
- In the next versions: In-game help system for all commands; possibility to add single quest IDs via slash command (you can already do that via modifier-click).

#### 4.1.0 (2023-08-24)

- __New:__ Assign Exceptions to quest ID groups or quest types via slash command
  - Examples:
    - `/aqt a ata` assigns the _Always Track_ Exception (`a`) to the "Aiding the Accord" quest group (`ata`).
    - `/aqt n dung` assigns the _Never Track_ Exception (`n`) to all quests of type 62 "Dungeon" (`dung`).
  - For the complete documentation and lists of available commands, groupes and types, see the [Exceptions section](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki/Exceptions) of the [AQT wiki](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki). In-game help will be added later (v4.2 or 4.3).
- Fixed non-working Never Track Exceptions.
- Exceptions report (`/aqt x`) should now work for all types of Exceptions. (Formatting of the report still needs some work.)
- Greatly improved the wiki, all new 4.1 stuff should be properly documented. Let me know if you find that info is missing, or if something is poorly explained!
- If you are new to version 4, please have look at the previous version 4.x.x changelogs, and, most important, check out the [AQT wiki](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki).
  
#### 4.0.1 (2023-08-18)

- CF messed up th push (again, sigh)
- So, once again the whole story:
- OK folks: I'm taking the beta into release, just because there are almost zero downloads on the beta channel.
- The current beta is pretty stable, so there shouldn't be any (major) issues.
- I need feedback. Especially on the config system. Should I switch to AceGUI? (instead of pure CLI, aka Slash input) Let me know!
- The important part comes now. AQT v4 has quite a bunch of changes and new features. You do not have to know them. For the moment, you can continue using AQT as you are used to.
- But: You should know them, because they are great improvements.
- Now the notes for the folks that have missed out on v4-beta-1:
- You can now assign the following account-wide Exceptions to quests:
  - Ignore (as if AQT was disabled for a specific quest)
  - Track always and everywhere
  - Never track
- Exceptions can be assigned via modifier keys while tracking/untracking a quest in the quest log or quest tracker.
- See the brand new [AQT wiki](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki), namely the [Exceptions section](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki/Exceptions), for how to do. It's too much new stuff to list here.
- Print Exceptions report with `/aqt x`
- Slash commands to clear Exceptions (see Wiki!)
- More to come. Stay tuned!
- AGAIN: Check the wiki for news and docs regularly! At least during this pseudo-beta time, until 4.1 is out. Thank you.

#### 4.0- (2023-08-18)

- OK folks: I'm taking the beta into release, just because there are almost zero downloads on the beta channel.
- The current beta is pretty stable, so there shouldn't be any (major) issues.
- I need feedback. Especially on the config system. Should I switch to AceGUI? (instead of pure CLI, aka Slash input) Let me know!
- The important part comes now. AQT v4 has quite a bunch of changes and new features. You do not have to know them. For the moment, you can continue using AQT as you are used to.
- But: You should know them, because they are great improvements.
- Now the notes for the folks that have missed out on v4-beta-1:
- You can now assign the following account-wide Exceptions to quests:
  - Ignore (as if AQT was disabled for a specific quest)
  - Track always and everywhere
  - Never track
- Exceptions can be assigned via modifier keys while tracking/untracking a quest in the quest log or quest tracker.
- See the brand new [AQT wiki](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki), namely the [Exceptions section](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki/Exceptions), for how to do. It's too much new stuff to list here.
- Print Exceptions report with `/aqt x`
- Slash commands to clear Exceptions (see Wiki!)
- More to come. Stay tuned!
- AGAIN: Check the wiki for news and docs regularly! At least during this pseudo-beta time, until 4.1 is out. Thank you.

#### 4.0-beta-4 (2023-08-18)

- Small but impactful: Greatly reduced the lockout time between clicks, when changing Exceptions.

#### 4.0-beta-3 (2023-08-16)

- Removed some double message prefixes.
- Debug system cleaned up.
  
#### 4.0-beta-2 (2023-08-16)

- Removed some debug code.
- Ad-hoc updates on Exception status change via modifier will now be performed even if the status has not actually changed.
- Much more info in quest list now (see also [Wiki: Quest List](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki/Quest-List))
- __If you haven't already:__ For the new stuff in AQT v4 check out the changelog entry for version _4.0-beta-1 (2023-08-15)_ and the [AQT wiki](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki), especially the [Exceptions section](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki/Exceptions).

#### 4.0-beta-1 (2023-08-15)

- First implementation of the new Exceptions system
- You can now assign the following account-wide Exceptions to quests:
  - Ignore (as if AQT was disabled for a specific quest)
  - Track always and everywhere
  - Never track
- Exceptions can be assigned via modifier keys while tracking/untracking a quest in the quest log or quest tracker.
- See the brand new [AQT wiki](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki), namely the [Exceptions section](https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki/Exceptions), for how to do. It's too much new stuff to list here.
- Print Exceptions report with `/aqt x`
- Slash commands to clear Exceptions (see Wiki!)
- More to come. Stay tuned!

#### 3.0.5 (2023-08-12)

- Added addon compartment button tooltip, providing these infos:
  - Activation status.
  - List of available click actions:
    - Left-click: Print status text; same as `/aqt`.
    - Command-left-click: Print help text (use Control-left-click on Windows); same as `/aqt h` or `/aqt help`.
    - Right-click: Toggle AQT for the current session; same as `/aqt d` / `/aqt e` or `/aqt off` / `/aqt on`.

#### 3.0.4 (2023-07-23)

- Minor code and readme fixes.

#### 3.0.3 (2023-07-12)

- Session grace time increased to 20 minutes (was 6 minutes). (This is the amount of time you can be logged out of a toon without having a disabled AQT automatically re-enabled the next time you log in).
- Updated readme.
- toc updated for 10.1.5.
  - I have not yet had a chance to really test AQT with 10.1.5, but as far as I know there are no relevant API changes. If I find any problems, you'll get a content update soon.

#### 3.0.2 (2023-05-14)

- Safeguard against an error that could happen in this scenario: AQT disabled by user--> UI reload --> Client crash or force-quit --> Login

#### 3.0.1 (2023-05-08)

- No changes, trying to get the wrong client version listing on CurseForge fixed.
- PS: This version was later retired from CF, as the listing of v3.0 could get fixed.

#### 3.0 (2023-05-08)

- New: Disabling AQT (`/aqt off` or `/aqt d`) now disables it for the duration of your session, instead of permanently.
- There are now 3 modes of disabling AQT:
  - Disable AQT for the duration of the current session: `/aqt off` or `/aqt d`
    - This is the new default since v3.0. The point of this is to make it (almost) impossible to disable AQT and then forget to re-enable it in the next session. (There's nothing worse than missing half of your quest log just because the zone-related quests weren't auto-tracked!)
    - AQT is smart enough not to confuse a /reload or a disconnect with the start of a new session. A new session will start if you are logged out for 6 minutes or more. AQT will then re-enable itself the next time you log in.
  - Disable AQT permanently: `/aqt offp` or `/aqt dp`
    - This was the default before v3.0.
    - AQT will stay disabled on the char until you manually enable it again (`/aqt e`).
  - Disable AQT for the current map instance: `/aqt offi` or `/aqt di`
    - A map instance usually is everything that is separated by a loading screen. So, for example, an instance change happens when you use a portal or when you enter/leave a dungeon instance, etc.
    - AQT will re-enable itself automatically as soon as you have left the map instance.
- Better help and status messages.
- Increased the tracker update delay after a zone change from 2 to 3 seconds.
  - In addition, further updates are throttled during this time. This should greatly reduce CPU usage in cases where multiple zone changes occur quickly in a row.
- Added addon icon for the addon manager and for the minimap addon compartment.
- Added button to the addon compartment, with these functions:
  - Click the button to display the status info in the chat.
  - Command-click (Mac) or Control-click (Windows) the button to toggle AQT.
  - Shift-click the button to display the complete list of slash commands.

#### 2.2.2 (2023-05-02)

- Readme/description:
  - Added note on compatibility with Classic Quest Log
  - Added download link for the Classic Quest Log fix
- toc updated for 10.1

#### 2.2.1 (2023-03-21)

- Some code optimization
- toc updated for 10.0.7

#### 2.2 (2023-02-16)

- Added the option to ignore instance quests (raid & dungeon):
  - Enter `/aqt in` or `/aqt instances` to toggle.
  - Enable this to keep the quest tracker free of instance quest spam. (Technically, instance quests are on a specific map and have map POIs like any other quest. However, from a player's point of view, these quests aren't tied to a specific zone in the same way as normal quests, as in most cases you enter dungeons via LFG, which is location-neutral.)
  - "Ignore" means that instance quests will not be removed from your tracker when you enable this option, but if you remove them, they won't come back when you zone into the quest's map. (And if you put them in the tracker, they will stay there wherever you are).
  - Currently, instance quests are identified by their quest type (62 and 81). This may need some additional criteria or fine-tuning in the future.

#### 2.1.2 (2023-02-05)

- To illustrate the usage of the recently added global toggle function, the addon now has an external [companion WeakAura](https://wago.io/3sHwNATna). See description/ReadMe.
- ReadMe: Added mention of the companion WeakAura.

#### 2.1.1 (2023-02-03)

- Fixed combat lockdown check
- Better quest list and with more info (quest log index, quest type, onMap, hasPOI)
- More debug info for quest tracking (temporarily)
- Shorter slash commands (enter `/aqt` for a list)
- Updated ReadMe

#### 2.1 (2023-02-02)

- If you enable AQT (via `/aqt on`), the quest tracker now is immediately updated for your current zone, not only when the next zone change event fires.
- Added a global function that you can use in your scripts: `addon_aqt_enable()`
  - It does the same as the slash commands and takes a boolean as argument:
    - To enable AQT: `addon_aqt_enable(true)`
    - To disable AQT: `addon_aqt_enable(false)`
    - To toggle AQT: `addon_aqt_enable(not AQT_CharDB.enabled)`

#### 2.0.1.2 (2023-01-25)

- Added pkgmeta file for correct Curse packaging and changelog

#### 2.0.1.1 (2023-01-25)

- toc: updated for 10.0.5
- Improved ReadMe

#### 2.0.1 (2022-12-24)

- Added CF ID

#### 2.0 (2022-12-22)

- Initial version of my Dragonflight fork ("Mk III")
- Code cleanup
- New: You can now disable/enable AQT with the slash commands `/aqt off` / `/aqt on`. This is a per-char setting.
- New: Loading message that shows the current state (enabled/disabled) of AQT. This can be disabled/enabled with `/aqt toggleloadingmessage` (account-wide setting).
- New: `/aqt` slash command now shows the current state of AQT (enabled/disabled). As before, it also shows all available slash commands.
- toc: updated to 100002

### Previous Changelog (up to January 2021: by ErrondGamer (original) and gamer-angel05 (Shadowlands))

#### v1.5

- Update for better filtering with new Shadowlands api.

#### v1.4

- Updated for Shadowlands
- Updating TOC

#### v1.2

- Filter trying to show / hide: World Quests and Hidden Quests (eg: 2v2 weekly arena quest)
- Added debugging to show the current quests in the quest log by using /aqt quests
- Updating TOC

#### v1.1

- This version brings the rework of a lot of the addon's code to simplify it considerably.
- Fixed some obscure bugs causing quests to be added as manually tracked incorrectly
- Performance improvements
- Fixed some possible tainting

#### v1.0.3

- Fixed a bug with quest progression causing quests to be marked as manually added
- Added code to cleanup old entries at startup
- Added debugging logic

#### v1.0.2

- Updating for patch 7.1.5

#### v1.0.1

- Fixed a bug causing all quests being detected as manually added.

#### v1.0

- First release

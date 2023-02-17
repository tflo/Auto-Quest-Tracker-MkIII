#### 2.2 (2023-02-16)
- Added the option to ignore instance quests (raid & dungeon):
  - Enter `/aqt in` or `/aqt instances` to toggle.
  - Enable this to keep the quest tracker free of instance quest spam. (Technically, instance quests are on a specific map and have map POIs like any other quest. However, from a player's point of view, these quests aren't tied to a specific zone in the same way as normal quests, as in most cases you enter dungeons via LFG, which is location-neutral.)
  - "Ignore" means that instance quests will not be removed from your tracker when you enable this option, but if you remove them, they won't come back when you zone into the quest's map. (And if you put them in the tracker, they will stay there wherever you are).
  - Currently, instance quests are identified by their quest type (62 and 81). This may need some additional criteria or fine-tuning in the future.

#### 2.1.2 (2023-02-05)
- To illustrate the usage of the recently added global toggle function, the addon now has an external companion WeakAura (https://wago.io/3sHwNATna). See description/ReadMe.
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

#### 3.0.5 (2023-08-12)

- Added addon compartment button tooltip, providing these infos:
  - Activation status.
  - List of available click actions:
    - Left-click: Print status text; same as `/aqt`.
    - Command-left-click: Print help tex (use Control-left-click on Windows); same as `/aqt h` or `/aqt help`.
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

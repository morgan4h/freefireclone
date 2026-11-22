# freefireclone
sofai 4h clone free fire — a Garena Free Fire style battle royale prototype built in Godot 4.7.

## What's in it

**Flow:** Player profile and cat preview → lobby → match → results → lobby. The profile screen opens directly so startup does not replay multiple loading screens.

**Lobby (Free Fire style):**
- Persistent profile: username, level + XP bar, coins and diamonds
- Rotating 3D character preview
- Side navigation (Store, Luck Royale, Vault, Clan, Friends, Messages, Profile, Ranked)
- Mode selector: **Battle Royale** (50 players, shrinking zone) and **Clash Squad** (10 players, fast skirmish)
- Big START button

**Match (Battle Royale / Clash Squad):**
- 50 combatants in BR (you + 49 AI bots), 10 in Clash Squad
- Bots acquire the nearest living enemy and fight **each other and you** — the alive count ticks down naturally
- Phased shrinking safe zone with a glowing boundary ring; taking damage outside it, scaling up per phase
- Bots retreat into the safe zone
- Supply crates + periodic airdrops (press **E** near a glowing crate for ammo, armor, or a medkit)
- Hitscan shooting with **headshots (double damage)**, recoil, reload, and out-of-combat health regen
- Armor vest absorbs part of incoming damage

**HUD:**
- Dynamic crosshair, hit markers, damage vignette + low-health pulse
- Health and armor bars, ammo (mag / reserve), reload indicator
- Circular minimap (zone, enemies, airdrops, your facing)
- Alive counter, kills, zone timer, live kill feed, pickup toasts
- Match intro countdown (GET READY → 3 → 2 → 1 → GO!)

**Results:** BOOYAH! screen with placement, kills, damage, and rewards (XP, coins, diamonds, level-ups) plus an XP progress bar — then return to lobby.

## Controls

- `WASD` — move
- Mouse — look
- `Shift` — sprint
- `Space` — jump
- Left mouse — shoot
- `R` — reload
- `E` — open nearby supply crate / interact
- `Esc` — release / recapture the mouse

On Android, use the on-screen joystick and touch buttons for movement, camera look, fire, aim, sprint, jump / drop, reload, weapon swap, crate interaction, and Gloo Walls.

## Project layout

- `autoloads/` — `GameManager` (match state + input map), `PlayerData` (save file)
- `scripts/` — gameplay (`player`, `bot`, `battle_map`, `minimap`), `lobby`, and `theme_manager` (shared Free Fire theme)
- `Scenes/` — `logo_screen`, `loading_screen`, `login_screen`, `Lobby`, `BattleMap`

Open `project.godot` in Godot 4.7 and run the project. Progress saves to `user://player_data.cfg`.

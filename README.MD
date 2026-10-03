# TrannyWare

A modular, lightweight Luau utility suite and game enhancement framework built using **Fluent-Renewed**. Automatically differentiates between **Murder Mystery 2** and other Roblox titles to load game-specific modules alongside a dedicated multi-game Universal engine.

---

### Verified Executor Compatibility
* **Potassium** (Windows) — Fully Tested & Supported
* Any modern environment providing standard filesystem, dynamic UI indexing (`gethui`), and HTTP request globals.

---

### Quick Launch

Run the following loadstring inside your executor:

```lua
loadstring(game:HttpGet("[https://raw.githubusercontent.com/scenegore/TrannyWare/main/main.luau](https://raw.githubusercontent.com/scenegore/TrannyWare/main/main.luau)"))()
```

---

### Core Feature Matrix

#### 1. Universal Engine (All Games)
* **Smart Anti-Fling:** Proactively scans players within physics reach. High-torque spin exploiters and abnormal momentum rammers are locally stripped of collision, while innocent launched players retain natural ragdoll states. Includes automatic self-velocity clamping.
* **Camera Flight (Freecam) & Warp:** Independent orbital spectator mode with adjustable speed and right-click directional aiming. Press **F** while active to immediately warp your physical character to the camera's world position.
* **Anti-Void (Fall Saver):** Constantly tracks the last grounded position. If thrown or dropped below kill boundaries, your velocity zeroes out and returns you safely to solid ground.
* **Visual Shaders & World Tuning:** 
  * Fullbright mode (strips fog, dark ambiance, and world shadows).
  * Custom post-processing shader stack (Bloom, ColorCorrection, SunRays).
  * Safe Potato Mode: Maximizes FPS by disabling non-essential geometry details, textures, and emitters while caching original properties for clean restoration.
* **Locomotion & Utilities:** 
  * Character flight (WASD + Space/Shift).
  * Ghost walk Noclip & Infinite Jump.
  * Ctrl + Click raycast teleport (Blink).
  * Alt + Click client-side part removal (Client BTools).
  * High-frequency background Auto-Clicker (5–35 CPS).
* **Tactical HUD Overlay:** Real-time FPS and ping tracker with configurable 8-point screen snapping (Top-Left, Bottom-Right, Center, etc.).

#### 2. Murder Mystery 2 Module
* **Event-Driven Role Sync:** Connects directly into MM2's client gameplay remotes to instantly detect Murderers, Sheriffs, Innocents, and Heroes without polling delay.
* **Intelligent ESP:** Glow, Solid, and Tracer beam modes with distance readouts, weapon draw indicators, and friend color overrides.
* **Gun Snagger & Drop Alerts:** Real-time dropped weapon highlight with manual grab keybind and automated safe-return teleport.
* **Tactical Combat:**
  * Auto-Shoot Triggerbot targeting the Murderer within configurable FOV limits.
  * Synced reload bar visualizing active revolver recovery frames.
  * Orbital directional arrow constantly tracking the Murderer's vector off-screen.
  * Remote-injected packet Kill All with protected Whitelist filtering.
* **Map Vote Automation:** High-frequency map pad exploit with built-in round-state locks to prevent accidental eliminations.

#### 3. Data & Config Persistence
* **Per-Game Config Isolation:** Automatically silos configuration files under `TrannyWare/Games/<PlaceId>` to prevent cross-game toggle bleeding. MM2 preferences remain stored in `TrannyWare/MM2`.
* **Autoload Ready:** Fully compatible with Fluent's built-in SaveManager and InterfaceManager.
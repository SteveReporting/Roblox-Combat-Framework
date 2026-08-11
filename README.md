# Roblox Server-Authoritative Combat Framework

A modular sword-and-shield combat sample for Roblox using a **client intent / server authority** model.

## Features

- slash, stab and kick attacks
- toggle guard with `E` and hold guard with right click
- directional blocking using facing dot products
- 100-point shield stamina
- guard damage and delayed regeneration
- 20-second kick cooldown
- kick removes 40 shield stamina when guarded
- kick stuns an unguarded target for 2 seconds
- guard break stun
- server-owned target selection and hit validation
- line-of-sight checks
- replicated status attributes for animation/UI

## Why this is portfolio-worthy

The client never tells the server which player was hit. It only requests an action. The server checks cooldowns, state, distance, attack arc, line of sight, target health and guard direction before applying damage.

```text
src/
├── client/
│   └── CombatController.client.lua
├── server/
│   └── CombatService.server.lua
└── shared/
    ├── CombatConfig.lua
    └── StatusService.lua
```

## Controls

| Input | Action |
|---|---|
| Left click | Slash |
| R | Stab |
| K | Kick |
| E | Toggle shield guard |
| Right click | Hold shield guard |

## Security approach

Roblox RemoteEvents are treated as untrusted input. Attack targets are found server-side from world geometry; cooldown and status state are also validated server-side. This reduces common exploit paths such as a client firing a remote with an arbitrary target or damage value.

## Tech

Luau, RemoteEvents, Attributes, raycasting, overlap queries, vector/dot-product geometry and server-authoritative gameplay state.
# Jellyfin stream badge packs

Badge logos for stream versions, driven by pack JSON URLs that **modified AIOS** publishes on Jellyfin `System/Info`.

Works with **stock AIOM**: AIOM only wraps AIOS for catalogs/playback. Pack discovery always talks to AIOS.

---

## Flow

```
Stock AIOM (Jellyfin)          Modified AIOS
  catalogs + PlaybackInfo         System/Info
         │                        aiostreams.defaultBadgePacks
         │                               │
         └────────── sample app ─────────┘
              match logos on versions
```

1. Save pack URLs in AIOS (Configure → Miscellaneous → Badge Packs), or set `JELLYFIN_DEFAULT_BADGE_PACK_URLS`.
2. Point stock AIOM’s stream addon at that AIOS instance.
3. In the sample app:
   - **Jellyfin URL** = AIOM (browse / play)
   - **AIOS URL** = the same AIOS (Jellyfin or Stremio base) → packs from `System/Info/Public`
4. App matches pack patterns to each version’s formatter text and loads pack `imageURL`s.

No AIOM changes required. Badge PNGs are not hosted by Jellyfin.

---

## Diffs

| | Branch | Compare |
|--|--------|---------|
| **AIOStreams (required)** | [`feature/badge-packs`](https://github.com/Yuno-XC/aiostreams-experimental/tree/feature/badge-packs) | [vs base](https://github.com/Yuno-XC/aiostreams-experimental/compare/6ca32ed2...feature/badge-packs) |

Optional AIOM forwarder patches remain under `patches/aiometadata/` if you want packs mirrored onto AIOM’s own `System/Info`. They are not needed for the sample when the AIOS URL is set.

```bash
cd AIOStreams && git checkout 6ca32ed2 && git am ../jellyfin-badge-packs/patches/aiostreams/*.patch
```

---

## Sample

```text
sample-ios/BadgeStreamsSample.xcworkspace
```

Scheme: `BadgeStreamsSample`.

Settings:

- Jellyfin URL → stock AIOM (or AIOS if you browse AIOS directly)
- AIOS URL → modified AIOS Jellyfin or Stremio base (required when Jellyfin is AIOM)

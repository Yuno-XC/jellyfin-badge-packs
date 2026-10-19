# Jellyfin stream badge packs

Badge logos for stream versions, driven by pack JSON URLs that **modified AIOS** publishes on Jellyfin `System/Info`.

**Stock AIOM is enough** for catalogs and playback. Only AIOS is modified.

---

## Flow

```
Stock AIOM                          Modified AIOS
 catalogs + PlaybackInfo              Configure → Badge Packs
        │                             System/Info
        │                             aiostreams.defaultBadgePacks
        └──────── client ─────────────┘
             match logos on versions
```

1. Save pack URLs in AIOS (Configure → Miscellaneous → Badge Packs), or set `JELLYFIN_DEFAULT_BADGE_PACK_URLS`.
2. Point stock AIOM’s stream addon at that AIOS instance.
3. Point the client’s **Jellyfin URL** at AIOM (or at AIOS Jellyfin directly).
4. Client reads `aiostreams.defaultBadgePacks` from that server’s `System/Info/Public`, matches pack patterns to each version, and loads pack `imageURL`s.

No AIOM fork or AIOM patches. Badge PNGs are not hosted by Jellyfin.

---

## Diffs (AIOS only)

| | Branch | Compare |
|--|--------|---------|
| **AIOStreams** | [`feature/badge-packs`](https://github.com/Yuno-XC/aiostreams-experimental/tree/feature/badge-packs) | [vs base](https://github.com/Yuno-XC/aiostreams-experimental/compare/6ca32ed2...feature/badge-packs) |

```bash
cd AIOStreams && git checkout 6ca32ed2 && git am ../jellyfin-badge-packs/patches/aiostreams/*.patch
```

Patches:

1. Publish `JELLYFIN_DEFAULT_BADGE_PACK_URLS` on Jellyfin `System/Info`
2. Save pack URLs from Configure → Miscellaneous → Badge Packs
3. Honour Fusion `groupId` when importing packs

---

## Sample

```text
sample-ios/BadgeStreamsSample.xcworkspace
```

Scheme: `BadgeStreamsSample`.

Settings: **Jellyfin URL** only (AIOM or AIOS). Pack URLs are not configured in the app.

# Changelog

## 2026-03-22 — Home redesign

**Prompt:** `/implement make the home section better regarding font sizes and empty spaces. Also make sections look better.`

**Changes:**
- Replaced `List(.insetGrouped)` with `ScrollView` + `LazyVStack` in HomeView for a fluid, edge-to-edge layout without grouped card backgrounds
- Increased section title font from `.headline` to `.title2.bold()` to have bold typography
- Enlarged station cards: width 130→160pt, favicon 64→80pt, name font `.caption`→`.subheadline`
- Tightened spacing between sections and cards for better content density
- Styled vertical sections (Recently Changed, Now Playing) with rounded containers and dividers
- Fixed pre-existing Simulator crash in `AudioPlayerService.setupRouteDetector()` by guarding `AVRouteDetector` KVO with `#if !targetEnvironment(simulator)`

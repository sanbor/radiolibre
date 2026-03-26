---
name: No Live Activity or widget extension
description: Never create a Live Activity, widget extension, or WidgetKit integration — NowPlayingService handles lock screen via MPNowPlayingInfoCenter
type: feedback
---

Do NOT create a Live Activity (ActivityKit), widget extension, or WidgetKit integration for this project.

**Why:** A Live Activity was previously built and shipped alongside `NowPlayingService`, which caused duplicate UI on the lock screen — both the Live Activity banner and the standard Now Playing widget showed the same station info. The entire widget extension (`LibreRadioActivity/`, `Shared/`, `LiveActivityService`, `WidgetDataService`, `RadioActivityAttributes`, App Group entitlements) was removed. It also triggered Apple Review Guideline 2.1 rejections because reviewers could see a `widgetkit-extension` bundle but couldn't find a widget in the gallery.

**How to apply:** Lock screen playback controls, CarPlay, and Control Center are fully handled by `NowPlayingService` via `MPNowPlayingInfoCenter` + `MPRemoteCommandCenter`. There is no need for ActivityKit, WidgetKit, or a widget extension target. If asked to add lock screen features, enhance `NowPlayingService` instead.

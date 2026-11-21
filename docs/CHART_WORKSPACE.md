# Chart Workspace — v0.2.0

## Functional scope

The chart module consumes immutable daily OHLC candles. This milestone includes candle validation, a causal 20-bar simple moving average, bounded pan and zoom, a crosshair with OHLC readout, candlestick and line modes, and a responsive instrument directory. The replay page gives the chart only the revealed close series. The input is synthetic, explicitly labeled, and must not be interpreted as historical market prices.

## Design and motion

Use Midnight Slate (#232F38), Burgundy (#872A35), Steel Grey (#929FA8), and Warm Ivory (#D9D2BF). Gains and losses have separate muted semantic colors. Motion tokens are shared by buttons, tab transitions, and amount changes. Reduced Motion bypasses animations. Desktop pointer hover, mobile tap, mouse-wheel zoom, drag, and pinch are supported by the implementation; physical-device testing remains pending.

## Performance

Only candles inside the viewport are painted. A repaint boundary isolates chart painting. Indicators are recalculated when the data changes. Hover changes are ignored when the highlighted bar is unchanged. The target is 60 FPS on standard displays and up to 120 FPS on supported hardware. These are not measured results. Profile builds and device measurements are required before release.

## Acceptance criteria

- No future bars appear in a replay viewport.
- Pan, zoom, reset and empty datasets do not cause out-of-range reads.
- SMA uses only current and previous bars.
- Chart type and indicator selection work at narrow widths.
- Chart and navigation remain usable with Reduced Motion enabled.
- All Dart analyzer and automated test checks pass on the selected Flutter stable release.

## Deferred

Real market feeds, exchange calendars, persistent user preferences, order execution, annotations, multi-chart layouts and release installers are outside this milestone.

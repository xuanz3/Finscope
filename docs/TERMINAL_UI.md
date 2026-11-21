# Finscope terminal workspace

Project owner: Xuanze Chen

Native Flutter layout inspired by professional charting terminals. The market workspace uses a linked instrument directory, chart, technical inspector, watchlist and screener. All figures are derived from the selected local daily datasets; the six bundled series remain explicitly synthetic. No fabricated live feed, news, volume, fundamentals or market capitalization is presented. RSI is a simple 14-bar calculation (not Wilder smoothing). Return windows use available bar history. Existing replay execution and SQLite persistence are unchanged. Historical replay chart receives revealed candles only.

Reference concepts: Koyfin (custom dashboards), TradingView (chart and screener), FINVIZ (performance heatmap) and the supplied Shakuro UI references. No reference artwork is embedded.

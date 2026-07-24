# MyLinedChart

**MyLinedChart is a technical-analysis charting app that turns your chart markup into structured data.** Draw trend lines, levels, zones, and notes on your own broker's data, then export it all as XLSX, CSV, or JSON, or let an AI agent read and draw on your chart. It is read-only: it analyzes and marks up the chart; you place the trade.

- **Website:** https://mylinedchart.com
- **Try the demo (no signup):** https://mylinedchart.com/demo
- **Pricing & free trial:** https://mylinedchart.com/pricing

---

## This repository

Public distribution point for the compiled **MyLinedChart** desktop installers — macOS `.dmg` and Windows `.exe`. The application source is private; this repo holds only the built installers plus a workflow that compiles the Windows `.exe` from the private source at build time (via a read-only token). No application source lives here.

**Download the app:** see [Releases](../../releases) — the website links directly to these assets.

### Install (beta — not yet notarized/signed)

- **macOS:** right-click the app → **Open** to bypass Gatekeeper once.
- **Windows:** on the SmartScreen prompt, choose **More info → Run anyway**.

Full signed and notarized distribution comes later.

---

## What MyLinedChart does

- **Draw, then export.** Every trend line, level, zone, and note exports as **XLSX, CSV, or JSON** with the numbers attached, so your analysis becomes reusable data instead of a screenshot.
- **Bring your own broker or data feed.** Connect **Interactive Brokers, Charles Schwab, Alpaca**, and market-data APIs (Alpha Vantage, Finnhub, Twelve Data, and more) locally with your own keys. Credentials stay on your device.
- **Let AI read and draw your chart.** A chart-context connector over the **Model Context Protocol (MCP)** gives **Claude Code, Codex, Claude Desktop**, or any MCP client your live candles, drawings, indicators, and trades, plus one confirmation-gated tool to draw back. It never places orders or touches your brokerage account.
- **Full charting.** 10 chart types, a library of built-in indicators (MA, EMA, BOLL, MACD, RSI, VWAP, and more), custom formula indicators described in plain language, split-screen panes, and large watchlists.

## A TradingView / TrendSpider alternative for data portability

Most charting platforms keep your drawings locked inside them. MyLinedChart exports your markup as structured data with the prices attached — so a drawing becomes a reusable **trading rule**, a journal entry, or AI-readable chart context. Compare the approaches: https://mylinedchart.com/resources/articles/tradingview-drawing-export-alternative

## The AI / MCP connector

- npm: https://www.npmjs.com/package/@mylinedchart/mcp-chart-context
- How it works: https://mylinedchart.com/mcp
- Listed on the official Model Context Protocol registry, and on mcp.so, Glama, and Smithery.

## More

- Articles & guides: https://mylinedchart.com/resources/articles
- AlternativeTo: https://alternativeto.net/software/mylinedchart/
- YouTube: https://youtube.com/@mylinedchart · X: https://x.com/ltlbirdtrading · Reddit: https://www.reddit.com/user/MyLinedChart/

Made by [Little Bird Trading](https://littlebirdtrading.com).

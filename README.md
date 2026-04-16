# Vaux

Vaux is a Turtle WoW focused fork of **aux**, the classic 1.12 auction house replacement addon.

This fork keeps the original aux core and UI style, but adds Turtle-specific quality-of-life features for faster posting, better bag management, craft material workflows, and a few extra utility commands.

> **Important:** the repository is called **Vaux**, but the addon currently still installs and runs under the original internal name **aux**.
>
> That means:
> - the addon folder / files are still `aux-addon`
> - the in-game slash command is still `/aux`
> - the `.toc` title is still `aux`

## Turtle WoW notes

- Accurate Turtle WoW auction duration mapping.
- Autocompletion for custom Turtle WoW items.
- Optional AH data sharing through LFT chat.
- Blizzard-like theme included by default, with a switch back to the modern theme.
- Vendor prices are collected and shown in tooltips / posting views where available.

## Main features

### Search tab

- Full AH scans for a query.
- Recent and favorite searches.
- Search result history with browser-like backtracking.
- Advanced filter syntax with logical operators.
- Autocompletion for filters and item names.
- Sorting by unit price and historical percentage.
- Quick buying without rescanning the whole query.
- Real Time mode for repeatedly checking live listings.
- Purchase summary tracking for buy sessions.

### Post tab

- Multi-stack posting workflow.
- Existing auction scan and undercut helpers.
- **Scan Bag** button to pre-scan auctionable bag items before posting.
- Per-item **Exclude** checkbox in the posting list.
- **Show exclude list** toggle to review hidden / excluded items.
- Excluded items are skipped by **Scan Bag** and hidden from the normal post list.
- **Exclude this item** toggle on the selected item panel.
- **Cancel Profit** column in the buyout comparison list.
- Unit vendor price display and warning when your configured price is below vendor value after AH fees.
- Per-item saved posting configuration, including stack size when enabled.

### Craft tab

- Separate **Craft** tab included in the addon.
- Reads profession recipe data after opening and closing a profession window.
- Recipe list with **Missing Mats**, **AH Price**, and **Profit** columns.
- **Show only craftable** toggle.
- Left-click a recipe to scan its materials.
- Right-click a recipe for a quick one-page-per-material scan.
- **Scan Missing Mats** button to bulk-scan required materials.
- **Buy Missing Materials** button to buy required materials from the results panel.
- Search cache and craft session helpers for repeated recipe/material workflows.

### History / tooltips

- Historical price collection from scans.
- Merchant buy / sell tooltip support.
- Disenchant value and distribution tooltip support.
- Optional WoWAuctions tooltip / link helpers.
- Efficient saved-data model for historical values.

## Installation

1. Download or clone the repository.
2. Place the addon folder in your WoW addons directory.
3. Because the addon is still internally named **aux**, the folder should currently remain:

```text
Interface/AddOns/aux-addon
```

4. Start the game and open the Auction House.
5. Use `/aux` to view available commands.

## Slash commands

### General

- `/aux`
  - Show current settings and available commands.
- `/aux scale <factor>`
  - Scale the addon UI.
- `/aux uc`
  - Toggle automatic undercutting.
- `/aux ignore owner`
  - Toggle waiting for owner names during scans.
- `/aux post bid`
  - Toggle bid price listing in the Post tab.
- `/aux post duration <6|24|72>`
  - Set default auction duration.
- `/aux post stack`
  - Toggle saving stack size per item.
- `/aux crafting cost`
  - Toggle crafting cost information.
- `/aux sharing`
  - Toggle Turtle WoW price-data sharing.
- `/aux theme [modern|blizzard]`
  - Switch the theme.
- `/aux show hidden`
  - Toggle showing excluded items in the Post tab.
- `/aux purchase summary`
  - Toggle the purchase summary window.
- `/aux clear item cache`
  - Clear cached item lookup data.
- `/aux populate wdb`
  - Populate item data from local cache where available.

### Tooltip

- `/aux tooltip value`
- `/aux tooltip daily`
- `/aux tooltip merchant buy`
- `/aux tooltip merchant sell`
- `/aux tooltip disenchant value`
- `/aux tooltip disenchant distribution`
- `/aux tooltip wowauctions`

### Profit / cache / external helpers

- `/aux profit`
  - Show all-time auto-buy profit stats.
- `/aux profit reset`
  - Reset all-time profit tracking.
- `/aux profit top [N]`
  - Print top profit items.
- `/aux cache`
  - Show search cache stats.
- `/aux cache clear`
  - Clear search cache and craft-related cached stats.
- `/aux cache debug`
  - Print cache debug information.
- `/aux cache limit [N]`
  - Set cache entry limit.
- `/aux wowauction <item name>`
- `/aux wa <item name>`
  - Print a WoWAuctions.net link for the item.

### Craft helpers

- `/aux craft`
- `/aux craft status`
  - Show collected craft-session materials.
- `/aux craft ready`
  - Show what can currently be crafted from tracked materials.
- `/aux craft missing`
  - Show missing materials.
- `/aux craft safe`
  - List safe materials with no leftover-risk logic.
- `/aux craft recipes`
  - Print tracked recipes.
- `/aux craft profitable`
  - Show profitable craft-to-vendor / market-based opportunities.
- `/aux craft maxprice [margin%]`
  - Show maximum material buy prices for target margins.
- `/aux craft reset`
  - Clear the tracked craft session.

## Quick usage

### Searching

- Type a query in the search box and press **Search**.
- Use **Tab** to accept autocompletion.
- Right-click an item link or bag item to start a search.
- Use saved searches for repeat scans.

### Posting faster with Scan Bag

1. Open **Post**.
2. Mark items you do not want included with the **Exclude** checkbox.
3. Use **Show exclude list** if you want to review excluded items.
4. Click **Scan Bag**.
5. Let Vaux pre-scan your sellable bag items before you start posting.
6. Post with the cached pricing view instead of waiting on every single item one by one.

### Craft workflow

1. Open and close a profession window once so recipe data can be cached.
2. Open the **Craft** tab.
3. Select a recipe to scan its materials.
4. Use **Scan Missing Mats** for batch material scans.
5. Use **Buy Missing Materials** to purchase what you still need.
6. Check `/aux craft ready` to see what your tracked materials can craft right now.

## Search filter notes

Aux queries are separated by semicolons and always contain exactly one Blizzard query per branch. The Blizzard query may be empty, which allows broader scans for history gathering. Real Time mode only supports empty Blizzard queries.

The first query part is treated as the Blizzard name search unless it matches a specific filter keyword. The `exact` modifier narrows matching toward the intended item and is usually recommended for item-specific searches.

Examples:

```text
felcloth/exact
recipe/usable/not/libram
armor/cloth/50/intellect/stamina
wrangler's wristbands/exact/or2/and2/+3 agility/+3 stamina/+5 stamina/price/1g
```

## Historical value model

Aux condenses scans from a day into a daily value and then uses a rolling set of recent daily values to estimate market value. This keeps memory usage manageable on the 1.12 client while still giving a useful median-style historical estimate for tooltips and pricing decisions.

## Credits

- Original addon: **aux**
- Turtle WoW specific work and fork packaging: **Vaux**
- Blizzard-like theme credit as noted in the original README: **Oldmana**

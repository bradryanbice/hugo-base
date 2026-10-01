// Checks the semantic color token contract of a built site.
//
// Usage:
//   node contrast.mjs --url http://127.0.0.1:8080/ [--color-scheme dark] [--report out.json]
//
// Two things axe cannot do for us:
//
//   1. It only sees pairs a page actually renders. This checks every semantic
//      pair in the contract, including ones no current page uses.
//   2. A token that fails to resolve (a site's theme.css leaving out an input
//      that a ramp multiplies, for example) silently inherits a color, so the
//      page can still pass axe while the token is broken. An unresolved token
//      is an error here.
//
// Chrome reports computed colors in oklch(), so the conversion to sRGB
// luminance is done explicitly rather than trusting a parser.

import { writeFileSync } from "node:fs";
import { chromium } from "playwright-core";

// The contract: [foreground, background, minimum ratio].
// 4.5 for text, 3 for UI components and focus indicators (WCAG 2.2 AA).
const PAIRS = [
  ["--color-text", "--color-surface", 4.5],
  ["--color-text", "--color-surface-raised", 4.5],
  ["--color-text", "--color-surface-sunken", 4.5],
  ["--color-text", "--color-surface-accent", 4.5],
  ["--color-text-muted", "--color-surface", 4.5],
  ["--color-text-muted", "--color-surface-raised", 4.5],
  ["--color-text-muted", "--color-surface-sunken", 4.5],
  ["--color-text-inverse", "--color-accent", 4.5],
  ["--color-link", "--color-surface", 4.5],
  ["--color-link", "--color-surface-raised", 4.5],
  ["--color-link-hover", "--color-surface", 4.5],
  ["--color-link-visited", "--color-surface", 4.5],
  ["--color-on-accent", "--color-accent", 4.5],
  ["--color-on-accent", "--color-accent-hover", 4.5],
  ["--color-on-accent", "--color-accent-active", 4.5],
  ["--color-text", "--color-accent-subtle", 4.5],
  ["--color-selection-text", "--color-selection", 4.5],
  ["--color-info-text", "--color-info-surface", 4.5],
  ["--color-success-text", "--color-success-surface", 4.5],
  ["--color-warning-text", "--color-warning-surface", 4.5],
  ["--color-danger-text", "--color-danger-surface", 4.5],
  // Syntax highlighting sits on the sunken surface.
  ["--color-accent", "--color-surface-sunken", 4.5],
  ["--color-success-text", "--color-surface-sunken", 4.5],
  ["--color-info-text", "--color-surface-sunken", 4.5],
  ["--color-danger-text", "--color-surface-sunken", 4.5],
  ["--color-focus-ring", "--color-surface", 3],
  ["--color-focus-ring", "--color-surface-raised", 3],
  ["--color-focus-ring", "--color-surface-sunken", 3],
  ["--color-border-strong", "--color-surface", 3],
  ["--color-info-border", "--color-info-surface", 3],
  ["--color-success-border", "--color-success-surface", 3],
  ["--color-warning-border", "--color-warning-surface", 3],
  ["--color-danger-border", "--color-danger-surface", 3],
];

function parseArgs(argv) {
  const args = { colorScheme: "light" };
  for (let i = 0; i < argv.length; i += 1) {
    const next = () => argv[(i += 1)];
    const arg = argv[i];
    if (arg === "--url") args.url = next();
    else if (arg === "--color-scheme") args.colorScheme = next();
    else if (arg === "--report") args.report = next();
    else throw new Error(`unknown argument: ${arg}`);
  }
  if (!args.url) throw new Error("--url is required");
  return args;
}

const args = parseArgs(process.argv.slice(2));

let browser;
try {
  browser = await chromium.launch({ channel: "chrome" });
} catch {
  browser = await chromium.launch();
}

let rows;
try {
  const context = await browser.newContext({ colorScheme: args.colorScheme });
  const page = await context.newPage();
  const response = await page.goto(args.url, { waitUntil: "load" });
  if (!response || !response.ok()) {
    throw new Error(`could not load ${args.url}`);
  }
  rows = await page.evaluate((pairs) => {
    // Two probes under parents with different inherited colors. A token that
    // resolves gives the same computed color in both. One that fails to
    // substitute falls back to the inherited color, so the two disagree. This
    // avoids a false positive when a token legitimately equals the text color.
    const makeProbe = (inherited) => {
      const parent = document.createElement("div");
      parent.style.color = inherited;
      const probe = document.createElement("span");
      parent.append(probe);
      document.body.append(parent);
      return probe;
    };
    const probeA = makeProbe("rgb(1, 2, 3)");
    const probeB = makeProbe("rgb(254, 253, 252)");

    const resolve = (token) => {
      probeA.style.color = `var(${token})`;
      probeB.style.color = `var(${token})`;
      const a = getComputedStyle(probeA).color;
      const b = getComputedStyle(probeB).color;
      return { value: a, resolved: a === b };
    };

    const luminance = (oklch) => {
      const [L, C, H] = oklch.match(/-?[\d.]+/g).map(Number);
      const hueRadians = (H * Math.PI) / 180;
      const a = C * Math.cos(hueRadians);
      const b = C * Math.sin(hueRadians);
      const l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3;
      const m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3;
      const s = (L - 0.0894841775 * a - 1.291485548 * b) ** 3;
      const [r, g, bl] = [
        4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s,
      ].map((channel) => Math.min(1, Math.max(0, channel)));
      return 0.2126 * r + 0.7152 * g + 0.0722 * bl;
    };

    return pairs.map(([foreground, background, minimum]) => {
      const fg = resolve(foreground);
      const bg = resolve(background);
      if (!fg.value.startsWith("oklch") || !bg.value.startsWith("oklch")) {
        return { foreground, background, minimum, error: `not an oklch value: ${fg.value} on ${bg.value}` };
      }
      if (!fg.resolved || !bg.resolved) {
        return { foreground, background, minimum, error: "token did not resolve" };
      }
      const a = luminance(fg.value);
      const b = luminance(bg.value);
      const ratio = (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
      return { foreground, background, minimum, ratio: Math.round(ratio * 100) / 100 };
    });
  }, PAIRS);
} finally {
  await browser.close();
}

let failures = 0;
for (const row of rows) {
  const pair = `${row.foreground.replace("--color-", "")} on ${row.background.replace("--color-", "")}`;
  if (row.error) {
    failures += 1;
    console.error(`FAIL ${pair}: ${row.error}`);
  } else if (row.ratio < row.minimum) {
    failures += 1;
    console.error(`FAIL ${pair}: ${row.ratio} to 1, needs ${row.minimum}`);
  } else {
    console.log(`ok   ${pair}: ${row.ratio} to 1 (needs ${row.minimum})`);
  }
}

if (args.report) {
  writeFileSync(args.report, JSON.stringify({ colorScheme: args.colorScheme, rows }, null, 2));
}

console.log(`\nChecked ${rows.length} semantic pair(s) in ${args.colorScheme} mode`);

if (failures > 0) {
  console.error(`::error::${failures} semantic color pair(s) fail in ${args.colorScheme} mode`);
  process.exit(1);
}

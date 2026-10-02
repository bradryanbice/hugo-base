// Runs axe against every page of a built site and fails on any violation.
//
// Usage:
//   node axe.mjs --base http://127.0.0.1:8080 --sitemap path/to/sitemap.xml
//   node axe.mjs --base http://127.0.0.1:8080 --url /only/this/page/
//   node axe.mjs ... --expect-violations     (self test: passes only if axe finds something)
//   node axe.mjs ... --report path/to/axe-report.json
//
// Page URLs come from the site's own sitemap, with the host swapped for the
// local server, so the gate covers whatever the site actually publishes.
// Chrome comes from the machine (Playwright channel "chrome"), so no browser
// download is needed in CI or locally.

import { readFileSync, writeFileSync } from "node:fs";
import { chromium } from "playwright-core";

const TAGS = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"];

function parseArgs(argv) {
  const args = { urls: [], expectViolations: false, colorScheme: "light" };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    const next = () => argv[(i += 1)];
    if (arg === "--base") args.base = next();
    else if (arg === "--sitemap") args.sitemap = next();
    else if (arg === "--url") args.urls.push(next());
    else if (arg === "--report") args.report = next();
    else if (arg === "--expect-violations") args.expectViolations = true;
    else if (arg === "--color-scheme") args.colorScheme = next();
    else throw new Error(`unknown argument: ${arg}`);
  }
  if (!args.base) throw new Error("--base is required");
  return args;
}

// Hugo writes absolute URLs built from baseURL. Keep the path, swap the origin.
function urlsFromSitemap(file, base) {
  const xml = readFileSync(file, "utf8");
  const locs = [...xml.matchAll(/<loc>([^<]+)<\/loc>/g)].map((m) => m[1].trim());
  return locs.map((loc) => new URL(new URL(loc).pathname, base).toString());
}

function formatViolation(violation) {
  const lines = [
    `  ${violation.id} (${violation.impact ?? "unknown impact"}): ${violation.help}`,
    `    ${violation.helpUrl}`,
  ];
  for (const node of violation.nodes.slice(0, 5)) {
    lines.push(`    at ${node.target.join(" ")}`);
    lines.push(`      ${node.html.replace(/\s+/g, " ").slice(0, 160)}`);
    // axe measures the colors it compared. Printing them turns "contrast
    // failed somewhere" into a diagnosis, which matters most when a failure
    // only reproduces on another machine.
    for (const check of node.any ?? []) {
      const data = check.data ?? {};
      if (data.contrastRatio !== undefined) {
        lines.push(
          `      measured ${data.fgColor} on ${data.bgColor} = ${data.contrastRatio}:1, needs ${data.expectedContrastRatio}`,
        );
      }
    }
  }
  if (violation.nodes.length > 5) {
    lines.push(`    and ${violation.nodes.length - 5} more`);
  }
  return lines.join("\n");
}

// Wait until every stylesheet the page declares has actually been applied.
//
// Without this the check is racy: axe (and the contrast probe) can sample a
// page whose author CSS has not landed yet, and then measure the browser's
// default colors. That produced a dark mode contrast failure in CI that did
// not reproduce locally and passed on the next run, which is the worst kind of
// gate failure: it teaches people to re-run rather than to look.
//
// A page with no stylesheet links (the self test fixture) passes immediately.
async function waitForStylesheets(page, url) {
  try {
    await page.waitForFunction(
      () => [...document.querySelectorAll('link[rel="stylesheet"]')].every((link) => link.sheet),
      undefined,
      { timeout: 15000 },
    );
  } catch {
    throw new Error(
      `stylesheets never applied on ${url}. The page declares a stylesheet that did not load, ` +
        "so any color result would be the browser's defaults rather than the site's.",
    );
  }
}

async function launch() {
  // Use the Chrome installed on the machine. Fall back to any Chromium
  // Playwright has, so a contributor without Chrome still gets a clear path.
  try {
    return await chromium.launch({ channel: "chrome" });
  } catch (error) {
    try {
      return await chromium.launch();
    } catch {
      throw new Error(
        `could not start Chrome. Install Google Chrome, or run "npx playwright install chromium".\nOriginal error: ${error.message}`,
      );
    }
  }
}

const args = parseArgs(process.argv.slice(2));
const urls = args.sitemap
  ? [...urlsFromSitemap(args.sitemap, args.base), ...args.urls.map((u) => new URL(u, args.base).toString())]
  : args.urls.map((u) => new URL(u, args.base).toString());

if (urls.length === 0) throw new Error("no URLs to test");

const axeModule = await import("@axe-core/playwright");
const AxeBuilder = axeModule.default ?? axeModule.AxeBuilder;

const browser = await launch();
// Which browser ran matters: a contrast failure that appears only in CI is
// usually a browser difference, and this is the first thing to compare.
console.log(`browser: ${browser.version()}`);
const results = [];
let violationCount = 0;

try {
  // Emulate the OS light or dark preference, so both sets of semantic tokens
  // get their contrast checked rather than only the default scheme.
  const context = await browser.newContext({ colorScheme: args.colorScheme });
  for (const url of urls) {
    const page = await context.newPage();
    const response = await page.goto(url, { waitUntil: "load" });
    if (response && response.ok()) {
      await waitForStylesheets(page, url);
    }
    if (!response || !response.ok()) {
      console.error(`FAIL ${url}: HTTP ${response ? response.status() : "no response"}`);
      violationCount += 1;
      await page.close();
      continue;
    }
    const result = await new AxeBuilder({ page }).withTags(TAGS).analyze();
    results.push({ url, violations: result.violations });
    if (result.violations.length === 0) {
      console.log(`ok   ${url}`);
    } else {
      violationCount += result.violations.length;
      console.error(`FAIL ${url}`);
      for (const violation of result.violations) console.error(formatViolation(violation));
    }
    await page.close();
  }
} finally {
  await browser.close();
}

if (args.report) {
  writeFileSync(
    args.report,
    JSON.stringify({ tags: TAGS, colorScheme: args.colorScheme, results }, null, 2),
  );
}

console.log(
  `\naxe checked ${urls.length} page(s) in ${args.colorScheme} mode against ${TAGS.join(", ")}`,
);

if (args.expectViolations) {
  if (violationCount === 0) {
    console.error("::error::self test found no violations, so the gate is not working");
    process.exit(1);
  }
  console.log(`Self test passed: axe caught ${violationCount} violation(s) as expected.`);
  process.exit(0);
}

if (violationCount > 0) {
  console.error(`::error::axe found ${violationCount} violation(s)`);
  process.exit(1);
}

console.log("No accessibility violations.");

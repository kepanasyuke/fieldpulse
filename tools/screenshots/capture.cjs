const { spawn } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");
const { chromium } = require("playwright");

const ROOT = path.resolve(__dirname, "../..");
const WEB_DIR = path.join(ROOT, "apps/web_console/build/web");
const OUT_DIR = path.join(ROOT, "docs/screenshots");
const PORT = 8123;

async function serve() {
  const server = spawn("python3", ["-m", "http.server", String(PORT)], {
    cwd: WEB_DIR,
    stdio: "ignore",
  });
  await new Promise((resolve) => setTimeout(resolve, 1500));

  return server;
}

async function capture(browser, name, viewport) {
  const context = await browser.newContext({ viewport, deviceScaleFactor: 1 });
  const page = await context.newPage();
  await page.goto(`http://127.0.0.1:${PORT}`, { waitUntil: "networkidle" });
  await page.waitForTimeout(8000);
  const target = path.join(OUT_DIR, name);
  await page.screenshot({ path: target, fullPage: false });
  await context.close();

  return target;
}

async function main() {
  fs.mkdirSync(OUT_DIR, { recursive: true });
  const server = await serve();
  const browser = await chromium.launch();

  const shots = [
    await capture(browser, "console-desktop.png", { width: 1440, height: 900 }),
    await capture(browser, "console-tablet.png", { width: 820, height: 1180 }),
  ];

  await browser.close();
  server.kill();
  shots.forEach((file) => console.log(`wrote ${file}`));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

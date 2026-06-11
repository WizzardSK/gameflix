// Verifies intent.js URL/intent building against the real cores.json, no device.
//   node test_intent.js
const fs = require("fs");
const path = require("path");
const I = require("./intent.js");

const cores = JSON.parse(fs.readFileSync(path.join(__dirname, "cores.json"), "utf8"));
const FALLBACK = "https://wizzardsk.github.io/atari2600.html";

const cases = [
    "play:///atari2600/ROMS/Assault (Hack) (32 in 1) (Bit Corporation) (R320).bin",
    "play:///nes/NoIntro/Super Mario Bros. (World).nes",
    "play:///atari2600/MAME/et.zip",            // MAME -> must be rejected
];

let fail = 0;
for (const href of cases) {
    const r = I.resolve(cores, href, FALLBACK);
    console.log("HREF :", href);
    if (r.error) { console.log("  REJECTED:", r.error.replace(/\n/g, " ")); console.log(); continue; }
    console.log("  fname :", r.fname);
    console.log("  romUrl:", r.romUrl);
    console.log("  ROM   :", r.romPath);
    console.log("  core  :", r.corePath);
    console.log("  intent:", r.intent);
    console.log();

    // assertions
    if (/ /.test(r.intent)) { console.error("  !! intent contains a raw space"); fail++; }
    if (!r.intent.startsWith("intent://")) { console.error("  !! bad scheme"); fail++; }
    if (!r.intent.includes("component=" + I.RETRO_PKG + "/com.retroarch.browser")) { console.error("  !! component mangled"); fail++; }
    if (!r.corePath.startsWith("/data/data/" + I.RETRO_PKG + "/cores/")) { console.error("  !! core dir wrong"); fail++; }
    // ROM/LIBRETRO must round-trip via decodeURIComponent (what Android does)
    const rom = decodeURIComponent(r.intent.match(/S\.ROM=([^;]*)/)[1]);
    const lib = decodeURIComponent(r.intent.match(/S\.LIBRETRO=([^;]*)/)[1]);
    if (rom !== r.romPath) { console.error("  !! ROM round-trip:", rom); fail++; }
    if (lib !== r.corePath) { console.error("  !! LIBRETRO round-trip:", lib); fail++; }
}

// the atari URL must equal the exact one we already proved downloads (4096 B earlier)
const atari = I.resolve(cores, cases[0], FALLBACK).romUrl;
const expected = "https://archive.org/download/atari-2600-vcs-roms/ROMS/Assault%20%28Hack%29%20%2832%20in%201%29%20%28Bit%20Corporation%29%20%28R320%29.bin";
if (atari !== expected) { console.error("!! atari romUrl mismatch\n  got " + atari + "\n  exp " + expected); fail++; }
else console.log("OK: atari romUrl matches the verified-downloadable URL");

console.log(fail ? `\nFAILED (${fail})` : "\nALL CHECKS PASSED");
process.exit(fail ? 1 : 0);

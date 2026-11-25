// Generates Thai voice-over for every cutscene line (lines.json) with ElevenLabs.
// Usage: npm run generate        (skips lines that already have a file)
// Key: read by the SDK from ELEVENLABS_API_KEY (.env.local via --env-file).
import { ElevenLabsClient } from "@elevenlabs/elevenlabs-js";
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "fs";
import { Readable } from "stream";
import { finished } from "stream/promises";
import { createWriteStream } from "fs";

const OUT = new URL("../../godot/assets/voice/", import.meta.url);
mkdirSync(OUT, { recursive: true });

// premade voices (any plan can use them via the API)
const CAST = {
  "": { id: "JBFqnCBsd6RMkjVDRZzb", stability: 0.6 },        // George  - narration
  oli: { id: "TX3LPaxmHKxFdv7VOQHJ", stability: 0.4 },       // Liam    - upbeat boy
  haru: { id: "EXAVITQu4vr4xnSDxMaL", stability: 0.8 },      // Sarah   - calm, flat
  ren: { id: "bIHbv24MWmeRgasZH58o", stability: 0.65 },      // Will    - quiet
  mio: { id: "IKne3meq5aSn9XLyUdCD", stability: 0.4 },       // Charlie - loud, energetic
  setsu: { id: "SOYHLrjzK2X1ezoPC6cr", stability: 0.55 },    // Harry   - rough
  leon: { id: "N2lVS1w4EtoT3dr4eOWO", stability: 0.5 },      // Callum  - husky, arrogant
  lumi: { id: "cgSgspJ2msm6clMCkdW9", stability: 0.35 },     // Jessica - bright idol
  null: { id: "cjVigY5qzO86Huf0OWal", stability: 0.75 },     // Eric    - soft
  kuroba: { id: "onwK4e9ZLuTAKqWW03F9", stability: 0.7 },    // Daniel  - formal
  piang: { id: "pFZP5JQG7iQjIQuC4Bku", stability: 0.6 },     // Lily    - warm elder
  clover: { id: "FGY2WhTYpPnrIDTdsKH5", stability: 0.35 },   // Laura   - quirky spirit
  enji: { id: "pNInz6obpgDQGcFmaJgB", stability: 0.45 },     // Adam    - bully
  teacher: { id: "pqHfZKP75CvOlQylNhV4", stability: 0.7 },   // Bill
  mom: { id: "hpp4J3VqNfWAUOO0d1Us", stability: 0.6 },       // Bella
  kai: { id: "CwhRBWXzGAHq8TQ4Fs17", stability: 0.5 },       // Roger
  thug: { id: "nPczCjzI2devNBz1zQrb", stability: 0.45 },     // Brian
};

const client = new ElevenLabsClient();
const lines = JSON.parse(readFileSync(new URL("lines.json", import.meta.url), "utf8"));
const manifest = {};
let made = 0, skipped = 0, failed = 0, chars = 0;

async function one(l) {
  const who = l.who.replace(/\*$/, "");
  const thought = l.who.endsWith("*");
  const cast = CAST[who] ?? CAST[""];
  const file = new URL(`${l.key}.mp3`, OUT);
  manifest[l.key] = { who: l.who, text: l.text };
  if (existsSync(file)) { skipped++; return; }
  const text = (thought ? "[whispers] " : "") + l.speak;
  try {
    const audio = await client.textToSpeech.convert(cast.id, {
      text, modelId: "eleven_v4", languageCode: "th", outputFormat: "mp3_44100_128",
      voiceSettings: { stability: cast.stability, similarityBoost: 0.75 },
    });
    await finished(Readable.fromWeb(audio).pipe(createWriteStream(file)));
    made++; chars += l.speak.length;
    process.stdout.write(`ok ${l.key} ${who || "narr"}: ${l.speak.slice(0, 30)}\n`);
  } catch (e) {
    failed++;
    console.error(`FAIL ${l.key} ${who}: ${e.statusCode ?? ""} ${e.message?.slice(0, 160)}`);
  }
}

// one request at a time with a short pause: free-tier accounts get flagged for bursts
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
for (const l of lines) {
  await one(l);
  if (failed >= 3) { console.error("stopping after 3 failures"); break; }
  await sleep(1200);
}
writeFileSync(new URL("manifest.json", OUT), JSON.stringify(manifest, null, 1));
console.log(`done: ${made} new, ${skipped} already there, ${failed} failed, ~${chars} characters`);

// Lists the voices this ElevenLabs account can use (pre-made + own), to pick per character.
import { ElevenLabsClient } from "@elevenlabs/elevenlabs-js";
const client = new ElevenLabsClient();
const res = await client.voices.getAll();
for (const v of res.voices) {
  const l = v.labels || {};
  console.log([v.voiceId, v.name, v.category, l.gender, l.age, l.accent, l.description || l.descriptive, l.use_case || l.use_cases].filter(Boolean).join(" | "));
}

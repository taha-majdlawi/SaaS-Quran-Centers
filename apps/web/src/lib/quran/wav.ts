// A browser recording (webm / mp4, whatever MediaRecorder makes) as a 16 kHz
// mono WAV: small (~2 MB a minute), and what the speech model expects - the app
// records the same format directly.

export const WAV_RATE = 16000;

export async function toWav16k(blob: Blob): Promise<{ wav: Blob; seconds: number }> {
  const Ctx = window.AudioContext ?? (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
  const ctx = new Ctx();
  let decoded: AudioBuffer;
  try {
    decoded = await ctx.decodeAudioData(await blob.arrayBuffer());
  } finally {
    void ctx.close();
  }
  const frames = Math.max(1, Math.ceil(decoded.duration * WAV_RATE));
  const offline = new OfflineAudioContext(1, frames, WAV_RATE);
  const src = offline.createBufferSource();
  src.buffer = decoded; // several channels are mixed down to the one
  src.connect(offline.destination);
  src.start();
  const pcm = (await offline.startRendering()).getChannelData(0);

  const out = new DataView(new ArrayBuffer(44 + pcm.length * 2));
  const text = (at: number, s: string) => [...s].forEach((ch, i) => out.setUint8(at + i, ch.charCodeAt(0)));
  text(0, 'RIFF');
  out.setUint32(4, 36 + pcm.length * 2, true);
  text(8, 'WAVE');
  text(12, 'fmt ');
  out.setUint32(16, 16, true);
  out.setUint16(20, 1, true); // PCM
  out.setUint16(22, 1, true); // mono
  out.setUint32(24, WAV_RATE, true);
  out.setUint32(28, WAV_RATE * 2, true);
  out.setUint16(32, 2, true);
  out.setUint16(34, 16, true);
  text(36, 'data');
  out.setUint32(40, pcm.length * 2, true);
  for (let i = 0; i < pcm.length; i++) {
    const v = Math.max(-1, Math.min(1, pcm[i]));
    out.setInt16(44 + i * 2, v < 0 ? v * 0x8000 : v * 0x7fff, true);
  }
  return { wav: new Blob([out.buffer], { type: 'audio/wav' }), seconds: Math.round(decoded.duration) };
}

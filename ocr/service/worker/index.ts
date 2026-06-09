// Rate-limiting Cloudflare Worker in front of the FreeType glyph-matcher
// container (see ../app.py). Per-IP rate limit + size cap + CORS, then forward
// the PDF to a container instance. Deploy needs the Workers Paid plan
// (Containers requirement). See ../README.md.

import { Container } from "@cloudflare/containers";

export class Decoder extends Container {
  defaultPort = 8080;
  requiredPorts = [8080];
  sleepAfter = "10m"; // scale to zero after 10 min idle
}

export interface Env {
  // Container binding (Durable Object namespace augmented by @cloudflare/containers)
  DECODER: { getRandom(): { startAndWaitForPorts(): Promise<void>; fetch(req: Request): Promise<Response> } };
  // Native Rate Limiting binding
  RATE: { limit(opts: { key: string }): Promise<{ success: boolean }> };
}

const ALLOW_ORIGIN = "https://abdealikhurrum.github.io";
const MAX_BYTES = 25 * 1024 * 1024;

function withCors(resp: Response): Response {
  const h = new Headers(resp.headers);
  h.set("Access-Control-Allow-Origin", ALLOW_ORIGIN);
  h.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  h.set("Access-Control-Allow-Headers", "Content-Type");
  return new Response(resp.body, { status: resp.status, statusText: resp.statusText, headers: h });
}
function json(obj: unknown, status = 200): Response {
  return withCors(new Response(JSON.stringify(obj), {
    status, headers: { "Content-Type": "application/json; charset=utf-8" },
  }));
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") return withCors(new Response(null, { status: 204 }));
    const url = new URL(request.url);

    if (url.pathname === "/health") {
      const c = env.DECODER.getRandom();
      await c.startAndWaitForPorts();
      return withCors(await c.fetch(new Request("http://container/health")));
    }

    if (url.pathname !== "/decode" || request.method !== "POST") {
      return json({ error: "Not found. POST a PDF to /decode." }, 404);
    }

    // Per-IP rate limit (configured in wrangler.jsonc: 20 / 60s).
    const ip = request.headers.get("CF-Connecting-IP") || "anon";
    const { success } = await env.RATE.limit({ key: ip });
    if (!success) {
      return json({ error: "Rate limit reached — please wait a minute and try again." }, 429);
    }

    const len = Number(request.headers.get("Content-Length") || "0");
    if (len > MAX_BYTES) return json({ error: "PDF too large (max 25 MB)." }, 413);

    const c = env.DECODER.getRandom();
    await c.startAndWaitForPorts();
    const upstream = await c.fetch(new Request("http://container/decode", {
      method: "POST",
      body: request.body,
      headers: { "Content-Length": String(len), "Content-Type": "application/pdf" },
    }));
    return withCors(new Response(upstream.body, upstream));
  },
};

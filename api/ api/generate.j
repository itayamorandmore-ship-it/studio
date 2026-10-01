export const config = { maxDuration: 60 };

// Vercel serverless function: keeps the API key on the server, never in the browser.
export default async function handler(req, res) {
  if (req.method !== "POST") return res.status(405).json({ error: "POST only" });
  const key = process.env.ANTHROPIC_API_KEY;
  if (!key) return res.status(500).json({ error: "Missing ANTHROPIC_API_KEY" });

  const { system, user } = req.body || {};
  if (typeof user !== "string" || !user || user.length > 6000)
    return res.status(400).json({ error: "Bad request" });

  try {
    const r = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": key,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: process.env.CLAUDE_MODEL || "claude-sonnet-5-5",
        max_tokens: 1800,
        system: typeof system === "string" ? system.slice(0, 2000) : undefined,
        messages: [{ role: "user", content: user }],
      }),
    });
    const data = await r.json();
    if (!r.ok) return res.status(r.status).json({ error: data?.error?.message || "Upstream error" });
    const text = (data.content || []).map(c => (c.type === "text" ? c.text : "")).join("");
    return res.status(200).json({ text });
  } catch (e) {
    return res.status(500).json({ error: "Server error" });
  }
}

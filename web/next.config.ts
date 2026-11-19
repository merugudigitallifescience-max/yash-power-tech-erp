import type { NextConfig } from "next";

const API = process.env.API_URL || "http://localhost:8000";

const nextConfig: NextConfig = {
  // The browser only ever talks to this origin; /api is proxied to FastAPI so the
  // httpOnly refresh cookie stays first-party.
  async rewrites() {
    return [{ source: "/api/:path*", destination: `${API}/api/:path*` }];
  },
};

export default nextConfig;

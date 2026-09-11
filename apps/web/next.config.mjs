import { initOpenNextCloudflareForDev } from '@opennextjs/cloudflare';

/** @type {import('next').NextConfig} */
const nextConfig = {
  typedRoutes: true,
};

export default nextConfig;

initOpenNextCloudflareForDev();

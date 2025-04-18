# use the official Bun image
# see all versions at https://hub.docker.com/r/oven/bun/tags
FROM oven/bun:alpine AS base
WORKDIR /usr/src/app

# install dependencies into temp directory
# this will cache them and speed up future builds
FROM base AS install
RUN mkdir -p /temp/dev
COPY package.json bun.lock /temp/dev/
RUN cd /temp/dev && bun install --frozen-lockfile



FROM base AS prerelease
COPY --from=install /temp/dev/node_modules node_modules
COPY . .

ENV NODE_ENV=production

RUN bun run build

# Delete source maps
RUN find .output -type f -name '*.js.map' -delete && \
    find .output -type f -name '*.css.map' -delete

# Delete source map references
RUN find .output -type f -name '*.js' -exec sed -i -E 's/sourceMappingURL=[^ ]*\.js\.map//g' {} + && \
    find .output -type f -name '*.css' -exec sed -i -E 's/sourceMappingURL=[^ ]*\.css\.map//g' {} +

# # copy production dependencies and source code into final image
FROM base AS release
COPY --from=prerelease /usr/src/app/.output .


WORKDIR /usr/src/app

USER bun
EXPOSE 3000
ENTRYPOINT [ "bun", "run", "/server/index.mjs" ]

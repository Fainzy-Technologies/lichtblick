# Build stage
FROM node:20 AS build
WORKDIR /src
COPY . ./

RUN corepack enable

# Configure Yarn 3 to use node_modules instead of PnP
RUN yarn config set nodeLinker node-modules

# Ensure devDependencies are installed for the build
ENV NODE_ENV=development
RUN yarn install --immutable

# Add a fallback for Webpack TypeScript configs
RUN yarn add -D ts-node typescript --mode=update-lockfile

RUN yarn run web:build:prod

# Release stage
FROM caddy:2.5.2-alpine
WORKDIR /src
COPY --from=build /src/web/.webpack ./

EXPOSE 8080

# COPY <<EOF /entrypoint.sh
# # Optionally override the default layout with one provided via bind mount
# mkdir -p /lichtblick
# touch /lichtblick/default-layout.json
# index_html=\$(cat index.html)
# replace_pattern='/*LICHTBLICK_SUITE_DEFAULT_LAYOUT_PLACEHOLDER*/'
# replace_value=\$(cat /lichtblick/default-layout.json)
# echo "\${index_html/"\$replace_pattern"/\$replace_value}" > index.html

# # Continue executing the CMD
# exec "\$@"
# EOF

# Optionally override the default layout with one provided via bind mount
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
CMD ["caddy", "file-server", "--listen", ":8080"]

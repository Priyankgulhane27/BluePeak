FROM node:20-alpine

WORKDIR /usr/src/app

COPY package.json ./
RUN npm install --omit=dev

# Download AWS's official public RDS/Aurora CA bundle so the app can verify
# the database's TLS certificate properly instead of disabling verification.
# Source: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html
RUN wget -O /usr/src/app/rds-ca-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

COPY server.js ./
COPY public ./public

ENV PORT=3000
EXPOSE 3000

# Basic container-level healthcheck; ALB target group does the real health check
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
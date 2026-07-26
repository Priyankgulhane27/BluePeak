/**
 * BluePeak Counter App - Application Tier
 *
 * Serves the static presentation tier (public/) and exposes a small REST API
 * that persists the counter value in the data tier (Aurora MySQL).
 *
 * DB credentials are pulled from AWS Secrets Manager at startup (never from
 * plaintext env vars in production), falling back to env vars for local dev.
 */
const express = require("express");
const mysql = require("mysql2/promise");
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");

const app = express();
const PORT = process.env.PORT || 3000;
const AWS_REGION = process.env.AWS_REGION || "us-east-1";
const DB_SECRET_ARN = process.env.DB_SECRET_ARN;

let pool;

async function loadDbCredentials() {
  if (DB_SECRET_ARN) {
    const client = new SecretsManagerClient({ region: AWS_REGION });
    const resp = await client.send(new GetSecretValueCommand({ SecretId: DB_SECRET_ARN }));
    const secret = JSON.parse(resp.SecretString);
    return {
      host: secret.host || process.env.DB_HOST,
      user: secret.username,
      password: secret.password,
      database: secret.dbname || "bluepeak",
    };
  }
  // Local/dev fallback
  return {
    host: process.env.DB_HOST || "localhost",
    user: process.env.DB_USER || "root",
    password: process.env.DB_PASSWORD || "",
    database: process.env.DB_NAME || "bluepeak",
  };
}

async function initDb() {
  const creds = await loadDbCredentials();
  pool = mysql.createPool({
    host: creds.host,
    user: creds.user,
    password: creds.password,
    database: creds.database,
    waitForConnections: true,
    connectionLimit: 5,
    ssl: { rejectUnauthorized: true },
  });

  await pool.query(`
    CREATE TABLE IF NOT EXISTS counter (
      id INT PRIMARY KEY,
      value INT NOT NULL DEFAULT 0
    )
  `);
  await pool.query(`INSERT IGNORE INTO counter (id, value) VALUES (1, 0)`);
}

app.use(express.json());
app.use(express.static("public"));

// Health check for ALB target group
app.get("/health", (req, res) => res.status(200).send("ok"));

app.get("/api/count", async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT value FROM counter WHERE id = 1");
    res.json({ value: rows[0].value });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "db_error" });
  }
});

async function adjust(delta, res) {
  try {
    await pool.query("UPDATE counter SET value = value + ? WHERE id = 1", [delta]);
    const [rows] = await pool.query("SELECT value FROM counter WHERE id = 1");
    res.json({ value: rows[0].value });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "db_error" });
  }
}

app.post("/api/increment", (req, res) => adjust(1, res));
app.post("/api/decrement", (req, res) => adjust(-1, res));

initDb()
  .then(() => {
    app.listen(PORT, () => console.log(`BluePeak counter app listening on ${PORT}`));
  })
  .catch((err) => {
    console.error("Failed to initialize DB, starting anyway (health check only):", err);
    app.listen(PORT, () => console.log(`BluePeak counter app listening on ${PORT} (DB unavailable)`));
  });

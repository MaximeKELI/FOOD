const http = require("http");
const express = require("express");
const cors = require("cors");
const { Server } = require("socket.io");
const { createAdapter } = require("@socket.io/redis-adapter");
const { createClient } = require("redis");
const jwt = require("jsonwebtoken");

const PORT = process.env.PORT || 3001;
const REDIS_URL = process.env.REDIS_URL || "redis://127.0.0.1:6379/1";
const JWT_SECRET = process.env.JWT_SECRET || "change-me";
const INTERNAL_SECRET = process.env.SOCKET_INTERNAL_SECRET || "socket-internal-dev";
const CORS_ORIGIN = process.env.CORS_ORIGIN || "*";

const app = express();
app.use(cors({ origin: CORS_ORIGIN === "*" ? true : CORS_ORIGIN.split(",") }));
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: CORS_ORIGIN === "*" ? "*" : CORS_ORIGIN.split(",") },
  path: "/socket.io/",
});

async function setupRedis() {
  const pub = createClient({ url: REDIS_URL });
  const sub = pub.duplicate();
  await Promise.all([pub.connect(), sub.connect()]);
  io.adapter(createAdapter(pub, sub));
}

io.use((socket, next) => {
  const token =
    socket.handshake.auth?.token ||
    socket.handshake.headers?.authorization?.replace(/^Bearer\s+/i, "");
  if (!token) {
    return next(new Error("Token manquant"));
  }
  try {
    const payload = jwt.verify(token, JWT_SECRET, { algorithms: ["HS256"] });
    socket.userId = payload.user_id || payload.sub || payload.id;
    return next();
  } catch (err) {
    return next(new Error("Token invalide"));
  }
});

io.on("connection", (socket) => {
  const uid = socket.userId;
  if (uid) {
    socket.join(`user:${uid}`);
  }

  socket.on("join", (rooms) => {
    const list = Array.isArray(rooms) ? rooms : [rooms];
    for (const room of list) {
      if (typeof room === "string" && room.length < 80) {
        socket.join(room);
      }
    }
  });

  socket.on("chat:message", (payload) => {
    const conversationId = payload?.conversation_id;
    if (!conversationId) return;
    io.to(`conversation:${conversationId}`).emit("chat:message", {
      ...payload,
      sender_id: uid,
    });
  });

  socket.on("delivery:location", (payload) => {
    const deliveryId = payload?.delivery_id;
    if (!deliveryId) return;
    io.to(`delivery:${deliveryId}`).emit("delivery:location", payload);
  });

  socket.on("chat:typing", (payload) => {
    const conversationId = payload?.conversation_id;
    if (!conversationId) return;
    socket.to(`conversation:${conversationId}`).emit("chat:typing", {
      conversation_id: conversationId,
      user_id: uid,
      is_typing: Boolean(payload?.is_typing),
    });
  });

  socket.on("chat:read", (payload) => {
    const conversationId = payload?.conversation_id;
    if (!conversationId) return;
    io.to(`conversation:${conversationId}`).emit("chat:read", {
      conversation_id: conversationId,
      message_id: payload?.message_id || null,
      reader_id: uid,
      read_at: new Date().toISOString(),
    });
  });
});

app.post("/internal/emit", (req, res) => {
  const secret = req.headers["x-internal-secret"];
  if (secret !== INTERNAL_SECRET) {
    return res.status(403).json({ detail: "Forbidden" });
  }
  const { event, room, data } = req.body || {};
  if (!event || !room) {
    return res.status(400).json({ detail: "event and room required" });
  }
  io.to(room).emit(event, data || {});
  return res.json({ ok: true });
});

app.get("/health", (_req, res) => res.json({ status: "ok" }));

setupRedis()
  .then(() => {
    server.listen(PORT, () => {
      console.log(`Socket gateway listening on :${PORT}`);
    });
  })
  .catch((err) => {
    console.error("Redis setup failed", err);
    process.exit(1);
  });

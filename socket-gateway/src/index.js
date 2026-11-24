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
const AUTHORIZE_URL =
  process.env.SOCKET_AUTHORIZE_URL ||
  "http://django:8000/api/internal/socket-authorize/";

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

async function authorizeRooms(userId, rooms) {
  if (!rooms.length) return [];
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 4000);
  try {
    const res = await fetch(AUTHORIZE_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Internal-Secret": INTERNAL_SECRET,
      },
      body: JSON.stringify({ user_id: userId, rooms }),
      signal: controller.signal,
    });
    if (!res.ok) return [];
    const data = await res.json();
    return Array.isArray(data.allowed) ? data.allowed : [];
  } catch (err) {
    console.error("Room authorize failed", err.message || err);
    return [];
  } finally {
    clearTimeout(timer);
  }
}

function inConversationRoom(socket, conversationId) {
  return socket.rooms.has(`conversation:${conversationId}`);
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
    socket.userId = String(payload.user_id || payload.sub || payload.id || "");
    if (!socket.userId) {
      return next(new Error("Token sans user_id"));
    }
    return next();
  } catch (err) {
    return next(new Error("Token invalide"));
  }
});

io.on("connection", (socket) => {
  const uid = socket.userId;
  socket.join(`user:${uid}`);

  socket.on("join", async (rooms) => {
    const list = (Array.isArray(rooms) ? rooms : [rooms]).filter(
      (r) => typeof r === "string" && r.length > 0 && r.length < 80
    );
    if (!list.length) return;
    const allowed = await authorizeRooms(uid, list);
    for (const room of allowed) {
      socket.join(room);
    }
  });

  socket.on("leave", (rooms) => {
    const list = Array.isArray(rooms) ? rooms : [rooms];
    for (const room of list) {
      if (typeof room === "string") socket.leave(room);
    }
  });

  // Messages and GPS are server-emitted only (via /internal/emit).
  // Typing/read are allowed only if the socket already joined the conversation.

  socket.on("chat:typing", (payload) => {
    const conversationId = payload?.conversation_id;
    if (!conversationId || !inConversationRoom(socket, conversationId)) return;
    socket.to(`conversation:${conversationId}`).emit("chat:typing", {
      conversation_id: conversationId,
      user_id: uid,
      is_typing: Boolean(payload?.is_typing),
    });
  });

  socket.on("chat:read", (payload) => {
    const conversationId = payload?.conversation_id;
    if (!conversationId || !inConversationRoom(socket, conversationId)) return;
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
  if (typeof event !== "string" || typeof room !== "string") {
    return res.status(400).json({ detail: "invalid event/room" });
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

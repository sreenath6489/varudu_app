const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const http = require('http');
const { Server } = require('socket.io');
const crypto = require('crypto');
require('dotenv').config();

const authController = require('./controllers/auth');
const profileController = require('./controllers/profile');
const interestController = require('./controllers/interest');
const rosesController = require('./controllers/roses');
const astroController = require('./controllers/astro');
const chatController = require('./controllers/chat');
const authMiddleware = require('./middleware/auth');
const prisma = require('./db');

const app = express();
const PORT = process.env.PORT || 3001;

// Enable CORS for frontend connections (from emulator, local dev)
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Serve uploaded images statically
app.use('/uploads', express.static(uploadsDir));

// Multer storage configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    cb(null, 'photo-' + uniqueSuffix + ext);
  }
});

const upload = multer({ storage });

// Routes
// 1. Auth routes
app.post('/api/auth/send-otp', authController.sendOtp);
app.post('/api/auth/verify-otp', authController.verifyOtp);

// 2. Profile routes (Authenticated)
app.post('/api/profile', authMiddleware, upload.array('photos', 5), profileController.createProfile);
app.post('/api/profile/update', authMiddleware, upload.array('photos', 5), profileController.createProfile); // alias
app.get('/api/profile', authMiddleware, profileController.getProfile);
app.post('/api/profile/verify-face', authMiddleware, upload.single('selfie'), profileController.verifyFace);
app.post('/api/profile/verify-aadhaar', authMiddleware, profileController.verifyAadhaar);
app.post('/api/profile/settings', authMiddleware, profileController.updateSettings);

// 3. Search route (Authenticated)
app.get('/api/search', authMiddleware, profileController.searchProfiles);

// 4. Interest routes (Authenticated)
app.post('/api/interests', authMiddleware, interestController.expressInterest);
app.get('/api/interests', authMiddleware, interestController.getInterests);
app.post('/api/interests/swipe', authMiddleware, interestController.swipe);
app.get('/api/interests/requests', authMiddleware, interestController.getRequests);
app.post('/api/interests/accept', authMiddleware, interestController.acceptInterest);
app.post('/api/interests/decline', authMiddleware, interestController.declineInterest);
app.post('/api/interests/withdraw', authMiddleware, interestController.withdrawInterest);

// 5. Roses / Boutique routes (Authenticated)
app.get('/api/roses/balance', authMiddleware, rosesController.getBalance);
app.post('/api/roses/claim-free', authMiddleware, rosesController.claimFree);
app.post('/api/roses/watch-ad', authMiddleware, rosesController.watchAd);
app.post('/api/roses/buy-order', authMiddleware, rosesController.buyOrder);
app.post('/api/roses/buy-verify', authMiddleware, rosesController.buyVerify);
app.get('/api/roses/history', authMiddleware, rosesController.history);

// 6. Astrology / Compatibility routes (Authenticated)
app.get('/api/astro/match-details', authMiddleware, astroController.getMatchDetails);
app.post('/api/astro/unlock-match', authMiddleware, astroController.unlockMatch);

// 7. Chat history (Authenticated)
app.get('/api/chats/:partnerId', authMiddleware, chatController.getChats);
app.post('/api/chatbot/message', authMiddleware, chatController.chatbotMessage);

// Simple health check
app.get('/', (req, res) => {
  res.json({ message: 'Shubamasthu Matrimony API is running.' });
});

// Setup HTTP Server & Socket.io
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

io.on('connection', (socket) => {
  console.log('Socket connected:', socket.id);

  // User joins their personal room named after their userId
  socket.on('join', (userId) => {
    socket.join(String(userId));
    console.log(`User ${userId} joined room`);
  });

  // Typing state updates relaying
  socket.on('typing', ({ senderId, receiverId, isTyping }) => {
    io.to(String(receiverId)).emit('typing', { senderId, isTyping });
  });

  // Messaging relay & db saving
  socket.on('sendMessage', async ({ senderId, receiverId, message }) => {
    try {
      const chatRecord = await prisma.chats.create({
        data: {
          id: crypto.randomUUID(),
          sender_id: senderId,
          receiver_id: receiverId,
          message: message,
          created_at: new Date()
        }
      });
      // Emit to both parties
      io.to(String(receiverId)).emit('message', chatRecord);
      io.to(String(senderId)).emit('message', chatRecord);
    } catch (error) {
      console.error('Error saving chat message to database:', error);
    }
  });

  socket.on('disconnect', () => {
    console.log('Socket disconnected:', socket.id);
  });
});

// Start listening via the Server instance
server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

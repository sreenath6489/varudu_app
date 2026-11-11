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
app.get('/api/interests/matches', authMiddleware, interestController.getMatches);
app.post('/api/interests/unlock', authMiddleware, interestController.unlockChat);

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
app.get('/api/calls/history', authMiddleware, chatController.getCallHistory);

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
  },
  allowEIO3: true
});

// Keep track of active calls and socket/user mapping in memory
const activeCalls = new Map();
const socketUserMap = new Map();

io.on('connection', (socket) => {
  console.log('Socket connected:', socket.id);

  // User joins their personal room named after their userId
  socket.on('join', (userId) => {
    socket.join(String(userId));
    socketUserMap.set(socket.id, String(userId));
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

  // Calling signaling
  socket.on('call-dial', async ({ senderId, receiverId, senderName, senderPhoto }) => {
    console.log(`Dialing call: ${senderId} to ${receiverId}`);
    const logId = crypto.randomUUID();
    try {
      await prisma.call_logs.create({
        data: {
          id: logId,
          caller_id: String(senderId),
          receiver_id: String(receiverId),
          status: 'missed',
          duration: 0,
          created_at: new Date()
        }
      });
      activeCalls.set(String(senderId), { logId, partnerId: String(receiverId), isCaller: true, dialTime: Date.now() });
      activeCalls.set(String(receiverId), { logId, partnerId: String(senderId), isCaller: false, dialTime: Date.now() });
    } catch (e) {
      console.error('Error creating call log:', e);
    }
    io.to(String(receiverId)).emit('incoming-call', { senderId, senderName, senderPhoto });
  });

  socket.on('call-accept', ({ senderId, receiverId }) => {
    console.log(`Call accepted: ${senderId} by ${receiverId}`);
    
    // update start time of the call
    const callerCall = activeCalls.get(String(senderId));
    const receiverCall = activeCalls.get(String(receiverId));
    const startTime = Date.now();
    
    if (callerCall) callerCall.startTime = startTime;
    if (receiverCall) receiverCall.startTime = startTime;
    
    io.to(String(senderId)).emit('call-connected', { receiverId });
  });

  socket.on('call-reject', async ({ senderId, receiverId }) => {
    console.log(`Call rejected: ${senderId} by ${receiverId}`);
    const callerCall = activeCalls.get(String(senderId));
    if (callerCall) {
      try {
        await prisma.call_logs.update({
          where: { id: callerCall.logId },
          data: { status: 'rejected' }
        });
      } catch (e) {
        console.error('Error updating call log to rejected:', e);
      }
    }
    activeCalls.delete(String(senderId));
    activeCalls.delete(String(receiverId));
    io.to(String(senderId)).emit('call-rejected', { receiverId });
    io.to(String(receiverId)).emit('call-rejected', { senderId });
  });

  socket.on('call-end', async ({ senderId, receiverId }) => {
    console.log(`Call ended between ${senderId} and ${receiverId}`);
    const callInfo = activeCalls.get(String(senderId)) || activeCalls.get(String(receiverId));
    if (callInfo) {
      const duration = callInfo.startTime ? Math.round((Date.now() - callInfo.startTime) / 1000) : 0;
      const finalStatus = callInfo.startTime ? 'completed' : 'missed';
      try {
        await prisma.call_logs.update({
          where: { id: callInfo.logId },
          data: { status: finalStatus, duration }
        });
      } catch (e) {
        console.error('Error updating call log to final:', e);
      }
    }
    activeCalls.delete(String(senderId));
    activeCalls.delete(String(receiverId));
    io.to(String(receiverId)).emit('call-terminated', { senderId });
    io.to(String(senderId)).emit('call-terminated', { receiverId });
  });

  socket.on('disconnect', async () => {
    console.log('Socket disconnected:', socket.id);
    const userId = socketUserMap.get(socket.id);
    if (userId) {
      socketUserMap.delete(socket.id);
      
      // If the user was in an active call, terminate it!
      const callInfo = activeCalls.get(String(userId));
      if (callInfo) {
        const partnerId = callInfo.partnerId;
        const duration = callInfo.startTime ? Math.round((Date.now() - callInfo.startTime) / 1000) : 0;
        const finalStatus = callInfo.startTime ? 'completed' : 'missed';
        try {
          await prisma.call_logs.update({
            where: { id: callInfo.logId },
            data: { status: finalStatus, duration }
          });
        } catch (e) {
          console.error('Error updating call log on disconnect:', e);
        }
        
        // Notify the partner that the call is terminated
        io.to(String(partnerId)).emit('call-terminated', { senderId: userId });
        activeCalls.delete(String(userId));
        activeCalls.delete(String(partnerId));
      }
    }
  });
});

// Start listening via the Server instance
server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

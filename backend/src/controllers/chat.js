const prisma = require('../db');
const { mapUserToProfile } = require('./profile');
const https = require('https');

// Get message logs
exports.getChats = async (req, res) => {
  try {
    const userId = String(req.user.id);
    const { partnerId } = req.params;

    if (!partnerId) {
      return res.status(400).json({ error: 'Partner ID is required.' });
    }

    const messages = await prisma.chats.findMany({
      where: {
        OR: [
          { sender_id: userId, receiver_id: partnerId },
          { sender_id: partnerId, receiver_id: userId }
        ]
      },
      orderBy: { created_at: 'asc' }
    });

    return res.status(200).json(messages);
  } catch (error) {
    console.error('Error fetching chat history:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

// Conversational Gemini Bot logic
async function callGeminiChat(message, recommendedProfiles) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) return null;

  let context = "You are 'Matchmaker AI', a friendly and elite matchmaking assistant for the premium matrimonial app Varudu Matrimony (PerfMatch). You converse in English and Telugu (as needed). Respond warmly and concisely.";
  if (recommendedProfiles && recommendedProfiles.length > 0) {
    context += ` Tell the user that you found matching profiles: ${recommendedProfiles.map(p => p.name).join(', ')}.`;
  }

  const prompt = `${context}\nUser says: "${message}"\nMatchmaker AI:`;

  const payload = JSON.stringify({
    contents: [{ parts: [{ text: prompt }] }]
  });

  return new Promise((resolve) => {
    const options = {
      hostname: 'generativelanguage.googleapis.com',
      path: `/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          const text = json.candidates?.[0]?.content?.parts?.[0]?.text;
          resolve(text);
        } catch (e) {
          resolve(null);
        }
      });
    });

    req.on('error', () => resolve(null));
    req.write(payload);
    req.end();
  });
}

// chatbot message endpoint
exports.chatbotMessage = async (req, res) => {
  try {
    const userId = String(req.user.id);
    const { message } = req.body;

    if (!message || message.trim() === '') {
      return res.status(400).json({ error: 'Message content is required.' });
    }

    const currentUser = await prisma.users.findUnique({
      where: { id: userId }
    });

    if (!currentUser) {
      return res.status(404).json({ error: 'User profile not found.' });
    }

    const lowerMsg = message.toLowerCase();
    let recommendedProfiles = [];
    let responseText = '';

    // Search keywords inside message
    let citySearch = '';
    const cities = ['hyderabad', 'vijayawada', 'bangalore', 'tirupati', 'mumbai', 'vizag', 'guntur', 'nellore'];
    for (const city of cities) {
      if (lowerMsg.includes(city)) {
        citySearch = city;
        break;
      }
    }

    // Determine opposite gender for matchmaking search
    const interestGender = currentUser.gender === 'Male' ? 'Female' : 'Male';

    // If city keyword found, query matching profiles in database
    if (citySearch) {
      const matchedDb = await prisma.users.findMany({
        where: {
          is_onboarded: 1,
          gender: interestGender,
          place: { contains: citySearch, mode: 'insensitive' }
        },
        take: 5
      });

      recommendedProfiles = matchedDb.map(mapUserToProfile).filter(Boolean);
    }

    // Call Gemini AI if API key is present
    const geminiText = await callGeminiChat(message, recommendedProfiles);

    if (geminiText) {
      responseText = geminiText;
    } else {
      // Fallback rule-based responses
      if (citySearch) {
        const cityNameCapitalized = citySearch.charAt(0).toUpperCase() + citySearch.slice(1);
        if (recommendedProfiles.length > 0) {
          responseText = `ఖచ్చితంగా! I have found ${recommendedProfiles.length} compatible profiles from **${cityNameCapitalized}** for you. Swipe through them below! 😊`;
        } else {
          responseText = `నేను ${cityNameCapitalized} లో ఎలాంటి మ్యాచ్‌లను కనుగొనలేకపోయాను. Try searching another city, or update your preferences!`;
        }
      } else if (lowerMsg.includes('hello') || lowerMsg.includes('hi') || lowerMsg.includes('నమస్తే')) {
        responseText = `నమస్కారం! Hello! I am your personal Matchmaker AI. How can I help you find your life partner today? \n\nYou can ask me: \n- "Show me profiles from Vijayawada"\n- "Find someone matching my Rasi"`;
      } else if (lowerMsg.includes('star') || lowerMsg.includes('nakshatram') || lowerMsg.includes('rasi')) {
        // Query users with star/rasi details
        const matchedDb = await prisma.users.findMany({
          where: {
            is_onboarded: 1,
            gender: interestGender
          },
          take: 3
        });
        recommendedProfiles = matchedDb.map(mapUserToProfile).filter(Boolean);
        responseText = `Sure! Astrology alignment is very auspicious. Based on your horoscope star settings, here are some recommended profiles with highly compatible Ashtakoota aspects.`;
      } else {
        responseText = `Thank you for sharing that. As your Matchmaker AI, I'm analyzing your interests. To narrow down your searches, you can type a city name (like "Vijayawada" or "Hyderabad") and I will immediately recommend profiles!`;
      }
    }

    return res.status(200).json({
      reply: responseText,
      profiles: recommendedProfiles
    });

  } catch (error) {
    console.error('Error in chatbot handler:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

// Get Call History
exports.getCallHistory = async (req, res) => {
  try {
    const userId = String(req.user.id);

    const callLogs = await prisma.call_logs.findMany({
      where: {
        OR: [
          { caller_id: userId },
          { receiver_id: userId }
        ]
      },
      orderBy: { created_at: 'desc' }
    });

    const partnerIds = [...new Set(callLogs.flatMap(log => [log.caller_id, log.receiver_id]))].filter(id => id !== userId);

    const partners = await prisma.users.findMany({
      where: { id: { in: partnerIds } }
    });

    const partnerMap = new Map(partners.map(p => [p.id, mapUserToProfile(p)]).filter(x => x[1] !== null));

    const enrichedLogs = callLogs.map(log => {
      const partnerId = log.caller_id === userId ? log.receiver_id : log.caller_id;
      return {
        id: log.id,
        isOutgoing: log.caller_id === userId,
        status: log.status,
        duration: log.duration,
        created_at: log.created_at,
        partner: partnerMap.get(partnerId) || { id: partnerId, name: 'User', photos: [] }
      };
    });

    return res.status(200).json(enrichedLogs);
  } catch (error) {
    console.error('Error fetching call history:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

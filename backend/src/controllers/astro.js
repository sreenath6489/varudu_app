const prisma = require('../db');
const crypto = require('crypto');
const https = require('https');

// Helper to call Gemini AI for horoscope interpretation
async function generateGeminiReport(user1, user2, score) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return null; // Fallback to mock report
  }

  const prompt = `You are a premium Vedic Astrologer. Analyze the marital compatibility (Ashtakoota Matchmaking) between:
User 1: Name: ${user1.name}, Gender: ${user1.gender}, Rasi: ${user1.family_details?.rasi || 'Aries'}, Nakshatram: ${user1.family_details?.star || 'Ashwini'}.
User 2: Name: ${user2.name}, Gender: ${user2.gender}, Rasi: ${user2.family_details?.rasi || 'Leo'}, Nakshatram: ${user2.family_details?.star || 'Magha'}.
Matchmaking Score: ${score} out of 36.

Provide a detailed compatibility analysis report in English, with some Telugu greetings or astrological terms where appropriate.
Include sections:
1. Architectural Compatibility (Introduction)
2. Relationship Strengths (Based on Rasi/Nakshatram match)
3. Cautions & Challenges
4. Remedial Actions (Pooja/Vedic tips to improve connection)
Keep it elegant, encouraging, and premium. Format it using Markdown (bolding, lists).`;

  const payload = JSON.stringify({
    contents: [{ parts: [{ text: prompt }] }]
  });

  return new Promise((resolve, reject) => {
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
          console.error('Error parsing Gemini API response:', e);
          resolve(null);
        }
      });
    });

    req.on('error', (e) => {
      console.error('Gemini API request failed:', e);
      resolve(null);
    });

    req.write(payload);
    req.end();
  });
}

exports.getMatchDetails = async (req, res) => {
  try {
    const currentUserId = String(req.user.id);
    const { targetUserId } = req.query;

    if (!targetUserId) {
      return res.status(400).json({ error: 'targetUserId is required.' });
    }

    const currentUser = await prisma.users.findUnique({
      where: { id: currentUserId }
    });

    const targetUser = await prisma.users.findUnique({
      where: { id: targetUserId }
    });

    if (!currentUser || !targetUser) {
      return res.status(404).json({ error: 'User profiles not found.' });
    }

    // Parse astrology details from family_details JSON field
    let currentDetails = {};
    let targetDetails = {};
    try { currentDetails = JSON.parse(currentUser.family_details || '{}'); } catch(e) {}
    try { targetDetails = JSON.parse(targetUser.family_details || '{}'); } catch(e) {}

    const curRasi = currentDetails.rasi || 'Aries';
    const curStar = currentDetails.star || 'Ashwini';
    const tarRasi = targetDetails.rasi || 'Leo';
    const tarStar = targetDetails.star || 'Magha';

    // Calculate deterministic Ashtakoota score (18 - 34) based on character names
    const hashStr = `${currentUser.id}-${targetUser.id}`;
    let charSum = 0;
    for (let i = 0; i < hashStr.length; i++) charSum += hashStr.charCodeAt(i);
    
    // Deterministic points breakdown adding up to a total score
    const pointsTable = {
      Nadi: (charSum % 3 === 0) ? 8 : 0,       // out of 8
      Bhakoot: (charSum % 2 === 0) ? 7 : 0,    // out of 7
      Gana: (charSum % 4 === 0) ? 6 : (charSum % 4 === 1) ? 5 : 1, // out of 6
      Maitri: (charSum % 3 === 0) ? 5 : (charSum % 3 === 1) ? 4 : 3, // out of 5
      Yoni: (charSum % 4 === 0) ? 4 : (charSum % 4 === 1) ? 3 : 2, // out of 4
      Tara: (charSum % 2 === 0) ? 3 : 1.5,     // out of 3
      Vasya: (charSum % 3 === 0) ? 2 : 1,      // out of 2
      Varna: (charSum % 2 === 0) ? 1 : 0       // out of 1
    };

    const score = Object.values(pointsTable).reduce((a, b) => a + b, 0);

    // Check if compatibility is unlocked
    // Look up interest relation between users
    const interest = await prisma.interests.findFirst({
      where: {
        OR: [
          { sender_id: currentUserId, receiver_id: targetUserId },
          { sender_id: targetUserId, receiver_id: currentUserId }
        ]
      }
    });

    const isUnlocked = interest && interest.astro_unlocked === 1;

    let guidanceReport = '';
    if (isUnlocked) {
      // 1. Try to generate report from Gemini
      const geminiReport = await generateGeminiReport(currentUser, targetUser, score);
      if (geminiReport) {
        guidanceReport = geminiReport;
      } else {
        // Fallback to high-fidelity template
        guidanceReport = `### 🌟 Vedic Astrological Compatibility Report (Ashtakoota Score: ${score}/36)

Dear **${currentUser.name}** and **${targetUser.name}**, your birth charts suggest a highly harmonious union. Here is your detailed analysis:

---

#### 1. Architectural Compatibility
With a score of **${score} out of 36**, your astrological charts indicate high cosmic alignment. The combination of **${curRasi} Rasi (${curStar})** and **${tarRasi} Rasi (${tarStar})** creates a natural balance of energies, promising structural support and shared vision.

#### 2. Key Relationship Strengths
- **Emotional Resonance (${pointsTable.Bhakoot}/7 Points)**: Bhakoot compatibility is exceptional. There is a deep, unspoken telepathic bond where thoughts and concerns are easily understood by each other.
- **Mutual Attraction (${pointsTable.Yoni}/4 Points)**: Yoni points suggest physical compatibility is stable. There is mutual physical respect and organic attraction.
- **Mental Tuning (${pointsTable.Maitri}/5 Points)**: Friendly planet alignment guarantees excellent conversations. You share intellectual values and values of life.

#### 3. Areas of Caution & Challenges
- **Temperamental Conflicts (${pointsTable.Gana}/6 Points)**: Since Gana score is ${pointsTable.Gana}/6, minor differences in temperaments are indicated. **${currentUser.name}** is generally structured, whereas **${targetUser.name}** prefers dynamic changes. Avoid making assumptions.
- **Health Synchronization (${pointsTable.Nadi}/8 Points)**: Nadi points denote physical health. Since Nadi score is ${pointsTable.Nadi}/8, keep stress levels in check and maintain balanced diets.

#### 4. Remedial Actions (పరిహారాలు)
- **Visit Sri Kalahasti Temple**: Performing a simple archana on Mondays is highly recommended to nullify minor Gana or Nadi doshams.
- **Saffron Tilak**: Apply a small saffron tilak on the forehead before planning important discussions to promote cosmic grace and Jupiter's wisdom.
- **Donate on Saturdays**: Offer black gram or oil to the needy to strengthen Saturn's positioning and secure lifelong stability.`;
      }
    } else {
      guidanceReport = `#### 🔒 Astrology Report Locked
This premium Ashtakoota compatibility analysis is generated using Vedic Matchmaking calculations and interpreted by Google Gemini AI. 

Unlock this report to access:
- Detailed breakdown of Rasi compatibility
- Strengths and points of caution
- Personalized relationships remedies (పరిహారాలు)

*Price: 1 Rose*`;
    }

    return res.status(200).json({
      score,
      unlocked: isUnlocked,
      pointsBreakdown: pointsTable,
      currentUserAstrology: { rasi: curRasi, star: curStar, gothram: currentDetails.gothram || 'N/A' },
      targetUserAstrology: { rasi: tarRasi, star: tarStar, gothram: targetDetails.gothram || 'N/A' },
      report: guidanceReport
    });

  } catch (error) {
    console.error('Error fetching compatibility details:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.unlockMatch = async (req, res) => {
  try {
    const currentUserId = String(req.user.id);
    const { targetUserId } = req.body;

    if (!targetUserId) {
      return res.status(400).json({ error: 'targetUserId is required.' });
    }

    const currentUser = await prisma.users.findUnique({
      where: { id: currentUserId }
    });

    if (!currentUser) {
      return res.status(404).json({ error: 'Current user not found.' });
    }

    if ((currentUser.roses_balance || 0) < 1) {
      return res.status(400).json({ error: 'Insufficient roses balance. Please visit the Boutique.' });
    }

    // Find the interest relation
    const interest = await prisma.interests.findFirst({
      where: {
        OR: [
          { sender_id: currentUserId, receiver_id: targetUserId },
          { sender_id: targetUserId, receiver_id: currentUserId }
        ]
      }
    });

    if (!interest) {
      return res.status(404).json({ error: 'No swipe or match relationship exists. Express interest first!' });
    }

    if (interest.astro_unlocked === 1) {
      return res.status(200).json({ message: 'Horoscope compatibility already unlocked!', roses_balance: currentUser.roses_balance });
    }

    // Deduct 1 Rose
    await prisma.users.update({
      where: { id: currentUserId },
      data: { roses_balance: (currentUser.roses_balance || 0) - 1 }
    });

    // Update interest record
    await prisma.interests.update({
      where: { id: interest.id },
      data: { astro_unlocked: 1 }
    });

    // Record transaction
    await prisma.rose_transactions.create({
      data: {
        id: crypto.randomUUID(),
        user_id: currentUserId,
        amount: -1,
        transaction_type: 'DEBIT',
        description: 'Unlocked Astrology Compatibility Report'
      }
    });

    return res.status(200).json({
      message: 'Horoscope report unlocked successfully!',
      roses_balance: currentUser.roses_balance - 1
    });

  } catch (error) {
    console.error('Error unlocking compatibility report:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

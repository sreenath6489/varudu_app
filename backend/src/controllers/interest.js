const prisma = require('../db');
const crypto = require('crypto');
const { mapUserToProfile } = require('./profile');

// Express a swipe / like
exports.expressInterest = async (req, res) => {
  try {
    const currentUserId = String(req.user.id);
    const { interestedProfileId } = req.body;

    if (!interestedProfileId) {
      return res.status(400).json({ error: 'interestedProfileId is required.' });
    }

    if (interestedProfileId === currentUserId) {
      return res.status(400).json({ error: 'You cannot express interest in yourself.' });
    }

    // Default behavior is equivalent to a swipe standard right
    const interest = await prisma.interests.findUnique({
      where: {
        sender_id_receiver_id: {
          sender_id: currentUserId,
          receiver_id: interestedProfileId
        }
      }
    });

    if (!interest) {
      await prisma.interests.create({
        data: {
          id: crypto.randomUUID(),
          sender_id: currentUserId,
          receiver_id: interestedProfileId,
          status: 'pending',
          interaction_type: 'standard'
        }
      });
    }

    return res.status(200).json({
      message: 'Interest saved successfully',
      interestedProfileId
    });
  } catch (error) {
    console.error('Error expressing interest:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

// Main Swipes / Likes handler
exports.swipe = async (req, res) => {
  try {
    const senderId = String(req.user.id);
    const { receiver_id, status, interaction_type, attached_message } = req.body;

    if (!receiver_id || !status) {
      return res.status(400).json({ error: 'receiver_id and status (accepted or rejected) are required.' });
    }

    if (senderId === receiver_id) {
      return res.status(400).json({ error: 'You cannot swipe on yourself.' });
    }

    // Verify target exists
    const receiverUser = await prisma.users.findUnique({
      where: { id: receiver_id }
    });

    if (!receiverUser) {
      return res.status(404).json({ error: 'Target profile not found.' });
    }

    // 1. Check if there is an incoming swipe from the target user
    const incomingInterest = await prisma.interests.findUnique({
      where: {
        sender_id_receiver_id: {
          sender_id: receiver_id,
          receiver_id: senderId
        }
      }
    });

    // If swipe is PASS/REJECT
    if (status === 'rejected') {
      // Upsert a rejected swipe from us
      await prisma.interests.upsert({
        where: {
          sender_id_receiver_id: {
            sender_id: senderId,
            receiver_id
          }
        },
        update: { status: 'rejected' },
        create: {
          id: crypto.randomUUID(),
          sender_id: senderId,
          receiver_id,
          status: 'rejected'
        }
      });

      return res.status(200).json({ message: 'Pass recorded successfully', match: false });
    }

    // If swipe is LIKE/ACCEPT
    if (incomingInterest && incomingInterest.status === 'pending') {
      // It's a match!
      const updatedIncoming = await prisma.interests.update({
        where: { id: incomingInterest.id },
        data: {
          status: 'accepted',
          accepted_at: new Date()
        }
      });

      // Also create/update our outbound record as accepted
      await prisma.interests.upsert({
        where: {
          sender_id_receiver_id: {
            sender_id: senderId,
            receiver_id
          }
        },
        update: {
          status: 'accepted',
          accepted_at: new Date()
        },
        create: {
          id: crypto.randomUUID(),
          sender_id: senderId,
          receiver_id,
          status: 'accepted',
          accepted_at: new Date()
        }
      });

      return res.status(200).json({
        message: 'It is a match!',
        match: true,
        interest: updatedIncoming
      });
    }

    // If no incoming interest, create a pending outbound interest
    // Handle rose debit if interaction_type is 'rose'
    const isRoseSwipe = interaction_type === 'rose';
    if (isRoseSwipe) {
      const senderUser = await prisma.users.findUnique({
        where: { id: senderId }
      });

      const currentRoses = senderUser.roses_balance || 0;
      if (currentRoses < 1) {
        return res.status(400).json({ error: 'Insufficient roses balance. Please visit the Boutique.' });
      }

      // Deduct rose
      await prisma.users.update({
        where: { id: senderId },
        data: { roses_balance: currentRoses - 1 }
      });

      // Add transaction log
      await prisma.rose_transactions.create({
        data: {
          id: crypto.randomUUID(),
          user_id: senderId,
          amount: -1,
          transaction_type: 'DEBIT',
          description: `Sent a Premium Rose swipe to ${receiverUser.name || 'someone'}`
        }
      });
    }

    const interest = await prisma.interests.upsert({
      where: {
        sender_id_receiver_id: {
          sender_id: senderId,
          receiver_id
        }
      },
      update: {
        status: 'pending',
        interaction_type: isRoseSwipe ? 'rose' : 'standard',
        attached_message: attached_message || null
      },
      create: {
        id: crypto.randomUUID(),
        sender_id: senderId,
        receiver_id,
        status: 'pending',
        interaction_type: isRoseSwipe ? 'rose' : 'standard',
        attached_message: attached_message || null
      }
    });

    return res.status(200).json({
      message: isRoseSwipe ? 'Rose sent successfully!' : 'Like sent successfully!',
      match: false,
      interest
    });
  } catch (error) {
    console.error('Error swiping profile:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

// Accept a received interest
exports.acceptInterest = async (req, res) => {
  try {
    const currentUserId = String(req.user.id);
    const { interestId } = req.body;

    const interest = await prisma.interests.findUnique({
      where: { id: interestId }
    });

    if (!interest) {
      return res.status(404).json({ error: 'Interest request not found.' });
    }

    if (interest.receiver_id !== currentUserId) {
      return res.status(403).json({ error: 'Not authorized to accept this interest.' });
    }

    // Check user rose balance
    const user = await prisma.users.findUnique({
      where: { id: currentUserId }
    });

    if (!user) {
      return res.status(404).json({ error: 'User profile not found.' });
    }

    const currentRoses = user.roses_balance || 0;
    if (currentRoses < 1) {
      return res.status(400).json({ error: 'Insufficient roses balance. Please visit the Boutique.' });
    }

    // Deduct rose from user
    await prisma.users.update({
      where: { id: currentUserId },
      data: { roses_balance: currentRoses - 1 }
    });

    // Create transaction log
    await prisma.rose_transactions.create({
      data: {
        id: crypto.randomUUID(),
        user_id: currentUserId,
        amount: -1,
        transaction_type: 'DEBIT',
        description: `Accepted match request from ${interest.sender_id}`
      }
    });

    // Update original row
    const updated = await prisma.interests.update({
      where: { id: interestId },
      data: {
        status: 'accepted',
        receiver_unlocked: 1, // B accepts, so B (receiver) unlocks their side
        accepted_at: new Date()
      }
    });

    // Create/update mutual reciprocal interest
    await prisma.interests.upsert({
      where: {
        sender_id_receiver_id: {
          sender_id: currentUserId,
          receiver_id: interest.sender_id
        }
      },
      update: {
        status: 'accepted',
        sender_unlocked: 1, // B is sender of the mutual row, so B's side is unlocked
        accepted_at: new Date()
      },
      create: {
        id: crypto.randomUUID(),
        sender_id: currentUserId,
        receiver_id: interest.sender_id,
        status: 'accepted',
        sender_unlocked: 1,
        accepted_at: new Date()
      }
    });

    return res.status(200).json({ message: 'Request accepted!', interest: updated });
  } catch (error) {
    console.error('Error accepting interest:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

// Decline/Reject a received interest
exports.declineInterest = async (req, res) => {
  try {
    const currentUserId = String(req.user.id);
    const { interestId } = req.body;

    const interest = await prisma.interests.findUnique({
      where: { id: interestId }
    });

    if (!interest) {
      return res.status(404).json({ error: 'Interest request not found.' });
    }

    if (interest.receiver_id !== currentUserId) {
      return res.status(403).json({ error: 'Not authorized to decline this interest.' });
    }

    const updated = await prisma.interests.update({
      where: { id: interestId },
      data: { status: 'rejected' }
    });

    return res.status(200).json({ message: 'Request declined.', interest: updated });
  } catch (error) {
    console.error('Error declining interest:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

// Withdraw a sent interest
exports.withdrawInterest = async (req, res) => {
  try {
    const currentUserId = String(req.user.id);
    const { interestId } = req.body;

    const interest = await prisma.interests.findUnique({
      where: { id: interestId }
    });

    if (!interest) {
      return res.status(404).json({ error: 'Interest not found.' });
    }

    if (interest.sender_id !== currentUserId) {
      return res.status(403).json({ error: 'Not authorized to withdraw this interest.' });
    }

    await prisma.interests.delete({
      where: { id: interestId }
    });

    return res.status(200).json({ message: 'Interest withdrawn successfully.' });
  } catch (error) {
    console.error('Error withdrawing interest:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

// Get sent and received interest requests
exports.getRequests = async (req, res) => {
  try {
    const currentUserId = String(req.user.id);

    // 1. Received: pending likes sent to us
    const receivedInterests = await prisma.interests.findMany({
      where: {
        receiver_id: currentUserId,
        status: 'pending'
      },
      orderBy: { created_at: 'desc' }
    });

    const senderIds = receivedInterests.map(ri => ri.sender_id).filter(Boolean);
    const sendersDb = await prisma.users.findMany({
      where: { id: { in: senderIds } }
    });

    const receivedProfiles = receivedInterests.map(interest => {
      const dbUser = sendersDb.find(u => u.id === interest.sender_id);
      if (!dbUser) return null;
      return {
        interestId: interest.id,
        status: interest.status,
        interaction_type: interest.interaction_type,
        attached_message: interest.attached_message,
        profile: mapUserToProfile(dbUser)
      };
    }).filter(Boolean);

    // 2. Sent: interests we sent to others (can be pending or accepted)
    const sentInterests = await prisma.interests.findMany({
      where: {
        sender_id: currentUserId,
        status: { in: ['pending', 'accepted'] }
      },
      orderBy: { created_at: 'desc' }
    });

    const receiverIds = sentInterests.map(si => si.receiver_id).filter(Boolean);
    const receiversDb = await prisma.users.findMany({
      where: { id: { in: receiverIds } }
    });

    const sentProfiles = sentInterests.map(interest => {
      const dbUser = receiversDb.find(u => u.id === interest.receiver_id);
      if (!dbUser) return null;
      return {
        interestId: interest.id,
        status: interest.status,
        interaction_type: interest.interaction_type,
        profile: mapUserToProfile(dbUser)
      };
    }).filter(Boolean);

    return res.status(200).json({
      received: receivedProfiles,
      sent: sentProfiles
    });
  } catch (error) {
    console.error('Error fetching requests:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

// Existing method kept for compatibility
exports.getInterests = async (req, res) => {
  try {
    const currentUserId = String(req.user.id);

    const interests = await prisma.interests.findMany({
      where: { sender_id: currentUserId },
      orderBy: { created_at: 'desc' }
    });

    const receiverIds = interests.map((i) => i.receiver_id).filter(Boolean);

    const dbUsers = await prisma.users.findMany({
      where: { id: { in: receiverIds } }
    });

    const profiles = dbUsers.map(mapUserToProfile).filter(Boolean);
    return res.status(200).json(profiles);
  } catch (error) {
    console.error('Error getting interests:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

// Get all matched connections with unlock metadata
exports.getMatches = async (req, res) => {
  try {
    const currentUserId = String(req.user.id);

    // Find all interests where status = 'accepted'
    // and current user is sender_id or receiver_id
    const matchedInterests = await prisma.interests.findMany({
      where: {
        status: 'accepted',
        OR: [
          { sender_id: currentUserId },
          { receiver_id: currentUserId }
        ]
      },
      orderBy: { accepted_at: 'desc' }
    });

    // Gather partner IDs for batch loading
    const partnerIds = matchedInterests.map(interest => {
      const isSender = interest.sender_id === currentUserId;
      return isSender ? interest.receiver_id : interest.sender_id;
    }).filter(Boolean);

    // Batch query all partner users
    const partnerUsers = await prisma.users.findMany({
      where: {
        id: { in: partnerIds }
      }
    });

    // Map partner users by ID for O(1) lookup
    const partnerUsersMap = new Map(partnerUsers.map(u => [u.id, u]));

    // Fetch the other users' profiles
    const matches = [];
    for (const interest of matchedInterests) {
      const isSender = interest.sender_id === currentUserId;
      const partnerId = isSender ? interest.receiver_id : interest.sender_id;

      if (!partnerId) continue;

      const partnerUser = partnerUsersMap.get(partnerId);
      if (!partnerUser) continue;

      // Determine unlock status
      // A chat is unlocked for BOTH if:
      // interest.sender_unlocked === 1 && interest.receiver_unlocked === 1
      const myUnlocked = isSender ? (interest.sender_unlocked === 1) : (interest.receiver_unlocked === 1);
      const partnerUnlocked = isSender ? (interest.receiver_unlocked === 1) : (interest.sender_unlocked === 1);
      const isUnlocked = interest.sender_unlocked === 1 && interest.receiver_unlocked === 1;

      matches.push({
        interestId: interest.id,
        partnerId,
        sender_unlocked: interest.sender_unlocked || 0,
        receiver_unlocked: interest.receiver_unlocked || 0,
        my_unlocked: myUnlocked ? 1 : 0,
        partner_unlocked: partnerUnlocked ? 1 : 0,
        is_unlocked: isUnlocked,
        profile: mapUserToProfile(partnerUser)
      });
    }

    // Deduplicate profiles by partnerId (since we might have both original and reciprocal rows)
    const uniqueMatches = [];
    const seenIds = new Set();
    for (const m of matches) {
      if (!seenIds.has(m.partnerId)) {
        seenIds.add(m.partnerId);
        uniqueMatches.push(m);
      }
    }

    return res.status(200).json(uniqueMatches);
  } catch (error) {
    console.error('Error fetching matches:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

// Unlock a match chat by spending 1 rose
exports.unlockChat = async (req, res) => {
  try {
    const currentUserId = String(req.user.id);
    const { interestId } = req.body;

    if (!interestId) {
      return res.status(400).json({ error: 'interestId is required.' });
    }

    const interest = await prisma.interests.findUnique({
      where: { id: interestId }
    });

    if (!interest) {
      return res.status(404).json({ error: 'Match request not found.' });
    }

    // Verify current user is either sender or receiver
    const isSender = interest.sender_id === currentUserId;
    const isReceiver = interest.receiver_id === currentUserId;

    if (!isSender && !isReceiver) {
      return res.status(403).json({ error: 'Not authorized to unlock this chat.' });
    }

    // Check if already unlocked by this user
    if (isSender && interest.sender_unlocked === 1) {
      return res.status(200).json({ message: 'Already unlocked', interest });
    }
    if (isReceiver && interest.receiver_unlocked === 1) {
      return res.status(200).json({ message: 'Already unlocked', interest });
    }

    // Check user rose balance
    const user = await prisma.users.findUnique({
      where: { id: currentUserId }
    });

    if (!user) {
      return res.status(404).json({ error: 'User profile not found.' });
    }

    const currentRoses = user.roses_balance || 0;
    if (currentRoses < 1) {
      return res.status(400).json({ error: 'Insufficient roses balance. Please visit the Boutique.' });
    }

    // Deduct rose
    await prisma.users.update({
      where: { id: currentUserId },
      data: { roses_balance: currentRoses - 1 }
    });

    // Record transaction
    const partnerId = isSender ? interest.receiver_id : interest.sender_id;
    await prisma.rose_transactions.create({
      data: {
        id: crypto.randomUUID(),
        user_id: currentUserId,
        amount: -1,
        transaction_type: 'DEBIT',
        description: `Unlocked chat room with partner ${partnerId}`
      }
    });

    // Update unlock field for this interest
    const updateData = {};
    if (isSender) {
      updateData.sender_unlocked = 1;
    } else {
      updateData.receiver_unlocked = 1;
    }

    const updatedInterest = await prisma.interests.update({
      where: { id: interestId },
      data: updateData
    });

    // Also sync the reciprocal row if it exists
    const reciprocalInterest = await prisma.interests.findUnique({
      where: {
        sender_id_receiver_id: {
          sender_id: interest.receiver_id,
          receiver_id: interest.sender_id
        }
      }
    });

    if (reciprocalInterest) {
      const recipUpdateData = {};
      if (isSender) {
        // Current user is original sender, which is the reciprocal receiver
        recipUpdateData.receiver_unlocked = 1;
      } else {
        // Current user is original receiver, which is the reciprocal sender
        recipUpdateData.sender_unlocked = 1;
      }
      await prisma.interests.update({
        where: { id: reciprocalInterest.id },
        data: recipUpdateData
      });
    }

    return res.status(200).json({
      message: 'Chat unlocked successfully on your side!',
      interest: updatedInterest
    });
  } catch (error) {
    console.error('Error unlocking chat:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

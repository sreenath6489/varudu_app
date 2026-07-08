const prisma = require('../db');
const crypto = require('crypto');

exports.getBalance = async (req, res) => {
  try {
    const userId = String(req.user.id);
    const user = await prisma.users.findUnique({
      where: { id: userId }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    // Generate referral code if not exists
    let referralCode = user.referral_code;
    if (!referralCode) {
      referralCode = 'REF-' + Math.random().toString(36).substring(2, 8).toUpperCase();
      await prisma.users.update({
        where: { id: userId },
        data: { referral_code: referralCode }
      });
    }

    return res.status(200).json({
      roses_balance: user.roses_balance || 0,
      referral_code: referralCode,
      last_free_rose_at: user.last_free_rose_at
    });
  } catch (error) {
    console.error('Error fetching rose balance:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.claimFree = async (req, res) => {
  try {
    const userId = String(req.user.id);
    const user = await prisma.users.findUnique({
      where: { id: userId }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const now = new Date();
    const lastClaim = user.last_free_rose_at ? new Date(user.last_free_rose_at) : null;
    const cooldownMs = 24 * 60 * 60 * 1000; // 24 hours

    if (lastClaim && (now.getTime() - lastClaim.getTime() < cooldownMs)) {
      const remainingMs = cooldownMs - (now.getTime() - lastClaim.getTime());
      const remainingSeconds = Math.ceil(remainingMs / 1000);
      return res.status(400).json({
        error: 'Daily rose already claimed.',
        remaining_seconds: remainingSeconds
      });
    }

    // Grant 1 Rose
    const updated = await prisma.users.update({
      where: { id: userId },
      data: {
        roses_balance: (user.roses_balance || 0) + 1,
        last_free_rose_at: now
      }
    });

    // Record transaction
    await prisma.rose_transactions.create({
      data: {
        id: crypto.randomUUID(),
        user_id: userId,
        amount: 1,
        transaction_type: 'CREDIT',
        description: 'Daily Free Rose Claimed'
      }
    });

    return res.status(200).json({
      message: 'Claimed free rose successfully!',
      roses_balance: updated.roses_balance,
      last_free_rose_at: updated.last_free_rose_at
    });
  } catch (error) {
    console.error('Error claiming free rose:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.watchAd = async (req, res) => {
  try {
    const userId = String(req.user.id);
    const user = await prisma.users.findUnique({
      where: { id: userId }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    // Award 1 Rose
    const updated = await prisma.users.update({
      where: { id: userId },
      data: {
        roses_balance: (user.roses_balance || 0) + 1
      }
    });

    // Record transaction
    await prisma.rose_transactions.create({
      data: {
        id: crypto.randomUUID(),
        user_id: userId,
        amount: 1,
        transaction_type: 'CREDIT',
        description: 'Watched Mock Ad Reward'
      }
    });

    return res.status(200).json({
      message: 'Watched ad and earned 1 Rose!',
      roses_balance: updated.roses_balance
    });
  } catch (error) {
    console.error('Error rewarding rose from ad:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.buyOrder = async (req, res) => {
  try {
    const userId = String(req.user.id);
    const { roses_amount, amount_in_rupees } = req.body;

    if (!roses_amount || !amount_in_rupees) {
      return res.status(400).json({ error: 'roses_amount and amount_in_rupees are required.' });
    }

    // Generate a mock order ID
    const orderId = 'order_' + Math.random().toString(36).substring(2, 12).toUpperCase();

    return res.status(200).json({
      id: orderId,
      amount: amount_in_rupees * 100, // in paisa
      currency: 'INR',
      receipt: 'receipt_' + Date.now(),
      roses_amount
    });
  } catch (error) {
    console.error('Error creating buy order:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.buyVerify = async (req, res) => {
  try {
    const userId = String(req.user.id);
    const { razorpay_order_id, razorpay_payment_id, roses_amount } = req.body;

    if (!roses_amount) {
      return res.status(400).json({ error: 'roses_amount is required.' });
    }

    const user = await prisma.users.findUnique({
      where: { id: userId }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const purchasedRoses = parseInt(roses_amount, 10);
    if (isNaN(purchasedRoses) || purchasedRoses <= 0) {
      return res.status(400).json({ error: 'Invalid roses amount.' });
    }

    // Credit Roses
    const updated = await prisma.users.update({
      where: { id: userId },
      data: {
        roses_balance: (user.roses_balance || 0) + purchasedRoses
      }
    });

    // Record transaction
    await prisma.rose_transactions.create({
      data: {
        id: crypto.randomUUID(),
        user_id: userId,
        amount: purchasedRoses,
        transaction_type: 'CREDIT',
        description: `Purchased ${purchasedRoses} Roses Bundle (${razorpay_payment_id || 'Mock Payment'})`
      }
    });

    return res.status(200).json({
      message: 'Payment verified and roses added!',
      roses_balance: updated.roses_balance
    });
  } catch (error) {
    console.error('Error verifying payment:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.history = async (req, res) => {
  try {
    const userId = String(req.user.id);
    const logs = await prisma.rose_transactions.findMany({
      where: { user_id: userId },
      orderBy: { created_at: 'desc' }
    });

    return res.status(200).json(logs);
  } catch (error) {
    console.error('Error fetching rose transactions:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

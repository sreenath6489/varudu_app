const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const prisma = require('../db');

exports.sendOtp = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    return res.status(200).json({
      message: 'OTP sent successfully (Use fake OTP: 1234 for testing)',
      email
    });
  } catch (error) {
    console.error('Error sending OTP:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.verifyOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) {
      return res.status(400).json({ error: 'Email and OTP are required' });
    }

    if (otp !== '1234') {
      return res.status(400).json({ error: 'Invalid OTP. Please use 1234.' });
    }

    // Look up user in the introspected "users" table
    let user = await prisma.users.findUnique({
      where: { email }
    });

    let isNewUser = false;
    if (!user) {
      // User doesn't exist, create they in "users" table with mock phone_number
      user = await prisma.users.create({
        data: {
          id: crypto.randomUUID(),
          email,
          phone_number: 'mock-' + Date.now() + Math.floor(Math.random() * 1000),
          is_onboarded: 0
        }
      });
      isNewUser = true;
    } else {
      if (user.is_onboarded !== 1) {
        isNewUser = true;
      }
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET || 'shubamasthu-secret-key-12345',
      { expiresIn: '30d' }
    );

    return res.status(200).json({
      token,
      isNewUser,
      email: user.email,
      userId: user.id
    });
  } catch (error) {
    console.error('Error verifying OTP:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

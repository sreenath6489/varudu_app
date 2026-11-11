const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const prisma = require('../db');

exports.sendOtp = async (req, res) => {
  try {
    const identifier = req.body.email || req.body.phone || req.body.phoneNumber || req.body.emailOrPhone;
    if (!identifier) {
      return res.status(400).json({ error: 'Phone number or email is required' });
    }

    return res.status(200).json({
      message: 'OTP sent successfully (Use fake OTP: 1234 for testing)',
      identifier
    });
  } catch (error) {
    console.error('Error sending OTP:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.verifyOtp = async (req, res) => {
  try {
    const identifier = req.body.email || req.body.phone || req.body.phoneNumber || req.body.emailOrPhone;
    const { otp } = req.body;
    if (!identifier || !otp) {
      return res.status(400).json({ error: 'Phone number/Email and OTP are required' });
    }

    // Allow fake OTP 1234, 0000, 1111 for testing
    if (otp !== '1234' && otp !== '0000' && otp !== '1111') {
      return res.status(400).json({ error: 'Invalid OTP. Please use fake OTP 1234.' });
    }

    const cleanId = String(identifier).trim();
    const isPhone = !cleanId.includes('@');
    const emailVal = isPhone ? `${cleanId.replace(/\D/g, '')}@varudu.in` : cleanId;
    const phoneVal = isPhone ? cleanId : `+91-${Date.now()}`;

    // Look up user in the "users" table
    let user = await prisma.users.findFirst({
      where: {
        OR: [
          { email: emailVal },
          { email: cleanId },
          { phone_number: cleanId },
          { phone_number: phoneVal }
        ]
      }
    });

    let isNewUser = false;
    if (!user) {
      // User doesn't exist, create them in "users" table with their actual phone/email
      user = await prisma.users.create({
        data: {
          id: crypto.randomUUID(),
          email: emailVal,
          phone_number: phoneVal,
          is_onboarded: 0,
          roses_balance: 25
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
      phone: user.phone_number,
      userId: user.id
    });
  } catch (error) {
    console.error('Error verifying OTP:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

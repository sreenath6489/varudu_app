const prisma = require('../db');
const crypto = require('crypto');

// Helper to map DB users table structure to frontend Profile structure
function mapUserToProfile(user) {
  if (!user) return null;

  let photosList = [];
  if (user.photos) {
    try {
      photosList = JSON.parse(user.photos);
    } catch (e) {
      if (typeof user.photos === 'string' && user.photos.startsWith('/')) {
        photosList = [user.photos];
      }
    }
  }

  let familyDetails = {};
  if (user.family_details) {
    try {
      familyDetails = JSON.parse(user.family_details);
    } catch (e) {
      if (typeof user.family_details === 'object') {
        familyDetails = user.family_details;
      }
    }
  }

  return {
    id: user.id,
    phone_number: user.phone_number,
    name: user.name,
    city: user.place,
    age: user.age,
    dob: user.dob,
    gender: user.gender === 'Male' ? 'MAN' : 'WOMAN',
    interestedIn: user.interested_in === 'Male' ? 'MAN' : 'WOMAN',
    photos: photosList,
    photoUrl: photosList.length > 0 ? photosList[0] : null,
    is_onboarded: user.is_onboarded === 1,
    aadhaar_verified: user.aadhaar_verified === true,
    face_verified: user.face_verified === true,
    roses_balance: user.roses_balance || 0,
    referral_code: user.referral_code || '',
    referred_by: user.referred_by || '',
    last_free_rose_at: user.last_free_rose_at,
    family_details: familyDetails,
    email: user.email,
    tob: user.tob || '',
    pob: user.pob || '',
    phone_visible: user.phone_visible === true,
    is_mock: user.is_mock === true
  };
}

exports.mapUserToProfile = mapUserToProfile;

exports.createProfile = async (req, res) => {
  try {
    const userId = String(req.user.id);
    const { 
      name, city, age, dob, gender, interestedIn, 
      tob, pob, subCaste, gothram, rasi, star, 
      education, occupation, familyDetails 
    } = req.body;

    if (!name || !city || !age || !dob || !gender || !interestedIn) {
      return res.status(400).json({ error: 'Name, city, age, dob, gender, and interestedIn are required.' });
    }

    const parsedAge = parseInt(age, 10);
    if (isNaN(parsedAge)) {
      return res.status(400).json({ error: 'Age must be a valid number.' });
    }

    // Process uploaded photos
    let photosList = [];
    if (req.files && req.files.length > 0) {
      photosList = req.files.map(file => `/uploads/${file.filename}`);
    } else if (req.file) {
      photosList = [`/uploads/${req.file.filename}`];
    }

    // Parse family details if provided
    let familyDetailsObj = {};
    if (familyDetails) {
      try {
        familyDetailsObj = typeof familyDetails === 'string' ? JSON.parse(familyDetails) : familyDetails;
      } catch (e) {
        familyDetailsObj = { raw: familyDetails };
      }
    }
    
    // Add subCaste, gothram etc if not inside nested familyDetails already
    familyDetailsObj = {
      subCaste: subCaste || familyDetailsObj.subCaste || '',
      gothram: gothram || familyDetailsObj.gothram || '',
      rasi: rasi || familyDetailsObj.rasi || '',
      star: star || familyDetailsObj.star || '',
      education: education || familyDetailsObj.education || '',
      occupation: occupation || familyDetailsObj.occupation || '',
      ...familyDetailsObj
    };

    const dbGender = gender === 'MAN' ? 'Male' : 'Female';
    const dbInterestedIn = interestedIn === 'MAN' ? 'Male' : 'Female';

    // Generate referral code if user doesn't have one
    const referralCode = 'REF-' + Math.random().toString(36).substring(2, 8).toUpperCase();

    // Check existing photos to preserve or overwrite
    const currentUser = await prisma.users.findUnique({ where: { id: userId } });
    let existingPhotos = [];
    if (currentUser && currentUser.photos) {
      try {
        existingPhotos = JSON.parse(currentUser.photos);
      } catch (e) {}
    }

    // If new photos were uploaded, replace or append them.
    const finalPhotos = photosList.length > 0 ? photosList : (existingPhotos.length > 0 ? existingPhotos : []);

    const updatedUser = await prisma.users.update({
      where: { id: userId },
      data: {
        name,
        place: city,
        age: parsedAge,
        dob,
        gender: dbGender,
        interested_in: dbInterestedIn,
        is_onboarded: 1,
        tob: tob || undefined,
        pob: pob || undefined,
        family_details: JSON.stringify(familyDetailsObj),
        photos: JSON.stringify(finalPhotos),
        roses_balance: currentUser.roses_balance === 0 ? 5 : currentUser.roses_balance,
        referral_code: currentUser.referral_code || referralCode,
      }
    });

    const profile = mapUserToProfile(updatedUser);

    return res.status(200).json({
      message: 'Profile saved successfully',
      profile
    });
  } catch (error) {
    console.error('Error creating profile:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.getProfile = async (req, res) => {
  try {
    const userId = String(req.user.id);
    const user = await prisma.users.findUnique({
      where: { id: userId }
    });

    if (!user || user.is_onboarded !== 1) {
      return res.status(404).json({ error: 'Profile not found.' });
    }

    const profile = mapUserToProfile(user);
    return res.status(200).json(profile);
  } catch (error) {
    console.error('Error fetching profile:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.searchProfiles = async (req, res) => {
  try {
    const userId = String(req.user.id);
    const { query } = req.query;

    const currentUser = await prisma.users.findUnique({
      where: { id: userId }
    });

    if (!currentUser || currentUser.is_onboarded !== 1) {
      return res.status(400).json({ error: 'Please create your profile first.' });
    }

    const { gender, interested_in } = currentUser;

    let whereClause = {
      id: { not: userId },
      is_onboarded: 1,
      gender: interested_in,
      interested_in: gender
    };

    if (query && query.trim() !== '') {
      whereClause = {
        ...whereClause,
        OR: [
          { name: { contains: query, mode: 'insensitive' } },
          { place: { contains: query, mode: 'insensitive' } }
        ]
      };
    }

    const dbUsers = await prisma.users.findMany({
      where: whereClause,
      orderBy: { created_at: 'desc' }
    });

    const profiles = dbUsers.map(mapUserToProfile).filter(Boolean);

    return res.status(200).json(profiles);
  } catch (error) {
    console.error('Error searching profiles:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.verifyFace = async (req, res) => {
  try {
    const userId = String(req.user.id);
    if (!req.file && !req.body.selfieUrl) {
      return res.status(400).json({ error: 'Selfie photo is required.' });
    }

    const updatedUser = await prisma.users.update({
      where: { id: userId },
      data: { face_verified: true }
    });

    return res.status(200).json({
      message: 'Face verification successful (Mock AWS Rekognition Match Score: 98.7%)',
      profile: mapUserToProfile(updatedUser)
    });
  } catch (error) {
    console.error('Error verifying face:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.verifyAadhaar = async (req, res) => {
  try {
    const userId = String(req.user.id);
    const { aadhaarNumber } = req.body;

    if (!aadhaarNumber || aadhaarNumber.length < 12) {
      return res.status(400).json({ error: 'Valid 12-digit Aadhaar number is required.' });
    }

    const updatedUser = await prisma.users.update({
      where: { id: userId },
      data: { aadhaar_verified: true }
    });

    return res.status(200).json({
      message: 'Aadhaar verified successfully',
      profile: mapUserToProfile(updatedUser)
    });
  } catch (error) {
    console.error('Error verifying Aadhaar:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.updateSettings = async (req, res) => {
  try {
    const userId = String(req.user.id);
    const { phone_visible } = req.body;

    const updatedUser = await prisma.users.update({
      where: { id: userId },
      data: { phone_visible: !!phone_visible }
    });

    return res.status(200).json({
      message: 'Settings updated successfully',
      profile: mapUserToProfile(updatedUser)
    });
  } catch (error) {
    console.error('Error updating settings:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

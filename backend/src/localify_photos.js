const prisma = require('./db');

async function main() {
  console.log('Fetching all users in Render database to localify photos...');
  const users = await prisma.users.findMany();

  let femaleIndex = 0;
  let maleIndex = 0;

  const femalePhotos = [
    '/uploads/photo-pooja.png',
    '/uploads/photo-priya.png'
  ];

  const malePhotos = [
    '/uploads/photo-rahul.png',
    '/uploads/photo-amit.png'
  ];

  for (const user of users) {
    let needsUpdate = false;
    let photoUrl = '';

    // Check if the user has photos field
    if (user.photos) {
      try {
        const photosList = JSON.parse(user.photos);
        if (Array.isArray(photosList) && photosList.length > 0) {
          photoUrl = photosList[0];
        }
      } catch (e) {
        if (typeof user.photos === 'string') {
          photoUrl = user.photos;
        }
      }
    }

    // If there is no photo, or it is a remote Unsplash/Render URL, replace it
    if (!photoUrl || photoUrl.startsWith('http')) {
      needsUpdate = true;
      if (user.gender === 'Female') {
        photoUrl = femalePhotos[femaleIndex % femalePhotos.length];
        femaleIndex++;
      } else {
        photoUrl = malePhotos[maleIndex % malePhotos.length];
        maleIndex++;
      }
    }

    if (needsUpdate) {
      await prisma.users.update({
        where: { id: user.id },
        data: {
          photos: JSON.stringify([photoUrl])
        }
      });
      console.log(`Updated user ${user.name} (${user.gender}) with local photo: ${photoUrl}`);
    }
  }

  console.log('Localification of photos completed successfully.');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

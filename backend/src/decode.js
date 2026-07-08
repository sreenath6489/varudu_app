const fs = require('fs');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const user = await prisma.users.findFirst({ where: { name: 'Sreenath' } });
  if (!user || !user.photos) {
    console.log('No user found');
    return;
  }
  const photos = JSON.parse(user.photos);
  const data = photos[0];
  if (data.startsWith('data:image')) {
    const base64Data = data.split(',')[1];
    fs.writeFileSync('/Users/sreenath/.gemini/antigravity-ide/brain/ab67884a-9d5e-4cd5-ab95-37b36866080f/decoded_sreenath.jpg', Buffer.from(base64Data, 'base64'));
    console.log('Saved decoded image to artifacts!');
  } else {
    console.log('Photo is not base64');
  }
}

main().finally(() => prisma.$disconnect());

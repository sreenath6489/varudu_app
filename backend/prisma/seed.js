const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Seeding profiles...');

  const mockUsers = [
    {
      email: 'pooja@example.com',
      profile: {
        name: 'Pooja',
        city: 'Vijayawada',
        age: 21,
        dob: new Date('2005-04-12'),
        gender: 'WOMAN',
        interestedIn: 'MAN',
        photoUrl: '/uploads/photo-pooja.png'
      }
    },
    {
      email: 'rahul@example.com',
      profile: {
        name: 'Rahul',
        city: 'Hyderabad',
        age: 24,
        dob: new Date('2002-08-15'),
        gender: 'MAN',
        interestedIn: 'WOMAN',
        photoUrl: '/uploads/photo-rahul.png'
      }
    },
    {
      email: 'priya@example.com',
      profile: {
        name: 'Priya',
        city: 'Bangalore',
        age: 23,
        dob: new Date('2003-01-20'),
        gender: 'WOMAN',
        interestedIn: 'MAN',
        photoUrl: '/uploads/photo-priya.png'
      }
    },
    {
      email: 'amit@example.com',
      profile: {
        name: 'Amit',
        city: 'Mumbai',
        age: 26,
        dob: new Date('2000-11-05'),
        gender: 'MAN',
        interestedIn: 'WOMAN',
        photoUrl: '/uploads/photo-amit.png'
      }
    }
  ];

  for (const u of mockUsers) {
    const user = await prisma.user.upsert({
      where: { email: u.email },
      update: {},
      create: {
        email: u.email,
        profile: {
          create: u.profile
        }
      }
    });
    console.log(`Created user ${user.email} with profile ${u.profile.name}`);
  }

  console.log('Seeding finished successfully.');
}

main()
  .catch((e) => {
    console.error('Error seeding data:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

const prisma = require('./db');

async function main() {
  console.log('Querying count of users by is_onboarded...');
  const counts = await prisma.users.groupBy({
    by: ['is_onboarded'],
    _count: {
      id: true
    }
  });
  console.log('Counts:', JSON.stringify(counts, null, 2));

  console.log('Querying first 5 users in database...');
  const users = await prisma.users.findMany({
    take: 5,
    select: {
      id: true,
      name: true,
      gender: true,
      interested_in: true,
      is_onboarded: true,
      photos: true
    }
  });
  console.log('Users:', JSON.stringify(users, null, 2));
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

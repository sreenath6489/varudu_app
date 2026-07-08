const prisma = require('./db');

async function main() {
  console.log('Querying user Shruthi...');
  const user = await prisma.users.findFirst({
    where: {
      name: 'Shruthi'
    }
  });
  console.log('User Shruthi:', JSON.stringify(user, null, 2));
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

import { resetDatabase } from './reset-dev-database';

export async function resetToFreshApp() {
  await resetDatabase();
}

if (require.main === module) {
  resetToFreshApp()
    .catch((err) => {
      console.error('❌ Reset failed:', err);
      process.exit(1);
    });
}

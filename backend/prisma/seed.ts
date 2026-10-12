/// <reference types="node" />
import { resetDatabase } from '../src/scripts/reset-dev-database';

async function main() {
  await resetDatabase();
}

main()
  .catch((e) => {
    console.error('❌ Error during database seed / reset:', e);
    process.exit(1);
  });

import { exec } from 'child_process';
import { logger } from '../logger/logger';

let adbWatcherTimer: NodeJS.Timeout | null = null;

export function setupAdbReverse(port: number = 5000): void {
  exec('adb devices', (err, stdout) => {
    if (err || !stdout) return;

    const lines = stdout.split('\n');
    const deviceIds: string[] = [];
    for (let i = 1; i < lines.length; i++) {
      const parts = lines[i].trim().split(/\s+/);
      if (parts.length >= 2 && parts[1] === 'device') {
        deviceIds.push(parts[0]);
      }
    }

    if (deviceIds.length === 0) return;

    for (const devId of deviceIds) {
      exec(`adb -s ${devId} reverse tcp:${port} tcp:${port}`, (revErr) => {
        if (!revErr) {
          logger.info(`🔌 [ADB] Port ${port} reversed for device ${devId}`);
        }
      });
    }
  });
}

export function startAdbWatcher(port: number = 5000, intervalMs: number = 10000): void {
  if (adbWatcherTimer) return;
  setupAdbReverse(port);
  adbWatcherTimer = setInterval(() => {
    setupAdbReverse(port);
  }, intervalMs);
  if (adbWatcherTimer.unref) {
    adbWatcherTimer.unref();
  }
}

export function stopAdbWatcher(): void {
  if (adbWatcherTimer) {
    clearInterval(adbWatcherTimer);
    adbWatcherTimer = null;
  }
}

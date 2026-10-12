const { exec } = require('child_process');

function reverseAdb(port = process.env.PORT || 5000) {
  exec('adb devices', (err, stdout) => {
    if (err || !stdout) {
      return;
    }

    const lines = stdout.split('\n');
    const deviceIds = [];
    for (let i = 1; i < lines.length; i++) {
      const parts = lines[i].trim().split(/\s+/);
      if (parts.length >= 2 && parts[1] === 'device') {
        deviceIds.push(parts[0]);
      }
    }

    if (deviceIds.length === 0) {
      console.log('ℹ️  [ADB] No Android devices currently connected.');
      return;
    }

    for (const devId of deviceIds) {
      exec(`adb -s ${devId} reverse tcp:${port} tcp:${port}`, (revErr) => {
        if (!revErr) {
          console.log(`✅ [ADB] Reversed tcp:${port} on device ${devId}`);
        } else {
          console.warn(`⚠️  [ADB] Failed to reverse on ${devId}: ${revErr.message}`);
        }
      });
    }
  });
}

if (require.main === module) {
  reverseAdb();
}

module.exports = { reverseAdb };

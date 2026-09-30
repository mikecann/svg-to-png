import { afterEach, describe, expect, test } from 'bun:test';
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync, readlinkSync } from 'fs';
import { tmpdir } from 'os';
import { join, resolve } from 'path';

const repo = resolve(import.meta.dir, '..');
const temporaryDirs: string[] = [];
function tempDir() {
  const dir = mkdtempSync(join(tmpdir(), 'svg-to-png test '));
  temporaryDirs.push(dir);
  return dir;
}
afterEach(() => {
  for (const dir of temporaryDirs.splice(0)) rmSync(dir, { recursive: true, force: true });
});
function run(args: string[], cwd: string, command = [process.execPath, join(repo, 'svg-to-png.ts')]) {
  return Bun.spawnSync([...command, ...args], { cwd });
}
function svg(width: number, height: number) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}"><rect width="100%" height="100%" fill="red"/></svg>`;
}
function pngSize(path: string) {
  const png = readFileSync(path);
  // Read the actual PNG header, not the CLI's reported dimensions.
  expect(png.subarray(0, 8)).toEqual(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
  expect(png.toString('ascii', 12, 16)).toBe('IHDR');
  return [png.readUInt32BE(16), png.readUInt32BE(20)];
}

describe('standalone CLI', () => {
  test.each([
    [100, 100, 2048, 2048],
    [100, 200, 2048, 4096],
    [800, 600, 2731, 2048],
    [3000, 4000, 3000, 4000],
  ])('renders %i x %i at %i x %i', (width, height, outWidth, outHeight) => {
    const dir = tempDir();
    writeFileSync(join(dir, 'my logo.svg'), svg(width, height));
    const result = run(['my logo.svg'], dir);
    expect(result.exitCode).toBe(0);
    expect(pngSize(join(dir, 'my logo.png'))).toEqual([outWidth, outHeight]);
    expect(readFileSync(join(dir, 'my logo.svg'), 'utf8')).toBe(svg(width, height));
  });

  test('rejects missing input without producing output', () => {
    const dir = tempDir();
    for (const args of [[], ['missing.svg']]) {
      const result = run(args, dir);
      expect(result.exitCode).toBe(1);
      expect(result.stderr.toString()).toContain('File not found');
    }
  });

  test('rejects invalid SVG data', () => {
    const dir = tempDir();
    writeFileSync(join(dir, 'bad.svg'), 'not SVG');
    expect(run(['bad.svg'], dir).exitCode).not.toBe(0);
    expect(existsSync(join(dir, 'bad.png'))).toBe(false);
  });

  test('replaces an existing PNG beside the SVG', () => {
    const dir = tempDir();
    writeFileSync(join(dir, 'logo.svg'), svg(2048, 2048));
    writeFileSync(join(dir, 'logo.png'), 'old output');
    expect(run(['logo.svg'], dir).exitCode).toBe(0);
    expect(pngSize(join(dir, 'logo.png'))).toEqual([2048, 2048]);
  });
});

// Windows has its own stub and Explorer integration; this exercises the POSIX installer.
test.skipIf(process.platform === 'win32')('installs a reusable symlink and runs from another directory', () => {
  const dir = tempDir();
  const bin = join(dir, 'bin with spaces');
  for (let i = 0; i < 2; i++) {
    expect(run([join(repo, 'install.sh'), bin, '--skip-deps'], dir, ['bash']).exitCode).toBe(0);
    expect(readlinkSync(join(bin, 'svg-to-png'))).toBe(join(repo, 'svg-to-png'));
  }
  writeFileSync(join(dir, 'logo.svg'), svg(2048, 2048));
  expect(run(['logo.svg'], dir, [join(bin, 'svg-to-png')]).exitCode).toBe(0);
  expect(pngSize(join(dir, 'logo.png'))).toEqual([2048, 2048]);
});

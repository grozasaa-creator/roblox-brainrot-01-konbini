// Konbini Brainrot — entry for make.fun roblox-brainrot-01 (Node 22, standard library only).
// The game is this folder's Rojo project: `rojo build default.project.json --output game.rbxl`.
// Running this file stages the submission into the output directory:
//   game.rbxl, PLAY.json, src/, screenshots/  ->  <out>/   plus  <out>/dossier.json (the judge's summary).
// Output names must be letters, digits, . _ - only and must not start with a dot, so dotfiles are skipped.
//
// Local run, standing in for the grader's /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const root = fileURLToPath(new URL('.', import.meta.url));
const outDir = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

const skipDotNames = (p: string): boolean => !basename(p).startsWith('.');

function stage(): void {
  mkdirSync(outDir, { recursive: true });
  for (const f of ['game.rbxl', 'PLAY.json']) {
    copyFileSync(join(root, f), join(outDir, f));
  }
  cpSync(join(root, 'src'), join(outDir, 'src'), { recursive: true, filter: skipDotNames });
  mkdirSync(join(outDir, 'screenshots'), { recursive: true });
  const shots = join(root, 'screenshots');
  if (existsSync(shots)) {
    cpSync(shots, join(outDir, 'screenshots'), { recursive: true, filter: skipDotNames });
  }
}

stage();

const caps = {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 262144 },
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
};
writeFileSync(join(outDir, 'dossier.json'), buildDossier(outDir, caps));

#!/usr/bin/env node
// Validates a Fluctseed track plan.md file against the phased task schema:
// 1. H1 title present
// 2. Throughput Checkpoint section present
// 3. At least one "## Phase" heading present
// 4. Valid task checkboxes (- [ ], - [~], - [x]) with no malformed checkbox markers
// 5. Phase Verification & Checkpoint task present

import { readFileSync } from "node:fs";

const file = process.argv[2];
if (!file) {
  console.error("Usage: node check-plan.mjs <plan.md>");
  process.exit(2);
}

let text;
try {
  text = readFileSync(file, "utf8");
} catch (err) {
  console.error(`${file}: cannot read file (${err.message})`);
  process.exit(2);
}

const lines = text.split(/\r?\n/);
const problems = [];

const fail = (lineNo, msg) => problems.push(`${file}:${lineNo}: ${msg}`);

let hasH1 = false;
let hasThroughput = false;
let phaseCount = 0;
let taskCount = 0;
let checkpointTaskCount = 0;
let inFence = false;

for (let i = 0; i < lines.length; i++) {
  const n = i + 1;
  const line = lines[i];

  if (/^```/.test(line.trim())) {
    inFence = !inFence;
    continue;
  }
  if (inFence) continue;

  if (/^#\s+\S+/.test(line)) hasH1 = true;
  if (/^#{2,3}\s+.*Throughput Checkpoint/i.test(line)) hasThroughput = true;
  if (/^##\s+Phase\b/i.test(line)) {
    phaseCount++;
    const tags = [...line.matchAll(/\[([^\]]+)\]/g)].map((m) => m[1].trim());
    for (const tag of tags) {
      if (tag !== "human-gate" && !/^checkpoint:\s*`?[0-9a-f]{7,40}`?$/i.test(tag)) {
        fail(
          n,
          `invalid phase heading tag '[${tag}]' (expected '[human-gate]' or '[checkpoint: <sha>]')`
        );
      }
    }
  }

  const bulletBracket = line.match(/^\s*-\s*\[([^\]]*)\](.*)$/);
  if (bulletBracket) {
    const marker = bulletBracket[1];
    const rest = bulletBracket[2];
    if (![" ", "~", "x", "X"].includes(marker)) {
      fail(n, `invalid checkbox marker '[${marker}]' (expected '[ ]', '[~]', or '[x]')`);
    } else if (!/^\s+\S+/.test(rest)) {
      fail(n, "empty task description after checkbox");
    } else {
      taskCount++;
      if (/Phase Verification|Checkpoint/i.test(rest)) checkpointTaskCount++;
    }
  }
}

if (!hasH1) fail(1, "missing H1 title ('# ...')");
if (!hasThroughput) fail(1, "missing 'Throughput Checkpoint' section");
if (phaseCount === 0) fail(1, "missing '## Phase ...' section");
if (taskCount === 0) fail(1, "no checkbox tasks ('- [ ] ...') found");
if (checkpointTaskCount === 0) fail(1, "missing Phase Verification & Checkpoint task");

if (problems.length > 0) {
  for (const p of problems) console.error(p);
  console.log(`${phaseCount} phase(s), ${taskCount} task(s), ${problems.length} problem(s)`);
  process.exit(1);
}

console.log(`${phaseCount} phase(s), ${taskCount} task(s), 0 problems`);
process.exit(0);

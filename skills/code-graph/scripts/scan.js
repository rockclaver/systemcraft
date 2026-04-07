#!/usr/bin/env node
/**
 * scan.js — Code graph scanner
 *
 * Extracts file structure, exports, local imports, and entry points using
 * grep + filesystem reads. No AI tokens spent. Outputs a draft codegraph.md
 * with Purpose fields left as "???" for the agent to fill in.
 *
 * Usage:
 *   node scan.js                        # full scan
 *   node scan.js --since abc1234        # only files changed since commit
 *   node scan.js --dir ./src            # scan a subdirectory
 *
 * Output: writes to stdout → redirect to .claude/codegraph.draft.md
 */

import { execSync } from 'child_process';
import { readFileSync, existsSync, mkdirSync } from 'fs';
import { resolve, relative, extname, dirname } from 'path';

// ── Config ────────────────────────────────────────────────────────────────────

const EXCLUDE_DIRS = [
  'node_modules', '.git', 'dist', 'build', 'out', 'coverage',
  '.next', '.nuxt', '.svelte-kit', '__pycache__', '.venv', 'venv',
  '.cache', 'tmp', 'temp',
];

const SOURCE_EXTENSIONS = new Set([
  '.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs',
  '.py', '.go', '.rs', '.java', '.rb', '.php',
]);

const CONFIG_EXTENSIONS = new Set([
  '.json', '.yaml', '.yml', '.toml', '.env', '.prisma', '.graphql', '.sql',
]);

// Entry point filename patterns
const ENTRY_PATTERNS = [
  /^(index|main|app|server|worker|cli|start)\.(ts|js|mjs|py|go)$/i,
];

// Export grep patterns by file extension
const EXPORT_PATTERNS = {
  ts: [
    /^export\s+(default\s+)?(async\s+)?(function|class|const|let|var|type|interface|enum)\s+(\w+)/,
    /^export\s+default\s+(\w+)/,
    /^export\s+\{([^}]+)\}/,
  ],
  js: [
    /^export\s+(default\s+)?(async\s+)?(function|class|const|let|var)\s+(\w+)/,
    /^module\.exports\s*=/,
    /^exports\.(\w+)\s*=/,
  ],
  py: [
    /^def\s+(\w+)\s*\(/,
    /^class\s+(\w+)/,
    /^(\w+)\s*=\s*/,
  ],
  go: [
    /^func\s+(\w+)/,
    /^type\s+(\w+)/,
    /^var\s+(\w+)/,
    /^const\s+(\w+)/,
  ],
};

// Local import patterns by extension
const IMPORT_PATTERNS = {
  ts: /from\s+['"](\.[^'"]+)['"]/g,
  js: /(?:require\(['"]|from\s+['"])(\.[^'"]+)['"]/g,
  py: /^from\s+\.(\S+)\s+import|^import\s+\.(\S+)/gm,
  go: /^\s+"\.\/([^"]+)"/gm,
};

// ── Args ──────────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const sinceCommit = args.includes('--since') ? args[args.indexOf('--since') + 1] : null;
const rootDir = resolve(args.includes('--dir') ? args[args.indexOf('--dir') + 1] : '.');

// ── Helpers ───────────────────────────────────────────────────────────────────

function run(cmd, opts = {}) {
  try {
    return execSync(cmd, { encoding: 'utf8', cwd: rootDir, ...opts }).trim();
  } catch {
    return '';
  }
}

function getChangedFiles(since) {
  return run(`git diff --name-only ${since}...HEAD`)
    .split('\n')
    .filter(Boolean)
    .map(f => resolve(rootDir, f));
}

function discoverFiles() {
  const excludeArgs = EXCLUDE_DIRS.map(d => `--exclude-dir=${d}`).join(' ');
  const extensions = [...SOURCE_EXTENSIONS, ...CONFIG_EXTENSIONS]
    .map(e => e.slice(1))
    .join(',');

  // Use find for file discovery — fast and no token cost
  const findExcludes = EXCLUDE_DIRS.map(d => `-not -path '*/${d}/*'`).join(' ');
  const result = run(
    `find . -type f \\( ${[...SOURCE_EXTENSIONS, ...CONFIG_EXTENSIONS]
      .map(e => `-name "*${e}"`)
      .join(' -o ')} \\) ${findExcludes} | sort`
  );

  return result.split('\n').filter(Boolean).map(f => resolve(rootDir, f.replace(/^\.\//, '')));
}

function extractExports(filePath) {
  const ext = extname(filePath).slice(1);
  const lang = ext === 'tsx' ? 'ts' : ext === 'jsx' ? 'js' : ext;
  const patterns = EXPORT_PATTERNS[lang];
  if (!patterns) return [];

  const exports = new Set();

  // Use grep to extract export lines — no full file read
  const grepPattern = lang === 'ts' || lang === 'js'
    ? '^export'
    : lang === 'py'
    ? '^def \\|^class '
    : '^func \\|^type \\|^var \\|^const ';

  const lines = run(`grep -n "${grepPattern}" "${filePath}" 2>/dev/null`);
  if (!lines) return [];

  for (const line of lines.split('\n')) {
    for (const pattern of patterns) {
      const match = line.match(pattern);
      if (match) {
        // Extract the exported name(s)
        const name = match[4] || match[1];
        if (name) {
          // Handle named export lists: export { foo, bar }
          if (name.includes(',')) {
            name.split(',').map(n => n.trim()).filter(Boolean).forEach(n => exports.add(n));
          } else {
            exports.add(name.trim());
          }
        } else if (line.includes('module.exports')) {
          exports.add('(default export)');
        }
        break;
      }
    }
  }

  return [...exports].slice(0, 12); // cap at 12 to keep graph compact
}

function extractLocalImports(filePath) {
  const ext = extname(filePath).slice(1);
  const lang = ext === 'tsx' ? 'ts' : ext === 'jsx' ? 'js' : ext;

  // grep for relative imports only
  const grepPattern = lang === 'ts' || lang === 'js'
    ? "from ['\"]\\."
    : lang === 'py'
    ? "^from \\."
    : '"\\./';

  const lines = run(`grep -o "${grepPattern}[^'\"]*" "${filePath}" 2>/dev/null`);
  if (!lines) return [];

  const imports = new Set();
  const pattern = IMPORT_PATTERNS[lang];
  if (!pattern) return [];

  const content = lines;
  let match;
  const re = new RegExp(pattern.source, pattern.flags);
  while ((match = re.exec(content)) !== null) {
    const dep = (match[1] || match[2] || '').split('/').pop();
    if (dep) imports.add(dep);
  }

  return [...imports].slice(0, 8);
}

function findUsedBy(filePath, allFiles) {
  const name = filePath.split('/').pop().replace(/\.[^.]+$/, '');
  // grep across all source files for imports of this filename
  const excludeArgs = EXCLUDE_DIRS.map(d => `--exclude-dir=${d}`).join(' ');
  const result = run(
    `grep -rl "${name}" ${rootDir}/src 2>/dev/null ${excludeArgs} || grep -rl "${name}" ${rootDir} --include="*.ts" --include="*.js" --include="*.py" ${excludeArgs} 2>/dev/null`
  );
  if (!result) return 0;
  const count = result.split('\n').filter(f => f && f !== filePath).length;
  return count;
}

function isEntryPoint(filePath) {
  const name = filePath.split('/').pop();
  return ENTRY_PATTERNS.some(p => p.test(name));
}

function detectLanguage() {
  if (existsSync(resolve(rootDir, 'package.json'))) return 'js/ts';
  if (existsSync(resolve(rootDir, 'go.mod'))) return 'go';
  if (existsSync(resolve(rootDir, 'requirements.txt')) || existsSync(resolve(rootDir, 'pyproject.toml'))) return 'python';
  if (existsSync(resolve(rootDir, 'Cargo.toml'))) return 'rust';
  return 'unknown';
}

function groupByFolder(files) {
  const groups = {};
  for (const f of files) {
    const rel = relative(rootDir, f);
    const folder = rel.includes('/') ? rel.split('/').slice(0, 2).join('/') : '.';
    if (!groups[folder]) groups[folder] = [];
    groups[folder].push(rel);
  }
  return groups;
}

// ── Main ──────────────────────────────────────────────────────────────────────

const currentCommit = run('git rev-parse --short HEAD') || 'unknown';
const currentDate = new Date().toISOString().split('T')[0];
const lang = detectLanguage();

let files = discoverFiles();

if (sinceCommit) {
  const changed = getChangedFiles(sinceCommit);
  files = files.filter(f => changed.includes(f));
  process.stderr.write(`Partial scan: ${files.length} changed files since ${sinceCommit}\n`);
} else {
  process.stderr.write(`Full scan: ${files.length} files found\n`);
}

const sourceFiles = files.filter(f => SOURCE_EXTENSIONS.has(extname(f)));
const configFiles = files.filter(f => CONFIG_EXTENSIONS.has(extname(f)));
const entryPoints = sourceFiles.filter(isEntryPoint);

// Build nodes
const nodes = [];
for (const f of sourceFiles) {
  const rel = relative(rootDir, f);
  const exports = extractExports(f);
  const imports = extractLocalImports(f);
  const usedByCount = findUsedBy(f, sourceFiles);
  nodes.push({ path: rel, exports, imports, usedByCount, isEntry: isEntryPoint(f) });
}

// ── Output ────────────────────────────────────────────────────────────────────

const lines = [];

lines.push(`# Code Graph`);
lines.push(`> Commit: ${currentCommit} | Date: ${currentDate} | Files: ${sourceFiles.length} | Lang: ${lang}`);
lines.push(`> Status: DRAFT — agent must fill in Purpose fields marked "???"`);
lines.push('');

// Architecture placeholder
lines.push(`## Architecture Overview`);
lines.push(`> ???  (agent: write 3-5 sentences describing what this app does and how the layers connect)`);
lines.push('');

// Entry points
if (entryPoints.length > 0) {
  lines.push(`## Entry Points`);
  lines.push('');
  lines.push('| File | Purpose |');
  lines.push('|---|---|');
  for (const ep of entryPoints) {
    const rel = relative(rootDir, ep);
    lines.push(`| \`${rel}\` | ??? |`);
  }
  lines.push('');
}

// Module index grouped by folder
const grouped = groupByFolder(sourceFiles);
const USE_FOLDER_SUMMARIES = sourceFiles.length > 60;

lines.push(`## Module Index`);
lines.push('');

for (const [folder, folderFiles] of Object.entries(grouped).sort()) {
  lines.push(`### ${folder}/`);

  if (USE_FOLDER_SUMMARIES) {
    // Large repo: one line per folder
    const allExports = folderFiles
      .flatMap(f => nodes.find(n => n.path.endsWith(f.split('/').pop()))?.exports || [])
      .slice(0, 8)
      .join(', ');
    lines.push(`> ??? (${folderFiles.length} files — exports include: ${allExports || 'see files'})`);
    lines.push('');
    continue;
  }

  lines.push('');
  lines.push('| File | Purpose | Key Exports | Used by |');
  lines.push('|---|---|---|---|');

  for (const filePath of folderFiles.sort()) {
    const rel = relative(rootDir, filePath);
    const node = nodes.find(n => n.path === rel);
    if (!node) continue;

    const fileName = rel.split('/').pop();
    const exportsStr = node.exports.length > 0
      ? node.exports.join(', ')
      : '—';
    const usedBy = node.usedByCount > 0 ? `${node.usedByCount} file(s)` : '—';

    lines.push(`| \`${fileName}\` | ??? | ${exportsStr} | ${usedBy} |`);
  }

  lines.push('');
}

// Config / low-signal files
if (configFiles.length > 0) {
  lines.push(`## Config & Schema Files`);
  lines.push('');
  for (const f of configFiles) {
    lines.push(`- \`${relative(rootDir, f)}\``);
  }
  lines.push('');
}

// Staleness footer
lines.push(`---`);
lines.push(`_Regenerate: \`node <skill-dir>/scripts/scan.js > .claude/codegraph.draft.md\`_`);

process.stdout.write(lines.join('\n') + '\n');
process.stderr.write(`Done. Draft written. Agent should fill in ??? fields.\n`);

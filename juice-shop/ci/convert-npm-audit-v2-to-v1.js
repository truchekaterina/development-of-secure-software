#!/usr/bin/env node
'use strict';

const fs = require('fs');

const inputPath = process.argv[2] || 'npm-audit-raw.json';
const outputPath = process.argv[3] || 'npm-audit.json';

const rawText = fs.readFileSync(inputPath, 'utf8').replace(/^\uFEFF/, '');
const raw = JSON.parse(rawText);

if (raw.error) {
  fs.writeFileSync(outputPath, JSON.stringify(raw));
  process.exit(0);
}

if (!raw.auditReportVersion || raw.auditReportVersion < 2) {
  fs.writeFileSync(outputPath, JSON.stringify(raw));
  process.exit(0);
}

const advisories = {};

function addFinding(advisory, version, paths) {
  if (!paths.length) {
    return;
  }
  const existing = advisory.findings.find((f) => f.version === version);
  if (existing) {
    for (const p of paths) {
      if (!existing.paths.includes(p)) {
        existing.paths.push(p);
      }
    }
    return;
  }
  advisory.findings.push({ version, paths: [...paths] });
}

function ensureAdvisory(via, vuln) {
  const id = String(via.source);
  if (!advisories[id]) {
    advisories[id] = {
      id: via.source,
      module_name: via.name || vuln.name,
      title: via.title || `${via.name} vulnerability`,
      severity: via.severity || vuln.severity || 'moderate',
      url: via.url || '',
      cwe: via.cwe || [],
      access: 'public',
      overview: via.title || via.url || 'Imported from npm audit v2 report',
      recommendation: 'Review npm audit output and upgrade affected packages.',
      vulnerable_versions: via.range || vuln.range || '*',
      patched_versions: 'See npm audit recommendation',
      findings: [],
      cves: [],
    };
    const cveMatch = (via.title || '').match(/CVE-\d{4}-\d+/);
    if (cveMatch) {
      advisories[id].cves.push(cveMatch[0]);
    }
  }
  return advisories[id];
}

for (const vuln of Object.values(raw.vulnerabilities || {})) {
  const paths = (vuln.nodes || []).map((n) => n.replace(/^node_modules\//, ''));
  const version = '0.0.0';

  for (const via of vuln.via || []) {
    if (typeof via === 'string') {
      continue;
    }
    const advisory = ensureAdvisory(via, vuln);
    addFinding(advisory, version, paths.length ? paths : [vuln.name]);
  }
}

const converted = {
  actions: raw.actions || [],
  advisories,
  muted: raw.muted || [],
  metadata: raw.metadata || {},
};

if (!Object.keys(advisories).length) {
  console.error('ERROR: no advisories extracted from npm audit v2 report');
  process.exit(1);
}

fs.writeFileSync(outputPath, JSON.stringify(converted));
console.log(`Converted ${Object.keys(advisories).length} advisories for DefectDojo NPM Audit Scan`);

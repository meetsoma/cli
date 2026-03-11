/**
 * Soma Content CLI — standalone, no core dependencies
 * Handles: soma content install|list, soma init --template
 */
import { existsSync, mkdirSync, writeFileSync, readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";

const REPO = "meetsoma/community";
const BRANCH = "main";
const RAW_BASE = `https://raw.githubusercontent.com/${REPO}/${BRANCH}`;
const API_BASE = `https://api.github.com/repos/${REPO}`;
const SOMA_DIR = ".soma";
const VALID_TYPES = ["protocol", "muscle", "skill", "template"];

async function fetchText(url) {
	const res = await fetch(url, { headers: { "User-Agent": "soma-cli" } });
	if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
	return res.text();
}

async function fetchJson(url) {
	const res = await fetch(url, {
		headers: { "Accept": "application/vnd.github.v3+json", "User-Agent": "soma-cli" },
	});
	if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
	return res.json();
}

function findSomaDir(cwd) {
	let dir = cwd;
	while (true) {
		const somaPath = join(dir, SOMA_DIR);
		if (existsSync(somaPath)) return somaPath;
		const parent = join(dir, "..");
		if (parent === dir) return null;
		dir = parent;
	}
}

function targetDir(somaPath, type) {
	const map = { protocol: "protocols", muscle: "memory/muscles", skill: "skills", template: "templates" };
	return join(somaPath, map[type]);
}

function remoteDir(type) {
	return type === "protocol" ? "protocols" : type === "muscle" ? "muscles" : type === "skill" ? "skills" : "templates";
}

async function installItem(somaPath, type, name, force = false) {
	if (type === "template") return installTemplate(somaPath, name, force);

	const dir = targetDir(somaPath, type);
	const localPath = join(dir, `${name}.md`);

	if (existsSync(localPath) && !force) {
		return { ok: false, error: `Already exists. Use --force to overwrite.`, path: localPath };
	}

	try {
		const content = await fetchText(`${RAW_BASE}/${remoteDir(type)}/${name}.md`);
		mkdirSync(dir, { recursive: true });
		writeFileSync(localPath, content, "utf-8");
		return { ok: true, path: localPath };
	} catch (err) {
		return { ok: false, error: err.message.includes("404") ? `Not found in hub: ${name}` : err.message };
	}
}

async function installTemplate(somaPath, name, force) {
	let manifest;
	try {
		manifest = JSON.parse(await fetchText(`${RAW_BASE}/templates/${name}/template.json`));
	} catch {
		return { ok: false, error: `Template manifest not found: ${name}` };
	}

	// Identity
	try {
		const identity = await fetchText(`${RAW_BASE}/templates/${name}/identity.md`);
		const p = join(somaPath, "identity.md");
		if (!existsSync(p) || force) writeFileSync(p, identity, "utf-8");
	} catch {}

	// Settings
	try {
		const settings = await fetchText(`${RAW_BASE}/templates/${name}/settings.json`);
		const p = join(somaPath, "settings.json");
		if (!existsSync(p) || force) {
			writeFileSync(p, settings, "utf-8");
		} else {
			const existing = JSON.parse(readFileSync(p, "utf-8"));
			const merged = { ...JSON.parse(settings), ...existing };
			writeFileSync(p, JSON.stringify(merged, null, 2), "utf-8");
		}
	} catch {}

	// Dependencies
	const deps = [];
	const requires = manifest.requires || {};
	for (const type of ["protocol", "muscle", "skill"]) {
		for (const depName of (requires[type + "s"] || [])) {
			const r = await installItem(somaPath, type, depName, force);
			deps.push({ type, name: depName, ...r });
		}
	}

	const allOk = deps.every(d => d.ok || d.error?.includes("Already exists"));
	return { ok: allOk, deps, error: allOk ? undefined : "Some dependencies failed" };
}

function printUsage() {
	console.log(`
Usage:
  soma content install <type> <name> [--force]
  soma content list [--remote] [--local] [--type <type>]

Types: protocol, muscle, skill, template

Examples:
  soma content install protocol breath-cycle
  soma content install template architect --force
  soma content list --remote
  soma content list --local --type protocol
  soma init --template devops
`);
}

export async function handleContentCommand(args) {
	// soma init --template <name>
	if (args[0] === "init" && args.includes("--template")) {
		const idx = args.indexOf("--template");
		const name = args[idx + 1];
		if (!name) { console.error("Error: --template requires a name"); return true; }

		const cwd = process.cwd();
		const somaPath = join(cwd, SOMA_DIR);
		mkdirSync(join(somaPath, "protocols"), { recursive: true });
		mkdirSync(join(somaPath, "memory", "muscles"), { recursive: true });
		mkdirSync(join(somaPath, "skills"), { recursive: true });
		mkdirSync(join(somaPath, "extensions"), { recursive: true });

		console.log(`Initializing Soma with template: ${name}...`);
		const r = await installTemplate(somaPath, name, args.includes("--force"));
		if (r.ok) {
			console.log(`✓ Initialized with template "${name}"`);
			for (const d of (r.deps || [])) {
				console.log(`  ${d.ok ? "✓" : d.error?.includes("Already") ? "·" : "✗"} ${d.type}: ${d.name}`);
			}
			console.log(`\nRun \`soma\` to start your agent session.`);
		} else {
			console.error(`✗ Template "${name}" failed: ${r.error}`);
		}
		return true;
	}

	if (args[0] !== "content") return false;
	const sub = args[1];

	if (!sub || sub === "help" || sub === "--help") { printUsage(); return true; }

	if (sub === "install") {
		const type = args[2], name = args[3];
		if (!type || !name) { console.error("Error: soma content install <type> <name>"); return true; }
		if (!VALID_TYPES.includes(type)) { console.error(`Error: invalid type "${type}". Use: ${VALID_TYPES.join(", ")}`); return true; }

		const cwd = process.cwd();
		let somaPath = findSomaDir(cwd);
		if (!somaPath) {
			somaPath = join(cwd, SOMA_DIR);
			mkdirSync(join(somaPath, "protocols"), { recursive: true });
			mkdirSync(join(somaPath, "memory", "muscles"), { recursive: true });
			console.log(`Created ${SOMA_DIR}/`);
		}

		console.log(`Installing ${type}: ${name}...`);
		const r = await installItem(somaPath, type, name, args.includes("--force"));
		if (r.ok) {
			console.log(`✓ Installed ${type} "${name}" → ${r.path}`);
			for (const d of (r.deps || [])) {
				console.log(`  ${d.ok ? "✓" : "·"} ${d.type}: ${d.name}`);
			}
		} else {
			console.error(`✗ Failed: ${r.error}`);
		}
		return true;
	}

	if (sub === "list") {
		const isRemote = args.includes("--remote");
		const isLocal = args.includes("--local");
		const typeIdx = args.indexOf("--type");
		const typeFilter = typeIdx >= 0 ? args[typeIdx + 1] : undefined;
		if (typeFilter && !VALID_TYPES.includes(typeFilter)) {
			console.error(`Error: invalid type. Use: ${VALID_TYPES.join(", ")}`);
			return true;
		}

		const showRemote = isRemote || !isLocal;
		const showLocal = isLocal || !isRemote;

		if (showLocal) {
			const somaPath = findSomaDir(process.cwd());
			if (somaPath) {
				console.log(`\n📁 Local (${somaPath}):`);
				const types = typeFilter ? [typeFilter] : VALID_TYPES;
				let found = false;
				for (const t of types) {
					const dir = targetDir(somaPath, t);
					if (!existsSync(dir)) continue;
					const entries = readdirSync(dir).filter(e => !e.startsWith("."));
					if (entries.length) {
						found = true;
						console.log(`  ${t}s:`);
						for (const e of entries) console.log(`    · ${e.replace(/\.md$/, "")}`);
					}
				}
				if (!found) console.log("  (none)");
			} else if (isLocal) {
				console.log("\nNo .soma/ found.");
			}
		}

		if (showRemote) {
			console.log(`\n🌐 Hub (meetsoma/community):`);
			const types = typeFilter ? [typeFilter] : VALID_TYPES;
			try {
				for (const t of types) {
					let entries;
					try { entries = await fetchJson(`${API_BASE}/contents/${remoteDir(t)}?ref=${BRANCH}`); } catch { continue; }
					if (!Array.isArray(entries)) continue;
					const items = entries.filter(e => e.name !== "README.md" && e.name !== ".gitkeep");
					if (items.length) {
						console.log(`  ${t}s:`);
						for (const e of items) console.log(`    · ${e.name.replace(/\.md$/, "")}`);
					}
				}
			} catch (err) {
				console.error(`  Error: ${err.message}`);
			}
		}
		console.log();
		return true;
	}

	console.error(`Unknown: soma content ${sub}`);
	printUsage();
	return true;
}

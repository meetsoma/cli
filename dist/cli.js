#!/usr/bin/env node
/**
 * CLI entry point for Soma (meetsoma).
 *
 * Uses Pi's main.ts with AgentSession and new mode modules.
 * Supports auto-rotation: when an extension writes .soma/.rotate-signal
 * and triggers shutdown, we re-exec the process for a fresh session.
 *
 * Test with: npx tsx src/cli-new.ts [args...]
 */
process.title = "soma";
// Soma has its own versioning — skip Pi's upstream version check
// which compares Soma 0.1.0 against pi-coding-agent 0.57.1 on npm
process.env.PI_SKIP_VERSION_CHECK = "1";
import { setBedrockProviderModule } from "@mariozechner/pi-ai";
import { bedrockProviderModule } from "@mariozechner/pi-ai/bedrock-provider";
import { EnvHttpProxyAgent, setGlobalDispatcher } from "undici";
import { main } from "./main.js";
import { handleContentCommand } from "./content-cli.js";
import { existsSync, unlinkSync, readFileSync } from "fs";
import { join } from "path";
import { execFileSync } from "child_process";
setGlobalDispatcher(new EnvHttpProxyAgent());
setBedrockProviderModule(bedrockProviderModule);

// ── Auto-rotation support ──────────────────────────────────────────────
// When auto-breathe triggers rotation but no command context is available
// (Pi only exposes newSession() in command handlers), the extension writes
// .soma/.rotate-signal and calls ctx.shutdown(). Pi's shutdown calls
// process.exit(0). We intercept that exit to check for the rotation signal
// and re-exec if found — giving the user a seamless fresh session.
//
// The re-exec spawns a NEW process via execFileSync (stdio: inherit),
// which blocks the parent until the child exits. This means each rotation
// adds one level of process nesting. SOMA_ROTATION_DEPTH limits this to
// prevent runaway loops (default: 5).
// ────────────────────────────────────────────────────────────────────────
const MAX_ROTATIONS = parseInt(process.env.SOMA_MAX_ROTATIONS || "5", 10);
const currentDepth = parseInt(process.env.SOMA_ROTATION_DEPTH || "0", 10);

const _realExit = process.exit;
process.exit = function somaRotationExit(code) {
	if (code === 0 && currentDepth < MAX_ROTATIONS) {
		try {
			const signal = join(process.cwd(), ".soma", ".rotate-signal");
			if (existsSync(signal)) {
				// Read signal metadata (optional — for logging)
				let meta = {};
				try { meta = JSON.parse(readFileSync(signal, "utf-8")); } catch {}
				unlinkSync(signal);

				// Log rotation
				const reason = meta.reason || "auto-breathe";
				process.stderr.write(`\n🫧 Rotating session (${reason})...\n\n`);

				// Re-exec with incremented depth counter
				try {
					execFileSync(process.execPath, process.argv.slice(1), {
						stdio: "inherit",
						env: {
							...process.env,
							SOMA_ROTATION_DEPTH: String(currentDepth + 1),
						},
					});
				} catch {
					// Child exited non-zero — that's fine, we still exit cleanly
				}

				_realExit.call(process, 0);
				return;
			}
		} catch {
			// Signal check failed — fall through to normal exit
		}
	}
	_realExit.call(process, code);
};

// ── Command dispatch ───────────────────────────────────────────────────
const args = process.argv.slice(2);

// Version flag
if (args[0] === "--version" || args[0] === "-V" || args[0] === "-v") {
	const { readFileSync: rf } = await import("fs");
	const { fileURLToPath } = await import("url");
	const { dirname, join: j } = await import("path");
	const __dirname = dirname(fileURLToPath(import.meta.url));
	const pkg = JSON.parse(rf(j(__dirname, "..", "package.json"), "utf-8"));
	console.log(`soma v${pkg.version}`);
	process.exit(0);
}

if (args[0] === "content" || args[0] === "install" || args[0] === "list" || args[0] === "init") {
	handleContentCommand(args).then(handled => {
		if (!handled) main(args);
	}).catch(err => {
		console.error("Soma content error:", err.message);
		process.exit(1);
	});
} else {
	main(args);
}
//# sourceMappingURL=cli.js.map

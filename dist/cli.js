#!/usr/bin/env node
/**
 * CLI entry point for the refactored coding agent.
 * Uses main.ts with AgentSession and new mode modules.
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
setGlobalDispatcher(new EnvHttpProxyAgent());
setBedrockProviderModule(bedrockProviderModule);

// Intercept Soma content commands before pi's main()
const args = process.argv.slice(2);
if (args[0] === "content" || (args[0] === "init" && args.includes("--template"))) {
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
"use strict";

/*
	Generates default.project.json from the contents of src/.

	src/network/Foo.luau              -> ReplicatedStorage.Network.Foo
	src/modules/Foo.luau              -> ReplicatedStorage.Shared.Modules.Foo
	src/services/Foo/Client.luau      -> ReplicatedStorage.Shared.Services.Foo.FooClient
	src/services/Foo/Server.luau      -> ServerScriptService.Services.Foo.FooServer
	src/services/Foo/Utils.luau       -> ReplicatedStorage.Shared.Services.Foo.FooUtils
	any folder with init.luau         -> the folder itself becomes the ModuleScript (Rojo handles its children)

	A file is treated as server code only when it is named exactly "Server".
	(The old substring check sent files like "Observer.luau" to ServerScriptService.)
*/

const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..");
const BASE_PATH = path.join(ROOT, "src");
const OUTPUT_PATH = path.join(ROOT, "default.project.json");

const PROJECT_NAME = "ObjectAbuse";

const SPECIAL_FILE_NAMES = ["server", "client", "utils", "types"];

const BLACKLISTED_DIRS = [
	toPosix(path.join(BASE_PATH, "ui")),
	toPosix(path.join(BASE_PATH, "startup")),
];

function toPosix(p) {
	return p.split(path.sep).join("/");
}

function toPascalCase(str) {
	return str.charAt(0).toUpperCase() + str.slice(1);
}

// Creates the folder node if needed and returns it.
function ensureFolder(parent, name) {
	if (!parent[name]) {
		parent[name] = { $className: "Folder" };
	}

	return parent[name];
}

// Adds a leaf node and refuses to silently overwrite an existing one.
function addLeaf(parent, name, node, source) {
	if (parent[name] !== undefined) {
		throw new Error(`Duplicate Rojo node "${name}" while adding ${source}`);
	}

	parent[name] = node;
}

// True if any folder between BASE_PATH and the file (excluding the file itself) contains init.luau.
// Rojo already maps those folders as a single ModuleScript, so their other files must not be added again.
function isInsideInitFolder(filepath) {
	let dir = path.dirname(filepath);

	while (dir.length > BASE_PATH.length) {
		const initFile = path.join(dir, "init.luau");

		if (fs.existsSync(initFile) && initFile !== filepath) {
			return true;
		}

		dir = path.dirname(dir);
	}

	return false;
}

function getVirtualPath(filepath) {
	const relativePath = path.relative(BASE_PATH, filepath);
	const parts = relativePath.split(path.sep);

	const filename = path.basename(filepath, ".luau");
	const filenameLower = filename.toLowerCase();

	const isServer = filenameLower === "server";

	const folderName =
		parts.length > 1 ? toPascalCase(parts[parts.length - 2]) : "";

	let name;

	if (filename === "init") {
		name = folderName;
	} else if (SPECIAL_FILE_NAMES.includes(filenameLower)) {
		name = folderName + toPascalCase(filename);
	} else {
		name = filename;
	}

	return {
		isInit: filename === "init",
		isNetwork: parts[0]?.toLowerCase() === "network",

		target: isServer ? "ServerScriptService" : "ReplicatedStorage",

		folder: parts.slice(0, -1).map(toPascalCase),

		name,

		file:
			filename === "init"
				? toPosix(path.join("src", ...parts.slice(0, -1)))
				: toPosix(path.join("src", ...parts)),
	};
}

const tree = {
	name: PROJECT_NAME,

	tree: {
		$className: "DataModel",

		ReplicatedStorage: {
			Shared: {
				$className: "Folder",

				Services: { $className: "Folder" },
				Classes: { $className: "Folder" },
				Modules: { $className: "Folder" },
			},

			Network: { $className: "Folder" },

			// Models live here (put them in Studio or sync an .rbxm). Rojo must not delete
			// them, and the folders must exist so services can fail with a clear message.
			Assets: {
				$className: "Folder",
				$ignoreUnknownInstances: true,
				Objects: {
					$className: "Folder",
					$ignoreUnknownInstances: true,
				},
			},

			Packages: { $path: "Packages" },

			UI: { $path: "src/ui" },
		},

		ServerScriptService: {
			Server: { $path: "src/startup/Server.server.luau" },

			Services: { $className: "Folder" },
			Classes: { $className: "Folder" },
			Modules: { $className: "Folder" },
		},

		StarterPlayer: {
			StarterPlayerScripts: {
				Client: { $path: "src/startup/Client.client.luau" },
			},
		},
	},
};

const sharedRoot = tree.tree.ReplicatedStorage.Shared;
const networkRoot = tree.tree.ReplicatedStorage.Network;
const serverRoot = tree.tree.ServerScriptService;

// Recursively walk all files (sorted, so the output is identical on every OS).
function walk(dir, callback) {
	if (BLACKLISTED_DIRS.includes(toPosix(dir))) {
		return;
	}

	const entries = fs
		.readdirSync(dir, { withFileTypes: true })
		.sort((a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0));

	for (const entry of entries) {
		const full = path.join(dir, entry.name);

		if (entry.isDirectory()) {
			walk(full, callback);
		} else if (entry.isFile() && entry.name.endsWith(".luau")) {
			callback(full);
		}
	}
}

walk(BASE_PATH, (filepath) => {
	const source = toPosix(path.relative(ROOT, filepath));

	// An empty ModuleScript errors on require ("did not return exactly one value"), so keep it out.
	if (fs.statSync(filepath).size === 0) {
		console.warn(`⚠️  Skipping empty file: ${source}`);
		return;
	}

	if (isInsideInitFolder(filepath)) {
		return;
	}

	const { target, folder, name, file, isInit, isNetwork } =
		getVirtualPath(filepath);

	// NETWORK: src/network/Foo.luau -> ReplicatedStorage.Network.Foo
	if (isNetwork) {
		const relativePath = path.relative(path.join(BASE_PATH, "network"), filepath);
		const networkParts = relativePath.split(path.sep);
		const filename = path.basename(filepath, ".luau");

		let current = networkRoot;

		for (let i = 0; i < networkParts.length - 1; i++) {
			current = ensureFolder(current, toPascalCase(networkParts[i]));
		}

		addLeaf(current, filename, { $path: file }, source);
		return;
	}

	// SERVER / SHARED
	const root = target === "ServerScriptService" ? serverRoot : sharedRoot;

	if (isInit) {
		const parent = folder.slice(0, -1).reduce(ensureFolder, root);
		addLeaf(parent, name, { $path: file }, source);
		return;
	}

	let current = root;

	for (const part of folder) {
		current = ensureFolder(current, part);
	}

	addLeaf(current, name, { $path: file }, source);
});

fs.writeFileSync(OUTPUT_PATH, JSON.stringify(tree, null, 2) + "\n");

console.log("✅ default.project.json generated.");

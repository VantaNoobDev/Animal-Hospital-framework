--!strict
--!native

type Enums = {
	read Colors: { [string]: Color3 },
	read CommonDialogues: { string },
}

const DialogueEnums: Enums = {
	Colors = {
		cs = Color3.fromRGB(0, 255, 255),
		rs = Color3.fromRGB(255, 0, 0),
		gs = Color3.fromRGB(0, 255, 0),
		bs = Color3.fromRGB(0, 0, 255),
		ys = Color3.fromRGB(255, 255, 0),
		ps = Color3.fromRGB(170, 0, 255),
	},

	CommonDialogues = {
		"Hello, i am %s.",
	},
}

table.freeze(DialogueEnums.Colors)
table.freeze(DialogueEnums.CommonDialogues)
table.freeze(DialogueEnums)

return DialogueEnums

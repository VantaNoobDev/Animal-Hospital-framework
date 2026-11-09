--!strict
--!native

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const DialogueEnums = require(ReplicatedStorage.UI:WaitForChild("Enums"):WaitForChild("DialogueEnums"))

const DialogueMarkup = {}

const function EscapeRichText(Text: string): string
	return (Text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

function DialogueMarkup.Format(Text: string): string
	return (
		Text:gsub(
			"_(%a+)_([^_]+)_%a+_",
			(
					function(ColorName: string, Content: string): string
						const Color = DialogueEnums.Colors[ColorName]
						if not Color then
							return string.format("_%s_%s_%s_", ColorName, Content, ColorName)
						end

						return string.format(
							'<font color="rgb(%d,%d,%d)">%s</font>',
							math.round(Color.R * 255),
							math.round(Color.G * 255),
							math.round(Color.B * 255),
							EscapeRichText(Content)
						)
					end
				) :: any
		)
	)
end

return DialogueMarkup

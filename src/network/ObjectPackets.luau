--!strict
--!native

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const ByteNetMax = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ByteNetMax"))

--[[
	Direction of each packet:
		SpawnObject         server -> client   a new object exists
		UpdateObject        server -> client   health changed / object broke
		RemoveObject        server -> client   object was despawned
		InteractWithObject  client -> server   player used an object (server validates ownership + rate limit)
]]

return table.freeze(ByteNetMax.defineNamespace("Objects", function()
	return {
		packets = {
			SpawnObject = ByteNetMax.definePacket({
				value = ByteNetMax.struct({
					Id = ByteNetMax.uint32,
					Name = ByteNetMax.string,
					Pivot = ByteNetMax.cframe,
					Health = ByteNetMax.float32,
				}),
			}),

			UpdateObject = ByteNetMax.definePacket({
				value = ByteNetMax.struct({
					Id = ByteNetMax.uint32,
					Health = ByteNetMax.float32,
					Broken = ByteNetMax.bool,
				}),
			}),

			RemoveObject = ByteNetMax.definePacket({
				value = ByteNetMax.uint32,
			}),

			InteractWithObject = ByteNetMax.definePacket({
				value = ByteNetMax.uint32,
			}),
		},
	}
end))

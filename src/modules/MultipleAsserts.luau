--!strict
--!native

return function(Asserts: { any }, Message: string)
	for _, Assert in Asserts do
		assert(Assert, Message)
	end
end

-- No strict mode here because require(Target) errors, looks ugly and annoys me. --
--!native

--// Constants
const DEFAULT_TIMEOUT = 10

const RequireUtil = {}

--// Path helpers
-- Waits for each name in Path under Root. Errors with the full path if anything is missing.
function RequireUtil.WaitForPath(Root: Instance, Path: { string }, TimeOut: number?): Instance
	local Current = Root

	for _, Name in Path do
		const Child = Current:WaitForChild(Name, TimeOut or DEFAULT_TIMEOUT)
		assert(Child, `Missing instance "{Name}" under {Current:GetFullName()}`)
		Current = Child
	end

	return Current
end

-- WaitForPath + require, with a clear error if the target isn't a ModuleScript.
function RequireUtil.Require(Root: Instance, Path: { string }, TimeOut: number?): any
	const Target = RequireUtil.WaitForPath(Root, Path, TimeOut)
	assert(Target:IsA("ModuleScript"), `{Target:GetFullName()} is a {Target.ClassName}, expected ModuleScript`)

	return require(Target)
end

-- Calling the module directly still works, so existing `RequireUtil(Root, Path)` code isn't broken.
return table.freeze(setmetatable(RequireUtil, {
	__call = function(_, Root: Instance, Path: { string }, TimeOut: number?): Instance
		return RequireUtil.WaitForPath(Root, Path, TimeOut)
	end,
}))

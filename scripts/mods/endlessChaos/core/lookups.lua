-- Runs on: ALL (deterministic). Every NetworkLookup addition the mod makes goes through here.
--
-- NetworkLookup entries are sent over the wire as indices. Every peer must add the same keys in
-- the same order, or indices drift and RPCs carry the wrong (or nil) ids, which crashes clients.
-- Keep all registrations at mod load, in a fixed order (arrays, never pairs()).
-- The fingerprint lets the host verify that every peer ended up with identical indices.
local mod = get_mod("endlessChaos")

local Lookups = {}

local _registered = {}
local _registered_set = {}

-- Appends `key` to NetworkLookup[table_name] if missing and returns its index.
-- Idempotent, so VMF hot reloads don't append duplicates.
function Lookups.add(table_name, key)
	local lookup = rawget(NetworkLookup, table_name)

	fassert(lookup, "[endlessChaos] NetworkLookup.%s does not exist", tostring(table_name))

	-- NetworkLookup tables error on unknown keys through __index, so always use rawget.
	local index = rawget(lookup, key)

	if not index then
		index = #lookup + 1
		lookup[index] = key
		lookup[key] = index
	end

	local id = table_name .. ":" .. key

	if not _registered_set[id] then
		_registered_set[id] = true
		_registered[#_registered + 1] = {
			table_name,
			key,
		}
	end

	return index
end

-- Hash over every (table, key, index) the mod registered. Two peers with the same mod version
-- but a different mod load order can still end up with different indices; this catches that.
function Lookups.fingerprint()
	local parts = {}

	for i = 1, #_registered do
		local entry = _registered[i]
		local table_name, key = entry[1], entry[2]
		local index = rawget(NetworkLookup[table_name], key)

		parts[i] = table_name .. ":" .. key .. "=" .. tostring(index)
	end

	local hash = HashUtils.fnv32_hash(table.concat(parts, ";"))

	return tostring(math.floor(hash))
end

function Lookups.registered()
	return _registered
end

return Lookups

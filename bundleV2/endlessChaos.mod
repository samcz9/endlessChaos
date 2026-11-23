return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Risk of Rats` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("endlessChaos", {
			mod_script       = "scripts/mods/endlessChaos/endlessChaos",
			mod_data         = "scripts/mods/endlessChaos/endlessChaos_data",
			mod_localization = "scripts/mods/endlessChaos/endlessChaos_localization",
		})
	end,
	packages = {
		"resource_packages/endlessChaos/endlessChaos",
	},
}

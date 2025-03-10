local tier = 1
local real_suffix = "-mk" .. tier
local suffix = (tier > 1) and real_suffix or ""

local F = "__aai-vehicles-miner__"
local animation_speed = 60

local shuffle = function(n, v)
	local variance = (math.random() - 0.5) * v
	return math.min(math.max(n + variance, 0), 1)
end

local names = require("__Mining_Drones__/shared")
local drone_name = names.drone_name
local shared = require("__Mining_Drones__/shared")

local items = data.raw.item
local tools = data.raw.tool
local get_item = function(name)
	if items[name] then
		return items[name]
	end
	if tools[name] then
		return tools[name]
	end
end

local sound = {
	filename = "__base__/sound/fight/tank-engine.ogg",
	volume = 0.2,
}
local sound_enabled = not settings.startup.mute_drones.value
local working_sound = sound_enabled
		and {
			aggregation = {
				max_count = 2,
				remove = true,
			},
			variations = sound,
		}
	or nil
local mining_sound = sound_enabled
	and {
		aggregation = {
			max_count = 3,
			remove = true,
		},
		variations = {
			filename = "__base__/sound/walking/dirt-02.ogg",
			volume = 0.4,
		},
		{
			filename = "__base__/sound/walking/dirt-03.ogg",
			volume = 0.4,
		},
		{
			filename = "__base__/sound/walking/dirt-04.ogg",
			volume = 0.4,
		},
	}

local walking_sound = nil

local scale = 0.5 * 0.7

local animation = function(tint)
	local anim = {
		layers = {
			{
				width = 2024 / 8,
				height = 1744 / 8,
				frame_count = 2,
				direction_count = 64,
				scale = scale,
				shift = { 0.0 * scale, -0.88125 * scale },
				animation_speed = animation_speed,
				max_advance = 1,
				priority = "low",
				stripes = {
					{
						filename = F .. "/graphics/entity/miner/miner" .. real_suffix .. "-main-b.png",
						width_in_frames = 8,
						height_in_frames = 8,
					},
					{
						filename = F .. "/graphics/entity/miner/miner" .. real_suffix .. "-main-a.png",
						width_in_frames = 8,
						height_in_frames = 8,
					},
				},
			},
			{
				width = 2024 / 8,
				height = 1744 / 8,
				frame_count = 2,
				apply_runtime_tint = false,
				tint = tint,
				direction_count = 64,
				scale = scale,
				shift = { 0.0 * scale, -0.88125 * scale },
				animation_speed = animation_speed,
				max_advance = 1,
				priority = "low",
				line_length = 8,
				stripes = {
					{
						filename = F .. "/graphics/entity/miner/miner" .. real_suffix .. "-mask-b.png",
						width_in_frames = 8,
						height_in_frames = 8,
					},
					{
						filename = F .. "/graphics/entity/miner/miner" .. real_suffix .. "-mask-a.png",
						width_in_frames = 8,
						height_in_frames = 8,
					},
				},
			},
			{
				width = 2048 / 8,
				height = 1344 / 8,
				frame_count = 2,
				draw_as_shadow = true,
				direction_count = 64,
				shift = { 0.9 * scale, 0.15 * scale },
				animation_speed = animation_speed,
				max_advance = 1,
				priority = "low",
				scale = 4448 / 2 / 2048 * scale, -- shadow was downscaled to fit in 2048
				stripes = {
					{
						filename = F .. "/graphics/entity/miner/miner" .. real_suffix .. "-shadow-b.png",
						width_in_frames = 8,
						height_in_frames = 8,
					},
					{
						filename = F .. "/graphics/entity/miner/miner" .. real_suffix .. "-shadow-a.png",
						width_in_frames = 8,
						height_in_frames = 8,
					},
				},
			},
		},
	}
	return anim
end

local retex_drone = function(name, tint)
	local r, g, b = tint.r or tint[1], tint.g or tint[2], tint.b or tint[3]

	if r > 1 or g > 1 or b > 1 then
		r = r / 255
		g = g / 255
		b = b / 255
	end

	local mask_tint = { r ^ 2, g ^ 2, b ^ 2, shuffle(0.5, 0.5) }

	--assert(data.raw.unit[name], "failed "..name)
	if data.raw.unit[name] then
		data.raw.unit[name].attack_parameters.animation = animation(tint)
		data.raw.unit[name].run_animation = animation(tint)
		data.raw.unit[name].walking_sound = walking_sound
		data.raw.unit[name].working_sound = working_sound
		data.raw.unit[name].icon = F .. "/graphics/icons/miner" .. suffix .. ".png"
		data.raw.unit[name].icon_size = 64
		--data.raw.unit[name].icons_mipmaps = 1
		local newcorpse = util.copy(data.raw["corpse"]["small-remnants"])

		newcorpse.name = name .. "-corpse"
		newcorpse.selectable_in_game = false
		newcorpse.selection_box = nil
		newcorpse.render_layer = "remnants"
		newcorpse.order = "zzz-" .. name
	end
end

retex_drone(drone_name, { r = 1, g = 1, b = 1, a = 0.5 })
data.raw.item[drone_name].icon = F .. "/graphics/icons/miner" .. suffix .. ".png"
data.raw.item[drone_name].icon_size = 64

local recipe = data.raw.recipe[drone_name]
if settings.startup["md-aai-recipe-change"].value then
	recipe.ingredients = {
		{ type = "item", name = "iron-plate", amount = 10 },
		{ type = "item", name = "iron-gear-wheel", amount = 5 },
		{ type = "item", name = "engine-unit", amount = 1 },
	}
end

local retex_depot_recipe = function(resource, item_prototype)
	if not item_prototype then
		return
	end
	local item_name = item_prototype.name
	local map_color = resource.map_color or { r = 0.869, g = 0.5, b = 0.130, a = 0.5 }

	for k = 1, shared.variation_count do
		retex_drone(resource.name .. shared.drone_name .. k, map_color)
	end
end

local resound_proxy = function(resource)
	local proxy_name = shared.attack_proxy_name .. resource.name
	if data.raw.unit[proxy_name] then
		if data.raw.unit[proxy_name].damaged_trigger_effect then
			local _, effect = next(data.raw.unit[proxy_name].damaged_trigger_effect)
			if effect and effect.sound then
				effect.sound = mining_sound
			end
		end
	end
end

local is_stupid = function(entity)
	--Thanks NPE and dectorio!
	return entity.name:find("wreck") or entity.name:find("dect")
end

local retex_recipes = function(resource)
	if not resource.minable then
		return
	end
	if is_stupid(resource) then
		return
	end

	if resource.minable.result then
		local name = resource.minable.result or resource.minable.result[1]
		retex_depot_recipe(resource, get_item(name))
	end

	if resource.minable.results then
		for k, result in pairs(resource.minable.results) do
			local name = result.name or result[1]
			retex_depot_recipe(resource, get_item(name))
		end
	end
end

for k, resource in pairs(data.raw.resource) do
	if resource.minable and (resource.minable.result or resource.minable.results) then
		retex_recipes(resource)
		if sound_enabled then
			resound_proxy(resource)
		end
	end
end

-- MathModule

--// SERVICES 

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// VARIABLES 

const TROOP_MODEL: Model = ReplicatedStorage.TroopModel
const CANNON_MODEL: Model = ReplicatedStorage.CannonModel

const INFO = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

const OFFSETS = {
	[1] = {
		{0, 0}
	},

	[2] = {
		{0.5, 0},
		{-0.5, 0}
	},

	[3] = {
		{0, 0.433},
		{0.5, -0.433},
		{-0.5, -0.433}
	},

	-- ...
}

--// FUNCTIONS

local function _GetVector(vector2: {number, number}): Vector3
	return Vector3.new(vector2[1], 0, vector2[2])
end

local function _TweenModel(model: Model, target: CFrame)
	local value = Instance.new("CFrameValue")
	value.Value = model:GetPivot()

	local connection = value:GetPropertyChangedSignal("Value"):Connect(function()
		if model.Parent then
			model:PivotTo(value.Value)
		end
	end)

	local tween = TweenService:Create(value, INFO, {
		Value = target
	})

	tween.Completed:Once(function()
		connection:Disconnect()
		value:Destroy()
	end)

	tween:Play()
end

local function _RemoveModel(model: Model)
	local value = Instance.new("CFrameValue")
	value.Value = model:GetPivot()

	local connection = value:GetPropertyChangedSignal("Value"):Connect(function()
		if model.Parent then
			model:PivotTo(value.Value)
		end
	end)

	local tween = TweenService:Create(value, INFO, {
		Value = value.Value * CFrame.new(0, -5, 0)
	})

	tween.Completed:Once(function()
		connection:Disconnect()
		value:Destroy()

		if model.Parent then
			model:Destroy()
		end
	end)

	tween:Play()
end

local function _CreateModel(
	tile: Model,
	is_cannon: boolean,
	index: number
): Model

	local model: Model

	if is_cannon then
		model = CANNON_MODEL:Clone()
	else
		model = TROOP_MODEL:Clone()
	end

	model.Name = tostring(index)
	model.Parent = tile.Troops

	-- Spawn the model slightly above the center first.
	-- It will then tween to its actual position.
	model:PivotTo(
		CFrame.new(
			tile.CENTER.Position + Vector3.new(0, 1, 0)
		)
	)

	return model
end

--// MODULE

local MathModule = {}

function MathModule.TweenTroops(tile: Model, old_amount: number, new_amount: number)

	if old_amount == new_amount then
		return
	end

	-- Instantiating

	local old_cannon_amount: number = math.floor(old_amount / 10)
	local new_cannon_amount: number = math.floor(new_amount / 10)

	local old_troop_amount: number = old_amount % 10
	local new_troop_amount: number = new_amount % 10

	local old_model_amount: number = old_cannon_amount + old_troop_amount
	local new_model_amount: number = new_cannon_amount + new_troop_amount

	local troop_folder: Folder = tile.Troops

	-- OFFSETS is based on the amount of visible models,
	-- not the actual troop amount.
	--
	-- 14 troops = 1 cannon + 4 troops = 5 models
	-- therefore OFFSETS[5]
	local offsets = OFFSETS[new_model_amount]

	assert(
		offsets,
		"Missing OFFSETS[" .. tostring(new_model_amount) .. "]"
	)

	-- Store the current models before changing their names.
	--
	-- Cannons are always the first indices.
	-- Therefore, based on old_amount:
	--
	-- 24 troops:
	-- 1, 2 = cannons
	-- 3, 4, 5, 6 = troops
	--
	-- We can therefore determine the model type
	-- entirely from its current index.

	local old_cannons = {}
	local old_troops = {}

	for i = 1, old_cannon_amount do
		local model = troop_folder:FindFirstChild(tostring(i))

		if model then
			table.insert(old_cannons, model)
		end
	end

	for i = old_cannon_amount + 1, old_model_amount do
		local model = troop_folder:FindFirstChild(tostring(i))

		if model then
			table.insert(old_troops, model)
		end
	end

	-- The amount of existing models we can keep.

	local kept_cannon_amount: number = math.min(
		#old_cannons,
		new_cannon_amount
	)

	local kept_troop_amount: number = math.min(
		#old_troops,
		new_troop_amount
	)

	-- Rename all models that are being removed first.
	--
	-- This prevents duplicate names while the indices are
	-- being reorganized.
	--
	-- Example 24 -> 19:
	--
	-- Old:
	-- 1 = cannon
	-- 2 = cannon
	-- 3-6 = troops
	--
	-- New:
	-- 1 = cannon
	-- 2-10 = troops
	--
	-- Cannon 2 is renamed temporarily and removed.
	-- The old troops can then become indices 2-5.

	for i = kept_cannon_amount + 1, #old_cannons do
		local cannon = old_cannons[i]

		cannon.Name = "Removing_" .. tostring(i)
		_RemoveModel(cannon)
	end

	for i = kept_troop_amount + 1, #old_troops do
		local troop = old_troops[i]

		troop.Name = "Removing_Troop_" .. tostring(i)
		_RemoveModel(troop)
	end

	-- Reassign the existing cannons to the first indices.
	--
	-- Cannons ALWAYS occupy the first indices.

	for i = 1, kept_cannon_amount do
		local cannon = old_cannons[i]

		cannon.Name = tostring(i)
	end

	-- Reassign the existing troops after all cannons.
	--
	-- This is what allows something like:
	--
	-- 24 -> 19
	--
	-- old troop indices 3-6
	-- to become
	-- new troop indices 2-5.

	for i = 1, kept_troop_amount do
		local troop = old_troops[i]

		local new_index = new_cannon_amount + i

		troop.Name = tostring(new_index)
	end

	-- Create missing cannons.

	if kept_cannon_amount < new_cannon_amount then

		for i = kept_cannon_amount + 1, new_cannon_amount do

			_CreateModel(
				tile,
				true,
				i
			)

		end

	end

	-- Create missing troops.

	if kept_troop_amount < new_troop_amount then

		for i = kept_troop_amount + 1, new_troop_amount do

			local index = new_cannon_amount + i

			_CreateModel(
				tile,
				false,
				index
			)

		end

	end

	-- Tweening

	for i = 1, new_model_amount do

		local model = troop_folder:FindFirstChild(tostring(i))

		if model then

			local value = Instance.new(CFrameValue)
			value.Value = model:GetPivot()

			local connection = value:GetPropertyChangedSignal("Value"):Connect(function()
				if model.Parent then
					model:PivotTo(value.Value)
				end
			end)

			local target = CFrame.new(
				_GetVector(offsets[i]) + tile.CENTER.Position
			)

			local tween = TweenService:Create(value, INFO, {
				Value = target
			})

			tween.Completed:Once(function()
				connection:Disconnect()
				value:Destroy()
			end)

			tween:Play()

		end

	end
end

return MathModule

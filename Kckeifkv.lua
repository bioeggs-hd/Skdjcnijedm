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

	local tween = TweenService:Create(value, INFO, {Value = target})
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

local function _CreateModel(tile: Model, is_cannon: boolean, index: number): Model
	local model: Model = is_cannon and CANNON_MODEL:Clone() or TROOP_MODEL:Clone()

	model.Name = tostring(index)
	model.Parent = tile.Troops
	model:PivotTo(CFrame.new(tile.CENTER.Position + Vector3.new(0, -1, 0)))

	return model
end

--// MODULE

local MathModule = {}

function MathModule.TweenTroops(tile: Model, old_amount: number, new_amount: number)
	if old_amount == new_amount then
		return
	end
	
	local old_cannon_amount: number = math.floor(old_amount / 10)
	local new_cannon_amount: number = math.floor(new_amount / 10)
	local old_troop_amount: number = old_amount % 10
	local new_troop_amount: number = new_amount % 10
	local old_model_amount: number = old_cannon_amount + old_troop_amount
	local new_model_amount: number = new_cannon_amount + new_troop_amount
	
	local troop_folder: Folder = tile.Troops
	local offsets = OFFSETS[new_model_amount]
	assert(offsets, "Missing OFFSETS[" .. tostring(new_model_amount) .. "]")

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

	local kept_cannon_amount: number = math.min(#old_cannons, new_cannon_amount)

	local kept_troop_amount: number = math.min(#old_troops, new_troop_amount)

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

	for i = 1, kept_cannon_amount do
		local cannon = old_cannons[i]

		cannon.Name = tostring(i)
	end

	for i = 1, kept_troop_amount do
		local troop = old_troops[i]

		local new_index = new_cannon_amount + i

		troop.Name = tostring(new_index)
	end

	if kept_cannon_amount < new_cannon_amount then
		for i = kept_cannon_amount + 1, new_cannon_amount do
			_CreateModel(tile, true, i)
		end
	end

	if kept_troop_amount < new_troop_amount then
		for i = kept_troop_amount + 1, new_troop_amount do
			local index = new_cannon_amount + i
			_CreateModel(tile, false, index)
		end
	end

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

			local target = CFrame.new(_GetVector(offsets[i]) + tile.CENTER.Position)

			local tween = TweenService:Create(value, INFO, {Value = target})
			tween.Completed:Once(function()
				connection:Disconnect()
				value:Destroy()
			end)
			tween:Play()
		end
	end
end

return MathModule

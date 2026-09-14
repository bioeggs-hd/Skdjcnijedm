-- MathModule

--// SERVICES 

local TweenService = game:GetService("TweenService")

--// VARIABLES 

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

--// MODULE

local MathModule = {}

function MathModule.TweenTroops(tile: Model, old_amount: number, new_amount: number)
  if old_amount == new_amount then
    return
  end
  
  local change: number = new_amount - old_amount
  local troop_folder: Folder = tile.Troops
  if change > 0 then
    for i = 1, change do
      local new_troop: Model = troop_folder:FindFirstChild(tostring(old_amount)):Clone()
      new_troop.Name = tostring(old_amount + i)
    end
  else
    for i = old_amount, new_amount, -1 do
      local troop: Model = troop_folder:FindFirstChild(tostring(i))
      if troop then
        troop:Destroy()
      end
    end
  end
  
  for i = 1, new_amount do
    local troop: Model = troop_folder:FindFirstChild(tostring(i))
    local value = Instance.new(CFrameValue)
    value.Value = troop:GetPivot()
    local connection = value:GetPropertyChangedSignal("Value"):Connect(function()
      if troop.Parent then
        troop:PivotTo(value.Value)
      end
    end)
    local tween = TweenService:Create(value, INFO, {Value = troop:GetPivot() * CFrame.new(_GetVector(OFFSETS[new_amount][i]))})
    tween.Completed:Once(function()
      connection:Disconnect()
      value:Destroy()
    end)
    tween:Play()
  end
end

return MathModule

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
  local change: number = new_amount - old_amount
  local troop_folder: Folder = tile.Troops
  if change > 0 then
    for i = 1, change do
      local new_troop: Model = troop_folder:FindFirstChild(old_amount):Clone()
      new_troop.Name = tostring(old_amount + i)
    end
  else
    for i = old_amount, new_amount, -1 do
      local troop: Model = troop_folder:FindFirstChild(old_amount)
      if troop then
        troop:Destroy()
      end
    end
  end
  local tweens: {Tween} = {}
  for i = 1, new_amount do
    table.insert(tweens, TweenService:Create(troop_folder:FindFirstChild(tostring(i)), INFO, {Position = _GetVector(OFFSETS[i])})
  end
  for _, tween: Tween in tweens do 
    task.spawn(tween.Play)
  end
end

return MathModule

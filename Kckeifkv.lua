-- MathModule

--// VARIABLES 

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

return MathModule

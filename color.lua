-- SXColor.lua - Beckett Dunning 2024 -
-- v. 1.06

-- The Color Space converter converts colors between color spaces (HSI,HSV,HSL,RGB) and also between some experimental formats such as (YCbCr 601 and YCbCr 709). In addition to this, the function can also output and Input Hex strings for Color derivation. The function uses teo sub functions to perform conversions. RGB serves as the transient space, and one function converts colors to RGB while the other converts RGB to the other spaces. The usage description is below:

-- Supported Color Spaces : RGB | HSV / HSB | HSL | HSI | HWB | HSM | HCG | CMY | CMYK | TSL | YUV | YCbCr (601,709,2020) | YCgCo | YDbDr | XYZ | HEX | LAB | LUV | LCHab | LCHuv |

---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 

local abs,acos,cos,sqrt,pi,pow = math.abs , math.acos, math.sqrt, math.cos, math.pi,math.pow 

-- Polyfill math.pow
if not pow then 
  pow = function(val,exp)
    local output = 1
    for i = 1,exp do
      output = output * val
    end    
    return output
  end
end

---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 

---- ---- ---- -- -- ---- ---- ---- -- -- ---- ---- ---- -- -- ---- ---- ---- 

local colorData = { -- holds: Properties / Range Data for colors

  ---- ---- --- -- --- ---- ---- ---- --- -- --- ---- ---- ---- ----
  spaces = { -- data storage: color space properties 

    RGB = { _link = "XYZ", -- RGB (red,green,blue) 
     {"r","red", min = 0, max = 255}, 
     {"g","green", min = 0, max = 255}, 
     {"b","blue", min = 0, max = 255}}, 

    HSV = { _link = "RGB", -- HSV (hue,saturation,value) 
     {"h","hue", min = 0, max = 360}, 
     {"s","saturation", min = 0, max = 100},
     {"v","value", min = 0, max = 100}}, 

    HSB = { _link = "RGB", -- HSB (hue,saturation,brightness) 
     {"h","hue", min = 0, max = 360}, 
     {"s","saturation", min = 0, max = 100}, 
     {"b","brightness", min = 0, max = 100}}, 

    HSL = { _link = "RGB", -- HSL (hue,saturation,lightness)
     {"h","hue", min = 0, max = 360}, 
     {"s","saturation", min = 0, max = 100}, 
     {"l","lightness", min = 0, max = 100}}, 

    HSI = { _link = "RGB", -- HSI (hue,saturation,intensity) 
     {"h","hue", min = 0, max = 360}, 
     {"s","saturation", min = 0, max = 100}, 
     {"i","intensity", min = 0, max = 100}}, 

    HWB = { _link = "RGB", -- HWB (hue,whiteness,blackness) 
     {"h","hue", min = 0, max = 360}, 
     {"w","Whiteness", min = 0, max = 100}, 
     {"b","blackness", min = 0, max = 100}}, 

    HCG = { _link = "RGB", -- HCG (hue,chroma,greyscale)
     {"h","hue", min = 0, max = 360},
     {"c","chroma", min = 0, max = 100}, 
     {"g","greyscale", min = 0, max = 100}}, 

    HSM = { _link = "RGB", -- HCG (hue,saturation,mixture)
     {"h","hue", min = 0, max = 360},
     {"s","saturation", min = 0, max = 100}, 
     {"m","mixture", min = 0, max = 100}}, 
    
    CMY = { _link = "RGB",-- CMY (cyan,magenta,yellow)
     {"c","cyan", min = 0, max = 100},
     {"m","magenta", min = 0, max = 100},
     {"y","yellow", min = 0, max = 100}},

    CMYK = { _link = "RGB", -- CMY (cyan,magenta,yellow,key/black)
     {"c","cyan", min = 0, max = 100},
     {"m","magenta", min = 0, max = 100}, 
     {"y","yellow", min = 0, max = 100},
     {"k","black","key", min = 0, max = 100}},

    XYZ = { _link = "RGB",
     {"x", min = 0, max = 100},
     {"y", min = 0, max = 100},
     {"z", min = 0, max = 100}},

    LAB = { _link = "XYZ",
     {"l","lightness", min = 0, max = 100},
     {"a", min = -100, max = 100},
     {"b", min = -100, max = 100}},

    LUV = { _link = "XYZ",
     {"l","lightness", min = 0, max = 100},
     {"u", min = -134, max = 224},
     {"v", min = -140, max = 122}},

    LCHab = { _link = "LAB",
     {"l","lightness", min = 0, max = 100},
     {"c","chroma", min = 0, max = 100},
     {"h","hue", min = 0, max = 360}},

    LCHuv = { _link = "LUV",
     {"l","lightness", min = 0, max = 100},
     {"c","chroma", min = 0, max = 100},
     {"h","hue", min = 0, max = 360}},

    TSL = { _link = "RGB",
     {"t","tint", min = 0, max = 100},
     {"s","saturation", min = 0, max = 100},
     {"l","lightness", min = 0, max = 100}},

    YCbCr = { _link = "RGB",
     {"y", min = 0, max = 100},
     {"cb", min = -50, max = 50},
     {"cr", min = -50, max = 50}},

    YUV = { _link = "RGB",
     {"y", min = 0, max = 100},
     {"u", min = -43.6, max = 43.6},
     {"v", min = -61.5, max = 61.5}},

    YCgCo = { _link = "RGB",
     {"y", min = 0, max = 100},
     {"cg", min = -50, max = 50},
     {"co", min = -50, max = 50}},

    YDbDr = { _link = "RGB",
     {"y", min = 0, max = 100},
     {"db", min = -133.3, max = 133.3},
     {"dr", min = -133.3, max = 133.3}},

  },

  ---- ---- --- -- --- ---- ---- ---- --- -- --- ---- ---- ---- ----
  extraSpaces = { -- holds: arguments for special color spaces

   YCbCr601 = { _link = "RGB",
    _alias = {"YCC601","YPbPr"},
     {"y", min = 0, max = 100},
     {"cb", min = -50, max = 50},
     {"cr", min = -50, max = 50}},

   YCbCr709 = { _link = "RGB",
    _alias = {"YCC709"},
     {"y", min = 0, max = 100},
     {"cb", min = -50, max = 50},
     {"cr", min = -50, max = 50}},

   YCbCr2020 = { _link = "RGB",
    _alias = {"YCC2020", "YcCbcCrc"},
     {"y", min = 0, max = 100},
     {"cb", min = -50, max = 50},
     {"cr", min = -50, max = 50}},

  },

}


---- ---- --- -- --- ---- ---- ---- --- -- --- ---- ---- ---- ----
------ ----- ----- ----- ----- ----- -----
 -- Color Space Data - Alias Population


local function _populateAlias(lookup)
 local _alias = {} for k,v in pairs(lookup) do 
  if v._alias then local name 
   for i = 1, #v._alias do name = v._alias[i] 
    if type(name) == 'string' then _alias[name] = lookup[k] end 
  end end end

  for k,v in pairs(_alias) do lookup[k] = {} 
   for i = 1, #_alias[k] do lookup[k][i] = v[i] end
   lookup[k]._link = v._link lookup[k]._alias = nil
  
end end 


 ------ ----- ----- ----- ----- ----- -----
  _populateAlias(colorData.spaces) -- populate space aliases
  _populateAlias(colorData.extraSpaces) -- populate extraSpace aliases
 ------ ----- ----- ----- ----- ----- -----


---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- -
-- --- ---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- -----

-- [color object] -- creates: lua color object

---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- -
-- --- ---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- -----

-- New color objects can be created using methods color() or color.new(). The initializers follow:

--   color(255,255,255) -- creates RGB color object
--   color({r = 255, g = 0, b = 255}) -- auto detect color based on properties
--   color("RGB",255,0,255) -- space/model name passed as string       
--   color.RGB(255,0,255) -- indexed space/model creation
--   color.RGB({r = 255, g = 0, b = 255}) -- strict creation

--------------- --------------- --------------- --------------- ---------------

-- Color object properties / methods:

--  .space / .model -- (set) convert to color space | (get) return space description string
--  :to("space") / :convertTo("space") -- convert color to color space 
--  :as("space") -- create a copy of color and convert it to space

-- Properties: All color objects can access their channel properties through their abbreviated or verbose keys.
--  reference names for properties are case insensitive i.e.

--   color.r  color.red  color.Hue  color.V  color.SaTuRaTiOn


---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- -
-- --- ---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- -----

local _oldColor = color -- stores native color data (codea light userdata)

---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
local color = {} -- color object base class
---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----

color.new = color -- reference variable: creates new color object - (color.new() == color())

---- ----- ---- ---- ---- ---- ---- ---- 
-- Utility Functions

-- creates (6 char) hex string
local function _processHEX(inputStr) 
  
  local hex = ""
  if string.find(inputStr,"^[#]?%x%x%x%x%x%x(%x?%x?)$") then
    hex = hexString
  elseif string.find(inputStr,"^[#]?%x%x%x(%x?)$") then for match in string.gmatch(inputStr,".") do
    if match == "#" then hex = hex.."#"
    else hex = hex..match..match end end
    
  return hex end

end

---- ----- ---- ---- ---- ---- ---- ---- 

local color_meta = {

  __index = function(self,key)
  
   if key == "HEX" then return 
        
    function(hex)     
      local encodedHex = _processHEX(hex)
      local colorObj = self("RGB",self.convert.HEX.RGB(encodedHex))
        
   -- print("This is the colorObj:",colorObj)
        
    if colorObj and not colorObj.alpha then colorObj.alpha = 255 return colorObj
    end end end
    
   if colorData.predefinedColors[key] then -- handles: creation of predefined colors 
   	local source = colorData.predefinedColors[key] 
      
   	local definitionTable = {} setmetatable(definitionTable, {
     __index = function(dataStore,key) local entry = string.upper(key)
      if source[entry] then return function() return self("RGB", source[entry].RGB) end end end })
      
    return definitionTable end -- returns: pointer to creation table

   if colorData.spaces[key] or colorData.extraSpaces[key] then 
    --local color = color and color or self
   	return function(...)  
     --print("Got to here: ",key)
     return self(key,...) end end end,

   ---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
   -- ::mark:: __call(...) - color object creation / meta methods
   ---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  __call = function(super,...) -- creates: color object

   local count = select("#",...) if count == 0 then -- error("attemt to call color() with no arguments.")
    return super(0,0,0,0) end
    -- print("Meta was called.")
    
   local first,second,colorSpaces,extraColorSpaces = select(1,...),select(2,...),colorData.spaces, colorData.extraSpaces
    
   local form1,form2 = first and type(first),second and type(second)

   ---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
   local _colorData,out = {}, {} -- parameter data / color object (output)
   ---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
  
   local meta = { space = nil, data = _colorData,

    __tostring = function(self) -- (tostring(object)) - converts color object to string
        
      local meta = getmetatable(self) local data,space = meta.data,meta.space
      local out,val,insert = "[color]:("..space..") {",{}, table.insert insert(val,out)
      local target,key = colorSpaces[space] or extraColorSpaces[space] 
      for i = 1,#target do key = target[i][1] -- adds color channel keys to string
          
        if data[key] then insert(val,key) insert(val," = ") insert(val,tostring(data[key])) 
        -- if i ~= #target then 
          insert(val,", ") end
        -- end 
        
        end
        
       -- if data.alpha then   
        insert(val,"alpha = ") insert(val,data.alpha)
       -- end
      
       insert(val,"}") out = table.concat(val) return out end,

    __len = function(self) -- (# operator) - gets number of color object channels + alpha
      local space = getmetatable(self).space local target = colorSpaces[space] or extraColorSpaces[space]
      if target then return #target + 1 end end, 

----- ----- ----- -----

    __add = function(self,val) -- Add to color object (RGB)
     local space = self.space if not val then return self:as(self.space) end
     local form,subj,col = type(val), self:as("RGB") if form == 'string' or (form == 'table' and not val.space) then
      col = color(val) if col.space ~= "RGB" then col:to("RGB") end else col = val:as("RGB") end
     subj.r,subj.g,subj.b = (subj.r + col.r)/2,(subj.g + col.g)/2,(subj.b + col.b)/2
     getmetatable(subj).data.alpha = (subj.alpha + col.alpha)/2
     return subj:to(space) end,

    __sub = function(self,val) -- Subtract from color object (RGB)
     local space = self.space if not val then return self:as(self.space) end
     local form,subj,col = type(val), self:as("RGB") if form == 'string' or (form == 'table' and not val.space) then
      col = color(val) if col.space ~= "RGB" then col:to("RGB") end else col = val:as("RGB") end
     subj.r,subj.g,subj.b = (subj.r - col.r)/2,(subj.g - col.g)/2,(subj.b - col.b)/2
     getmetatable(subj).data.alpha = (subj.alpha - col.alpha)/2
     return subj:to(space) end,

    __unm = function(self) -- Create a 'negative' color (RGB)
     local out,space = self:as("RGB"), self.space 
     out.r,out.g,out.b,out.alpha = abs(out.r - 255), abs(out.g - 255), abs(out.b - 255), abs(out.alpha - 255)
     if space ~= "RGB" then out:to(space) end return out end,

----- ----- ----- -----

    __eq = function(self,value) -- compares two colors for equality based on parameters
        
      return self.hex == value.hex
      
    --return super(value).hex == super(self).hex

  --[=[  
      local metaA,metaB = type(self) == "table" and getmetatable(self), type(value) == "table" and getmetatable(value)
      local spaceA,spaceB,target = metaA and metaA.space, metaB and metaB.space

      if spaceA == spaceB or spaceA or spaceB then -- handles: comarison of 2 colors in same space
       target = (spaceA == spaceB or spaceA) and spaceA or spaceB and spaceB or nil
       target = target and colorData.spaces[target] or colorData.extraSpaces[target]

      if target then for i = 1, #target do -- compares if color space is valid
    	if self[target[i][1]] ~= value[target[i][1]] then return false end end
         if self.alpha == value.alpha then return true else return false end 
    	
    	elseif not target then -- compares if color space is invalid or nil
    	  print("comparison made without space declaration")


    	  local passed,entry = false 

    	  for key, value in pairs(self) do 

           target = colorData.spaces for k,v in pairs(target) do 
           	for a = 1,#target[k] do for b = 1,#target[k][a] do 
             if self[key] == target[k][a][b] then passed = true break end 
             if passed then break end end if passed then passed = false break end end end 

           target = colorData.extraSpaces for k,v in pairs(target) do 
           	for a = 1,#target[k] do for b = 1,#target[k][a] do 
             if self[key] == target[k][a][b] then passed = true break end 
             if passed then break end end if passed then passed = false break end end end 

           if not passed then return false else return true end end 

    	  return false end -- TBA: Compare target is space name not know

     end 

    --]=]  

     end,

    ---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
    -- ::mark:: color.__newindex(key,value) - color object new index handling
    ---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
      
    __newindex = function(self,key,value)

      local meta = getmetatable(self) local data,space = meta.data,meta.space 
      local entry = string.lower(key) local target = colorSpaces[space] or extraColorSpaces[space] 
        
     ------ ------ ------ ------ ------ 
     --[[ [setter]: hex string to color 
       color.hex = FFF(F) / FFFFFF(FF)
       4th channel is optional alpha ]]
     ------ ------ ------ ------ ------
        
     if key == "hex" then 
       
       local space = self.space
       local format = type(value)
          
       if format ~= "string" then
         print("Tring to set a hex value with type: ("..format..")") 
        return end
          
        local str68 = "^[#]?(%x%x)(%x%x)(%x%x)(%x?%x?)$"
        local str34 = "^[#]?(%x)(%x)(%x)(%x?)$"
        local patterns = {str68,str34}
      
        for _,pattern in pairs(patterns) do
          local r,g,b,alpha = value:match(pattern)
            
           -- print(value,r,g,b)
          
           if r and g and b then
              
              if space ~= "RGB" then
                self:to("RGB")
              end
              
              -- Expands hex values
              if pattern == str34 then
                r = r..r; g = g..g; 
                b = b..b; alpha = alpha..alpha
              end
              
              --print("matches",r,g,b,alpha)
              
              self.r,self.g,self.b = r,g,b 
              if alpha:len() == 2 then
                self.alpha = alpha 
              end
      
              if space ~= "RGB" then
                self:to(space)
              end
              
           end  
        end
 
      end
        
       ------ ------ ------ ------ ------   
       -- [setter]: color.channel = "FF" Uses a hex string to assign a value to a RGB or alpha color channel
       ------ ------ ------ ------ ------  
        
        local hex = type(value) == "string" and tonumber(value)
        if (space == "RGB" or (entry == "alpha" or entry == "opacity")) then
          hex = type(value) == "string" and tonumber(value,16)
          if hex and hex > 255 then
            hex = 255
          end
        end
        
      ------ ------ ------ ------ ------  
      -- [setter]: color.space = "space" converts between color spaces
      ------ ------ ------ ------ ------  
        
      if key == "space" or key == "model" then 
       local subject,k = colorSpaces[value] or extraColorSpaces[value]
          
        if not space then meta.space = subject and value end
          if subject then if meta.space ~= value then meta.space = value
            super.convert[space][value](self) end
  
        -- value scalar by defs.
        for i = 1,#subject do k = subject[i][1] -- clamps values after color space has been set
             
         rawset(data,k, not self[k] and 0 or self[k] >= subject[i].min and self[k] <= subject[i].max and self[k] or 
         self[k] < subject[i].min and subject[i].min or self[k] > subject[i].max and subject[i].max) end
    
       else print("color space: '"..tostring(value).."' not found.") return end
      
        --- ------ --- ------ --- ------ 
        -- [setter]: col.alpha -> (0 - 255)
        --- ------ --- ------ --- ------ 
          
        elseif --[[ entry == "a" or ]] entry == "alpha" or entry == "opacity" then 
         if hex and type(hex) == "number" then rawset(data,"alpha",hex)
         else rawset(data,"alpha",value >= 0 and value <= 255 and value or value > 255 and 255 or value < 0 and 0) return end
      
       --- ------ --- ------ --- ------

        elseif target then -- processes: property keys of current color space directly
          
        for a = 1, #target do for b = 1,#target[a] do
        if target[a][b] == key then -- clamps values for declared parameters (min / max)
        
        -- Note: This explicitly returns and may need to be changed later
        if hex and type(hex) == "number" then data[target[a][1]] = hex return     
                
        elseif not value then rawset(data,target[a][1],nil) 
         else rawset(data,target[a][1], value >= target[a].min and value <= target[a].max and value or 
          value < target[a].min and target[a].min or value > target[a].max and target[a].max) 
        return end end end end end 

      -------------- ---------- -----
      -- ToDo: Think about behavior if setting color channels for different spaces
        
      for k,v in pairs(colorSpaces) do -- processes: property keys from all color spaces
       for a = 1,#v do for b = 1,#v[a] do if v[a][b] == key then -- clamps values for declared parameters (min / max)
        rawset(data,v[a][1],value) end end end end 
        
       return end,
      
      -- ]=====]

    ---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
    -- ::mark:: color.__index(key) - color object index lookups
    ---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----

    __index = function(self,key)
      local meta = getmetatable(self) local data,space = meta.data,meta.space  
        
      local target,entry = colorSpaces[space] or extraColorSpaces[space], string.lower(key)
      local foundTo,foundAs = key:match("^to(.+)$") or key:match("^convert(.+)$") or key:match("^convertTo(.+)$"), key:match("^as(.+)$")
      local form = foundAs and 'as' or 'to'

      if type(key) == "number" then
       if key <= #target then return data[target[key][1]]
       elseif key == #target + 1 then return data.alpha end

        elseif key == "space" or key == "model" then return space -- (getter) returns: (string) color space name
          
        elseif --[[entry == "a" or ]] entry == "alpha" or entry == "opacity" then return data.alpha -- (getter) returns: (number) alpha property value
     
      ----- ----- ----- ----- ----- -----
      -- [getter] color.hex -> hex string
      ----- ----- ----- ----- ----- -----

       elseif entry == "hex" then 
        local floor, format = math.floor, string.format
        local channels,space,key,code = {}, self.space for i = 1,#colorData.spaces[space] do 
         key = colorData.spaces[space][i][1] channels[key] = self[key] end
        if super.convert[space].HEX then code = super.convert[space].HEX(channels)
        else local current,_space = colorData.spaces[space] or colorData.extraSpaces[space], space
        while not super.convert[_space].HEX do super.convert[_space][current._link](channels) _space = current._link 
         current = colorData.spaces[_space] or colorData.extraSpaces[_space]; end
        code = super.convert[_space].HEX(channels) end

       local alpha = format("%x",floor(self.alpha + 0.5)):upper() -- calculates alpha channel hex
       return code..(alpha:len() == 1 and "0"..alpha or alpha) -- returns: HEX (8 char) -> #RRGGBBAA

       --return code..HEXES[floor(floor(self.alpha + 0.5)/16) + 1]..HEXES[floor(self.alpha + 0.5) % 16 + 1]

      ---- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
      -- to() / as() / convert() object methods - convert color object to a given color space (clone?) 

      elseif foundTo or foundAs then  -- processes color:toSpace() / color:asSpace() / etc.
       return function() return self[form](self,(foundTo or foundAs)) end 

      elseif key == "to" or key == "as" or key == "convert" or key == "convertTo" then 
           
        return function(self,cs) if not self or not cs then return end if space == cs then return self end 
            
         local target,current = colorSpaces[cs] or extraColorSpaces[cs], colorSpaces[space] or extraColorSpaces[space]
            
          -- ::mark - Fix color channel rounding here
            
         local copy if key == "as" then copy = {} for i = 1,#current do copy[current[i][1]] = self[current[i][1]] end 
          copy = super(space,copy); copy.alpha = meta.data.alpha; if space == cs then return copy end end
            
         local clone = key == "as"
         local pointer = clone and copy or self
            
         if target and super.convert[space][cs] then
          
          -- Fix - Setting object color apace before processing color conversions
              
          local meta = getmetatable(pointer)
          if meta and meta.space then meta.space = cs end
              
          super.convert[space][cs](pointer) 
         
         else local link = target._link -- Handles mult-step color space conversions
          if super.convert[space][link] then super.convert[space][link](pointer) super.convert[link][cs](pointer) 
          else local links,entry = {link} while not super.convert[space][links[#links]] do
            entry = colorSpaces[links[#links]] or extraColorSpaces[links[#links]] 
            if entry._link == links[#links] or #links > 1 and entry._link == links[#links-1] then break 
            else table.insert(links,entry._link) end end
           if super.convert[space][links[#links]] then local count = #links 
            while count > 0 do super.convert[links[count+1]][links[count]](pointer) 
             count = count - 1 end  super.convert[link][cs](pointer) 
  
          else local _space,entry = space -- reverse _link lookkup - self > self._space
          	while not super.convert[_space][cs] do 
          	 entry = colorSpaces[_space] or extraColorSpaces[_space] 
             super.convert[_space][entry._link](pointer); _space = entry._link end 
           super.convert[_space][cs](pointer) end end end 

          getmetatable(pointer).space = cs return not clone and self or copy end 


      ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
      -- color harmony function support
          
      elseif key == "compliment" then
        return color.compliment
        elseif key == "triad" then 
          return color.triad
      elseif key == "square" then 
        return color.square
          
      end

      ----- ----- -----

      for a = 1,#target do for b = 1, #target[a] do 
        if target[a][b] == entry then return data[target[a][1]] end end end 
      for k,v in pairs(colorSpaces) do for a = 1,#v do for b = 1,#v[a] do
        if v[a][b] == entry then return data[v[a][1]] end end end end end

   } setmetatable(out,meta) -- sets metatable for returned color object
    
    ---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
    -- ::mark:: __call(...) - color object creation argument parsing
    ---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
    
    if form1 == "string" then -- string passed as first argument: color('space name',...)
      
      --- ::mark:: - Creates color based on hex string #FFF(F) #FFFFFF(FF)
      
       local patterns = {"^[#]?(%x%x)%x%x%x%x(%x?%x?)$","^[#]?(%x)%x%x(%x?)$"}

      for i,pattern in pairs(patterns) do
        
       local start,alphaHex = string.match(first,pattern)
      
      local isHex = not colorSpaces[first] and not extraColorSpaces[first]
      if start and isHex then
        
        local colorObj = super("RGB",super.convert.HEX.RGB(first)) 
      
        local alpha = alphaHex..alphaHex
        alpha = tonumber(alpha,16) or 255
        colorObj.alpha = alpha > 255 and 255 or alpha < 0 and 0 or alpha  
        return colorObj end end
      
      if not colorSpaces[first] and not extraColorSpaces[first] then 
        return error("invalid argument 1 to color(). no color space named '"..first.."'.") end
      
      rawset(meta,"space",first) local data = colorSpaces[first] or extraColorSpaces[first] 
      local second = select(2,...) local form2 = second and type(second) local total = #data
      
  
    ------- -------- ------- --------
    --- ::mark:: ToDo - Possible entry point for greyscale values

    -- print(form1,form2)
      
    if (form1 == "string" and first == "RGB" and form2 == "number" and (count == 2 or count == 3)) then
      
     out.alpha = select(3,...) or 255
     out.r, out.g, out.b = second, second, second
       
    -- print("I got to this point.",form1,form2) 
      
    ------- -------- ------- --------
      
    elseif form2 == "number" then -- (second arg: number) - color('space name', 255,...)
     rawset(meta,"space",first) for i = 1, total do out[data[i][1]] = select(i+1,...) end
     local ex1 = select(2 + total,...) out.alpha = ex1 and type(ex1) == "number" and ex1 or 255

    elseif form2 == "table" then -- (second arg: table) - color('space name',{...})
     if second[1] and second[2] and second[3] then -- (processed value array) - color('space name',{val,val,val,...})
      rawset(meta,"space",first) for i = 1, total do out[data[i][1]] = second[i] end 
      local ex1 = second[total+1]; out.alpha = ex1 and type(ex1) == "number" and ex1 or 255

     else -- (processed value array) - color('space name',{key = val, key = val, key = val})
      rawset(meta,"space",first) local pram for k,val in pairs(second) do pram = string.lower(k) 
            
      if pram == "alpha" or pram == "opacity" and type(val) == "number" then out.alpha = val or 255
              
      else for a = 1,total do for b = 1, #data[a] do if data[a][b] == pram then out[data[a][1]] = val  end
     end end end end end --end 

    -- color('space name','HEX String')
    elseif form2 == "string" then 
        
       -- print("Creating color object in space ("..first..")") 

     local str68,str34 = "^[#]?%x%x%x%x%x%x(%x?%x?)$",
     "^[#]?%x%x%x(%x?)$"
  
      print("[Const.] I am here:", second)  
       
     local val,alpha 
     local patterns = {str68,str34}
     for _,pattern in pairs(patterns) do
       
      if string.find(second,pattern) then
         alpha = string.match(second,pattern)

      if alpha then 
       if pattern == str34 then 
        alpha = alpha..alpha end
               
       -- print("Found alpha:",alpha)       
       alpha = tonumber(alpha,16) end
       val = second end   
          
     end
        
     v = super.convert.HEX.RGB(val)  
     -- print("Value:",object(v))
        
    -- if first == "RGB" then 
    --  return super("RGB",v) end
        
     -- ToDo - RGB to XYZ may be losing data in conversion

    if super.convert.RGB[first] then super.convert.RGB[first](v) 
     else local target = colorSpaces[first] or extraColorSpaces[first]

      local link = target._link 
          --print(link)
      if super.convert.RGB[link] then super.convert.RGB[link](v) super.convert[link][first](v) 
      else local links,entry = {link} while not super.convert.RGB[links[#links]] do
        entry = colorSpaces[links[#links]] or extraColorSpaces[links[#links]]
        table.insert(links,entry._link) end super.convert.RGB[links[#links]](v)
       local count = #links - 1 while count > 0 do 
        super.convert[links[count+1]][links[count]](v) count = count - 1 end  
        super.convert[link][first](v) end

        end v = super(first,v) -- creates color object     
           
        v.alpha = alpha and alpha or 255
    --  v.alpha = (char4 or char8) and super.convert.HEX.RGB(string.sub(val,val:len()-1)).r or 255 
        
     return v end

   elseif form1 == "table" then -- table passed as first argument (auto detect space) : color({key = val, key = val, ...}) 
     for k,v in pairs(colorSpaces) do if meta.space then break end
      local total,didMatch,matchNo,comp,pram = #colorSpaces[k], false, 0
      for a = 1, #v do for b = 1, #v[a] do comp,pram = v[a][b], nil
        for key,value in pairs(select(1,...)) do pram = string.lower(key) 
          if pram == "alpha" or pram == "opacity" then out.alpha = value 
          elseif comp == pram then didMatch = true out[v[a][1]] = value break end end
        if didMatch then didMatch = false matchNo = matchNo + 1  break end end 
       if matchNo == total then out.space = k out.alpha = out.alpha or 255 
       return out end end end 

    elseif form1 == "number" then -- number vararg passed (assumes RGB) color(...)
      
      rawset(meta,"space","RGB")
      
      ------- -------- ------- --------
      --- ::mark:: Greyscale RGB Values
      
      if (count == 1 or count == 2) then 
        -- print("In the conditional")
        out.alpha = form2 == "number" and second or 255
        out.r, out.g, out.b = first, first, first 
        
      else -- Standard RGB Values
    
       out.r = select(1,...) out.g = select(2,...) out.b = select(3,...) 
      out.alpha = select(4,...) or 255 end 
      end

  return out end,

} 

setmetatable(color,color_meta)


---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- -
-- Color Harmony Creation Functions
---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- -

color.compliment = function(col) -- calculates the compliment of a color
 local ref = (type(col) == 'table' and col.space) and col or color(col)
 local compliment = ref:as("HSV") compliment.hue = compliment.hue + 180 % 360
 compliment:to(ref.space) return compliment 
 end -- returns: color object compliment

color.triad = function(col) -- calculates the triadic scheme for a color
 local ref = (type(col) == 'table' and type(col.space) == 'string') and col or color(col)
 local triadA = ref:as("HSV") triadA.hue = triadA.hue + 120 % 360 
 local triadB = triadA:as("HSV") triadB.hue = triadB.hue + 120 % 360 
 triadA:to(ref.space) triadB:to(ref.space) return ref,triadA,triadB
end -- returns: 3 color objects (ref,triadA,triadB)

color.square = function(col) -- calculates the square scheme for a color
 local ref = (type(col) == 'table' and col.space) and col or color(col)
 local squareA = ref:as("HSV") squareA.hue = squareA.hue + 90 % 360
 local squareB = squareA:as("HSV") squareB.hue = squareB.hue + 90 % 360 
 local squareC = squareB:as("HSV") squareC.hue = squareC.hue + 90 % 360   
 squareA:to(ref.space) squareB:to(ref.space) squareC:to(ref.space)
 return ref,squareA,squareB,squareC
end -- returns: 4 color objects (ref,squareA,squareB,squareC)


---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- -
-- --- ---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- -----

-- Color Conversion Functions

-- Supported Normal Spaces: | RGB | HSV | HSB | HSL | HSI | HWB | HCG | CMY | CMYK |
-- Supported Extra Spaces: | YCbCr 601 | YCbCr 709 | YCbCr 2020 | YCgCo | YDbDr |
-- Beta / Testing Spaces: | HSM | TSL | XYZ

-- RGB -> HEX String Supported (no alpha channel)

---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- -
-- --- ---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- ----- ---- --- -- --- ---- -----


color.convert = { -- Holds internal color conversion functions

  RGB = { -- Convert from RGB (Red,Green,Blue)
  
   HSV = function(vals) -- converts: RGB to HSV (Hue,Saturation,Value) 
    local r,g,b = vals.r/255, vals.g/255, vals.b/255 -- normalized properties
    local max,min = math.max(r,g,b),math.min(r,g,b)
    local chroma = (r == 0 or g == 0 or b == 0) and max or max - min
    local hue = chroma == 0 and 0 or max == r and 60 * (((g - b)/chroma) % 6) or
     max == g and 60 * (((b - r)/chroma) + 2) or max == b and 60 * (((r - g)/chroma) + 4)
    local v,s = max; s = chroma == 0 and 0 or chroma/v 
     vals.r,vals.g,vals.b,vals.h,vals.s,vals.v = nil,nil,nil, hue, s * 100, v * 100
    return vals end, -- returns: (table) HSV Values {h = ?, s = ?, v = ?}

   HSB = function(vals) -- converts: RGB to HSV (Hue,Saturation,Brightness) 
    local r,g,b = vals.r/255, vals.g/255, vals.b/255 -- normalized properties
    local max,min = math.max(r,g,b),math.min(r,g,b)
    local chroma = (r == 0 or g == 0 or b == 0) and max or max - min
    local hue = chroma == 0 and 0 or max == r and 60 * (((g - b)/chroma) % 6) or
     max == g and 60 * (((b - r)/chroma) + 2) or max == b and 60 * (((r - g)/chroma) + 4)
    local b,s = max; s = chroma == 0 and 0 or chroma/b 
     vals.r,vals.g,vals.h,vals.s,vals.b = nil,nil, hue, s * 100, b * 100
    return vals end, -- returns: (table) HSB Values {h = ?, s = ?, b = ?}

   HSL = function(vals) -- converts: RGB to HSL (Hue,Saturation,Lightness) 
    local r,g,b = vals.r/255, vals.g/255, vals.b/255 -- normalized properties
    local max,min = math.max(r,g,b),math.min(r,g,b)
    local chroma = (r == 0 or g == 0 or b == 0) and max or max - min
    local hue = chroma == 0 and 0 or max == r and 60 * (((g - b)/chroma) % 6) or
     max == g and 60 * (((b - r)/chroma) + 2) or max == b and 60 * (((r - g)/chroma) + 4)
    local l,s = 0.5 * (max + min); s = chroma == 0 and 0 or chroma / (1 - math.abs((2 * l) - 1))
     vals.r,vals.g,vals.b,vals.h,vals.s,vals.l = nil,nil,nil, hue, s * 100, l * 100
    return vals end, -- returns: (table) HSL Values {h = ?, s = ?, l = ?}

   HSI = function(vals) -- converts: RGB to HSI (Hue,Saturation,Intensity) 
    local total = vals.r + vals.g + vals.b local r,g,b = vals.r/total,vals.g/total,vals.b/total
   
    local hue = math.acos(0.5*((r-g)+(r-b))/math.sqrt((r-g) * (r-g)+(r-b)*(g-b)))
    local min,ity,sat = math.min(r,g,b),(vals.r + vals.g + vals.b)/(3 * 255)
     sat = ity == 0 and 0 or 1 - (3 * min) if b > g then hue = (2 * math.pi) - hue end 
     hue = hue * 180/math.pi hue = hue >= 0 and hue or hue <= 360 and hue or 0
     vals.r,vals.g,vals.b,vals.h,vals.s,vals.i = nil,nil,nil,hue, sat * 100, ity * 100
    return vals end, -- returns: (table) HSI Values {h = ?, s = ?, i = ?}
   
   HWB = function(vals) -- converts: RGB to HWB (Hue,Whiteness,Blackness) 
    local r,g,b = vals.r/255, vals.g/255, vals.b/255 -- normalized properties
    local max,min = math.max(r,g,b),math.min(r,g,b) local delta = max - min
    local chroma = (r == 0 or g == 0 or b == 0) and max or max - min
    local hue = chroma == 0 and 0 or max == r and 60 * (((g - b)/chroma) % 6) or
     max == g and 60 * (((b - r)/chroma) + 2) or max == b and 60 * (((r - g)/chroma) + 4)
    local w,b = math.min(r,math.min(g,b)), 1 - math.max(r,math.max(g,b))
     vals.r,vals.g,vals.h,vals.w,vals.b = nil,nil,hue, w * 100, b * 100
    return vals end,  -- returns: (table) HWB Values {h = ?, w = ?, b = ?}
   
   HCG = function(vals) -- converts: RGB to HCG (Hue,Chroma,Greyscale)
    local r,g,b = vals.r/255, vals.g/255, vals.b/255 -- normalized properties
    local max,min,greyscale,hue = math.max(r,g,b),math.min(r,g,b) local chroma = max - min
    greyscale = chroma < 1 and min/(1 - chroma) or 0; if chroma > 0 then 
     hue = max == r and ((g-b) / chroma) % 6 or max == g and 2 + (b - r) / chroma or
     4 + (r - g) / chroma; hue = (hue/6) % 1 ; else hue = 0 end 
    vals.r,vals.b,vals.h,vals.c,vals.g = nil,nil,hue*360, chroma*100, greyscale*100
    return vals end,  -- returns: (table) HCG Values {h = ?, c = ?, g = ?}

---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 
-- RGB to TSL Conversion - port from: https://stackoverflow.com/questions/43696998/tsltorgb-colorspace-conversion

   TSL = function(vals) -- converts: RGB to TSL (Tint,Saturation,Lightness) 
    local r,g,b = vals.r, vals.g, vals.b -- normalized properties
    if r == 0 and g == 0 and b == 0 then 
     vals.r,vals.g,vals.b,vals.t,vals.s,vals.l = nil,nil,nil, 0,0,0 return vals end

    local l = 0.299 * r + 0.587 * g + 0.114 * b;
    local r1, g1 = r / (r + g + b) - 1.0 / 3, g / (r + g + b) - 1.0 / 3
    local s = math.sqrt(9.0 / 5 * (r1 * r1 + g1 * g1))
    local t if g1 == 0 then if r < b then t = -0.0 else t = 0.0 end
     else t = math.atan(r1/g1) / math.pi / 2 + 0.25 if g1 < 0 and t == t then t = t + 0.5 end end
    vals.r,vals.g,vals.b,vals.t,vals.s,vals.l = nil,nil,nil, t * 100, s * 100, l * 1
    return vals end,  -- returns: (table) TSL Values {t = ?, s = ?, l = ?}

---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 

-- Fix Me!! -- November 14, 2017 BD

   HSM = function(vals) -- converts: RGB to HSM (Hue,Saturation,Mixture) 
    local r,g,b = vals.r/255, vals.g/255, vals.b/255 -- normalized properties
    local m = ((4*r)+(2*g)+b)/7

    local lvl = math.sqrt(pow((r-m),2) + pow((g-m),2) + pow((b-m),2))
    local angle = math.acos(( ((3*(r-m))-(4*(g-m))-(4*(b-m)) ) / math.sqrt(41)) / lvl)

    --angle = angle ~= angle and 0 or angle
    local w = b <= g and angle or b > g and (2 * math.pi) - angle
    local h,s = w / (2 * math.pi)
   
    if 0 <= m and m <= 1/7 then
     s = lvl / math.sqrt(pow(0-m,2) + pow(0-m,2) + pow(7-m,2))
    elseif 1/7 < m and m <= 3/7 then
     s = lvl / math.sqrt(pow(0-m,2) + pow((((7*m)-1)/2)-m,2) + pow(1-m,2))
    elseif 3/7 < m and m <= 1/2 then
     s = lvl / math.sqrt(pow((((7*m)-3)/2)-m,2) + pow(1-m,2) + pow(1-m,2))
    elseif 1/2 < m and m <= 4/7 then
     s = lvl / math.sqrt(pow(((7*m)/4)-m,2) + pow(0-m,2) + pow(0-m,2))
    elseif 4/7 < m and m <= 6/7 then
     s = lvl / math.sqrt(pow(1-m,2) + pow((((7*m)-4)/2)-m,2) + pow(0-m,2))
    elseif 6/7 < m and m <= 1 then
     s = lvl / math.sqrt(pow(1-m,2) + pow(1-m,2) + pow(((7*m)-6)-m,2) )
    end

    h,s,m = h ~= h and 0 or h, s ~= s and 0 or s, m ~= m and 0 or m
    vals.r,vals.g,vals.b,vals.h,vals.s,vals.m = nil,nil,nil, h * 360, s * 100, m * 100
    return vals end, -- returns: (table) HSM Values {h = ?, s = ?, m = ?}


---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 

   YUV = function(vals) -- converts: RGB to YUV (Luma,Chroma Blue,Chroma Red)
    local r,g,b = vals.r/255,vals.g/255,vals.b/255 
    local y = (r * 0.299) + (g * 0.587) + (b * 0.114) 
    local u,v = 0.436 * ((b - y)/0.886), 0.615 * ((r - y)/0.701)
	vals.r,vals.g,vals.b,vals.y,vals.u,vals.v = nil,nil,nil, y * 100, u * 100, v * 100
    return vals end, -- returns: (table) YUV Values {y = ?, u = ?, u = ?}

   YCbCr601 = function(vals) -- converts: RGB to YCbCr 601 (Luminence,Chroma Blue,Chroma Red)
    local r,g,b,kR,kB = vals.r/255,vals.g/255,vals.b/255, 0.2990, 0.1146
    local y = (kR * r) + ((1 - kR - kB) * g) + (kB * b)
    local cB,cR = 0.5 * ((b - y)/(1 - kB)), 0.5 * ((r - y)/(1 - kR))
     vals.r,vals.g,vals.b,vals.y,vals.cb,vals.cr = nil,nil,nil, y * 100, cB * 100, cR * 100
    return vals end, -- returns: (table) YCbCr 601 Values {y = ?, cb = ?, cr = ?}

   YCbCr709 = function(vals) -- converts: RGB to YCbCr 709 (Luminence,Chroma Blue,Chroma Red)
    local r,g,b,kR,kB = vals.r/255,vals.g/255,vals.b/255, 0.2126, 0.0722 
    local y = (kR * r) + ((1 - kR - kB) * g) + (kB * b)
    local cB,cR = 0.5 * ((b - y)/(1 - kB)), 0.5 * ((r - y)/(1 - kR))
     vals.r,vals.g,vals.b,vals.y,vals.cb,vals.cr = nil,nil,nil, y * 100, cB * 100, cR * 100
    return vals end, -- returns: (table) YCbCr 709 Values {y = ?, cb = ?, cr = ?}

   YCbCr2020 = function(vals) -- converts: RGB to YCbCr 2020 (Luminence,Chroma Blue,Chroma Red)
    local r,g,b,kR,kB = vals.r/255,vals.g/255,vals.b/255, 0.2627, 0.0593 
    local y = (kR * r) + ((1 - kR - kB) * g) + (kB * b)
    local cB,cR = 0.5 * ((b - y)/(1 - kB)), 0.5 * ((r - y)/(1 - kR))
     vals.r,vals.g,vals.b,vals.y,vals.cb,vals.cr = nil,nil,nil, y * 100, cB * 100, cR * 100
    return vals end, -- returns: (table) YCbCr 2020 Values {y = ?, cb = ?, cr = ?}

   YCgCo = function(vals) -- converts: RGB to YCgCo (Luminence,Chroma Green,Chroma Orange)
    local r,g,b = vals.r/255, vals.g/255, vals.b/255 -- normalized properties
    vals.r,vals.g,vals.b = nil,nil,nil vals.y = ((0.25*r)+(0.5*g)+(0.25*b)) * 100
     vals.cg, vals.co = ((-0.25*r)+(0.5*g)-(0.25*b)) * 100, ((0.5*r)-(0.5*b)) * 100
    return vals end, -- returns: (table) YCgCo Values {y = ?, cg = ?, co = ?}

   YDbDr = function(vals) -- converts: RGB to YDbDr (Luminence,Chroma Blue,Chroma Red)
    local r,g,b = vals.r/255, vals.g/255, vals.b/255 -- normalized properties
    local y,db,dr = 0.299*r + 0.587*g + 0.114*b, -0.450*r - 0.883*g + 1.333*b, -1.333*r + 1.116*g + 0.217*b 
    vals.r,vals.g,vals.b,vals.y,vals.db,vals.dr = nil, nil, nil, y * 100, db * 100, dr * 100
    return vals end, -- returns: (table) YDbDr Values {y = ?, db = ?, dr = ?}

   XYZ = function(vals)  -- converts: RGB to XYZ (X,Y,Z)
    local r,g,b,pow,x,y,z = vals.r/255, vals.g/255, vals.b/255, pow
    r = r > 0.04045 and pow(((r + 0.055) / 1.055), 2.4) or (r / 12.92);
    g = g > 0.04045 and pow(((g + 0.055) / 1.055), 2.4) or (g / 12.92);
    b = b > 0.04045 and pow(((b + 0.055) / 1.055), 2.4) or (b / 12.92);
    x = (r * 0.41239079926595) + (g * 0.35758433938387) + (b * 0.18048078840183);
    y = (r * 0.21263900587151) + (g * 0.71516867876775) + (b * 0.072192315360733);
    z = (r * 0.019330818715591) + (g * 0.11919477979462) + (b * 0.95053215224966);
    vals.r,vals.g,vals.b,vals.x,vals.y,vals.z = nil,nil,nil, x*100, y*100, z*100
   return vals end, -- returns: (table) XYZ Values {x = ?, y = ?, z = ?}
  
   CMY = function(vals) -- converts: RGB to CMY (Cyan,Magenta,Yellow)
    local r,g,b = vals.r/255, vals.g/255, vals.b/255 -- normalized properties
     vals.r,vals.g,vals.b,vals.c,vals.m,vals.y = nil,nil,nil,(1-r)*100,(1-g)*100,(1-b)*100
    return val end, -- returns: (table) CMY Values {c = ?, m = ?, y = ?, k = ?}

   CMYK = function(vals) -- converts: RGB to CMYK (Cyan,Magenta,Yellow,Key/Black)
    local r,g,b = vals.r/255, vals.g/255, vals.b/255 -- normalized properties
    local k = math.min(1-r,1-g,1-b) local c,m,y = (1-r-k)/(1-k),(1-g-k)/(1-k),(1-b-k)/(1-k)
    c,m,y,k = c ~= c and 0 or c, m ~= m and 0 or m, y ~= y and 0 or y, k ~= k and 0 or k
     vals.r,vals.g,vals.b,vals.c,vals.m,vals.y,vals.k = nil,nil,nil,c*100,m*100,y*100,k*100
    return vals end, -- returns: (table) CMYK Values {c = ?, m = ?, y = ?, k = ?}
  
   HEX = function(vals) -- converts: RGB to HEX String
      
    local r,g,b,a,out,format,floor = vals.r,vals.g,vals.b,vals.a, "#",string.format, math.floor
      
    r,g,b,a = r % 1 == 0 and r or floor(r + 0.5), g % 1 == 0 and g or floor(g+ 0.5), b % 1 == 0 and b or floor(b + 0.5), a % 1 == 0 and a or floor(a + 0.5)
      
    r,g,b,a = format("%x",r):upper(), format("%x",g):upper(), format("%x",b):upper(),
     format("%x",a):upper()
      
    out = out..(r:len() == 1 and "0"..r or r)..(g:len() == 1 and "0"..g or g)..(b:len() == 1 and "0"..b or b)..(a:len() == 1 and "0"..a or a)
      
    return out end, -- returns: (string) Hex String 
   
  }, 

---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  HSV = { -- Converts from HSV (Hue,Saturation,Value)

   RGB = function(vals) -- converts: HSV to RGB (Red,Green,Blue)
    local h,s,v = vals.h,vals.s / 100, vals.v / 100
    local hdash,chroma,r,g,b = vals.h / 60, v * s, 0,0,0
    local x,min = chroma * (1.0 - math.abs((hdash % 2.0) - 1.0)), v - chroma 
    if hdash < 1.0 then r,g = chroma,x elseif hdash < 2.0 then r,g = x,chroma
    elseif hdash < 3.0 then g,b = chroma,x elseif hdash < 4.0 then g,b = x,chroma 
    elseif hdash < 5.0 then r,b = x,chroma elseif hdash <= 6.0 then r,b = chroma,x end
     vals.h,vals.s,vals.v,vals.r,vals.g,vals.b = nil,nil,nil, r + min, g + min, b + min
     vals.r,vals.g,vals.b = vals.r * 255, vals.g * 255, vals.b * 255
      
    return vals end, -- returns: (table) RGB Values {r = ?, g = ?, b = ?}

   HSB = function(vals) -- converts: HSV to HSB (Hue,Saturation,Brightness)
    vals.v,vals.b = nil,vals.v 
    return vals end, -- returns: (table) HSB Values {h = ?, s = ?, b = ?}

   HSL = function(vals) -- converts: HSV to HSL (Hue,Saturation,Lightness)
    local s,v = vals.s/100, vals.v/100; local l = ((2 - s) * v); vals.l = (l / 2) * 100
    local mod = l <= 1 and l or 2 - l; vals.s,vals.v = ((s * v) / mod) * 100, nil
    return vals end, -- returns: (table) HSL Values {h = ?, s = ?, l = ?}

   HWB = function(vals) -- converts: HSV to HWB (Hue,Whiteness,Blackness)
    local h,s,v = vals.h,vals.s/100,vals.v/100
    local b = 1 - v local w = (1 - s) * v
     vals.s,vals.v,vals.h,vals.w,vals.b = nil,nil, h, w * 100, b * 100
    return vals end, -- returns: (table) HWB Values {h = ?, w = ?, b = ?}

   HCG = function(vals) -- converts: HSV to HCG (Hue,Chroma,Greyscale)
    local h,s,v = vals.h,vals.s/100,vals.v/100 local c,r,g,b = s*v
    local ent = c < 1 and (v - c)/(1 - c) or 0
     vals.s,vals.v,vals.h,vals.c,vals.g = nil,nil, h, c * 100, ent * 100
    return vals end -- returns: (table) HCG Values {h = ?, c = ?, g = ?}

  },

---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  HSB = { -- Converts from HSB (Hue,Saturation,Brightness)
    
    --[==[
    RGB = function(vals) -- converts: HSB to RGB (Red,Green,Blue)
      
      -- [[ -- (temp.) - This would work
      if true then
       return vals:to("HSV"):toRGB()
      end
     -- ]]
      
    end,
    -- ]==]
    
    RGB = function(vals) -- converts: HSV to RGB (Red,Green,Blue)
      
    local h,s,v = vals.h,vals.s / 100, vals.b / 100
      
    local hdash,chroma,r,g,b = vals.h / 60, v * s, 0,0,0
    local x,min = chroma * (1.0 - math.abs((hdash % 2.0) - 1.0)), v - chroma 
      
    if hdash < 1.0 then r,g = chroma,x elseif hdash < 2.0 then r,g = x,chroma
    elseif hdash < 3.0 then g,b = chroma,x elseif hdash < 4.0 then g,b = x,chroma 
    elseif hdash < 5.0 then r,b = x,chroma elseif hdash <= 6.0 then r,b = chroma,x end
    
      local scaledB = vals.b / 100 * 255 
    vals.h,vals.s,vals.v,vals.r,vals.g,vals.b = nil,nil,nil, r + min, g + min, b + min
      
     vals.r,vals.g,vals.b = vals.r * 255, vals.g * 255, vals.b * 255
      
    return vals end, -- returns: (table) RGB Values {r = ?, g = ?, b = ?}
    
   HSV = function(vals) -- converts: HSB to HSV (Hue,Saturation,Value)
    vals.b,vals.v = nil,vals.b 
    return vals end, -- returns: (table) HSV Values {h = ?, s = ?, v = ?}

   HSL = function(vals) -- converts: HSB to HSL (Hue,Saturation,Lightness)
    local s,v = vals.s/100, vals.b/100; local l = ((2 - s) * v); vals.l = (l / 2) * 100
    local mod = l <= 1 and l or 2 - l; vals.s,vals.v = ((s * v) / mod) * 100, nil
    return vals end, -- returns: (table) HSL Values {h = ?, s = ?, l = ?}

   HWB = function(vals) -- converts: HSB to HWB (Hue,Whiteness,Blackness)
    local h,s,v = vals.h,vals.s/100,vals.b/100
    local b = 1 - v local w = (1 - s) * v
     vals.s,vals.v,vals.h,vals.w,vals.b = nil,nil, h, w * 100, b * 100
    return vals end, -- returns: (table) HWB Values {h = ?, w = ?, b = ?}

   HCG = function(vals) -- converts: HSB to HCG (Hue,Chroma,Greyscale)
    local h,s,v = vals.h,vals.s/100,vals.b/100 local c,r,g,b = s*v
    local ent = c < 1 and (v - c)/(1 - c) or 0
     vals.s,vals.v,vals.h,vals.c,vals.g = nil,nil, h, c * 100, ent * 100
    return vals end -- returns: (table) HCG Values {h = ?, c = ?, g = ?}

  },

---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  HSL = { -- Converts from HSL (Hue,Saturation,Lightness)
  
   RGB = function(vals) -- converts: HSL to RGB (Red,Green,Blue) 
    local h,s,l,hdash = vals.h, vals.s / 100, vals.l / 100, vals.h / 60
    local chroma,r,g,b = (1 - math.abs((2 * l) - 1)) * s, 0,0,0 
    local x,min = chroma * (1.0 - math.abs((hdash % 2.0) - 1.0)), l - (0.5 * chroma) 
    if hdash < 1.0 then r,g = chroma,x elseif hdash < 2.0 then r,g = x,chroma
    elseif hdash < 3.0 then g,b = chroma,x elseif hdash < 4.0 then g,b = x,chroma 
    elseif hdash < 5.0 then r,b = x,chroma elseif hdash <= 6.0 then r,b = chroma,x end 
     vals.h,vals.s,vals.l,vals.r,vals.g,vals.b = nil,nil,nil, r + min, g + min, b + min
     vals.r,vals.g,vals.b = vals.r * 255, vals.g * 255, vals.b * 255
    return vals end, -- returns: (table) RGB Values {r = ?, g = ?, b = ?}

   HSV = function(vals) -- converts: HSL to HSV (Hue,Saturation,Value)
    local h,s,l,s1,v = vals.h,vals.s/100, vals.l/100; if l == 0 then h,s1,v = 0,0,0
    else l = l * 2; s = l <= 1 and s*l or s*(2 - l); v = (l+s)/2; s1 = (2*s)/(l+s) end
     vals.l,vals.h,vals.s,vals.v = nil, h, s1 * 100, v * 100 
    return vals end, -- returns: (table) HSV Values {h = ?, s = ?, v = ?}

   HSB = function(vals) -- converts: HSL to HSB (Hue,Saturation,Brightness)
    local h,s,l,s1,b = vals.h,vals.s/100, vals.l/100; if l == 0 then h,s1,b = 0,0,0
    else l = l * 2; s = l <= 1 and s*l or s*(2 - l); b = (l+s)/2; s1 = (2*s)/(l+s) end
     vals.l,vals.h,vals.s,vals.b = nil, h, s1 * 100, b * 100 
    return vals end, -- returns: (table) HSB Values {h = ?, s = ?, b = ?}

   HCG = function(vals) -- converts: HSL to HCG (Hue,Chroma,Greyscale)
    local s,l = vals.s/100, vals.l/100 local c = l < 0.5 and 2 * s * l or 2 * s * (1-l) 
    local g = c < 1 and (l - 0.5 * c) / (1 - c) or 0
     vals.s, vals.l, vals.g, vals.c = nil, nil, g * 100, c * 100
    return vals end -- returns: (table) HCG Values {h = ?, c = ?, g = ?}

  },  

---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  HSI = { -- Converts from HSI (Hue,Saturation,Intensity)

   RGB = function(vals) -- converts: HSI to RGB (Red,Green,Blue)
    local h,s,i = vals.h * (math.pi/180), vals.s/100, vals.i/100
    local r,g,b if h >= 0 and h < (2 * math.pi)/3 then b = i*(1 - s) 
     r = i * (1+((s * math.cos(h))/math.cos((math.pi/3) - h))) g = (3 * i)-(b + r) 
    elseif h >= (2*math.pi)/3 and h < (4 * math.pi)/3 then h = h-((2*math.pi)/3) r = i*(1-s) 
     g = i * (1+((s * math.cos(h))/math.cos((math.pi/3) - h))) b = (3 * i)-(r + g) 
    elseif h >= (4 * math.pi)/3 and h <= 2 * math.pi then h = h-((4*math.pi)/3) g = i*(1-s) 
     b =  i * (1+((s * math.cos(h))/math.cos((math.pi/3) - h))) r = (3 * i)-(g + b) end
    vals.h,vals.s,vals.i,vals.r,vals.g,vals.b = nil,nil,nil, r * 255, g * 255, b * 255
    return vals end -- returns: (table) RGB Values {r = ?, g = ?, b = ?}

  },

 ---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  HWB = { -- Converts from HWB (Hue,Whiteness,Blackness)

   RGB = function(vals) -- converts: HWB to RGB (Red,Green,Blue)
    local h,w,b = vals.h/360, vals.w/100, vals.b/100 local ratio = w + b
    if ratio > 1 then b,w = b/ratio, w/ratio end local i,v = math.floor(6*h),1-b
    local f,r,g,b = 6 * h - i if i % 2 ~= 0 then f = 1 - f end local n = w + f * (v - w)
    r = (i == 0 or i == 5) and v or (i == 1 or i == 4) and n or (i == 2 or i == 3) and w 
    g = (i == 0 or i == 3) and n or (i == 1 or i == 2) and v or (i == 4 or i == 5) and w
    b = (i == 0 or i == 1) and w or (i == 2 or i == 5) and n or (i == 3 or i == 4) and v
     vals.h,vals.w,vals.r,vals.g,vals.b = nil,nil, r * 255, g * 255, b * 255
    return vals end, -- returns: (table) RGB Values {r = ?, g = ?, b = ?}

   HSV = function(vals) -- converts: HWB to HSV (Hue,Saturation,Value)
    local h,w,b = vals.h,vals.w/100,vals.b/100 local v = (-1*b) + 1 
    local s = (w == 0 or b == 1) and 0 or (1-(w/(1-b)))
     vals.w,vals.b,vals.h,vals.s,vals.v = nil,nil, h,s*100,v*100
    return vals end, -- returns: (table) HSV Values {h = ?, s = ?, v = ?}

   HSB = function(vals) -- converts: HWB to HSV (Hue,Saturation,Brightness)
    local h,w,b = vals.h,vals.w/100,vals.b/100 local v = (-1*b) + 1 
    local s = (w == 0 or b == 1) and 0 or (1-(w/(1-b)))
     vals.w,vals.h,vals.s,vals.b = nil, h,s*100,v*100
    return vals end -- returns: (table) HSB Values {h = ?, s = ?, b = ?}
  },

---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  HCG = { -- Converts from HCG (Hue,Chroma,Greyscale)

   RGB = function(vals) -- converts: HCG to RGB (Red,Green,Blue)
    local h,c,g = vals.h/360,vals.c/100,vals.g/100 if c == 0 then 
     vals.h,vals.c,vals.r,vals.g,vals.b = nil,nil,g*255,g*255,g*255 return vals end
    local hi,mg,r,g,b = (h%1)*6,(1-c)*g local v,i = hi%1, math.floor(hi) local w = 1-v 
    r = i == 0 and 1 or i == 1 and w or (i == 2 or i == 3) and 0 or i == 4 and v or 1
    g = i == 0 and v or (i == 1 or i == 2) and 1 or i == 3 and w or 0
    b = (i == 0 or i == 1) and 0 or i == 2 and v or (i == 3 or i == 4) and 1 or w 
     vals.h,vals.c,vals.r,vals.g,vals.b = nil,nil,((c*r)+mg)*255,((c*g)+mg)*255,((c*b)+mg)*255
    return vals end, -- returns: (table) RGB Values {r = ?, g = ?, b = ?}

   HSV = function(vals) -- converts: HCG to HSV (Hue,Saturation,Value)
    local hue,c,g = vals.h,vals.c / 100,vals.g / 100 local vh,h,s,v = c+g*(1.0-c)
     vals.c,vals.g,vals.h,vals.s,vals.v = nil, nil, hue, (c/vh) * 100, vh * 100
    return vals end, -- returns: (table) HSV Values {h = ?, s = ?, v = ?}

   HSB = function(vals) -- converts: HCG to HSB (Hue,Saturation,Brightness)
    local hue,c,g = vals.h,vals.c / 100,vals.g / 100 local vh,h,s,b = c+g*(1.0-c)
     vals.c,vals.g,vals.h,vals.s,vals.b = nil, nil, hue, (c/vh) * 100, vh * 100
    return vals end, -- returns: (table) HSB Values {h = ?, s = ?, b = ?}

   HSL = function(vals) -- converts: HCG to HSL (Hue,Saturation,Lightness)
    local h,c,g = vals.h,vals.c / 100,vals.g / 100 local l,s = g*(1-c)+0.5*c,0
    if l < 1 and l > 0 then s = l < 0.5 and c/(2*l) or c/(2*(1-l)) end
     vals.c,vals.g,vals.h,vals.s,vals.l = nil, nil, h, s * 100, l * 100
    return vals end -- returns: (table) HSL Values {h = ?, s = ?, l = ?}
 
  },

---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 
-- TSL to RGB Conversion - port from: https://stackoverflow.com/questions/43696998/tsltorgb-colorspace-conversion

  TSL = { -- Converts from TSL (Tint,Saturation,Lightness)

   RGB = function(vals) -- Converts TSL to RGB (Red,Green,Blue)
    local t,s,l = vals.t/100, vals.s/100, vals.l/1 -- normalized properties
    if l == 0 then -- returns: (table) RGB Values {r = 0, g = 0, b = 0}
     vals.t,vals.s,vals.l,vals.r,vals.g,vals.b = nil,nil,nil,0,0,0 
     return vals end
  
    local r1,g1 if (1/t) == -math.huge then g1 = 0 r1 = -math.sqrt(5)/3*s
    elseif (1/t) == math.huge then g1 = 0 r1 = math.sqrt(5)/3*s
    else local x = -1.0 / math.tan(2* math.pi * t)   
     g1 = math.sqrt(5/(1 + x * x)) / 3.0 * s
     if t > 0.5 then g1 = -g1 end r1 = x * g1 end
  
    local r,g = r1 + 1.0/3, g1 + 1.0/3 local b = 1 - r - g
    local k = l / (0.185 * r + 0.473 * g + 0.114)
    vals.t,vals.s,vals.l,vals.r,vals.g,vals.b = nil,nil,nil,r * k, g * k, b * k
    return vals end -- returns: (table) RGB Values {r = ?, g = ?, b = ?}

  },

---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 

 -- Fix Me!! -- November 14, 2017 BD

 HSM = { -- Converts from HSM (Hue,Saturation,Mixture)

  RGB = function(vals) -- Converts HSM to RGB (Red,Green,Blue)
   local h,s,m = vals.h / 360, vals.s / 100, vals.m / 100
   local r = (3/41) * s * math.cos(h) + m - ((4/861) * math.sqrt( ((861)*(s^2)) * (1 - pow(math.cos(h),2))))
   local g = ((math.sqrt(41)*s) * math.cos(h) + (23*m) - (19*r)) / 4
   local b = ((11*r) - (9*m) - (math.sqrt(41)*s) * math.cos(h))/2

   vals.h,vals.s,vals.m,vals.r,vals.g,vals.b = nil,nil,nil,r*255,g*255,b*255
  return vals end -- returns: (table) RGB Values {r = ?, g = ?, b = ?}

 },

---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 

  YUV = { -- Converts from YUV (Luma,Chroma Blue,Chroma Red)

   RGB = function(vals) -- converts: YUV to RGB (Red,Green,Blue)
    local y,u,v,max,min = vals.y/100, vals.u/100, vals.v/100, math.max, math.min
    local r = y + (v * (0.701 / 0.615))
    local g = y - (u * (0.101004 / 0.255932)) - (v * (0.209599 / 0.361005))
    local b = y + (u * (0.886 / 0.436))
    vals.y,vals.u,vals.v,vals.r,vals.g,vals.b = nil,nil,nil, r * 255, g * 255, b * 255
    return vals end, -- returns: (table) RGB Values {r = ?, g = ?, b = ?}

   --[[
   -- Fix Me!! - The scale factors are approximations and should be more precise
   YDbDr = function(vals) -- converts: YUV to YDbDr (Luminence,Chroma Blue,Chroma Red)
    local u,v = vals.u, vals.v
    vals.u,vals.v,vals.db,vals.dr = nil,nil, u * 3.0573448009416, -v * 2.1694966913406  
   return vals end -- returns: (table) YDbDr Values {y = ?, db = ?, dr = ?}
   --]]
  
  },

---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 

  YCbCr601 = { -- Converts from YCbCr 601 (Luminence,Chroma Blue,Chroma Red)

   RGB = function(vals) -- converts: YCbCr 601 to RGB (Red,Green,Blue)
    local y,cb,cr,kR,kB = vals.y/100, vals.cb/100, vals.cr/100, 0.2990, 0.1146
    local r,b,g = cr * 2 * (1 - kR) + y, cb * 2 * (1 - kB) + y
    g = (y - (r * kR) - (b * kB)) / (1 - kR - kB)
     vals.y,vals.cb,vals.cr,vals.r,vals.g,vals.b = nil,nil,nil, r * 255, g * 255, b * 255
    return vals end -- returns: (table) RGB Values {r = ?, g = ?, b = ?}
  
  },

---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  YCbCr709 = { -- Converts from YCbCr 709 (Luminence,Chroma Blue,Chroma Red)
  
   RGB = function(vals) -- converts: YCbCr 709 to RGB (Red,Green,Blue)
    local y,cb,cr,kR,kB = vals.y/100, vals.cb/100, vals.cr/100, 0.2126, 0.0722 
    local r,b,g = cr * 2 * (1 - kR) + y, cb * 2 * (1 - kB) + y
    g = (y - (r * kR) - (b * kB)) / (1 - kR - kB)
     vals.y,vals.cb,vals.cr,vals.r,vals.g,vals.b = nil,nil,nil, r * 255, g * 255, b * 255
    return vals end -- returns: (table) RGB Values {r = ?, g = ?, b = ?}

  },

---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  YCbCr2020 = { -- Converts from YCbCr 2020 (Luminence,Chroma Blue,Chroma Red)
  
   RGB = function(vals) -- converts: YCbCr 2020 to RGB (Red,Green,Blue)
    local y,cb,cr,kR,kB = vals.y/100, vals.cb/100, vals.cr/100, 0.2627, 0.0593 
    local r,b,g = cr * 2 * (1 - kR) + y, cb * 2 * (1 - kB) + y
    g = (y - (r * kR) - (b * kB)) / (1 - kR - kB)
     vals.y,vals.cb,vals.cr,vals.r,vals.g,vals.b = nil,nil,nil, r * 255, g * 255, b * 255
    return vals end -- returns: (table) RGB Values {r = ?, g = ?, b = ?}

  },

---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  YCgCo = { -- Converts from YCgCo (Luminence,Chroma Green,Chroma Orange)

   RGB = function(vals) -- converts: YCgCo to RGB (Red,Green,Blue)
    local y,cg,co = vals.y/100,vals.cg/100,vals.co/100 
    local mod = y - cg local r,g,b = mod + co, y + cg, mod - co
     vals.y,vals.cg,vals.co,vals.r,vals.g,vals.b = nil,nil,nil, r * 255, g * 255, b * 255
    return vals end -- returns: (table) RGB Values {r = ?, g = ?, b = ?}

  },

---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  YDbDr = { -- Converts from YDbDr (Luminence,Chroma Blue,Chroma Red)

   RGB = function(vals) -- converts: YDbDr to RGB (Red,Green,Blue)
    local y,db,dr,r,g,b = vals.y/100, vals.db/100, vals.dr/100
      r = y + 0.000092303716148 * db - 0.525912630661865 * dr;
      g = y - 0.129132898890509 * db + 0.267899328207599 * dr;
      b = y + 0.664679059978955 * db - 0.000079202543533 * dr;

     -- Values returned are clipped to 12 decimal places
     vals.y,vals.db,vals.dr = nil,nil,nil
     vals.r = math.floor(r * 255 * (10^12) + 0.5) / (10^12)
     vals.g = math.floor(g * 255 * (10^12) + 0.5) / (10^12)
     vals.b = math.floor(b * 255 * (10^12) + 0.5) / (10^12)
    return vals end, -- returns: (table) RGB Values {r = ?, g = ?, b = ?}

   --[[
   -- Fix Me!! - The scale factors are approximations and should be more precise
   YUV = function(vals) -- converts: YDbDr to YUV (Luma,Chroma Blue,Chroma Red)
    local y,db,dr,r,g,b = vals.y, vals.db, vals.dr
    vals.db,vals.dr,vals.u,vals.v = nil,nil, db / 3.0573448009416, -dr / 2.1694966913406
   return vals end -- returns: (table) YUV Values {y = ?, u = ?, v = ?}
   --]]

  },


---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  XYZ = { -- Converts from XYZ (X,Y,Z)

    RGB = function(vals) -- converts: XYZ to RGB (Red,Green,Blue)
     local x,y,z,pow,max,min = vals.x/100,vals.y/100,vals.z/100,pow,math.max,math.min
     r = (x * 3.240969941904521) + (y * -1.537383177570093) + (z * -0.498610760293);
     g = (x * -0.96924363628087) + (y * 1.87596750150772) + (z * 0.041555057407175);
     b = (x * 0.055630079696993) + (y * -0.20397695888897) + (z * 1.056971514242878);
     r = r > 0.0031308 and ((1.055 * pow(r, 1.0 / 2.4)) - 0.055) or (r * 12.92);
     g = g > 0.0031308 and ((1.055 * pow(g, 1.0 / 2.4)) - 0.055) or (g * 12.92);
     b = b > 0.0031308 and ((1.055 * pow(b, 1.0 / 2.4)) - 0.055) or (b * 12.92);
      r = min(max(0, r), 1); g = min(max(0, g), 1); b = min(max(0, b), 1);

     -- Values returned are clipped to 9 decimal places
     vals.x,vals.y,vals.z = nil,nil,nil
     vals.r = math.floor(r * 255 * (10^9) + 0.5) / (10^9)
     vals.g = math.floor(g * 255 * (10^9) + 0.5) / (10^9)
     vals.b = math.floor(b * 255 * (10^9) + 0.5) / (10^9)
     return vals end, -- returns: (table) RGB Values {r = ?, g = ?, b = ?}


    LAB = function(vals) -- converts: XYZ to LAB [CIELAB] (Lightness,Green-Red,Blue-Yellow)
     local x,y,z,pow = vals.x/95.047,vals.y/100,vals.z/108.883, pow
     x = x > 0.008856 and pow(x, 1/3) or (7.787 * x) + (16 / 116)
	 y = y > 0.008856 and pow(y, 1/3) or (7.787 * y) + (16 / 116)
	 z = z > 0.008856 and pow(z, 1/3) or (7.787 * z) + (16 / 116)

     vals.x,vals.y,vals.z = nil,nil,nil 
     vals.l,vals.a,vals.b = (116 * y) - 16, 500 * (x - y), 200 * (y - z);
    return vals end, -- returns: (table) LAB Values {l = ?, a = ?, b = ?}


    LUV = function(vals) -- converts: XYZ to LUV [CIELUV] (Lightness,U,V)
     local x,y,z,pow = vals.x, vals.y, vals.z, pow
     local xn,yn,zn = 100,100,100 -- placeholder: see white levels
     local un,vn = (4 * xn) / (xn + (15 * yn) + (3 * zn)), (9 * yn) / (xn + (15 * yn) + (3 * zn));

     local k,e,yr = pow((29/3),3), pow((6/29),3),y / yn
     local l = yr <= e and k * yr or 116 * pow(yr, 1/3) - 16
     local _u = (4 * x) / (x + (15 * y) + (3 * z)) or 0
	 local _v = (9 * y) / (x + (15 * y) + (3 * z)) or 0

     vals.x,vals.y,vals.z = nil,nil,nil 
     vals.l = yr <= e and k * yr or 116 * pow(yr, 1/3) - 16
     vals.u,vals.v = 13 * l * (_u - un), 13 * l * (_v - vn);
     return vals end, -- returns: (table) LUV Values {l = ?, u = ?, v = ?}

  },

---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  LAB = { -- Converts from LAB [CIELAB] (Lightness,Green-Red,Blue-Yellow)

    XYZ = function(vals) -- converts: LAB to XYZ (X,Y,Z)
     local l,a,b,pow = vals.l,vals.a,vals.b,pow
     local y,y2 if l <= 8 then y = (l*100) / 903.3; y2 = (7.787 * (y / 100)) + (16 / 116)
     else y = 100 * pow((l + 16) / 116, 3); y2 = pow(y / 100, 1/3) end
     local x,z = 100,100 -- Placeholder (see white points x and z)
     x = x / 95.047 <= 0.008856 and (95.047 * ((a / 500) + y2 - (16 / 116))) / 7.787 or 95.047 * pow((a / 500) + y2, 3);
     z = z / 108.883 <= 0.008859 and (108.883 * (y2 - (b / 200) - (16 / 116))) / 7.787 or 108.883 * pow(y2 - (b / 200), 3);
     vals.l,vals.a,vals.b,vals.x,vals.y,vals.z = nil,nil,nil,x,y,z
    return vals end, -- returns: (table) XYZ Values {x = ?, y = ?, z = ?}

    LCHab = function(vals) -- converts: LAB to LCHab (Lightness,Chroma,Hue)
     local a,b,atan2,sqrt = vals.a,vals.b,math.atan2,math.sqrt
     local hr = atan2(b,a) local h = hr * 360 / 2 / math.pi 
     local c = sqrt(a * a + b * b) if h < 0 then h = h + 360 end 
     vals.a,vals.b,vals.c,vals.h = nil,nil,c,h
    return vals end -- returns: (table) LCH Values {l = ?, c = ?, h = ?}

  },

---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  LUV = { -- Converts from LUV [CIELAB] (Lightness,U,V)

    XYZ = function(vals) -- converts: LUV to XYZ (X,Y,Z)
     local l,u,v,pow = vals.l,vals.u,vals.v,pow
     if l == 0 then -- returns: (table) XYZ Values {x = 0, y = 0, z = 0}
      vals.l,vals.u,vals.v,vals.x,vals.y,vals.z = nil,nil,nil,0,0,0 return vals end
     local xn,yn,zn = 100,100,100 -- placeholder: see white levels
     local un,vn = (4 * xn) / (xn + (15 * yn) + (3 * zn)), (9 * yn) / (xn + (15 * yn) + (3 * zn))
     local _u,_v = u / (13 * l) + un or 0, v / (13 * l) + vn or 0
	 local y = l > 8 and yn * pow( (l + 16) / 116 , 3) or yn * l * k;

     vals.l,vals.u,vals.v = nil,nil,nil
	 vals.y = l > 8 and yn * pow((l + 16)/116, 3) or yn * l * k;
	 vals.x = y * 9 * _u / (4 * _v) or 0;
	 vals.z = y * (12 - 3 * _u - 20 * _v) / (4 * _v) or 0;
    return vals end, -- returns: (table) XYZ Values {x = ?, y = ?, z = ?}
    
    LCHuv = function(vals) -- converts: LUV to LCHuv (Lightness,Chroma,Hue)
     local u,v,atan2,sqrt = vals.u,vals.v,math.atan2,math.sqrt
     local hr = atan2(v,u) local h = hr * 360 / 2 / math.pi 
     local c = sqrt(u * u + v * v) if h < 0 then h = h + 360 end 
     vals.u,vals.v,vals.c,vals.h = nil,nil,c,h
    return vals end -- returns: (table) LCH Values {l = ?, c = ?, h = ?}

  },

---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  LCHab = { -- Converts from LCHab (Lightness,Chroma,Hue)
    
    LAB = function(vals) -- convers: LCHab to LAB 
     local c,h,cos,sin = vals.c, vals.h, math.cos, math.sin
     local hr = h / 360 * 2 * math.pi
     vals.c,vals.h,vals.a, vals.b = nil,nil, c * cos(hr), c * sin(hr)
    return vals end -- returns: (table) LAB Values {l = ?, a = ?, b = ?}

  },

---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  LCHuv = { -- Converts from LCHuv (Lightness,Chroma,Hue)
    
    LAB = function(vals) -- convers: LCHuv to LAB 
     local c,h,cos,sin = vals.c, vals.h, math.cos, math.sin
     local hr = h / 360 * 2 * math.pi
     vals.c,vals.h,vals.u, vals.v = nil,nil, c * cos(hr), c * sin(hr)
    return vals end -- returns: (table) LAB Values {l = ?, a = ?, b = ?}

  },

---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  CMY = { -- Concverts from CMY (Cyan,Magenta,Yellow)

   RGB = function(vals) -- converts: CMY to RGB (Red,Green,Blue)
    local c,m,y = vals.c/100,vals.m/100,vals.y/100 local r,g,b = (1-c),(1-m),(1-y)
     vals.c,vals.m,vals.y,vals.k,vals.r,vals.g,vals.b = nil,nil,nil,nil,r*255,g*255,b*255
    return vals end, -- returns: (table) RGB Values {r = ?, g = ?, b = ?}

   CMYK = function(vals) -- converts: CMY to CMYK (Cyan,Magenta,Yellow,Key/Black)
    local c,m,y = vals.c/100, vals.m/100, vals.y/100 -- normalized properties
    local k = math.min(c,m,y) c,m,y = (c-k)/(1-k),(m-k)/(1-k),(y-k)/(1-k)
    c,m,y,k = c ~= c and 0 or c, m ~= m and 0 or m, y ~= y and 0 or y, k ~= k and 0 or k
     vals.r,vals.g,vals.b,vals.c,vals.m,vals.y,vals.k = nil,nil,nil,c*100,m*100,y*100,k*100
    return vals end, -- returns: (table) CMYK Values {c = ?, m = ?, y = ?, k = ?}

  },

---- ---- ---- ---- ---- ---- ---- ---- ---- ----

  CMYK = { -- Concverts from CMYK (Cyan,Magenta,Yellow,Key/Black)

   RGB = function(vals) -- converts: CMYK to RGB (Red,Green,Blue)
    local c,m,y,k = vals.c/100,vals.m/100,vals.y/100,vals.k/100
    local r,g,b = 1-math.min(1,c*(1-k)+k),1-math.min(1,m*(1-k)+k),1-math.min(1,y*(1-k)+k)   
     vals.c,vals.m,vals.y,vals.k,vals.r,vals.g,vals.b = nil,nil,nil,nil,r*255,g*255,b*255
    return vals end, -- returns: (table) RGB Values {r = ?, g = ?, b = ?}

   CMY = function(vals) -- converts: CMYK to CMY (Cyan,Magenta,Yellow)
    local c,m,y,k = vals.c/100,vals.m/100,vals.y/100,vals.k/100
    c,m,y = math.min(1,c*(1-k)+k),math.min(1,m*(1-k)+k),math.min(1,y*(1-k)+k) 
     vals.k,vals.c,vals.m,vals.y = nil,c*100,m*100,y*100
   return vals end -- returns: (table) CMY Values {c = ?, m = ?, y = ?}

  },

---- ---- ---- ---- ---- ---- ---- ---- ---- ----

 
  HEX = { -- Converts from HEX String (#FFFFFF) / (#FFF)

   RGB = function(str) -- converts: Hex (string) to RGB (Red,Green,Blue)

    local out,value = {} 
    local count = #str
      local selector = (count == 6 or count == 8) and "(%x%x)" or (count == 3 or count == 4) and "(%x)"
      
    --print(str)
      
    for entry in string.gmatch(str,selector) do 
    
      if count == 3 or count == 4 then
        entry = entry..entry
      end
    
    value = tonumber(entry,16) -- base 16 hex conversion
    
    if not out.r then out.r = value elseif not out.g then out.g = value 
    elseif not out.b then out.b = value 
    elseif not out.a then out.a = value end end 
  
    return out end  -- returns: (table) RGB Values {r = ?, g = ?, b = ?}

 },

}

---- ---- --- -- --- ---- ---- ---- --- -- --- ---- ---- ---- ----
------ ----- ----- ----- ----- ----- -----
 -- Color Space Conversions - Alias Population

local function _populateConversions(lookup)
 local _aliases = {} for k,v in pairs(lookup) do if v._alias then local name 
   for i = 1, #v._alias do name = v._alias[i] 
    if type(name) == 'string' then _aliases[name] = k end end end end
   for k,v in pairs(_aliases) do color.convert[k] = color.convert[v] 
   	color.convert[v][k] = function(self) self._space = v return self end
    for a,b in pairs(color.convert) do if b[v] then b[k] = b[v] 
 end end end end


 ------ ----- ----- ----- ----- ----- ----- ----- -----
  _populateConversions(colorData.spaces,color.convert) -- populate space aliases
  _populateConversions(colorData.extraSpaces,color.convert) -- populate extraSpace aliases

 ------ ----- ----- ----- ----- ----- ----- ----- -----

---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 
---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 


-- Testing Functionality of equality operator (colA == col)

-- local function codeTest()
codeTest = function()

--[[
--local test = color(255,128,13)
local test = color(128,255,9)

print(test)
print(test:asXYZ())
]]

local test = color.LCHab("#FFF0")

print(test:as("RGB"),test)
print(test:as("YcCbcCrc"):asRGB())
print(test)


--print(test,test:compliment(),-tbest)

print(color.triad("FFF1"))

print(test.hex)


--[[
local test = color(5,8,200)

print(test)
print(test:asYUV())

local a = test:asYUV()
local b = test:asYDbDr()

print(b.db /a.u )


print(test:asYUV():to("YDbDr"):as("RGB"))
print(test:asYDbDr():to("YUV"):as("RGB"))
print(test:asYDbDr():as("RGB"))


--print(color.YCbCr2020("#FFFE"))
print(color.YcCbcCrc("#FFFE"))
]]




--print(test:asYDbDr():to("RGB"))

--[[
print(test)
print(test.hex)
print(test:asHSL())
print(test:asHWB())
print(test:asCMYK())

--print(color.LCHab("#FFF"))

--print(test:toLAB())

print(test:asLAB())
print(test:asLCHuv())

print(test:asLCHab())

--print(test:asYPbPr())

print(test:asYUV())
]]



--[[
for k,v in pairs(color.convert.RGB) do 
  print(k,v) end
]]

--print(test:toLAB():toRGB())


--[[
print(test:toYCbCr601())
    
--print(color.HSL"#FF11")

print(color("#FF12"))
print(color.LAB("#FF12"))
print(color.LAB("#FF12"):toRGB())
]]

--[==[


local col = color.XYZ(44.757,40.745,54):to("RGB")
print(col.r/255)


local testColor = {r = 128, g = 22, b = 37}

 print("Starting color test ...")

 for k,v in pairs(testColor) do print(k.." : "..v) end 
 print("----------")

 color.convert.RGB.XYZ(testColor)

 --testColor.s = 50


 for k,v in pairs(testColor) do print(k.." : "..v) end 
 print("----------")

 color.convert.XYZ.LAB(testColor)

 for k,v in pairs(testColor) do print(k.." : "..v) end 

 print("----------")

 color.convert.LAB.XYZ(testColor)

 for k,v in pairs(testColor) do print(k.." : "..v) end 



print(test)

print(test:toXYZ())

print(test:toRGB())

--print(test:toRGB())

 --local test = color.HSV("#DFF1")

 --print(test:asYCgCo())

 local testColor = {r = 128, g = 200, b = 125}
 local testColor = {r = 128, g = 22, b = 37}



 print("Starting color test ...")

 for k,v in pairs(testColor) do print(k.." : "..v) end 
 print("----------")

 color.convert.RGB.TSL(testColor)

 --testColor.s = 50


 for k,v in pairs(testColor) do print(k.." : "..v) end 
 print("----------")

 color.convert.TSL.RGB(testColor)

 for k,v in pairs(testColor) do print(k.." : "..v) end 




-- [== [


 --print(_VERSION)
 local test = color.HSV("#DFF1")
 local test2 = color("HSV","#FFF3")

 print(test)
 print(test2)

 print(test.hex)

  print(test:asRGB().r)


local test3 = color{r = 0xFF, g = 0xFF, b = 0xFF}

-- local testColor = {r = 0x22, g = 0x21, b = 0x22}
 local testColor = {r = 0xFF, g = 0xFF, b = 0xFF}
 -- local testColor = {r = 128, g = 200, b = 125}

 print(test2,-test2)



 print("Starting color test ...")

 for k,v in pairs(testColor) do print(k.." : "..v) end 
 print("----------")

 color.convert.RGB.HSM(testColor)

 --testColor.s = 50

 for k,v in pairs(testColor) do print(k.." : "..v) end 
 print("----------")

 color.convert.HSM.RGB(testColor)

 for k,v in pairs(testColor) do print(k.." : "..v) end 

 --[[

print(test:asHWB())
print(test+"#FFF1")
print(test+"#FFF1")

test.opacity = 255

print(test)
print(test.hex)
print(test)

print(color.HTML4.fuchsia())
]]
  
  
  -- Constructor test (greyscale)
  local testA = col.RGB(128)
  local testB = col("RGB",128)
  local testC = col(128)
  print(testA,testB,testC)
   
  
]==]

end



---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 
---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 

---- ----- ---- ---- ---- ---- --- ---- ---- ---- ---- ---- ---- ---- ----
-- ::mark:: Defininitions for predefined (implementation specific) colors
---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
colorData.predefinedColors = {HTML4 = {}, x11 = {}} 
---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----

---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
-- Color Definitions - Holds Color Definitions separated into categories
---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----

 local HTML4 = colorData.predefinedColors.HTML4
 
  HTML4.WHITE = {RGB = {255,255,255}, HEX = "#FFFFFF"}
  HTML4.SILVER = {RGB = {192,192,192}, HEX = "#C0C0C0"}
  HTML4.GRAY = {RGB = {128,128,128}, HEX = "#808080"}
  HTML4.BLACK = {RGB = {0,0,0}, HEX = "#000000"}
  HTML4.RED = {RGB = {255,0,0}, HEX = "#FF0000"}
  HTML4.MAROON = {RGB = {128,0,0}, HEX = "#800000"}
  HTML4.YELLOW = {RGB = {255,255,0}, HEX = "#FFFF00"}
  HTML4.OLIVE = {RGB = {128,128,0}, HEX = "#808000"}
  HTML4.LIME = {RGB = {0,255,0}, HEX = "#00FF00"}
  HTML4.GREEN = {RGB = {0,128,0}, HEX = "#008000"}
  HTML4.AQUA = {RGB = {0,255,255}, HEX = "#00FFFF"}
  HTML4.TEAL = {RGB = {0,128,128}, HEX = "#008080"}
  HTML4.BLUE = {RGB = {0,0,255}, HEX = "#0000FF"}
  HTML4.NAVY = {RGB = {0,0,128}, HEX = "#000080"}
  HTML4.FUCHSIA = {RGB = {255,0,255}, HEX = "#FF00FF"}
  HTML4.PURPLE = {RGB = {128,0,128}, HEX = "#800080"}


---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 
---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------  



---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------  


colorData.predefinedColors.x11 = { 

  AntiqueWhite1 = {RGB = {255,238,219,255}, HEX = "#FFEEDB"},
  AntiqueWhite2 = {RGB = {237,223,204,255}, HEX = "#EDDFCC"},
  AntiqueWhite3 = {RGB = {205,191,175,255}, HEX = "#CDBFAF"},
  AntiqueWhite4 = {RGB = {138,130,119,255}, HEX = "#8A8277"},
  Aquamarine1 = {RGB = {126,255,211,255}, HEX = "#7EFFD3"},
  Aquamarine2 = {RGB = {118,237,197,255}, HEX = "#76EDC5"},
  Aquamarine3 = {RGB = {102,205,170,255}, HEX = "#66CDAA"},
  Aquamarine4 = {RGB = {68,138,116,255}, HEX = "#448A74"},
  Azure1 = {RGB = {239,255,255,255}, HEX = "#EFFFFF"},
  Azure2 = {RGB = {224,237,237,255}, HEX = "#E0EDED"},
  Azure3 = {RGB = {192,205,205,255}, HEX = "#C0CDCD"},
  Azure4 = {RGB = {130,138,138,255}, HEX = "#828A8A"},
  Bisque1 = {RGB = {255,227,196,255}, HEX = "#FFE3C4"},
  Bisque2 = {RGB = {237,212,182,255}, HEX = "#EDD4B6"},
  Bisque3 = {RGB = {205,182,158,255}, HEX = "#CDB69E"},
  Bisque4 = {RGB = {138,124,107,255}, HEX = "#8A7C6B"},
  Blue1 = {RGB = {0,0,255,255}, HEX = "#0000FF"},
  Blue2 = {RGB = {0,0,237,255}, HEX = "#0000ED"},
  Blue3 = {RGB = {0,0,205,255}, HEX = "#0000CD"},
  Blue4 = {RGB = {0,0,138,255}, HEX = "#00008A"},
  Brown1 = {RGB = {255,63,63,255}, HEX = "#FF3F3F"},
  Brown2 = {RGB = {237,58,58,255}, HEX = "#ED3A3A"},
  Brown3 = {RGB = {205,51,51,255}, HEX = "#CD3333"},
  Brown4 = {RGB = {138,34,34,255}, HEX = "#8A2222"},
  Burlywood1 = {RGB = {255,211,155,255}, HEX = "#FFD39B"},
  Burlywood2 = {RGB = {237,196,145,255}, HEX = "#EDC491"},
  Burlywood3 = {RGB = {205,170,124,255}, HEX = "#CDAA7C"},
  Burlywood4 = {RGB = {138,114,84,255}, HEX = "#8A7254"},
  CadetBlue1 = {RGB = {151,244,255,255}, HEX = "#97F4FF"},
  CadetBlue2 = {RGB = {141,228,237,255}, HEX = "#8DE4ED"},
  CadetBlue3 = {RGB = {122,196,205,255}, HEX = "#7AC4CD"},
  CadetBlue4 = {RGB = {82,133,138,255}, HEX = "#52858A"},
  Chartreuse1 = {RGB = {126,255,0,255}, HEX = "#7EFF00"},
  Chartreuse2 = {RGB = {118,237,0,255}, HEX = "#76ED00"},
  Chartreuse3 = {RGB = {102,205,0,255}, HEX = "#66CD00"},
  Chartreuse4 = {RGB = {68,138,0,255}, HEX = "#448A00"},
  Chocolate1 = {RGB = {255,126,35,255}, HEX = "#FF7E23"},
  Chocolate2 = {RGB = {237,118,33,255}, HEX = "#ED7621"},
  Chocolate3 = {RGB = {205,102,28,255}, HEX = "#CD661C"},
  Chocolate4 = {RGB = {138,68,19,255}, HEX = "#8A4413"},
  Coral1 = {RGB = {255,114,85,255}, HEX = "#FF7255"},
  Coral2 = {RGB = {237,105,79,255}, HEX = "#ED694F"},
  Coral3 = {RGB = {205,90,68,255}, HEX = "#CD5A44"},
  Coral4 = {RGB = {138,62,47,255}, HEX = "#8A3E2F"},
  Cornsilk1 = {RGB = {255,247,220,255}, HEX = "#FFF7DC"},
  Cornsilk2 = {RGB = {237,232,205,255}, HEX = "#EDE8CD"},
  Cornsilk3 = {RGB = {205,200,176,255}, HEX = "#CDC8B0"},
  Cornsilk4 = {RGB = {138,135,119,255}, HEX = "#8A8777"},
  Cyan1 = {RGB = {0,255,255,255}, HEX = "#00FFFF"},
  Cyan2 = {RGB = {0,237,237,255}, HEX = "#00EDED"},
  Cyan3 = {RGB = {0,205,205,255}, HEX = "#00CDCD"},
  Cyan4 = {RGB = {0,138,138,255}, HEX = "#008A8A"},
  DarkGoldenrod1 = {RGB = {255,184,15,255}, HEX = "#FFB80F"},
  DarkGoldenrod2 = {RGB = {237,173,14,255}, HEX = "#EDAD0E"},
  DarkGoldenrod3 = {RGB = {205,149,12,255}, HEX = "#CD950C"},
  DarkGoldenrod4 = {RGB = {138,100,7,255}, HEX = "#8A6407"},
  DarkOliveGreen1 = {RGB = {201,255,112,255}, HEX = "#C9FF70"},
  DarkOliveGreen2 = {RGB = {187,237,104,255}, HEX = "#BBED68"},
  DarkOliveGreen3 = {RGB = {161,205,89,255}, HEX = "#A1CD59"},
  DarkOliveGreen4 = {RGB = {109,138,61,255}, HEX = "#6D8A3D"},
  DarkOrange1 = {RGB = {255,126,0,255}, HEX = "#FF7E00"},
  DarkOrange2 = {RGB = {237,118,0,255}, HEX = "#ED7600"},
  DarkOrange3 = {RGB = {205,102,0,255}, HEX = "#CD6600"},
  DarkOrange4 = {RGB = {138,68,0,255}, HEX = "#8A4400"},
  DarkOrchid1 = {RGB = {191,62,255,255}, HEX = "#BF3EFF"},
  DarkOrchid2 = {RGB = {177,58,237,255}, HEX = "#B13AED"},
  DarkOrchid3 = {RGB = {154,49,205,255}, HEX = "#9A31CD"},
  DarkOrchid4 = {RGB = {104,33,138,255}, HEX = "#68218A"},
  DarkSeaGreen1 = {RGB = {192,255,192,255}, HEX = "#C0FFC0"},
  DarkSeaGreen2 = {RGB = {179,237,179,255}, HEX = "#B3EDB3"},
  DarkSeaGreen3 = {RGB = {155,205,155,255}, HEX = "#9BCD9B"},
  DarkSeaGreen4 = {RGB = {104,138,104,255}, HEX = "#688A68"},
  DarkSlateGray1 = {RGB = {150,255,255,255}, HEX = "#96FFFF"},
  DarkSlateGray2 = {RGB = {140,237,237,255}, HEX = "#8CEDED"},
  DarkSlateGray3 = {RGB = {121,205,205,255}, HEX = "#79CDCD"},
  DarkSlateGray4 = {RGB = {81,138,138,255}, HEX = "#518A8A"},
  DeepPink1 = {RGB = {255,20,146,255}, HEX = "#FF1492"},
  DeepPink2 = {RGB = {237,17,136,255}, HEX = "#ED1188"},
  DeepPink3 = {RGB = {205,16,118,255}, HEX = "#CD1076"},
  DeepPink4 = {RGB = {138,10,79,255}, HEX = "#8A0A4F"},
  DeepSkyBlue1 = {RGB = {0,191,255,255}, HEX = "#00BFFF"},
  DeepSkyBlue2 = {RGB = {0,177,237,255}, HEX = "#00B1ED"},
  DeepSkyBlue3 = {RGB = {0,154,205,255}, HEX = "#009ACD"},
  DeepSkyBlue4 = {RGB = {0,104,138,255}, HEX = "#00688A"},
  DodgerBlue1 = {RGB = {29,144,255,255}, HEX = "#1D90FF"},
  DodgerBlue2 = {RGB = {28,133,237,255}, HEX = "#1C85ED"},
  DodgerBlue3 = {RGB = {23,116,205,255}, HEX = "#1774CD"},
  DodgerBlue4 = {RGB = {16,77,138,255}, HEX = "#104D8A"},
  Firebrick1 = {RGB = {255,48,48,255}, HEX = "#FF3030"},
  Firebrick2 = {RGB = {237,43,43,255}, HEX = "#ED2B2B"},
  Firebrick3 = {RGB = {205,38,38,255}, HEX = "#CD2626"},
  Firebrick4 = {RGB = {138,25,25,255}, HEX = "#8A1919"},
  Gold1 = {RGB = {255,215,0,255}, HEX = "#FFD700"},
  Gold2 = {RGB = {237,201,0,255}, HEX = "#EDC900"},
  Gold3 = {RGB = {205,173,0,255}, HEX = "#CDAD00"},
  Gold4 = {RGB = {138,117,0,255}, HEX = "#8A7500"},
  Goldenrod1 = {RGB = {255,192,36,255}, HEX = "#FFC024"},
  Goldenrod2 = {RGB = {237,179,33,255}, HEX = "#EDB321"},
  Goldenrod3 = {RGB = {205,155,28,255}, HEX = "#CD9B1C"},
  Goldenrod4 = {RGB = {138,104,20,255}, HEX = "#8A6814"},
  Gray0 = {RGB = {189,189,189,255}, HEX = "#BDBDBD"},
  Green0 = {RGB = {0,255,0,255}, HEX = "#00FF00"},
  Green1 = {RGB = {0,255,0,255}, HEX = "#00FF00"},
  Green2 = {RGB = {0,237,0,255}, HEX = "#00ED00"},
  Green3 = {RGB = {0,205,0,255}, HEX = "#00CD00"},
  Green4 = {RGB = {0,138,0,255}, HEX = "#008A00"},
  Grey0 = {RGB = {189,189,189,255}, HEX = "#BDBDBD"},
  Honeydew1 = {RGB = {239,255,239,255}, HEX = "#EFFFEF"},
  Honeydew2 = {RGB = {224,237,224,255}, HEX = "#E0EDE0"},
  Honeydew3 = {RGB = {192,205,192,255}, HEX = "#C0CDC0"},
  Honeydew4 = {RGB = {130,138,130,255}, HEX = "#828A82"},
  HotPink1 = {RGB = {255,109,179,255}, HEX = "#FF6DB3"},
  HotPink2 = {RGB = {237,105,167,255}, HEX = "#ED69A7"},
  HotPink3 = {RGB = {205,95,144,255}, HEX = "#CD5F90"},
  HotPink4 = {RGB = {138,58,98,255}, HEX = "#8A3A62"},
  IndianRed1 = {RGB = {255,105,105,255}, HEX = "#FF6969"},
  IndianRed2 = {RGB = {237,99,99,255}, HEX = "#ED6363"},
  IndianRed3 = {RGB = {205,84,84,255}, HEX = "#CD5454"},
  IndianRed4 = {RGB = {138,58,58,255}, HEX = "#8A3A3A"},
  Ivory1 = {RGB = {255,255,239,255}, HEX = "#FFFFEF"},
  Ivory2 = {RGB = {237,237,224,255}, HEX = "#EDEDE0"},
  Ivory3 = {RGB = {205,205,192,255}, HEX = "#CDCDC0"},
  Ivory4 = {RGB = {138,138,130,255}, HEX = "#8A8A82"},
  Khaki1 = {RGB = {255,246,142,255}, HEX = "#FFF68E"},
  Khaki2 = {RGB = {237,229,132,255}, HEX = "#EDE584"},
  Khaki3 = {RGB = {205,197,114,255}, HEX = "#CDC572"},
  Khaki4 = {RGB = {138,133,77,255}, HEX = "#8A854D"},
  LavenderBlush1 = {RGB = {255,239,244,255}, HEX = "#FFEFF4"},
  LavenderBlush2 = {RGB = {237,224,228,255}, HEX = "#EDE0E4"},
  LavenderBlush3 = {RGB = {205,192,196,25}, HEX = "#CDC0C4"},
  LavenderBlush4 = {RGB = {138,130,133,255}, HEX = "#8A8285"},
  LemonChiffon1 = {RGB = {255,249,205,255}, HEX = "#FFF9CD"},
  LemonChiffon2 = {RGB = {237,232,191,255}, HEX = "#EDE8BF"},
  LemonChiffon3 = {RGB = {205,201,165,255}, HEX = "#CDC9A5"},
  LemonChiffon4 = {RGB = {138,136,112,255}, HEX = "#8A8870"},
  LightBlue1 = {RGB = {191,238,255,255}, HEX = "#BFEEFF"},
  LightBlue2 = {RGB = {177,223,237,255}, HEX = "#B1DFED"},
  LightBlue3 = {RGB = {154,191,205,255}, HEX = "#9ABFCD"},
  LightBlue4 = {RGB = {104,130,138,255}, HEX = "#68828A"},
  LightCyan1 = {RGB = {224,255,255,255}, HEX = "#E0FFFF"},
  LightCyan2 = {RGB = {209,237,237,255}, HEX = "#D1EDED"},
  LightCyan3 = {RGB = {179,205,205,255}, HEX = "#B3CDCD"},
  LightCyan4 = {RGB = {122,138,138,255}, HEX = "#7A8A8A"},
  LightGoldenrod1 = {RGB = {255,235,138,255}, HEX = "#FFEB8A"},
  LightGoldenrod2 = {RGB = {237,220,130,255}, HEX = "#EDDC82"},
  LightGoldenrod3 = {RGB = {205,189,112,255}, HEX = "#CDBD70"},
  LightGoldenrod4 = {RGB = {138,128,75,255}, HEX = "#8A804B"},
  LightPink1 = {RGB = {255,174,184,255}, HEX = "#FFAEB8"},
  LightPink2 = {RGB = {237,161,173,255}, HEX = "#EDA1AD"},
  LightPink3 = {RGB = {205,140,149,255}, HEX = "#CD8C95"},
  LightPink4 = {RGB = {138,94,100,255}, HEX = "#8A5E64"},
  LightSalmon1 = {RGB = {255,160,122,255}, HEX = "#FFA07A"},
  LightSalmon2 = {RGB = {237,149,114,255}, HEX = "#ED9572"},
  LightSalmon3 = {RGB = {205,128,98,255}, HEX = "#CD8062"},
  LightSalmon4 = {RGB = {138,86,66,255}, HEX = "#8A5642"},
  LightSkyBlue1 = {RGB = {175,226,255,255}, HEX = "#AFE2FF"},
  LightSkyBlue2 = {RGB = {164,211,237,255}, HEX = "#A4D3ED"},
  LightSkyBlue3 = {RGB = {140,181,205,255}, HEX = "#8CB5CD"},
  LightSkyBlue4 = {RGB = {95,123,138,255}, HEX = "#5F7B8A"},
  LightSteelBlue1 = {RGB = {201,225,255,255}, HEX = "#C9E1FF"},
  LightSteelBlue2 = {RGB = {187,210,237,255}, HEX = "#BBD2ED"},
  LightSteelBlue3 = {RGB = {161,181,205,255}, HEX = "#A1B5CD"},
  LightSteelBlue4 = {RGB = {109,123,138,255}, HEX = "#6D7B8A"},
  LightYellow1 = {RGB = {255,255,224,255}, HEX = "#FFFFE0"},
  LightYellow2 = {RGB = {237,237,209,255}, HEX = "#EDEDD1"},
  LightYellow3 = {RGB = {205,205,179,255}, HEX = "#CDCDB3"},
  LightYellow4 = {RGB = {138,138,122,255}, HEX = "#8A8A7A"},
  Magenta1 = {RGB = {255,0,255,255}, HEX = "#FF00FF"},
  Magenta2 = {RGB = {237,0,237,255}, HEX = "#ED00ED"},
  Magenta3 = {RGB = {205,0,205,255}, HEX = "#CD00CD"},
  Magenta4 = {RGB = {138,0,138,255}, HEX = "#8A008A"},
  Maroon0 = {RGB = {175,48,95,255}, HEX = "#AF305F"},
  Maroon1 = {RGB = {255,52,178,255}, HEX = "#FF34B2"},
  Maroon2 = {RGB = {237,48,167,255}, HEX = "#ED30A7"},
  Maroon3 = {RGB = {205,40,144,255}, HEX = "#CD2890"},
  Maroon4 = {RGB = {138,28,98,255}, HEX = "#8A1C62"},
  MediumOrchid1 = {RGB = {224,102,255,255}, HEX = "#E066FF"},
  MediumOrchid2 = {RGB = {209,94,237,255}, HEX = "#D15EED"},
  MediumOrchid3 = {RGB = {179,81,205,255}, HEX = "#B351CD"},
  MediumOrchid4 = {RGB = {122,54,138,255}, HEX = "#7A368A"},
  MediumPurple1 = {RGB = {170,130,255,255}, HEX = "#AA82FF"},
  MediumPurple2 = {RGB = {159,121,237,255}, HEX = "#9F79ED"},
  MediumPurple3 = {RGB = {136,104,205,255}, HEX = "#8868CD"},
  MediumPurple4 = {RGB = {93,71,138,255}, HEX = "#5D478A"},
  MistyRose1 = {RGB = {255,227,225,255}, HEX = "#FFE3E1"},
  MistyRose2 = {RGB = {237,212,210,255}, HEX = "#EDD4D2"},
  MistyRose3 = {RGB = {205,182,181,255}, HEX = "#CDB6B5"},
  MistyRose4 = {RGB = {138,124,123,255}, HEX = "#8A7C7B"},
  NavajoWhite1 = {RGB = {255,221,173,255}, HEX = "#FFDDAD"},
  NavajoWhite2 = {RGB = {237,206,160,255}, HEX = "#EDCEA0"},
  NavajoWhite3 = {RGB = {205,178,138,255}, HEX = "#CDB28A"},
  NavajoWhite4 = {RGB = {138,121,94,255}, HEX = "#8A795E"},
  OliveDrab1 = {RGB = {191,255,62,255}, HEX = "#BFFF3E"},
  OliveDrab2 = {RGB = {178,237,58,255}, HEX = "#B2ED3A"},
  OliveDrab3 = {RGB = {154,205,49,255}, HEX = "#9ACD31"},
  OliveDrab4 = {RGB = {104,138,33,255}, HEX = "#688A21"},
  Orange1 = {RGB = {255,165,0,255}, HEX = "#FFA500"},
  Orange2 = {RGB = {237,154,0,255}, HEX = "#ED9A00"},
  Orange3 = {RGB = {205,132,0,255}, HEX = "#CD8400"},
  Orange4 = {RGB = {138,89,0,255}, HEX = "#8A5900"},
  OrangeRed1 = {RGB = {255,68,0,255}, HEX = "#FF4400"},
  OrangeRed2 = {RGB = {237,63,0,255}, HEX = "#ED3F00"},
  OrangeRed3 = {RGB = {205,54,0,255}, HEX = "#CD3600"},
  OrangeRed4 = {RGB = {138,36,0,255}, HEX = "#8A2400"},
  Orchid1 = {RGB = {255,130,249,255}, HEX = "#FF82F9"},
  Orchid2 = {RGB = {237,122,232,255}, HEX = "#ED7AE8"},
  Orchid3 = {RGB = {205,104,201,255}, HEX = "#CD68C9"},
  Orchid4 = {RGB = {138,71,136,255}, HEX = "#8A4788"},
  PaleGreen1 = {RGB = {154,255,154,255}, HEX = "#9AFF9A"},
  PaleGreen2 = {RGB = {144,237,144,255}, HEX = "#90ED90"},
  PaleGreen3 = {RGB = {124,205,124,255}, HEX = "#7CCD7C"},
  PaleGreen4 = {RGB = {84,138,84,255}, HEX = "#548A54"},
  PaleTurquoise1 = {RGB = {186,255,255,255}, HEX = "#BAFFFF"},
  PaleTurquoise2 = {RGB = {174,237,237,255}, HEX = "#AEEDED"},
  PaleTurquoise3 = {RGB = {150,205,205,255}, HEX = "#96CDCD"},
  PaleTurquoise4 = {RGB = {102,138,138,255}, HEX = "#668A8A"},
  PaleVioletRed1 = {RGB = {255,130,170,255}, HEX = "#FF82AA"},
  PaleVioletRed2 = {RGB = {237,121,159,255}, HEX = "#ED799F"},
  PaleVioletRed3 = {RGB = {205,104,136,255}, HEX = "#CD6888"},
  PaleVioletRed4 = {RGB = {138,71,93,255}, HEX = "#8A475D"},
  PeachPuff1 = {RGB = {255,218,184,255}, HEX = "#FFDAB8"},
  PeachPuff2 = {RGB = {237,202,173,255}, HEX = "#EDCAAD"},
  PeachPuff3 = {RGB = {205,175,149,255}, HEX = "#CDAF95"},
  PeachPuff4 = {RGB = {138,119,100,255}, HEX = "#8A7764"},
  Pink1 = {RGB = {255,181,196,255}, HEX = "#FFB5C4"},
  Pink2 = {RGB = {237,169,183,255}, HEX = "#EDA9B7"},
  Pink3 = {RGB = {205,145,158,255}, HEX = "#CD919E"},
  Pink4 = {RGB = {138,99,108,255}, HEX = "#8A636C"},
  Plum1 = {RGB = {255,186,255,255}, HEX = "#FFBAFF"},
  Plum2 = {RGB = {237,174,237,255}, HEX = "#EDAEED"},
  Plum3 = {RGB = {205,150,205,255}, HEX = "#CD96CD"},
  Plum4 = {RGB = {138,102,138,255}, HEX = "#8A668A"},
  Purple0 = {RGB = {160,31,239,255}, HEX = "#A01FEF"},
  Purple1 = {RGB = {155,48,255,255}, HEX = "#9B30FF"},
  Purple2 = {RGB = {145,43,237,255}, HEX = "#912BED"},
  Purple3 = {RGB = {124,38,205,255}, HEX = "#7C26CD"},
  Purple4 = {RGB = {84,25,138,255}, HEX = "#54198A"},
  Red1 = {RGB = {255,0,0,255}, HEX = "#FF0000"},
  Red2 = {RGB = {237,0,0,255}, HEX = "#ED0000"},
  Red3 = {RGB = {205,0,0,255}, HEX = "#CD0000"},
  Red4 = {RGB = {138,0,0,255}, HEX = "#8A0000"},
  RosyBrown1 = {RGB = {255,192,192,255}, HEX = "#FFC0C0"},
  RosyBrown2 = {RGB = {237,179,179,255}, HEX = "#EDB3B3"},
  RosyBrown3 = {RGB = {205,155,155,255}, HEX = "#CD9B9B"},
  RosyBrown4 = {RGB = {138,104,104,255}, HEX = "#8A6868"},
  RoyalBlue1 = {RGB = {72,118,255,255}, HEX = "#4876FF"},
  RoyalBlue2 = {RGB = {67,109,237,255}, HEX = "#436DED"},
  RoyalBlue3 = {RGB = {58,94,205,255}, HEX = "#3A5ECD"},
  RoyalBlue4 = {RGB = {38,63,138,255}, HEX = "#263F8A"},
  Salmon1 = {RGB = {255,140,104,255}, HEX = "#FF8C68"},
  Salmon2 = {RGB = {237,130,98,255}, HEX = "#ED8262"},
  Salmon3 = {RGB = {205,112,84,255}, HEX = "#CD7054"},
  Salmon4 = {RGB = {138,75,57,255}, HEX = "#8A4B39"},
  SeaGreen1 = {RGB = {84,255,159,255}, HEX = "#54FF9F"},
  SeaGreen2 = {RGB = {77,237,147,255}, HEX = "#4DED93"},
  SeaGreen3 = {RGB = {67,205,127,255}, HEX = "#43CD7F"},
  SeaGreen4 = {RGB = {45,138,86,255}, HEX = "#2D8A56"},
  Seashell1 = {RGB = {255,244,237,255}, HEX = "#FFF4ED"},
  Seashell2 = {RGB = {237,228,221,255}, HEX = "#EDE4DD"},
  Seashell3 = {RGB = {205,196,191,255}, HEX = "#CDC4BF"},
  Seashell4 = {RGB = {138,133,130,255}, HEX = "#8A8582"},
  Sienna1 = {RGB = {255,130,71,255}, HEX = "#FF8247"},
  Sienna2 = {RGB = {237,121,66,255}, HEX = "#ED7942"},
  Sienna3 = {RGB = {205,104,57,255}, HEX = "#CD6839"},
  Sienna4 = {RGB = {138,71,38,255}, HEX = "#8A4726"},
  SkyBlue1 = {RGB = {135,206,255,255}, HEX = "#87CEFF"},
  SkyBlue2 = {RGB = {125,191,237,255}, HEX = "#7DBFED"},
  SkyBlue3 = {RGB = {108,165,205,255}, HEX = "#6CA5CD"},
  SkyBlue4 = {RGB = {73,112,138,255}, HEX = "#49708A"},
  SlateBlue1 = {RGB = {130,110,255,255}, HEX = "#826EFF"},
  SlateBlue2 = {RGB = {122,103,237,255}, HEX = "#7A67ED"},
  SlateBlue3 = {RGB = {104,89,205,255}, HEX = "#6859CD"},
  SlateBlue4 = {RGB = {71,59,138,255}, HEX = "#473B8A"},
  SlateGray1 = {RGB = {197,226,255,255}, HEX = "#C5E2FF"},
  SlateGray2 = {RGB = {184,211,237,255}, HEX = "#B8D3ED"},
  SlateGray3 = {RGB = {159,181,205,255}, HEX = "#9FB5CD"},
  SlateGray4 = {RGB = {108,123,138,255}, HEX = "#6C7B8A"},
  Snow1 = {RGB = {255,249,249,255}, HEX = "#FFF9F9"},
  Snow2 = {RGB = {237,232,232,255}, HEX = "#EDE8E8"},
  Snow3 = {RGB = {205,201,201,255}, HEX = "#CDC9C9"},
  Snow4 = {RGB = {138,136,136,255}, HEX = "#8A8888"},
  SpringGreen1 = {RGB = {0,255,126,255}, HEX = "#00FF7E"},
  SpringGreen2 = {RGB = {0,237,118,255}, HEX = "#00ED76"},
  SpringGreen3 = {RGB = {0,205,102,255}, HEX = "#00CD66"},
  SpringGreen4 = {RGB = {0,138,68,255}, HEX = "#008A44"},
  SteelBlue1 = {RGB = {99,183,255,255}, HEX = "#63B7FF"},
  SteelBlue2 = {RGB = {91,172,237,255}, HEX = "#5BACED"},
  SteelBlue3 = {RGB = {79,147,205,255}, HEX = "#4F93CD"},
  SteelBlue4 = {RGB = {53,99,138,255}, HEX = "#35638A"},
  Tan1 = {RGB = {255,165,79,255}, HEX = "#FFA54F"},
  Tan2 = {RGB = {237,154,73,255}, HEX = "#ED9A49"},
  Tan3 = {RGB = {205,132,63,255}, HEX = "#CD843F"},
  Tan4 = {RGB = {138,89,43,255}, HEX = "#8A592B"},
  Thistle1 = {RGB = {255,225,255,255}, HEX = "#FFE1FF"},
  Thistle2 = {RGB = {237,210,237,255}, HEX = "#EDD2ED"},
  Thistle3 = {RGB = {205,181,205,255}, HEX = "#CDB5CD"},
  Thistle4 = {RGB = {138,123,138,255}, HEX = "#8A7B8A"},
  Tomato1 = {RGB = {255,99,71,255}, HEX = "#FF6347"},
  Tomato2 = {RGB = {237,91,66,255}, HEX = "#ED5B42"},
  Tomato3 = {RGB = {205,79,57,255}, HEX = "#CD4F39"},
  Tomato4 = {RGB = {138,53,38,255}, HEX = "#8A3526"},
  Turquoise1 = {RGB = {0,244,255,255}, HEX = "#00F4FF"},
  Turquoise2 = {RGB = {0,228,237,255}, HEX = "#00E4ED"},
  Turquoise3 = {RGB = {0,196,205,255}, HEX = "#00C4CD"},
  Turquoise4 = {RGB = {0,133,138,255}, HEX = "#00858A"},
  VioletRed1 = {RGB = {255,62,150,255}, HEX = "#FF3E96"},
  VioletRed2 = {RGB = {237,58,140,255}, HEX = "#ED3A8C"},
  VioletRed3 = {RGB = {205,49,119,255}, HEX = "#CD3177"},
  VioletRed4 = {RGB = {138,33,81,255}, HEX = "#8A2151"},
  Wheat1 = {RGB = {255,230,186,255}, HEX = "#FFE6BA"},
  Wheat2 = {RGB = {237,216,174,255}, HEX = "#EDD8AE"},
  Wheat3 = {RGB = {205,186,150,255}, HEX = "#CDBA96"},
  Wheat4 = {RGB = {138,125,102,255}, HEX = "#8A7D66"},
  Yellow1 = {RGB = {255,255,0,255}, HEX = "#FFFF00"},
  Yellow2 = {RGB = {237,237,0,255}, HEX = "#EDED00"},
  Yellow3 = {RGB = {205,205,0,255}, HEX = "#CDCD00"},
  Yellow4 = {RGB = {138,138,0,255}, HEX = "#8A8A00"}

}

local x11 = colorData.predefinedColors.x11


---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 
---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 

---- ----- ---- ---- ---- ---- --- ---- ---- ---- ---- ---- ---- ---- ----
-- ::mark:: Defininitions for predefined (implementation specific) colors
---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
colorData.whitePoints = {CIE1931 = {}, CIE1964 = {}} 
---- ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----

 local CIE1931 = colorData.whitePoints.CIE1931 -- CIE 1931 (2°)

 local CIE1964 = colorData.whitePoints.CIE1964 -- CIE 1964 (10°)

---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 
---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 

-- codeTest() -- called to test the Color Library

-- ::mark: Codea Bindings :toCodeaColor :fromCodeaColor 
-- SX Namespace Initialization
if SX == nil then SX = {} end

color.fromCodeaColor = function(codeaColor)
  return color(codeaColor.r,codeaColor.g,codeaColor,b,codeaColor.alpha)
end

color.toCodeaColor = function(self)
    local RGBColor = self:as("RGB")
    return _G.color(RGBColor.r,RGBColor.g,RGBColor.b,RGBColor.alpha)
end

SX.color = color
color = _oldColor

---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 
---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- 

-- codeTest() -- called to test the Color Library

---------- ---------- ---------- ---------- 
-- Debug Tests 
---------- ---------- ---------- ---------- 

-- Tests hex value conversions
local function testHEX(lookup)
  
  print("[Test]: Running hexidecimal test.")
  
  for name,data in pairs(lookup) do
  
    local colVal = color(data.RGB)
    local colHex = color(data.HEX)
  
  if colVal.hex == colHex.hex then
    print(name.." (Cleared) "..data.HEX)
  else 
    print(name.." (Failed) "..data.HEX) end
    
  end
end

-- testHEX(HTML4)
-- testHEX(x11)

---------- ---------- ---------- ---------- 
-- TODOs / Issues: 05-24
---------- ---------- ---------- ---------- 

--[[

• color.alpha should be set at all times a new color object is created. (or remove alpha channel until assigned?) - maybe not

• equals operator should it be added and how would it round

• make color conversion functions more percise

--------- ----------

• expand the header(s) + tie in more to conversion scales + add default values?
• unify constructor toString data

• Document new hex features and offsets


---------- -----------

• Alpha doesnt construct properly when creating a new color with a hex

]]



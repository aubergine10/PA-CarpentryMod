
-- # local vars ------------------------------------------------------------

-- shortcut
local print = Game.DebugOut

-- despam Update
local Now   = Game.Time
local Delay = 2
local Ready = Now() + Delay

-- finding objects
local Find  = this.GetNearbyObjects
local OnMap = 9001

-- stack cache (refreshed each despammed update)
local StackCache

-- tree orders
local TreesOrdered = false
local ReorderThreshold = 10

-- remember if we've already converted to exportable logs/wood
local AlreadyExporting = {}

-- current embargo defined by Embargoes.SubType:
  -- 0 = none
  -- 1 = logs embargoed
  -- 2 = wood embargoed
  -- 3 = logs + wood embargoed
local Embargoes

-- lookup tables to work out if objType is sellable
local CanSell = {}
CanSell.Log  = { [ 0 ] = true, [ 2 ] = true }
CanSell.Wood = { [ 0 ] = true, [ 1 ] = true }

-- emabrgo tooltips
local Prefix = 'tooltip_embargo_'
local Tooltips = {
  [ 0 ] = Prefix..'none',
  [ 1 ] = Prefix..'logs',
  [ 2 ] = Prefix..'wood',
  [ 3 ] = Prefix..'both'
}

-- # PA Bug #9969 workaround -----------------------------------------------

-- see http://bugs.introversion.co.uk/view.php?id=9969

-- make it easy to find everything affected by this bug
local Bug9969 = {}

-- find numeric index for objType in a stack if not what expected
Bug9969.GetNumFor = function( test, objType, expected )
  local actual
  test.Contents = expected
  if test.Contents == objType then -- we were lucky this time
    actual = expected
  else -- cycle through a shit load of variations to see if we can find it
    for i = 1, 500 do
      test.Contents = i
      if test.Contents == objType then
        actual = i
        break
      end
    end
  end
  return actual -- will be nil if not found (unlikely as this mod should have added the objType)
end

-- cache numbers for our obj types
Bug9969.CacheNums = function()
  local test = Object.Spawn( 'Stack', 0, 0 )
  Bug9969['Log']   = Bug9969.GetNumFor( test, 'Log'  , 45  )
  Bug9969['Log2']  = Bug9969.GetNumFor( test, 'Log2' , 176 )
  Bug9969['Wood']  = Bug9969.GetNumFor( test, 'Wood' , 46  )
  Bug9969['Wood2'] = Bug9969.GetNumFor( test, 'Wood2', 177 )
  test.Delete()
end

Bug9969.CacheNums()


-- # generic functions -----------------------------------------------------

local function CacheStacks()
  StackCache = Find( 'Stack', OnMap )
end

-- replace oldType objects with newType objects
local function ConvertObjects( oldType, newType )
  local new
  for old in next, Find( oldType, OnMap ) do
    -- create new object in same pos as old one
    new = Object.Spawn( newType, old.Pos.x, old.Pos.y )
    -- orient same as old object
    new.Or.x, new.Or.y = old.Or.x, old.Or.y
    -- delete old object
    old.Delete()
  end
end

-- determine if a stack is already in/on a saw
local InSaw do
  local find = Object.GetNearbyObjects
  
  InSaw = function( stack )
    return find( stack, 'WorkshopSaw', 2 ) or find( stack, 'WoodSaw', 2 )
  end
end

-- replace oldType stacks with newType stacks
local function ConvertStacks( oldType, newType )
  newType = Bug9969[ newType ] -- delete this line when bug is fixed
  for stack in next, StackCache do
    if stack.Contents == oldType and not InSaw(stack) then
      stack.Contents = newType
    end
  end
end


-- # tree ordering ---------------------------------------------------------

-- note: OrderTree objects self-destruct after loading a save (OrderTree.lua)

-- count number of trees in stacks
local function NumStackedTrees()
  local treeCount = 0

  for stack in next, StackCache do
    if stack.Contents == 'Tree' then
      treeCount = treeCount + stack.Quantity
    end
  end

  return treeCount
end

-- order more trees if necesary, otherwise cancel outstanding orders
local function UpdateTreeOrders()
  if NumStackedTrees() < ReorderThreshold then -- order more trees
    TreesOrdered = TreesOrdered or Object.Spawn( 'OrderTree', 0, 0 )

  elseif TreesOrdered then -- cancel exissting order
    TreesOrdered.Delete()
    TreesOrdered = false

  end
end


-- # log/wood sales --------------------------------------------------------

local function UpdateExports( sellableType, embargoedType )
  local oldType, newType

  if CanSell[ sellableType ][ Embargoes.SubType ] then
    if AlreadyExporting[ sellableType ] then -- no action required
      return
    else -- lift embargo
      oldType, newType = embargoedType, sellableType
      AlreadyExporting[ sellableType ] = true
    end
  else -- impose embargo
    oldType, newType = sellableType, embargoedType
    AlreadyExporting[ sellableType ] = false
  end

  ConvertObjects( oldType, newType )
  ConvertStacks(  oldType, newType )
end


-- # game events -----------------------------------------------------------

-- triggered once when foreman object created
function Create()
  -- create embargo object
  Embargoes = Object.Spawn( 'ExportEmbargoes', this.Pos.x, this.Pos.y )
  -- make foreman carry the embargos
  this.Carrying.i, this.Carrying.u = Embargoes.Id.i, Embargoes.Id.u
  Embargoes.CarrierId.i, Embargoes.CarrierId.u = this.Id.i, this.Id.u
  -- tooltip
  this.Tooltip = Tooltips[ Embargoes.SubType ]
  -- use recurring update from now on
  _G.Update = _G.RecurringUpdate
  _G.RecurringUpdate = nil
end

-- triggered once when loading a save game
function Update()
  -- get embargo
  Embargoes = next( Find( 'ExportEmbargoes', 2 ) )
  if not Embargoes then return Create() end
  -- tooltip
  this.Tooltip = Tooltips[ Embargoes.SubType ]
  -- use recurring update from now on
  _G.Update = _G.RecurringUpdate
  _G.RecurringUpdate = nil
end

-- recurring update
function RecurringUpdate()
  if Now() > Ready then
    
    this.Tooltip = Tooltips[ Embargoes.SubType ]

    CacheStacks()

    UpdateTreeOrders()

    UpdateExports( 'Log' , 'Log2'  )
    UpdateExports( 'Wood', 'Wood2' )

    Ready = Now() + Delay
  end
end

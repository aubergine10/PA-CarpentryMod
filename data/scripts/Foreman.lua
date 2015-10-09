
-- # local vars ------------------------------------------------------------

-- shortcut
local print = Game.DebugOut

-- despam Update
local Now   = Game.Time
local Delay = 4 -- game seconds = prison minutes
local Ready = Now() + Delay

-- finding objects
local Find  = this.GetNearbyObjects
local OnMap = 9001

-- remember if we've already converted to exportable logs/wood
local AlreadyExporting = {}

-- tree orders
local TreesOrdered = false
local ReorderThreshold = 10

-- current embargo defined by Embargoes.SubType:
  -- 0 = none
  -- 1 = logs embargoed
  -- 2 = wood embargoed
  -- 3 = logs + wood embargoed
local Embargoes

-- lookup tables to work out if objType is sellable
local CanSell = {}
CanSell.Logs = { [ 0 ] = true, [ 2 ] = true }
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
  Bug9969['Log'  ] = Bug9969.GetNumFor( test, 'Log'  , 45  )
  Bug9969['Log2' ] = Bug9969.GetNumFor( test, 'Log2' , 176 )
  Bug9969['Wood' ] = Bug9969.GetNumFor( test, 'Wood' , 46  )
  Bug9969['Wood2'] = Bug9969.GetNumFor( test, 'Wood2', 177 )
  test.Delete()
end

Bug9969.CacheNums()


-- # helper functions ------------------------------------------------------

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

-- determine if we are processing a stack
local Processing = Object.GetNearbyObjects

local function Sawing( stack )
    return next( Processing( stack, 'WorkshopSaw', 2 ) ) or
           next( Processing( stack, 'WoodSaw'    , 2 ) )
end

local function MakingBed( stack )
    return next( Processing( stack, 'CarpenterTable', 2 ) )
end

-- convert resources based on embargoed state, and order trees if required
local function ManageResources( currentEmbargoes )

  -- work out what we need to convert from/to

  local logs, otherLogs, convertLogs,
        wood, otherWood, convertWood

  if CanSell.Logs[ currentEmbargoes ] then
    logs, otherLogs = 'Log2', 'Log'
    convertLogs = not AlreadyExporting.Logs -- new logs default to exportable
    AlreadyExporting.Logs = true
  else
    logs, otherLogs = 'Log', 'Log2'
    convertLogs = true
    AlreadyExporting.Logs = false
  end

  if CanSell.Wood[ currentEmbargoes ] then
    logs, otherWood = 'Wood2', 'Wood'
    convertLogs = not AlreadyExporting.Wood -- new wood default to exportable
    AlreadyExporting.Wood = true
  else
    logs, otherWood = 'Wood', 'Wood2'
    convertLogs = true
    AlreadyExporting.Wood = false
  end

  -- objects

  if convertLogs then ConvertObjects( logs, otherLogs ) end
  if convertWood then ConvertObjects( wood, otherWood ) end

  -- stacks

  local stacks = Find( 'Stack', OnMap )
  local treeCount, contents = 0

  for stack in next, stacks do

    contents = stack.Contents

    if contents == 'Tree' then
      treeCount = treeCount + stack.Quantity

    else if contents == logs then
      if not Sawing( stack ) then
        stack.Contents = Bug9969[ otherLogs ]
      end

    else if contents == wood then
      if not MakingBed( stack ) then
        stack.Contents = Bug9969[ otherWood ]
      end

    end

  end

  -- trees

  if treeCount < ReorderThreshold then -- order more trees
    TreesOrdered = TreesOrdered or Object.Spawn( 'OrderTree', 0, 0 )

  elseif TreesOrdered then -- cancel exissting order
    TreesOrdered.Delete()
    TreesOrdered = false

  end

end

-- set .i and .u
local function SetId( target, source )
  target.i, target.u = source.i, source.u
end


-- # game events -----------------------------------------------------------

-- triggered once when foreman object created
function Create()
  -- if triggered by Update() we might alrady have embargoes
  Embargoes = next( Find( 'ExportEmbargoes', 2 ) )
  -- create if not found
  if not Embargoes then
    Embargoes = Object.Spawn( 'ExportEmbargoes', this.Pos.x, this.Pos.y )
    -- make foreman carry the embargos
    SetId( this.Carrying,  Embargoes.Id )
    SetId( Embargoes.CarrierId, this.Id )
  end
  -- tooltip
  this.Tooltip = Tooltips[ Embargoes.SubType ]
  -- use recurring update from now on
  _G.Update = _G.RecurringUpdate
  _G.RecurringUpdate = nil
end

-- triggered once when loading a save game
function Update()
  Create() -- reinitialise script
end

-- recurring update
function RecurringUpdate()
  if Now() > Ready then

    local currentEmbargoes = Embargoes.SubType

    this.Tooltip = Tooltips[ currentEmbargoes ]

    ManageResources( currentEmbargoes )

    Ready = Now() + Delay
  end
end

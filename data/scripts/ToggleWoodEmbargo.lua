
-- lookup table to toggle embargos [ current in square brackets ]
  -- 0 = none
  -- 1 = logs
  -- 2 = wood
  -- 3 = logs + wood
local toggle = {
  [ 0 ] = 2,
  [ 1 ] = 3,
  [ 2 ] = 0,
  [ 3 ] = 1
}

function Create()
  local foreman = next( this.GetNearbyObjects( 'Foreman', 9001 ) )
  local embargo = next( foreman.GetNearbyObjects( 'ExportEmbargoes', 2 ) )

  embargo.SubType = toggle[ embargo.SubType ]

  this.Delete()
end

function Update()
  this.Delete()
end

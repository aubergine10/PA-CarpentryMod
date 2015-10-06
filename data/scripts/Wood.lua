
local embargoed = { [ 2 ] = true, [ 3 ] = true }

function Create()
  local foreman = next( this.GetNearbyObjects( 'Foreman', 9001 ) )
  local embargo = next( foreman.GetNearbyObjects( 'ExportEmbargoes', 2 ) )

  if embargoed[ embargo.SubType ] then -- convert to Log2
    local new = Object.Spawn( 'Wood2', this.Pos.x, this.Pos.y )
    new.Or.x, new.Or.y = this.Or.x, this.Or.y
    this.Delete()
  end
end

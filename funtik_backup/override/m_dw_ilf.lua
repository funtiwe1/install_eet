
function dwOnRentRoomButtonClick()
	roomtype=storeScreen:GetRoomType()
	C:Eval('SetGlobal("dw_inn_roomtype","GLOBAL",'..roomtype..')')
	storeScreen:OnRentRoomButtonClick()
end

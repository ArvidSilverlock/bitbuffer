local function CFrameCase(x, y, z)
	return CFrame.fromEulerAnglesYXZ(math.rad(x), math.rad(y), math.rad(z))
end

return {
	CFrameCase(0, 0, 0),
	CFrameCase(90, 0, 0),
	CFrameCase(0, 180, 180),
	CFrameCase(-90, 0, 0),
	CFrameCase(0, 180, 90),
	CFrameCase(0, 90, 90),
	CFrameCase(0, 0, 90),
	CFrameCase(0, -90, 90),
	CFrameCase(-90, -90, 0),
	CFrameCase(0, -90, 0),
	CFrameCase(90, -90, 0),
	CFrameCase(0, 90, 180),
	CFrameCase(0, 180, 0),
	CFrameCase(-90, -180, 0),
	CFrameCase(0, 0, 180),
	CFrameCase(90, 180, 0),
	CFrameCase(0, 0, -90),
	CFrameCase(0, -90, -90),
	CFrameCase(0, -180, -90),
	CFrameCase(0, 90, -90),
	CFrameCase(90, 90, 0),
	CFrameCase(0, 90, 0),
	CFrameCase(-90, 90, 0),
	CFrameCase(0, -90, 180),
}

----------------------------------------------------------------------
-- Merge Folder Images (Aseprite script)
-- Version 0.1.0
-- https://github.com/linecross/aseprite-scripts
--
-- Usage:
-- Merge all gifs(same freq) or png under the specified folder.
-- Images will be align from left to right.
-- 1. Merge by Fixed Columns
-- 2. Merge by Max Width
----------------------------------------------------------------------
function getfolderSprites(dir, ext)
	local sprites = {}
	local count = 1
	for _, filename in pairs(app.fs.listFiles(dir)) do
		local fullFilename = app.fs.joinPath(dir, filename)
		if (app.fs.isFile(fullFilename) and app.fs.fileExtension(fullFilename):lower() == ext:lower()) then
			local sprite = app.open(fullFilename)
			app.activeSprite = sprite
			app.command.ChangePixelFormat{format="rgb"}
			sprites[count] = sprite
			count = count + 1
		end
	end
	return sprites
end


function mergeImgByColumns(dir, ext, columns, paddingX, paddingY)
	local posX, posY = 0, 0
	local rowWidth = 0
	local rowGroupLayer = nil
	local gifGroupLayer = nil
	
	local sprites = getfolderSprites(dir, ext)
	local outSprite = Sprite(1, 1)

	app.transaction(function()
		app.activeSprite = outSprite
		if (#sprites > 0) then
			local sprite = sprites[1]
			outSprite.width = sprite.width
			outSprite.height = sprite.height
			for i = 2, #sprite.frames do
				outSprite:newEmptyFrame()
			end
			for i, frame in ipairs(sprite.frames) do
				outSprite.frames[i].duration = frame.duration
			end
			gifGroupLayer = outSprite:newGroup()
			gifGroupLayer.name = 'Gif Group'
		end

		for count,sprite in pairs(sprites) do
			local width = sprite.width
			local height = sprite.height

			posX = rowWidth + paddingX
			if (count % columns == 1 or columns == 1) then
				posX = 0
				rowWidth = width
				if (count ~= 1) then
					posY = outSprite.height + paddingY
				end
			else
				rowWidth = rowWidth + paddingX + width
			end

			if (rowWidth > outSprite.width) then
				outSprite.width = rowWidth
			end
			if (posY + paddingY + height > outSprite.height) then
				outSprite.height = posY + paddingY + height
			end

			if (count % columns == 1 or columns == 1) then
				rowGroupLayer = outSprite:newGroup()
				rowGroupLayer.name = 'Row ' .. math.ceil(count / columns)
				rowGroupLayer.parent = gifGroupLayer

				app.activeLayer = rowGroupLayer
				app.command.OpenGroup()
			end

			local outLayer = outSprite:newLayer()
			outLayer.name = app.fs.fileTitle(sprite.filename)
			outLayer.parent = rowGroupLayer
			for i = 1, #outSprite.frames do
				local image = sprite.layers[1].cels[i].image
				local pos = Point(posX, posY)
				outSprite:newCel(outLayer, i, image, pos)
			end
		end

		if (outSprite ~= nil) then
			app.activeSprite = outSprite
			app.activeFrame = 1
            app.activeLayer = gifGroupLayer
			app.command.ColorQuantization{ui=false, maxColors=6000}
            app.refresh()
		end
	end)
	for count,sprite in pairs(sprites) do
		sprite:close()
	end
	
end


function mergeImgByMaxWidth(dir, ext, maxWidth, paddingX, paddingY)
	local rowCount = 0
	local posX, posY = 0, 0
	local rowWidth = 0
	local rowGroupLayer = nil
	local gifGroupLayer = nil

	local sprites = getfolderSprites(dir, ext)
	local outSprite = Sprite(1, 1)

	app.transaction(function()
		app.activeSprite = outSprite
		if (#sprites > 0) then
			local sprite = sprites[1]
			outSprite.width = sprite.width
			outSprite.height = sprite.height
			for i = 2, #sprite.frames do
				outSprite:newEmptyFrame()
			end
			for i, frame in ipairs(sprite.frames) do
				outSprite.frames[i].duration = frame.duration
			end
			gifGroupLayer = outSprite:newGroup()
			gifGroupLayer.name = 'Gif Group'
		end

		for count,sprite in pairs(sprites) do
			local width = sprite.width
			local height = sprite.height

			local isNewRow = false
			posX = rowWidth + paddingX
			rowWidth = rowWidth + paddingX + width
			if (count == 1) then
				posX = 0
			end
			if (rowWidth > maxWidth) then
				posX = 0
				rowWidth = width
				isNewRow = true
				if (count ~= 1) then
					posY = outSprite.height + paddingY
				end
			end

			if (rowWidth > outSprite.width) then
				outSprite.width = rowWidth
			end
			if (posY + paddingY + height > outSprite.height) then
				outSprite.height = posY + paddingY + height
			end

			if (count == 1 or isNewRow) then
				rowCount = rowCount + 1
				rowGroupLayer = outSprite:newGroup()
				rowGroupLayer.name = 'Row ' .. rowCount
				rowGroupLayer.parent = gifGroupLayer

				app.activeLayer = rowGroupLayer
				app.command.OpenGroup()
			end

			local outLayer = outSprite:newLayer()
			outLayer.name = app.fs.fileTitle(sprite.filename)
			outLayer.parent = rowGroupLayer
			for i = 1, #outSprite.frames do
				local image = sprite.layers[1].cels[i].image
				local pos = Point(posX, posY)
				outSprite:newCel(outLayer, i, image, pos)
			end
		end
		
		if (outSprite ~= nil) then
			app.activeSprite = outSprite
			app.activeFrame = 1
			app.command.ColorQuantization{ui=false, maxColors=6000}
            app.activeLayer = gifGroupLayer
            app.refresh()
		end
	end)
	for count,sprite in pairs(sprites) do
		sprite:close()
	end
end

function getFileCount(dir, ext)
	local count = 0
	for _,filename in pairs(app.fs.listFiles(dir)) do
		local fullFilename = app.fs.joinPath(dir, filename)
		if (app.fs.isFile(fullFilename) and app.fs.fileExtension(fullFilename):lower() == ext:lower()) then
			count = count + 1
		end
	end
	return count
end

function mergeImgDlg()
	local dlg = Dialog('Merge Folder Images')
	dlg:entry{ id="dir", label="Folder Path :", focus=true, text="", onchange=function()
		local count = getFileCount(dlg.data.dir, dlg.data.ext)
		dlg:modify{id="countLabel", text=count}
		dlg:modify{id="ok", enabled=(count > 0)}
	end}
	dlg:combobox{ id="ext", label="File Type :", option="gif", options={"gif", "png"}, onchange=function()
		local count = getFileCount(dlg.data.dir, dlg.data.ext)
		dlg:modify{id="countLabel", text=count}
		dlg:modify{id="ok", enabled=(count > 0)}
	end}
	dlg:label{ id="countLabel", label="Files :", text="0" }
	dlg:separator{}

	dlg:combobox{ id="mergeType", label="Merge Type :", option="columns", options={"Fixed Columns", "Max Width" }, onchange=function()
		dlg:modify{id="fixCol", visible=(dlg.data.mergeType == "Fixed Columns")}
		dlg:modify{id="maxWidth", visible=(dlg.data.mergeType == "Max Width")}
	end}
	dlg:number{ id="fixCol", label="Columns :" , text="100" }
	dlg:number{ id="maxWidth", label="Max Width :" , text="300" }
	dlg:number{ id="paddingX", label="Padding X :" , text="0" }
	dlg:number{ id="paddingY", label="Padding Y :" , text="0" }
	
	dlg:button{ id="ok", text="OK", onclick=function() 
		local data = dlg.data
		if (data.mergeType == "Fixed Columns" and data.fixCol <= 0) then
			app.alert({title="Invalid Input", text="Columns must > 0"})
			return
		end
		if (data.mergeType == "Max Width" and data.maxWidth <= 0) then
			app.alert({title="Invalid Input", text="Max Width must > 0"})
			return
		end

		if (data.mergeType == "Fixed Columns") then
			mergeImgByColumns(data.dir, data.ext, data.fixCol, data.paddingX, data.paddingY)
		elseif (data.mergeType == "Max Width") then
			mergeImgByMaxWidth(data.dir, data.ext, data.maxWidth, data.paddingX, data.paddingY)
		end
		dlg:close()
	end}
	dlg:button{ id="cancel", text="Cancel" }

	dlg:modify{id="maxWidth", visible=false}
	dlg:modify{id="ok", enabled=false}
	
	dlg:show{wait=false}

    local bounds = dlg.bounds
    dlg.bounds = Rectangle(bounds.x-100, bounds.y, bounds.width+200, bounds.height)
end

mergeImgDlg()
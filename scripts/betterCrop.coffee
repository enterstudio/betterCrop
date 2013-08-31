# @codekit-prepend "resizable.coffee"
# @codekit-prepend "draggable.coffee"

$(document).ready ->
	window.betterCrop = {}
	betterCrop.$container = $("#img-container")
	betterCrop.minHeight = betterCrop.$container.height()
	betterCrop.minWidth = betterCrop.$container.width()
	betterCrop.maxOffset = betterCrop.$container.offset()
	betterCrop.$container.acceptsFileDrops()


do ($ = window.jQuery) ->
	$.fn.acceptsFileDrops = ->
		@on "dragover dragenter", (e) ->
			e.preventDefault()
			e.stopPropagation()
			
			$(@).addClass("dragover")
			
			return false

		@on "dragleave", (e) ->
			e.preventDefault()
			e.stopPropagation()
			
			$(@).removeClass("dragover")
			
			return false
		
		@on "drop", (e) ->
			e.preventDefault()
			e.stopPropagation()
			
			$(@).removeClass("dragover")

			readFile(e.originalEvent.dataTransfer.files[0])

			return false

		@on "click", (e) ->
			e.preventDefault()
			e.stopPropagation()

			$("""<input type="file">""")
				.on "change", (e) =>
					readFile(e.originalEvent.target.files[0])
					
					return
				
				.click()

			return false

		return @

	return

readFile = (file) ->
	fileReader = new FileReader()
	fileReader.onload = addImage
	fileReader.readAsDataURL(file)

	return

addImage = (e) ->
	betterCrop.$container.find("span").text("Loading image...")
	$("<img>")
		.css
			visibility: "hidden"
		.attr("src", e.target.result)
		.appendTo(betterCrop.$container)
		.on("load", imgLoadHandler)

	return

imgLoadHandler = (e) ->
	betterCrop.maxHeight = $(@).height()
	betterCrop.maxWidth = $(@).width()

	{minHeight, minWidth, maxHeight, maxWidth, maxOffset} = betterCrop

	if maxWidth < minWidth or maxHeight < minHeight
		alert("Image is too small to fit. Try another image.")
		return

	betterCrop.$container
		.off("dragover dragenter dragleave click")
		.find("ol").remove()

	if minHeight / maxHeight * maxWidth > minWidth
		width = minHeight / maxHeight * maxWidth
		height = minHeight
	else
		height = minWidth / maxWidth * maxHeight
		width = minWidth

	$(@).css
		visibility: "visible"
		height: height
		width: width
		left: (minWidth - width) / 2
		top: (minHeight - height) / 2

	
	betterCrop.$ghost = $("""
		<div class="resizable draggable" id="ghost-img-container"></div>
	""")

	betterCrop.$ghost
		.css
			height: height
			width: width
			left: maxOffset.left - (width - minWidth) / 2
			top: maxOffset.top - (height - minHeight) / 2
		.appendTo("body")
		.append($(@).clone())
		.draggable()
		.on("drag", dragHandler)
		.resizable()
		.on("resize", resizeHandler)

	$(document).on "keydown", (e) ->
		if e.keyCode is 13
			finishedCrop()
		return

	return

finishedCrop = ->
	{$ghost, minWidth, minHeight, maxOffset} = betterCrop
	ghostHeight = $ghost.height()
	ghostWidth = $ghost.width()
	ghostOffset = $ghost.offset()

	if ghostOffset.top + ghostHeight - maxOffset.top - minHeight < 0 or \
	ghostOffset.left + ghostWidth - maxOffset.left - minWidth < 0
		alert("Drag the image around to completely fill the box.")
		return

	betterCrop.$ghost.remove()
	$(document).off("keydown")

	return

dragHandler = (e, coords) ->
	{$ghost, minWidth, minHeight, maxOffset} = betterCrop
	ghostHeight = $ghost.height()
	ghostWidth = $ghost.width()
	{abs} = Math

	# Snap to container
	tolerance = 10
	if abs(coords.top - maxOffset.top) < tolerance
		coords.top = maxOffset.top
	if abs(coords.top + ghostHeight - maxOffset.top - minHeight) < tolerance
		coords.top = maxOffset.top + minHeight - ghostHeight

	if abs(coords.left - maxOffset.left) < tolerance
		coords.left = maxOffset.left
	if abs(coords.left + ghostWidth - maxOffset.left - minWidth) < tolerance
		coords.left = maxOffset.left + minWidth - ghostWidth

	# defer until calling stack is cleared
	setTimeout(changeImage)
	
	return coords

resizeHandler = (e, dim) ->
	# defer until calling stack is cleared
	setTimeout(changeImage)

	{minWidth, minHeight, maxWidth, maxHeight} = betterCrop
	
	# don't let the dimensions be greater than original image dimensions
	if dim.width > maxWidth or dim.height > maxHeight
		dim.width = maxWidth
		dim.height = maxHeight

		return dim

	# don't let the dimensions be smaller than the minimum dimensions needed
	# to completely fill the container while maintaining original image's
	# aspect ratio
	if dim.width < minWidth
		dim.width = minWidth
		dim.height = minWidth / maxWidth * maxHeight

	if dim.height < minHeight
		dim.height = minHeight
		dim.width = minHeight / maxHeight * maxWidth

	return dim

changeImage = (e) ->
	{$ghost, $container, maxOffset} = betterCrop
	ghostHeight = $ghost.height()
	ghostWidth = $ghost.width()
	ghostOffset = $ghost.offset()
	
	$container.find("img").css
		"left": ghostOffset.left - maxOffset.left
		"top": ghostOffset.top - maxOffset.top
		"height": ghostHeight
		"width": ghostWidth
	
	$ghost.find("img").css
		"height": ghostHeight
		"width": ghostWidth

	return
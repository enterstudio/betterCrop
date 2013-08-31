do ($ = window.jQuery) ->
	$.fn.draggable = ->
		@on("mousedown", mousedownHandler)

		return @

	mousedownHandler = (e) ->
		e.preventDefault()
		e.stopPropagation()

		offset = $(@).offset()

		# theta is the relative offset of the mouse from the draggable item
		theta =
			x: e.pageX - offset.left
			y: e.pageY - offset.top

		mousemoveHandler = mousemoveHandlerGenerator.apply($(@), [theta])

		$(document)
			.on("mousemove", mousemoveHandler)
			.one "mouseup", (e) ->
				$(document).off("mousemove", mousemoveHandler)
				return

		return false

	mousemoveHandlerGenerator = (theta) -> (e) =>
		e.preventDefault()
		e.stopPropagation()

		coords =
			left: e.pageX - theta.x
			top: e.pageY - theta.y

		# filter coords through an event handler, if it exists
		filteredCoords = @triggerHandler("drag", coords)
		if filteredCoords then coords = filteredCoords

		@css(coords)

		return false

	return
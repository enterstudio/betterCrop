do ($ = window.jQuery) ->
	$.fn.resizable = ->
		# set up all the borders
		setUpBorder.call(@, name, lambda) for own name, lambda of borders

		return @

	# configs for resize borders. defines lamda (the multiplicative constant
	# to adjust delta by upon resize) for each border
	borders = 
		left:
			height: 0
			width: -1
			left: -1
			top: -0.5
		top:
			height: -1
			width: 0
			left: -0.5
			top: -1
		right:	
			height: 0
			width: 1
			left: 0
			top: -0.5
		bottom:
			height: 1
			width: 0
			left: -0.5
			top: 0
		"top-left":
			height: -1
			width: -1
			left: -1
			top: -1
		"top-right":
			height: -1
			width: 1
			left: 0
			top: -1
		"bottom-left":
			height: 1
			width: -1
			left: -1
			top: 0
		"bottom-right":
			height: 1
			width: 1
			left: 0
			top: 0

	setUpBorder = (name, lambda) ->
		mousedownHandler = mousedownHandlerGenerator.call(@, lambda)

		$("""
			<div class="resizable-border resizable-border-#{name}"></div>
		""")
			.appendTo(@)
			.on("mousedown", mousedownHandler)

		return

	mousedownHandlerGenerator = (lambda) -> (e) =>
		e.preventDefault()
		e.stopPropagation()

		# theta is the initial offset of the mouse when resizing began
		theta =
			x: e.pageX
			y: e.pageY

		mousemoveHandler = mousemoveHandlerGenerator.call(@, lambda, theta)
		
		$(document)
			.on("mousemove", mousemoveHandler)
			.one "mouseup", (e) ->
				$(document).off("mousemove", mousemoveHandler)
				return

		return false

	mousemoveHandlerGenerator = (lambda, theta) ->
		# alpha is the initial configuration when the resizing began
		alpha =
			height: @height()
			width: @width()
			left: @offset().left
			top: @offset().top
		
		return (e) =>
			# delta is the amount of relative mouse movement from theta
			delta = 
				x: e.pageX - theta.x
				y: e.pageY - theta.y

			resize.call(@, alpha, lambda, delta)

			return false

	resize = (alpha, lambda, delta) ->
		# let's calculate the maximum possible size of the resized box
		dim =
			height: alpha.height + delta.y * lambda.height
			width: alpha.width + delta.x * lambda.width

		# adjust height or width if this was a one sided resize
		if delta.y * lambda.height is 0
			dim.height = alpha.height * dim.width / alpha.width
		if delta.x * lambda.width is 0
			dim.width = alpha.width * dim.height / alpha.height

		# resize down to the largest possible box that maintains
		# the original aspect ratio
		if alpha.height / alpha.width < dim.height / dim.width
			dim.height = alpha.height * dim.width / alpha.width
		else
			dim.width = alpha.width * dim.height / alpha.height

		# filter dim through an event handler, if it exists
		filteredDim = @triggerHandler("resize", dim)
		if filteredDim then dim = filteredDim

		# adjust coordinates
		dim.left = alpha.left + (dim.width - alpha.width) * lambda.left
		dim.top = alpha.top + (dim.height - alpha.height) * lambda.top

		@css(dim)

		return

	return
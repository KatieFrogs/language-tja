{CompositeDisposable} = require "atom"

module.exports =
	config:
		coloredCircles:
			title: "Use Colored Circles For Notes"
			description: "Turning this off will use plain text in the notation"
			type: "boolean"
			default: yes
			order: 1
		align:
			title: "Align Notes"
			description: "Justifies notes in each measure to have equal spacing"
			type: "boolean"
			default: yes
			order: 2
		alignmentSize:
			description: "Measure size in Align mode (arbitrary unit, the bigger the number the wider the measures will be, \"0\" uses full screen)"
			type: "number"
			default: 17
			minimum: 0
			order: 3
		theme:
			type: "string"
			default: "dark"
			enum: [
				value: "dark"
				description: "Dark"
			,
				value: "light"
				description: "Light"
			]
			order: 4
	activate: ->
		@namespace = "language-tja"
		@doc = document.documentElement
		@subscriptions = new CompositeDisposable
		for name of @config
			@subscriptions.add atom.config.onDidChange @cfg(name), => @configUpdated()
		@subscriptions.add atom.commands.add "atom-workspace", "language-tja:toggle-colored-circles":
			displayName: "Language Tja: Toggle Colored Circles For Notes"
			didDispatch: => @toggleColoredCircles()
		@subscriptions.add atom.commands.add "atom-workspace", "language-tja:toggle-align":
			displayName: "Language Tja: Toggle Align Notes"
			didDispatch: => @toggleAlign()
		@subscriptions.add atom.commands.add "atom-workspace", "language-tja:compress-measure":
			didDispatch: => @compressMeasure()
		@configUpdated()
	deactivate: ->
		@doc.classList.remove @className "colored-circles"
		@doc.classList.remove @className "light-theme"
		@subscriptions.dispose()
	serialize: ->
	load: (name) ->
		atom.config.get @cfg name
	save: (name, val) ->
		atom.config.set @cfg(name), val
		@[name] = val
	cfg: (name) ->
		@namespace + "." + name
	className: (name) ->
		@namespace + "--" + name
	addRemove: (name, val) ->
		result = @load name
		if (if val? then result is val else result) then "add" else "remove"
	configUpdated: ->
		@doc.classList[@addRemove "coloredCircles"] @className "colored-circles"
		@doc.classList[@addRemove "align"] @className "align"
		alignmentSize = @load "alignmentSize"
		@doc.style.setProperty "--" + @className("alignment-size"), if alignmentSize is 0 then "100%" else alignmentSize + "em"
		@doc.classList[@addRemove "theme", "light"] @className "light-theme"
	toggleColoredCircles: ->
		@save "coloredCircles", not @load "coloredCircles"
	toggleAlign: ->
		@save "align", not @load "align"
	compressMeasure: ->
		return unless editor = atom.workspace.getActiveTextEditor()
		selections = editor.getSelections()
		editor.transact 0, =>
			for selection in selections
				selection.selectLine()
				matches = selection.getText().split /^([\dABFabf]*|[\dABFabf]+)(,\w*(?:$|\/\/.*?$)?)/gm
				for i in [1...matches.length] by 3
					notes = matches[i].split ""
					while notes.length > 1
						allZero = yes
						for j in [notes.length-1..0] by -2
							if notes[j] isnt "0"
								allZero = no
								break
						if allZero
							for j in [notes.length-1..0] by -2
								notes.splice j, 1
						else break
					notes = notes.join ""
					matches[i] = if notes is "0" then "" else notes
				selection.insertText matches.join ""

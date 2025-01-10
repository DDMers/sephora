//src proc to enable and disable fullscreen
/client/proc/toggle_fullscreen(value)
	if(value)
		// Delete the menu
		winset(src, "mainwindow", "menu=\"\"")
		// Switch to the cool status bar
		winset(src, "mainwindow", "on-status=\".winset \\\"\[\[*]]=\\\"\\\" ? status_bar.text=\[\[*]] status_bar.is-visible=true : status_bar.is-visible=false\\\"\"")
		winset(src, "status_bar_wide", "is-visible=false")
		// Switch to fullscreen mode
		winset(src, "mainwindow","titlebar=false")
		winset(src, "mainwindow","can-resize=false")
		// Set it to minimized first because otherwise it doesn't enter fullscreen properly
		// This line is important, and the game won't properly enter fullscreen mode otherwise
		winset(src, "mainwindow","is-minimized=true")
		winset(src, "mainwindow","is-maximized=true")
		// Set the main window's size
		winset(src, null, "split.size=mainwindow.size")
		// Fit the viewport
		INVOKE_ASYNC(src, TYPE_VERB_REF(/client, fit_viewport))
	else
		// Restore the menu
		winset(src, "mainwindow", "menu=\"menu\"")
		// Switch to the lame status bar
		winset(src, "mainwindow", "on-status=\".winset \\\"status_bar_wide.text = \[\[*]]\\\"\"")
		winset(src, "status_bar", "is-visible=false")
		winset(src, "status_bar_wide", "is-visible=true")
		// Exit fullscreen mode
		winset(src, "mainwindow","titlebar=true")
		winset(src, "mainwindow","can-resize=true")
		// Fix the mapsize, turning off statusbar doesn't update scaling
		INVOKE_ASYNC(src, PROC_REF(fix_mapsize))

/client/proc/fix_mapsize()
	var/windowsize = winget(src, "split", "size")
	if (!src || !windowsize)
		return
	var/split = findtext(windowsize, "x")
	winset(src, "split", "size=[copytext(windowsize, 1, split)]x[text2num(copytext(windowsize, split + 1)) - 16]")
	src.fit_viewport()

/client/verb/switch_fullscreen()
	set category = "OOC"
	set name = "Toggle Fullscreen"

	if(!src || !prefs)
		return
	src.prefs.toggles2 ^= PREFTOGGLE_2_FULLSCREEN
	src.toggle_fullscreen(src.prefs.toggles2 & PREFTOGGLE_2_FULLSCREEN)
	to_chat(usr, "<span class ='info'>Switched [src.prefs.toggles2 & PREFTOGGLE_2_FULLSCREEN ? "to fullscreen" : "off fullscreen"], press F11 to toggle.</span>")

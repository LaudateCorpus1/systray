// +build !windows

package systray

/*
#cgo linux pkg-config: gtk+-3.0 appindicator3-0.1
#cgo darwin CFLAGS: -DDARWIN -x objective-c -fobjc-arc
#cgo darwin LDFLAGS: -framework Cocoa

#include "systray.h"
*/
import "C"

import (
	"unsafe"
)

func nativeLoop() {
	C.nativeLoop()
}

func quit() {
	C.quit()
}

// SetIcon sets the systray icon.
// iconBytes should be the content of .ico for windows and .ico/.jpg/.png
// for other platforms.
func SetIcon(iconBytes []byte) {
	cstr := (*C.char)(unsafe.Pointer(&iconBytes[0]))
	C.setIcon(cstr, (C.int)(len(iconBytes)))
}

// SetTitle sets the systray title, only available on Mac.
func SetTitle(title string) {
	C.setTitle(C.CString(title))
}

// SetTooltip sets the systray tooltip to display on mouse hover of the tray icon,
// only available on Mac and Windows.
func SetTooltip(tooltip string) {
	C.setTooltip(C.CString(tooltip))
}

// GetGitHash returns the git hash of the current project
func GetGitHash() string {
	cstr := C.get_git_hash()
	return C.GoString(cstr)
}

// GetUserSetting returns the string value of a user setting
func GetUserSetting(name string) string {
	cstr := C.get_user_setting(C.CString(name))
	return C.GoString(cstr)
}

// SetUserSetting sets the string value of a user setting
func SetUserSetting(name, value string) {
	C.set_user_setting(C.CString(name), C.CString(value))
}

// Hang sleeps for a indefinite amount of time
func Hang() {
	C.hang()
}

func addOrUpdateMenuItem(item *MenuItem) {
	var disabled C.short
	if item.disabled {
		disabled = 1
	}
	var checked C.short
	if item.checked {
		checked = 1
	}
	C.add_or_update_menu_item(
		C.int(item.id),
		C.CString(item.title),
		C.CString(item.tooltip),
		disabled,
		checked,
	)
}

func addSeparator(item *MenuItem) {
	C.add_separator(C.int(item.id))
}

func addOrUpdateSubmenu(item *MenuItem) {
	C.add_or_update_submenu(
		C.int(item.id),
		C.CString(item.title),
		C.CString(item.tooltip),
	)
}

func addOrUpdateSubmenuItem(item *MenuItem) {
	var disabled C.short
	if item.disabled {
		disabled = 1
	}
	var checked C.short
	if item.checked {
		checked = 1
	}
	C.add_or_update_submenu_item(
		C.int(item.submenuId),
		C.int(item.id),
		C.CString(item.title),
		C.CString(item.tooltip),
		disabled,
		checked,
	)
}

//export systray_ready
func systray_ready() {
	systrayReady()
}

//export systray_menu_item_selected
func systray_menu_item_selected(cID C.int) {
	systrayMenuItemSelected(int32(cID))
}

//export systray_menu_opened
func systray_menu_opened() {
	menuOpened()
}

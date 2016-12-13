#import <Cocoa/Cocoa.h>
#include "systray.h"

@interface MenuItem : NSObject
{
@public
  NSNumber *menuId;
  NSNumber *submenuId;
  NSString *title;
  NSString *tooltip;
  short disabled;
  short checked;
  short separator;
  short submenu;

}
- (id)initWithId:(int)theMenuId
       withTitle:(const char *)theTitle
     withTooltip:(const char *)theTooltip
    withDisabled:(short)theDisabled
     withChecked:(short)theChecked;

- (id)initSeparatorWithId:(int)theMenuId;

- (id)initSubmenuWithId:(int)theMenuId
              withTitle:(const char *)theTitle
            withTooltip:(const char *)theTooltip;
@end
@implementation MenuItem

- (id)initWithId:(int)theMenuId
       withTitle:(const char *)theTitle
     withTooltip:(const char *)theTooltip
    withDisabled:(short)theDisabled
     withChecked:(short)theChecked
{
  menuId = [NSNumber numberWithInt:theMenuId];
  submenuId = nil;
  title = [[NSString alloc] initWithCString:theTitle
                                   encoding:NSUTF8StringEncoding];
  tooltip = [[NSString alloc] initWithCString:theTooltip
                                     encoding:NSUTF8StringEncoding];
  disabled = theDisabled;
  checked = theChecked;
  separator = 0;
  submenu = 0;
  return self;
}

- (id)initSeparatorWithId:(int)theMenuId {
  menuId = [NSNumber numberWithInt:theMenuId];
  submenuId = nil;
  title = nil;
  tooltip = nil;
  disabled = 0;
  checked = 0;
  separator = 1;
  submenu = 0;
  return self;
}

- (id)initSubmenuWithId:(int)theMenuId
              withTitle:(const char *)theTitle
            withTooltip:(const char *)theTooltip
{
  menuId = [NSNumber numberWithInt:theMenuId];
  submenuId = nil;
  title = [[NSString alloc] initWithCString:theTitle
                                   encoding:NSUTF8StringEncoding];
  tooltip = [[NSString alloc] initWithCString:theTooltip
                                     encoding:NSUTF8StringEncoding];
  disabled = 0;
  checked = 0;
  separator = 0;
  submenu = 1;
  return self;
}

@end

@interface MenuItemRegistry : NSObject <NSMenuDelegate>
@property (strong) NSMenu *menu;
@property (strong) NSMutableDictionary *submenus;
@property (strong, nonatomic) NSStatusItem *statusItem;
- (void)addOrUpdateMenuItem:(MenuItem *)item;
- (void)addSeparator:(MenuItem *)item;
- (void)addOrUpdateSubmenu:(MenuItem *)item;
- (void)addOrUpdateSubmenuItem:(MenuItem *)item;
- (IBAction)menuHandler:(id)sender;
- (void)hang;
- (void)quit;
+ (MenuItemRegistry *)sharedRegistry;
@end

@implementation MenuItemRegistry

static MenuItemRegistry *sharedRegistry = nil;

- (id)init {
  self = [super init];
  self.menu = [[NSMenu alloc] init];
  [self.menu setAutoenablesItems:FALSE];
  [self.menu setDelegate:self];
  self.submenus = [[NSMutableDictionary alloc] init];
  self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
  [self.statusItem setMenu:self.menu];
  systray_ready();
  return self;
}

- (void)addOrUpdateMenuItem:(MenuItem*)item {
  NSMenuItem* menuItem;
  int existedMenuIndex = [self.menu indexOfItemWithRepresentedObject:item->menuId];
  if (existedMenuIndex == -1) {
    menuItem = [self.menu addItemWithTitle:item->title action:@selector(menuHandler:) keyEquivalent:@""];
    [menuItem setTarget:self];
    [menuItem setRepresentedObject:item->menuId];
  } else {
    menuItem = [self.menu itemAtIndex:existedMenuIndex];
    [menuItem setTitle:item->title];
  }

  [menuItem setToolTip:item->tooltip];
  if (item->disabled == 1) {
    [menuItem setEnabled:FALSE];
  } else {
    [menuItem setEnabled:TRUE];
  }
  if (item->checked == 1) {
    [menuItem setState:NSOnState];
  } else {
    [menuItem setState:NSOffState];
  }
}

- (void)addSeparator:(MenuItem *)item {
  NSMenuItem* menuItem;
  int existedMenuIndex = [self.menu indexOfItemWithRepresentedObject:item->menuId];
  if (existedMenuIndex == -1) {
    menuItem = [NSMenuItem separatorItem];
    [self.menu addItem:menuItem];
    [menuItem setTarget:self];
    [menuItem setRepresentedObject:item->menuId];
  }
}

- (void)addOrUpdateSubmenu:(MenuItem *)item {
  NSMenuItem* menuItem;
  int existedMenuIndex = [self.menu indexOfItemWithRepresentedObject:item->menuId];
  if (existedMenuIndex == -1) {
    menuItem = [self.menu addItemWithTitle:item->title action:nil keyEquivalent:@""];
    [menuItem setTarget:self];
    [menuItem setRepresentedObject:item->menuId];
    NSMenu *submenu = [[NSMenu alloc] initWithTitle:item->title];
    self.submenus[item->menuId] = submenu;
    [self.menu setSubmenu:submenu forItem:menuItem];
  }
}

- (void)addOrUpdateSubmenuItem:(MenuItem *)item {
  NSMenuItem* menuItem;
  NSMenu *submenu = self.submenus[item->submenuId];
  int existedMenuIndex = [submenu indexOfItemWithRepresentedObject:item->menuId];
  if (existedMenuIndex == -1) {
    menuItem = [submenu addItemWithTitle:item->title action:@selector(menuHandler:) keyEquivalent:@""];
    [menuItem setTarget:self];
    [menuItem setRepresentedObject:item->menuId];
  } else {
    menuItem = [submenu itemAtIndex:existedMenuIndex];
    [menuItem setTitle:item->title];
  }

  [menuItem setToolTip:item->tooltip];
  if (item->disabled == 1) {
    [menuItem setEnabled:FALSE];
  } else {
    [menuItem setEnabled:TRUE];
  }
  if (item->checked == 1) {
    [menuItem setState:NSOnState];
  } else {
    [menuItem setState:NSOffState];
  }
}

- (IBAction)menuHandler:(id)sender {
  NSNumber* menuId = [sender representedObject];
  systray_menu_item_selected(menuId.intValue);
}

- (void)setIcon:(NSImage *)image {
  [self.statusItem setImage:image];
}

- (void)setTitle:(NSString *)title {
  [self.statusItem setTitle:title];
}

- (void)setTooltip:(NSString *)tooltip {
  [self.statusItem setToolTip:tooltip];
}

- (void)hang {
  sleep(100000000);
}

- (void)quit {
  [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
  [NSApp terminate:[[NSApplication sharedApplication] delegate]];
}

- (void)menuWillOpen:(NSMenu *)menu {
  systray_menu_opened();
}

+ (MenuItemRegistry *)sharedRegistry {
  static dispatch_once_t pred;
  static id sharedRegistry = nil;
  dispatch_once(&pred, ^{
    sharedRegistry = [[[self class] alloc] init];
  });
  return sharedRegistry;
}

@end


int nativeLoop(void) {
  [MenuItemRegistry
    performSelectorOnMainThread:@selector(sharedRegistry)
                     withObject:nil
                  waitUntilDone:YES];
  return 0;
}

void runInMainThread(SEL method, id object) {
  [[MenuItemRegistry sharedRegistry]
    performSelectorOnMainThread:method
                     withObject:object
                  waitUntilDone:YES];
}

void setIcon(const char *iconBytes, int length) {
  NSData *buffer = [NSData dataWithBytes:iconBytes length:length];
  NSImage *image = [[NSImage alloc] initWithData:buffer];
  runInMainThread(@selector(setIcon:), (id)image);
}

void setTitle(char *ctitle) {
  NSString *title = [[NSString alloc] initWithCString:ctitle
                                             encoding:NSUTF8StringEncoding];
  free(ctitle);
  runInMainThread(@selector(setTitle:), (id)title);
}

void setTooltip(char *ctooltip) {
  NSString *tooltip = [[NSString alloc] initWithCString:ctooltip
                                               encoding:NSUTF8StringEncoding];
  free(ctooltip);
  runInMainThread(@selector(setTooltip:), (id)tooltip);
}

void add_or_update_menu_item(int menuId, char *title, char *tooltip, short disabled, short checked) {
  MenuItem *item = [[MenuItem alloc]
                     initWithId:menuId
                      withTitle:title
                     withTooltip:tooltip
                     withDisabled:disabled
                     withChecked:checked];
  free(title);
  free(tooltip);
  runInMainThread(@selector(addOrUpdateMenuItem:), (id)item);
}

void add_separator(int menuId) {
  MenuItem *item = [[MenuItem alloc] initSeparatorWithId:menuId];
  runInMainThread(@selector(addSeparator:), (id)item);
}

void add_or_update_submenu(int menuId, char *title, char *tooltip) {
  MenuItem *item = [[MenuItem alloc]
                     initSubmenuWithId:menuId
                             withTitle:title
                           withTooltip:tooltip];
  free(title);
  free(tooltip);
  runInMainThread(@selector(addOrUpdateSubmenu:), (id)item);
}

void add_or_update_submenu_item(int submenuId, int menuId, char *title, char *tooltip, short disabled, short checked) {
  MenuItem *item = [[MenuItem alloc]
                     initWithId:menuId
                      withTitle:title
                     withTooltip:tooltip
                     withDisabled:disabled
                     withChecked:checked];
  item->submenuId = [NSNumber numberWithInt:submenuId];
  free(title);
  free(tooltip);
  runInMainThread(@selector(addOrUpdateSubmenuItem:), (id)item);
}

const char *get_version() {
  NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
  return [version UTF8String];
}

const char *get_git_hash() {
  NSString *path = [[NSBundle mainBundle] pathForResource:@"Git" ofType:@"plist"];
  NSDictionary *gitPlist = [[NSDictionary alloc] initWithContentsOfFile:path];
  NSString *hash = [gitPlist objectForKey:@"GitHash"];
  return [hash UTF8String];
}

const char *get_user_setting(char *name) {
  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  NSString *setting = [prefs stringForKey:[[NSString alloc] initWithUTF8String:name]];
  free(name);
  return [setting UTF8String];
}

void set_user_setting(char *name, char *value) {
  NSString *nameStr = [[NSString alloc] initWithUTF8String:name];
  NSString *valueStr = [[NSString alloc] initWithUTF8String:value];
  free(name);
  free(value);
  [[NSUserDefaults standardUserDefaults] setObject:valueStr forKey:nameStr];
}

void hang() {
  runInMainThread(@selector(hang), nil);
}

void quit() {
  runInMainThread(@selector(quit), nil);
}

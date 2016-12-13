extern void systray_ready();
extern void systray_menu_item_selected(int menu_id);
extern void systray_menu_opened();
int nativeLoop(void);

void setIcon(const char *iconBytes, int length);
void setTitle(char *title);
void setTooltip(char *tooltip);
void add_or_update_menu_item(int menuId, char *title, char *tooltip, short disabled, short checked);
void add_separator(int menuId);
void add_or_update_submenu(int menuId, char *title, char *tooltip);
void add_or_update_submenu_item(int submenuId, int menuId, char *title, char *tooltip, short disabled, short checked);
const char *get_version();
const char *get_git_hash();
const char *get_user_setting(char *name);
void set_user_setting(char *name, char *value);
void hang();
void quit();

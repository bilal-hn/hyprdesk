-- Hyprland dynamic & base colors

CACHYLGREEN = "rgba(82dcccff)"
CACHYMGREEN = "rgba(00aa84ff)"
CACHYDGREEN = "rgba(007d6fff)"
CACHYLBLUE  = "rgba(01ccffff)"
CACHYMBLUE  = "rgba(182545ff)"
CACHYDBLUE  = "rgba(111826ff)"
CACHYWHITE  = "rgba(ffffffff)"
CACHYGREY   = "rgba(ddddddff)"
CACHYGRAY   = "rgba(798bb2ff)"

-- Dynamically load wallpaper accent
WALLPAPER_ACCENT = CACHYLGREEN
WALLPAPER_INACTIVE = "rgba(2a2b36aa)"

local home = os.getenv("HOME")
if home then
    local f = io.open(home .. "/.cache/hyprdesk/accent_color", "r")
    if f then
        local content = f:read("*all")
        f:close()
        local r, g, b = content:match("(%d+),%s*(%d+),%s*(%d+)")
        if r and g and b then
            WALLPAPER_ACCENT = string.format("rgba(%02x%02x%02xff)", tonumber(r), tonumber(g), tonumber(b))
            WALLPAPER_INACTIVE = string.format("rgba(%02x%02x%02x33)", tonumber(r), tonumber(g), tonumber(b))
        end
    end
end

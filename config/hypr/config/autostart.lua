-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("noctalia")
    hl.exec_cmd("awww-daemon --no-cache")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("/home/bihhlal/Projects/Personal/hyprdesk/scripts/waybar-controller.sh start")
    hl.exec_cmd("xhost +SI:localuser:root")
end)

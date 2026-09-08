#include <gtk/gtk.h>
#include <gtk-layer-shell/gtk-layer-shell.h>
#include <cairo.h>
#include <math.h>
#include <stdbool.h>
#include <sys/time.h>
#include <string.h>
#include <stdlib.h>

typedef enum {
    ANIM_EXPAND = 0,
    ANIM_COLLAPSE = 1
} AnimMode;

static AnimMode g_mode = ANIM_EXPAND;
static double g_start_time = 0.0;
static const double DURATION = 0.70; // 700ms total smooth animation

static int g_screen_w = 1280;

// Compact island geometry (centered pill)
static double compact_x = 458.0;
static double compact_y = 8.0;
static double compact_w = 365.0;
static double compact_h = 34.0;
static double compact_r = 17.0;

// Expanded 3-island geometry
static double left_x = 16.0;
static double left_y = 6.0;
static double left_w = 240.0;
static double left_h = 38.0;
static double left_r = 12.0;

static double mid_x = 530.0;
static double mid_y = 6.0;
static double mid_w = 220.0;
static double mid_h = 38.0;
static double mid_r = 12.0;

static double right_x = 804.0;
static double right_y = 6.0;
static double right_w = 460.0;
static double right_h = 38.0;
static double right_r = 12.0;

static double get_current_time(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + (tv.tv_usec / 1000000.0);
}

static double ease_in_out_cubic(double x) {
    return x < 0.5 ? 4.0 * x * x * x : 1.0 - pow(-2.0 * x + 2.0, 3.0) / 2.0;
}

static double ease_out_expo(double x) {
    return x >= 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * x);
}

static double ease_in_quad(double x) {
    return x * x;
}

static double lerp(double a, double b, double t) {
    return a + t * (b - a);
}

static void draw_rounded_rect(cairo_t *cr, double x, double y, double w, double h, double r) {
    if (r > h / 2.0) r = h / 2.0;
    if (r > w / 2.0) r = w / 2.0;
    if (r < 0.5) r = 0.5;
    cairo_new_sub_path(cr);
    cairo_arc(cr, x + w - r, y + r, r, -M_PI / 2.0, 0.0);
    cairo_arc(cr, x + w - r, y + h - r, r, 0.0, M_PI / 2.0);
    cairo_arc(cr, x + r, y + h - r, r, M_PI / 2.0, M_PI);
    cairo_arc(cr, x + r, y + r, r, M_PI, 3.0 * M_PI / 2.0);
    cairo_close_path(cr);
}

/* Colors - Unified wallpaper palette */
static const double BG_R = 14.0/255.0, BG_G = 21.0/255.0, BG_B = 19.0/255.0, BG_A = 0.90;
static double GLOW_R = 132.0/255.0, GLOW_G = 214.0/255.0, GLOW_B = 194.0/255.0; /* #84d6c2 default */
static const double BORDER_A = 0.18;

static void load_accent_color(void) {
    char path[1024];
    const char *home = getenv("HOME");
    if (!home) return;
    snprintf(path, sizeof(path), "%s/.cache/hyprdesk/accent_color", home);
    FILE *f = fopen(path, "r");
    if (f) {
        int r, g, b;
        if (fscanf(f, "%d, %d, %d", &r, &g, &b) == 3) {
            GLOW_R = (double)r / 255.0;
            GLOW_G = (double)g / 255.0;
            GLOW_B = (double)b / 255.0;
        }
        fclose(f);
    }
}

/* Draw a single pill with given color, position, size */
static void draw_pill(cairo_t *cr, double x, double y, double w, double h, double r,
                      double red, double grn, double blu, double alpha, double border_alpha) {
    draw_rounded_rect(cr, x, y, w, h, r);
    cairo_set_source_rgba(cr, red, grn, blu, alpha);
    cairo_fill(cr);
    if (border_alpha > 0.005) {
        draw_rounded_rect(cr, x, y, w, h, r);
        cairo_set_source_rgba(cr, GLOW_R, GLOW_G, GLOW_B, border_alpha);
        cairo_set_line_width(cr, 1.0);
        cairo_stroke(cr);
    }
}

static gboolean on_draw(GtkWidget *widget, cairo_t *cr, gpointer user_data) {
    (void)user_data;
    double now = get_current_time();
    double elapsed = now - g_start_time;
    double progress = elapsed / DURATION;
    if (progress > 1.0) progress = 1.0;

    /* Clear to transparent */
    cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
    cairo_paint(cr);
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER);

    /* Gentle fade-out in final 12% so handoff to waybar is seamless */
    double global_alpha = 1.0;
    if (progress > 0.88) {
        global_alpha = 1.0 - (progress - 0.88) / 0.12;
        if (global_alpha < 0.0) global_alpha = 0.0;
    }

    double line_center_y = compact_y + compact_h / 2.0;

    double bars[3][5] = {
        { left_x,  left_y,  left_w,  left_h,  left_r  },
        { mid_x,   mid_y,   mid_w,   mid_h,   mid_r   },
        { right_x, right_y, right_w, right_h, right_r  }
    };

    double seg_w = compact_w / 3.0;
    double segs[3][2] = {
        { compact_x,              seg_w },
        { compact_x + seg_w,      seg_w },
        { compact_x + 2.0*seg_w,  seg_w }
    };

    if (g_mode == ANIM_EXPAND) {
        /*
         * EXPAND: Compact Island  →  3 Expanded Bars
         *   Phase 1 (0.00–0.35): Pill squishes into a unified glowing line
         *   Phase 2 (0.25–0.75): Line trisects and slides apart
         *   Phase 3 (0.60–1.00): 3 lines bloom into the 3 full bars
         */

        /* Phase 1: Pill → thin glowing line */
        if (progress < 0.35) {
            double p = ease_in_out_cubic(progress / 0.35);

            double h = lerp(compact_h, 3.0, p);
            double y = lerp(compact_y, line_center_y - 1.5, p);
            double r = lerp(compact_r, 1.5, p);

            double cr_ = lerp(BG_R, GLOW_R, p);
            double cg_ = lerp(BG_G, GLOW_G, p);
            double cb_ = lerp(BG_B, GLOW_B, p);
            double ca_ = lerp(BG_A, 1.0, p) * global_alpha;
            double ba_ = lerp(BORDER_A, 0.0, p) * global_alpha;

            draw_pill(cr, compact_x, y, compact_w, h, r, cr_, cg_, cb_, ca_, ba_);
        }

        /* Phase 2: One line → 3 lines sliding apart */
        if (progress >= 0.25 && progress < 0.75) {
            double p = ease_in_out_cubic((progress - 0.25) / 0.50);
            double line_h = 3.0;
            double line_y = line_center_y - 1.5;

            double phase_blend = 1.0;
            if (progress < 0.35) {
                phase_blend = (progress - 0.25) / 0.10;
            }

            for (int i = 0; i < 3; i++) {
                double x = lerp(segs[i][0], bars[i][0], p);
                double w = lerp(segs[i][1], bars[i][2], p);

                /* All 3 lines use the single unified accent color */
                draw_pill(cr, x, line_y, w, line_h, 1.5,
                          GLOW_R, GLOW_G, GLOW_B, 0.95 * phase_blend * global_alpha, 0.0);
            }

            /* Connecting energy traces between the 3 segments as they split */
            if (p < 0.85) {
                double trace_alpha = 0.20 * (1.0 - p / 0.85) * phase_blend * global_alpha;
                cairo_set_source_rgba(cr, GLOW_R, GLOW_G, GLOW_B, trace_alpha);
                cairo_set_line_width(cr, 1.0);
                double x0end = lerp(segs[0][0]+segs[0][1], bars[0][0]+bars[0][2], p);
                double x1start = lerp(segs[1][0], bars[1][0], p);
                double x1end = lerp(segs[1][0]+segs[1][1], bars[1][0]+bars[1][2], p);
                double x2start = lerp(segs[2][0], bars[2][0], p);
                cairo_move_to(cr, x0end, line_y + 1.5);
                cairo_line_to(cr, x1start, line_y + 1.5);
                cairo_move_to(cr, x1end, line_y + 1.5);
                cairo_line_to(cr, x2start, line_y + 1.5);
                cairo_stroke(cr);
            }
        }

        /* Phase 3: 3 lines bloom into full bars */
        if (progress >= 0.60) {
            double p = ease_out_expo((progress - 0.60) / 0.40);

            double phase_blend = 1.0;
            if (progress < 0.75) {
                phase_blend = (progress - 0.60) / 0.15;
            }

            for (int i = 0; i < 3; i++) {
                double h = lerp(3.0, bars[i][3], p);
                double y = lerp(line_center_y - 1.5, bars[i][1], p);
                double r = lerp(1.5, bars[i][4], p);

                double cr_ = lerp(GLOW_R, BG_R, p);
                double cg_ = lerp(GLOW_G, BG_G, p);
                double cb_ = lerp(GLOW_B, BG_B, p);
                double ca_ = lerp(1.0, BG_A, p) * phase_blend * global_alpha;
                double ba_ = lerp(0.0, BORDER_A, p) * phase_blend * global_alpha;

                draw_pill(cr, bars[i][0], y, bars[i][2], h, r, cr_, cg_, cb_, ca_, ba_);
            }
        }

    } else {
        /*
         * COLLAPSE: 3 Expanded Bars  →  Compact Island
         *   Phase 1 (0.00–0.35): 3 bars flatten into 3 thin glowing lines
         *   Phase 2 (0.30–0.75): 3 lines glide inward and merge
         *   Phase 3 (0.65–1.00): Merged line blooms into the compact island
         */

        /* Phase 1: 3 bars → 3 thin lines */
        if (progress < 0.40) {
            double p = ease_in_out_cubic(progress / 0.40);

            for (int i = 0; i < 3; i++) {
                double h = lerp(bars[i][3], 3.0, p);
                double y = lerp(bars[i][1], line_center_y - 1.5, p);
                double r = lerp(bars[i][4], 1.5, p);

                double cr_ = lerp(BG_R, GLOW_R, p);
                double cg_ = lerp(BG_G, GLOW_G, p);
                double cb_ = lerp(BG_B, GLOW_B, p);
                double ca_ = lerp(BG_A, 1.0, p) * global_alpha;
                double ba_ = lerp(BORDER_A, 0.0, p) * global_alpha;

                draw_pill(cr, bars[i][0], y, bars[i][2], h, r, cr_, cg_, cb_, ca_, ba_);
            }
        }

        /* Phase 2: 3 lines glide inward and stack */
        if (progress >= 0.30 && progress < 0.80) {
            double p = ease_in_out_cubic((progress - 0.30) / 0.50);
            double line_h = 3.0;
            double line_y = line_center_y - 1.5;

            double phase_blend = 1.0;
            if (progress < 0.40) {
                phase_blend = (progress - 0.30) / 0.10;
            }

            for (int i = 0; i < 3; i++) {
                double x = lerp(bars[i][0], segs[i][0], p);
                double w = lerp(bars[i][2], segs[i][1], p);

                /* All 3 lines use the unified accent color */
                draw_pill(cr, x, line_y, w, line_h, 1.5,
                          GLOW_R, GLOW_G, GLOW_B, 0.95 * phase_blend * global_alpha, 0.0);
            }

            /* Connecting traces as lines converge */
            if (p > 0.15) {
                double trace_alpha = 0.20 * (p - 0.15) / 0.85 * phase_blend * global_alpha;
                cairo_set_source_rgba(cr, GLOW_R, GLOW_G, GLOW_B, trace_alpha);
                cairo_set_line_width(cr, 1.0);
                double x0end = lerp(bars[0][0]+bars[0][2], segs[0][0]+segs[0][1], p);
                double x1start = lerp(bars[1][0], segs[1][0], p);
                double x1end = lerp(bars[1][0]+bars[1][2], segs[1][0]+segs[1][1], p);
                double x2start = lerp(bars[2][0], segs[2][0], p);
                cairo_move_to(cr, x0end, line_y + 1.5);
                cairo_line_to(cr, x1start, line_y + 1.5);
                cairo_move_to(cr, x1end, line_y + 1.5);
                cairo_line_to(cr, x2start, line_y + 1.5);
                cairo_stroke(cr);
            }
        }

        /* Phase 3: Merged glow line → compact island */
        if (progress >= 0.65) {
            double p = ease_out_expo((progress - 0.65) / 0.35);

            double phase_blend = 1.0;
            if (progress < 0.80) {
                phase_blend = (progress - 0.65) / 0.15;
            }

            double h = lerp(3.0, compact_h, p);
            double y = lerp(line_center_y - 1.5, compact_y, p);
            double r = lerp(1.5, compact_r, p);

            double cr_ = lerp(GLOW_R, BG_R, p);
            double cg_ = lerp(GLOW_G, BG_G, p);
            double cb_ = lerp(GLOW_B, BG_B, p);
            double ca_ = lerp(1.0, BG_A, p) * phase_blend * global_alpha;
            double ba_ = lerp(0.0, BORDER_A, p) * phase_blend * global_alpha;

            draw_pill(cr, compact_x, y, compact_w, h, r, cr_, cg_, cb_, ca_, ba_);
        }
    }

    if (progress >= 1.0) {
        gtk_main_quit();
        return FALSE;
    }

    return FALSE;
}

static gboolean on_tick(GtkWidget *widget, GdkFrameClock *frame_clock, gpointer user_data) {
    (void)frame_clock; (void)user_data;
    gtk_widget_queue_draw(widget);
    return G_SOURCE_CONTINUE;
}

int main(int argc, char **argv) {
    if (argc > 1 && strcmp(argv[1], "collapse") == 0) {
        g_mode = ANIM_COLLAPSE;
    } else {
        g_mode = ANIM_EXPAND;
    }

    load_accent_color();

    gtk_init(&argc, &argv);

    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);

    /* Transparent window */
    GdkScreen *screen = gtk_widget_get_screen(window);
    GdkVisual *visual = gdk_screen_get_rgba_visual(screen);
    if (visual && gdk_screen_is_composited(screen)) {
        gtk_widget_set_visual(window, visual);
    }
    gtk_widget_set_app_paintable(window, TRUE);

    /* Detect screen geometry */
    GdkDisplay *display = gdk_display_get_default();
    GdkMonitor *monitor = gdk_display_get_primary_monitor(display);
    if (!monitor) monitor = gdk_display_get_monitor(display, 0);
    if (monitor) {
        GdkRectangle geom;
        gdk_monitor_get_geometry(monitor, &geom);
        if (geom.width > 0) g_screen_w = geom.width;
    }

    /* Dynamic scale for non-1280 monitors */
    double scale = (double)g_screen_w / 1280.0;
    if (fabs(scale - 1.0) > 0.05) {
        compact_x *= scale; compact_w *= scale;
        left_x *= scale;    left_w *= scale;
        mid_x *= scale;     mid_w *= scale;
        right_x *= scale;   right_w *= scale;
    }

    /* Layer shell: transparent overlay, no keyboard, no exclusive zone */
    gtk_layer_init_for_window(GTK_WINDOW(window));
    gtk_layer_set_layer(GTK_WINDOW(window), GTK_LAYER_SHELL_LAYER_OVERLAY);
    gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_TOP, TRUE);
    gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_LEFT, TRUE);
    gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_RIGHT, TRUE);
    gtk_layer_set_exclusive_zone(GTK_WINDOW(window), -1);
    gtk_layer_set_keyboard_mode(GTK_WINDOW(window), GTK_LAYER_SHELL_KEYBOARD_MODE_NONE);

    gtk_widget_set_size_request(window, g_screen_w, 60);

    g_signal_connect(G_OBJECT(window), "draw", G_CALLBACK(on_draw), NULL);
    gtk_widget_add_tick_callback(window, (GtkTickCallback)on_tick, NULL, NULL);

    g_start_time = get_current_time();

    gtk_widget_show_all(window);
    gtk_main();

    return 0;
}

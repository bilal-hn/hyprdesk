#include <gtk/gtk.h>
#include <gtk-layer-shell/gtk-layer-shell.h>
#include <cairo.h>
#include <math.h>
#include <stdbool.h>
#include <sys/time.h>
#include <string.h>

typedef enum {
    ANIM_EXPAND = 0,
    ANIM_COLLAPSE = 1
} AnimMode;

static AnimMode g_mode = ANIM_EXPAND;
static double g_start_time = 0.0;
static const double DURATION = 0.38; // 380ms total animation duration

static int g_screen_w = 1280;
static int g_screen_h = 720;

// Geometry coordinates for 1280x720 (scaled proportionally on other resolutions)
// Compact bar:
static double compact_x = 458.0;
static double compact_y = 8.0;
static double compact_w = 365.0;
static double compact_h = 34.0;
static double compact_r = 17.0;

// Expanded 3 bars:
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

static double get_current_time() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + (tv.tv_usec / 1000000.0);
}

static double ease_in_out_cubic(double x) {
    return x < 0.5 ? 4.0 * x * x * x : 1.0 - pow(-2.0 * x + 2.0, 3.0) / 2.0;
}

static double ease_out_quad(double x) {
    return 1.0 - (1.0 - x) * (1.0 - x);
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

static gboolean on_draw(GtkWidget *widget, cairo_t *cr, gpointer user_data) {
    double now = get_current_time();
    double elapsed = now - g_start_time;
    double progress = elapsed / DURATION;

    if (progress > 1.0) {
        progress = 1.0;
    }

    // Clear background to fully transparent
    cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
    cairo_paint(cr);
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER);

    // Fade out near the very end to seamlessly hand off to Waybar
    double global_alpha = 1.0;
    if (progress > 0.85) {
        global_alpha = 1.0 - (progress - 0.85) / 0.15;
        if (global_alpha < 0.0) global_alpha = 0.0;
    }

    // Colors
    // Dark pill glass
    double bg_r = 18.0 / 255.0, bg_g = 20.0 / 255.0, bg_b = 26.0 / 255.0, bg_a = 0.92;
    // Glowing accent line (Cyber Mint / Pink energy)
    double glow_r = 132.0 / 255.0, glow_g = 214.0 / 255.0, glow_b = 194.0 / 255.0; // #84d6c2

    if (g_mode == ANIM_EXPAND) {
        if (progress < 0.28) {
            // Stage 1: Single center pill collapses vertically into a thin glowing line
            double p = progress / 0.28;
            double ep = ease_in_quad(p);

            double h = lerp(compact_h, 3.0, ep);
            double y = lerp(compact_y, compact_y + compact_h / 2.0 - 1.5, ep);
            double r = lerp(compact_r, 1.5, ep);
            double w = compact_w;
            double x = compact_x;

            // Fill
            double cur_r = lerp(bg_r, glow_r, ep);
            double cur_g = lerp(bg_g, glow_g, ep);
            double cur_b = lerp(bg_b, glow_b, ep);
            double cur_a = lerp(bg_a, 1.0, ep) * global_alpha;

            draw_rounded_rect(cr, x, y, w, h, r);
            cairo_set_source_rgba(cr, cur_r, cur_g, cur_b, cur_a);
            cairo_fill(cr);

            // Border / Glow
            draw_rounded_rect(cr, x, y, w, h, r);
            cairo_set_source_rgba(cr, glow_r, glow_g, glow_b, 0.4 * (1.0 - ep) * global_alpha);
            cairo_set_line_width(cr, 1.0);
            cairo_stroke(cr);
        }
        else if (progress < 0.72) {
            // Stage 2: Line splits into 3 lines and slides horizontally to left, center, right
            double p = (progress - 0.28) / (0.72 - 0.28);
            double ep = ease_in_out_cubic(p);

            double line_y = compact_y + compact_h / 2.0 - 1.5;
            double line_h = 3.0;

            // Center initial segments:
            double seg_w = compact_w / 3.0;
            double s1_x = compact_x;
            double s2_x = compact_x + seg_w;
            double s3_x = compact_x + 2.0 * seg_w;

            // Animate positions and widths
            double x1 = lerp(s1_x, left_x, ep);
            double w1 = lerp(seg_w, left_w, ep);

            double x2 = lerp(s2_x, mid_x, ep);
            double w2 = lerp(seg_w, mid_w, ep);

            double x3 = lerp(s3_x, right_x, ep);
            double w3 = lerp(seg_w, right_w, ep);

            // Draw subtle connecting energy beam between them
            cairo_set_source_rgba(cr, glow_r, glow_g, glow_b, 0.25 * (1.0 - p) * global_alpha);
            cairo_set_line_width(cr, 1.0);
            cairo_move_to(cr, x1 + w1, line_y + 1.5);
            cairo_line_to(cr, x2, line_y + 1.5);
            cairo_move_to(cr, x2 + w2, line_y + 1.5);
            cairo_line_to(cr, x3, line_y + 1.5);
            cairo_stroke(cr);

            // Draw the 3 glowing lines
            cairo_set_source_rgba(cr, glow_r, glow_g, glow_b, 0.95 * global_alpha);

            draw_rounded_rect(cr, x1, line_y, w1, line_h, 1.5);
            cairo_fill(cr);

            draw_rounded_rect(cr, x2, line_y, w2, line_h, 1.5);
            cairo_fill(cr);

            draw_rounded_rect(cr, x3, line_y, w3, line_h, 1.5);
            cairo_fill(cr);
        }
        else {
            // Stage 3: The 3 lines expand vertically into the 3 full bars
            double p = (progress - 0.72) / (1.0 - 0.72);
            double ep = ease_out_quad(p);

            double line_y = compact_y + compact_h / 2.0 - 1.5;

            double bars[3][5] = {
                { left_x, left_y, left_w, left_h, left_r },
                { mid_x, mid_y, mid_w, mid_h, mid_r },
                { right_x, right_y, right_w, right_h, right_r }
            };

            for (int i = 0; i < 3; i++) {
                double target_x = bars[i][0];
                double target_y = bars[i][1];
                double target_w = bars[i][2];
                double target_h = bars[i][3];
                double target_r = bars[i][4];

                double h = lerp(3.0, target_h, ep);
                double y = lerp(line_y, target_y, ep);
                double r = lerp(1.5, target_r, ep);

                double cur_r = lerp(glow_r, bg_r, ep);
                double cur_g = lerp(glow_g, bg_g, ep);
                double cur_b = lerp(glow_b, bg_b, ep);
                double cur_a = lerp(1.0, bg_a, ep) * global_alpha;

                draw_rounded_rect(cr, target_x, y, target_w, h, r);
                cairo_set_source_rgba(cr, cur_r, cur_g, cur_b, cur_a);
                cairo_fill(cr);

                // Subtle border
                draw_rounded_rect(cr, target_x, y, target_w, h, r);
                cairo_set_source_rgba(cr, 255.0/255.0, 255.0/255.0, 255.0/255.0, 0.12 * ep * global_alpha);
                cairo_set_line_width(cr, 1.0);
                cairo_stroke(cr);
            }
        }
    }
    else {
        // ANIM_COLLAPSE (3 Bars -> Lines -> Merge to 1 Island)
        if (progress < 0.28) {
            // Stage 1: The 3 bars collapse vertically into 3 thin glowing lines
            double p = progress / 0.28;
            double ep = ease_in_quad(p);

            double line_y = compact_y + compact_h / 2.0 - 1.5;

            double bars[3][5] = {
                { left_x, left_y, left_w, left_h, left_r },
                { mid_x, mid_y, mid_w, mid_h, mid_r },
                { right_x, right_y, right_w, right_h, right_r }
            };

            for (int i = 0; i < 3; i++) {
                double target_x = bars[i][0];
                double target_y = bars[i][1];
                double target_w = bars[i][2];
                double target_h = bars[i][3];
                double target_r = bars[i][4];

                double h = lerp(target_h, 3.0, ep);
                double y = lerp(target_y, line_y, ep);
                double r = lerp(target_r, 1.5, ep);

                double cur_r = lerp(bg_r, glow_r, ep);
                double cur_g = lerp(bg_g, glow_g, ep);
                double cur_b = lerp(bg_b, glow_b, ep);
                double cur_a = lerp(bg_a, 1.0, ep) * global_alpha;

                draw_rounded_rect(cr, target_x, y, target_w, h, r);
                cairo_set_source_rgba(cr, cur_r, cur_g, cur_b, cur_a);
                cairo_fill(cr);
            }
        }
        else if (progress < 0.72) {
            // Stage 2: Left and right lines glide toward the center, merging with mid line
            double p = (progress - 0.28) / (0.72 - 0.28);
            double ep = ease_in_out_cubic(p);

            double line_y = compact_y + compact_h / 2.0 - 1.5;
            double line_h = 3.0;

            double seg_w = compact_w / 3.0;
            double s1_x = compact_x;
            double s2_x = compact_x + seg_w;
            double s3_x = compact_x + 2.0 * seg_w;

            // In reverse: from expanded positions -> center segments
            double x1 = lerp(left_x, s1_x, ep);
            double w1 = lerp(left_w, seg_w, ep);

            double x2 = lerp(mid_x, s2_x, ep);
            double w2 = lerp(mid_w, seg_w, ep);

            double x3 = lerp(right_x, s3_x, ep);
            double w3 = lerp(right_w, seg_w, ep);

            // Subtle energy beam
            cairo_set_source_rgba(cr, glow_r, glow_g, glow_b, 0.25 * p * global_alpha);
            cairo_set_line_width(cr, 1.0);
            cairo_move_to(cr, x1 + w1, line_y + 1.5);
            cairo_line_to(cr, x2, line_y + 1.5);
            cairo_move_to(cr, x2 + w2, line_y + 1.5);
            cairo_line_to(cr, x3, line_y + 1.5);
            cairo_stroke(cr);

            // 3 lines gliding into 1
            cairo_set_source_rgba(cr, glow_r, glow_g, glow_b, 0.95 * global_alpha);

            draw_rounded_rect(cr, x1, line_y, w1, line_h, 1.5);
            cairo_fill(cr);

            draw_rounded_rect(cr, x2, line_y, w2, line_h, 1.5);
            cairo_fill(cr);

            draw_rounded_rect(cr, x3, line_y, w3, line_h, 1.5);
            cairo_fill(cr);
        }
        else {
            // Stage 3: The unified center line expands vertically back into the single island
            double p = (progress - 0.72) / (1.0 - 0.72);
            double ep = ease_out_quad(p);

            double line_y = compact_y + compact_h / 2.0 - 1.5;

            double h = lerp(3.0, compact_h, ep);
            double y = lerp(line_y, compact_y, ep);
            double r = lerp(1.5, compact_r, ep);
            double w = compact_w;
            double x = compact_x;

            double cur_r = lerp(glow_r, bg_r, ep);
            double cur_g = lerp(glow_g, bg_g, ep);
            double cur_b = lerp(glow_b, bg_b, ep);
            double cur_a = lerp(1.0, bg_a, ep) * global_alpha;

            draw_rounded_rect(cr, x, y, w, h, r);
            cairo_set_source_rgba(cr, cur_r, cur_g, cur_b, cur_a);
            cairo_fill(cr);

            // Subtle border
            draw_rounded_rect(cr, x, y, w, h, r);
            cairo_set_source_rgba(cr, 255.0/255.0, 255.0/255.0, 255.0/255.0, 0.12 * ep * global_alpha);
            cairo_set_line_width(cr, 1.0);
            cairo_stroke(cr);
        }
    }

    if (progress >= 1.0) {
        gtk_main_quit();
        return FALSE;
    }

    return FALSE;
}

static gboolean on_tick(GtkWidget *widget, GdkFrameClock *frame_clock, gpointer user_data) {
    gtk_widget_queue_draw(widget);
    return G_SOURCE_CONTINUE;
}

int main(int argc, char **argv) {
    if (argc > 1 && strcmp(argv[1], "collapse") == 0) {
        g_mode = ANIM_COLLAPSE;
    } else {
        g_mode = ANIM_EXPAND;
    }

    gtk_init(&argc, &argv);

    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);

    // Make window transparent
    GdkScreen *screen = gtk_widget_get_screen(window);
    GdkVisual *visual = gdk_screen_get_rgba_visual(screen);
    if (visual && gdk_screen_is_composited(screen)) {
        gtk_widget_set_visual(window, visual);
    }
    gtk_widget_set_app_paintable(window, TRUE);

    // Detect screen geometry
    GdkDisplay *display = gdk_display_get_default();
    GdkMonitor *monitor = gdk_display_get_primary_monitor(display);
    if (!monitor) monitor = gdk_display_get_monitor(display, 0);
    if (monitor) {
        GdkRectangle geom;
        gdk_monitor_get_geometry(monitor, &geom);
        if (geom.width > 0) g_screen_w = geom.width;
        if (geom.height > 0) g_screen_h = geom.height;
    }

    // Dynamic scale if monitor is not 1280
    double scale = (double)g_screen_w / 1280.0;
    if (fabs(scale - 1.0) > 0.05) {
        compact_x *= scale;
        compact_w *= scale;
        left_x *= scale;
        left_w *= scale;
        mid_x *= scale;
        mid_w *= scale;
        right_x = g_screen_w - 16.0 * scale - (right_w * scale);
        right_w *= scale;
    }

    // Layer shell setup
    gtk_layer_init_for_window(GTK_WINDOW(window));
    gtk_layer_set_layer(GTK_WINDOW(window), GTK_LAYER_SHELL_LAYER_OVERLAY);
    gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_TOP, TRUE);
    gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_LEFT, TRUE);
    gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_RIGHT, TRUE);
    gtk_layer_set_exclusive_zone(GTK_WINDOW(window), -1); // Transparent, non-blocking
    gtk_layer_set_keyboard_mode(GTK_WINDOW(window), GTK_LAYER_SHELL_KEYBOARD_MODE_NONE);

    gtk_widget_set_size_request(window, g_screen_w, 60);

    g_signal_connect(G_OBJECT(window), "draw", G_CALLBACK(on_draw), NULL);
    gtk_widget_add_tick_callback(window, (GtkTickCallback)on_tick, NULL, NULL);

    g_start_time = get_current_time();

    gtk_widget_show_all(window);
    gtk_main();

    return 0;
}

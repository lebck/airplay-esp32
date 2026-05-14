// ============================================================
// Snap-fit case for ESP32-S3-Zero + PCM5102A (side by side)
// Both connectors (USB-C, 3.5mm jack) face the same end.
//
// PCM5102A layout: 3.5mm jack is on the LONG edge (32mm side),
// so the DAC is rotated 90° — its 32mm edge faces front,
// 17mm goes into depth.
// ============================================================
//
// Print settings: PLA, 0.2mm layer, no supports needed.
// Print base and lid separately (set PART below).
//
// PART = "base"  → bottom half with board cradles
// PART = "lid"   → snap-fit top cover
// PART = "both"  → exploded view for preview

PART = "both"; // "base", "lid", or "both"

// ---- Tolerances & print tuning ----
tol        = 0.3;   // clearance around boards
snap_tol   = 0.15;  // snap-fit clearance
wall       = 1.8;   // wall thickness
floor_t    = 1.5;   // floor / ceiling thickness
corner_r   = 2.0;   // outer corner radius

// ---- ESP32-S3-Zero dimensions (measured) ----
esp_l      = 23.5;  // long edge
esp_w      = 18.0;  // short edge
esp_pcb_t  = 1.0;   // PCB thickness
esp_total_h = 5.0;  // total board height (PCB + components)
esp_comp_h = esp_total_h - esp_pcb_t; // component height above PCB
esp_usbc_w = 9.0;   // USB-C connector width
esp_usbc_h = 3.5;   // USB-C connector height from PCB bottom
esp_usbc_protrude = 1.5; // how far USB-C sticks past PCB edge

// ---- PCM5102A dimensions (measured) ----
// Physical PCB is 32 x 17 mm. Total height 7mm.
// Jack is on the 32mm LONG edge, spanning 23mm–29mm from one end.
// In the case, the DAC is rotated so:
//   - 32mm edge faces front (X direction in case) = dac_front
//   - 17mm goes into depth (Y direction in case) = dac_depth
dac_front  = 32.0;  // dimension along front wall
dac_depth  = 17.0;  // dimension into the case
dac_pcb_t  = 1.6;   // PCB thickness
dac_total_h = 7.0;  // total board height (PCB + components)
dac_comp_h = dac_total_h - dac_pcb_t; // component height above PCB
// Jack position along the 32mm front edge (measured from left end of DAC)
dac_jack_start = 23.0; // jack starts at 23mm
dac_jack_end   = 29.0; // jack ends at 29mm
dac_jack_w = dac_jack_end - dac_jack_start; // = 6mm
dac_jack_h = dac_total_h;  // jack is the tallest component
dac_jack_protrude = 7.0;   // jack protrusion beyond PCB edge

// ---- Board gap ----
board_gap  = 3.0;   // space between the two boards (wire routing)

// Ledge height for boards to sit on
ledge_h    = 1.5;
ledge_w    = 1.2;

// ---- Derived dimensions ----
// Boards sit on small ledges, components face up.
// Front wall is at Y=0. Both connectors exit through it.
//
// Layout (top view, looking down):
//
//        FRONT (Y=0) — connectors exit here
//   ┌────────────────────────────────────────┐
//   │  ESP32-S3-Zero  │ gap │   PCM5102A     │
//   │  18 x 23.5      │     │   32 x 17      │
//   │  USB-C →front   │     │   jack →front   │
//   └────────────────────────────────────────┘
//        BACK
//
// ESP sits left, DAC sits right (wider along front).
// ESP is deeper (23.5mm) than DAC (17mm).

// Internal cavity
cavity_w = esp_w + board_gap + dac_front + 2*tol;
cavity_l = esp_l + 2*tol;  // ESP is deeper (23.5 > 17), dictates depth
max_comp_h = max(esp_total_h, dac_total_h); // 7mm (DAC with jack)
// Total internal height: ledge + tallest board + generous clearance
cavity_h = ledge_h + max_comp_h + 15.0;

// Outer box
box_w = cavity_w + 2*wall;
box_l = cavity_l + 2*wall;
box_h = cavity_h + 2*floor_t; // floor + cavity + ceiling

// Both halves same height (split at midpoint)
base_h = box_h / 2;
lid_h  = box_h / 2 + 2.0; // +2mm for overlap lip

// Board positions (relative to cavity origin)
// ESP32: left side, full depth, USB-C at front (Y=0 side)
esp_x = tol;
esp_y = tol;  // USB-C faces front

// DAC: right side, shorter depth, jack at front (Y=0 side)
dac_x = tol + esp_w + board_gap;
dac_y = tol;  // jack faces front, board extends back 17mm

// ---- Snap-fit parameters ----
snap_w     = 6.0;
snap_h     = 1.2;
snap_bump  = 0.6;

// Snaps on the long sides (front/back walls, since box is wider than deep)
// and on the short sides
snap_count_long = 2;  // snaps on each Y-axis wall (left & right sides)
snap_count_short = 1; // snap on each X-axis wall (front & back)

// ---- Antenna keep-out ----
// ESP32-S3-Zero antenna is at top-left corner near USB-C end.
// That's the front-left of the case. Thin the left wall there.
antenna_window_w = 10.0;
antenna_window_h = 6.0;

$fn = 30;

// ============================================================
// Modules
// ============================================================

module rounded_box(w, l, h, r) {
    hull() {
        for (x = [r, w-r], y = [r, l-r])
            translate([x, y, 0])
                cylinder(r=r, h=h);
    }
}

module base() {
    difference() {
        // Outer shell
        rounded_box(box_w, box_l, base_h, corner_r);

        // Cavity
        translate([wall, wall, floor_t])
            cube([cavity_w, cavity_l, base_h]);

        // --- Connector cutouts (front wall, Y=0) ---
        // Full height from floor to top — generous openings

        // USB-C cutout: centered on ESP32's width
        translate([wall + esp_x + (esp_w - esp_usbc_w)/2 - tol,
                   -0.1,
                   floor_t])
            cube([esp_usbc_w + 2*tol, wall + 0.2, base_h]);

        // 3.5mm jack cutout: at 23–29mm along DAC's 32mm front edge
        translate([wall + dac_x + dac_jack_start - tol,
                   -0.1,
                   floor_t])
            cube([dac_jack_w + 2*tol, wall + 0.2, base_h]);

        // Antenna relief: thin the left wall near the front
        // (ESP antenna is at front-left corner)
        translate([-0.1,
                   wall - 0.1,
                   floor_t])
            cube([wall - 0.4, antenna_window_w, antenna_window_h]);
    }

    // ---- Board support ledges ----

    // ESP32 ledges (left and right of the 18mm-wide board)
    for (side = [0, 1]) {
        translate([wall + esp_x + (side == 0 ? -ledge_w/2 : esp_w - ledge_w/2),
                   wall + esp_y,
                   floor_t])
            cube([ledge_w, esp_l, ledge_h]);
    }
    // ESP32 back ledge
    translate([wall + esp_x,
               wall + esp_y + esp_l - ledge_w,
               floor_t])
        cube([esp_w, ledge_w, ledge_h]);

    // DAC ledges (left and right of the 32mm-wide board, rotated orientation)
    for (side = [0, 1]) {
        translate([wall + dac_x + (side == 0 ? -ledge_w/2 : dac_front - ledge_w/2),
                   wall + dac_y,
                   floor_t])
            cube([ledge_w, dac_depth, ledge_h]);
    }
    // DAC back ledge
    translate([wall + dac_x,
               wall + dac_y + dac_depth - ledge_w,
               floor_t])
        cube([dac_front, ledge_w, ledge_h]);

    // ---- Snap-fit hooks ----
    // Left & right walls (along Y axis)
    for (side = [0, 1]) {
        for (i = [0:snap_count_short-1]) {
            y_pos = box_l * (i + 1) / (snap_count_short + 1);
            x_pos = side == 0 ? wall : box_w-wall;
            translate([x_pos, y_pos + snap_w/2, base_h-0.5])
              rotate([180, 0, 0])
                mirror([side, 0, 0])
                    snap_hook();
        }
    }
    // Front & back walls (along X axis)
    for (side = [0, 1]) {
        for (i = [0:snap_count_short-1]) {
            x_pos = box_w * (i + 1) / (2);
            y_pos = side == 0 ? wall : box_l-wall;
            translate([x_pos-snap_w + snap_w/2, y_pos, base_h-0.5])
                rotate([180, 0, 90])
                    mirror([side, 0, 0])
                        snap_hook();
        }
    }
}

module snap_hook() {
    difference() {
        cube([snap_bump + wall*0.1, snap_w, snap_h]);
        translate([snap_bump, -0.1, -0.1])
            rotate([0, -30, 0])
                cube([snap_bump*2, snap_w + 0.2, snap_h + 0.2]);
    }
}

module lid() {
    lip_h = 2.0;
    lip_t = 0.8;

    difference() {
        union() {
            // Outer lid
            rounded_box(box_w, box_l, floor_t, corner_r);

            // Inner lip
            translate([wall + snap_tol, wall + snap_tol, -lip_h])
                cube([cavity_w - 2*snap_tol,
                      cavity_l - 2*snap_tol,
                      lip_h]);
        }

        // Hollow out lip
        translate([wall + lip_t + snap_tol, wall + lip_t + snap_tol, -lip_h - 0.1])
            cube([cavity_w - 2*lip_t - 2*snap_tol,
                  cavity_l - 2*lip_t - 2*snap_tol,
                  lip_h + 0.2]);

    }
}

// ============================================================
// Render
// ============================================================

if (PART == "base" || PART == "both") {
    color("SlateGray", 0.9) base();
}

if (PART == "lid" || PART == "both") {
    explode = PART == "both" ? 15 : 0;
    translate([0, 0, base_h + explode])
        color("SteelBlue", 0.7) lid();
}

// ---- Preview: ghost board outlines ----
if (PART == "both") {
    // ESP32-S3-Zero
    %translate([wall + esp_x, wall + esp_y, floor_t + ledge_h])
        cube([esp_w, esp_l, esp_pcb_t]);

    // PCM5102A (rotated: 32mm along X, 17mm along Y)
    %translate([wall + dac_x, wall + dac_y, floor_t + ledge_h])
        cube([dac_front, dac_depth, dac_pcb_t]);

    // 3.5mm jack ghost (at 23–29mm along DAC front edge)
    %translate([wall + dac_x + dac_jack_start,
                wall + dac_y - dac_jack_protrude,
                floor_t + ledge_h + dac_pcb_t])
        cube([dac_jack_w, dac_jack_protrude, dac_jack_h - dac_pcb_t]);

    // USB-C ghost (protrudes from front of ESP32)
    %translate([wall + esp_x + (esp_w - esp_usbc_w)/2,
                wall + esp_y - esp_usbc_protrude,
                floor_t + ledge_h])
        cube([esp_usbc_w, esp_usbc_protrude, esp_usbc_h]);
}

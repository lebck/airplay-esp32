// ============================================================
// Ventilated snap-fit case: Seeed Studio XIAO ESP32S3 + PCM5102A
// Historical filename retained. Standard XIAO, without Sense expansion.
// USB-C and the DAC's jack face the front (Y=0).
// XIAO: components DOWN, solder side UP. DAC: components UP.
// XIAO is flipped about its front-to-back axis, so U.FL moves to rear-right.
// The PCB edge-to-edge gap remains exactly 3 mm, as in the old case.
//
// XIAO outline: https://wiki.seeedstudio.com/xiao_esp32s3_getting_started/
// Mechanical reference: XIAO_ESP32S3_v1.1_Dimensioning.dxf + Seeed 3D model.
// PCM dimensions and jack position retained from the measured old model.
// PCB thickness, solder, antenna and connector envelopes are fit parameters;
// check them against the actual assembly before printing the complete case.
//
// Print: PETG, 0.2 mm layers, 0.4 mm nozzle, 3 perimeters.
// Base: floor on bed. Lid: outside face on bed (PART="lid" does this).
// Small latch overhangs/vent bridges need no generated support.
// Slide connectors into the front openings, then gently seat the boards.
// Release the thin PCB fingers outwards to remove boards; do not pull cables.
//
// PART="base" / "lid": individual parts, resting on Z=0.
// PART="both": exploded preview; PART="assembled": closed preview.
// PART="print": base and inverted lid side by side on the build plate.
// SHOW_BOARDS only adds ghost geometry in preview, never to exported STLs.
// ============================================================

PART = "both"; // [base,lid,both,assembled,print]
SHOW_BOARDS = true;

// ---- Fit and print parameters (mm) ----
tol = 0.30;                  // lateral PCB clearance
wall = 1.8;
floor_t = 1.6;
corner_r = 2.0;
ledge_h = 7.0;               // shared PCB seating height above inner floor
support_bite = 0.8;          // only support the bare PCB edge
clip_t = 0.8;                // two nozzle widths; PETG spring finger
clip_bite = 0.4;             // lip overlap over PCB edge
clip_z_tol = 0.25;           // vertical play above the seated PCB
clip_hook_h = 0.8;           // ramp for pushing PCB into its clips
clip_relief = 0.8;           // space behind a finger for deflection

// ---- Seeed Studio XIAO ESP32S3 ----
esp_w = 17.8;                // X direction
esp_l = 21.0;                // Y direction, USB at the front
esp_pcb_t = 1.0;             // fit parameter: measure actual PCB
esp_corner_r = 1.5;
esp_total_h = 5.0;           // PCB + components; components now hang below PCB
esp_comp_h = esp_total_h - esp_pcb_t;
esp_under_air = 3.0;         // minimum free air below downward-facing components
esp_usbc_w = 9.0;
esp_usbc_h = 3.5;
esp_usbc_protrude = 1.8;
esp_usb_open_w = 12.0;       // clearance for the USB plug's moulding
esp_usb_open_h = 6.0;
esp_ufl_h = 2.5;             // provisional mated U.FL plug envelope below PCB
esp_clip_w = 1.0;
// Corners outside the seven solder pads; avoid RESET/BOOT and the U.FL socket.
esp_clip_y = [0.8, esp_l - 0.8 - esp_clip_w];

// ---- Measured PCM5102A, rotated 90 degrees ----
dac_front = 32.0;            // long edge along front wall
dac_depth = 17.0;            // short edge into case
dac_pcb_t = 1.6;
dac_total_h = 7.0;
dac_jack_start = 23.0;
dac_jack_end = 29.0;
dac_jack_w = dac_jack_end - dac_jack_start;
dac_jack_protrude = 7.0;
dac_clip_w = 2.4;
// Short front/rear contact patches; long side with I2S wiring stays open.
// Move these offsets if solder joints on your particular DAC reach its edge.
dac_clip_x = [3.0, 18.0];

// ---- Layout ----
board_gap = 3.0;             // UNCHANGED: PCB edge to PCB edge, not centres
side_clear = 2.4;            // room outside boards for XIAO fingers to flex
front_clear = 0.6;           // both PCB front edges remain aligned
headroom = 8.0;              // air and wire space above the tallest board
rear_service_gap = 6.0;      // finger release, U.FL cable bend and separation

// ---- Antenna compartment ----
// Provisional envelope for a small rod antenna, NOT a measured antenna size.
// Lay the antenna across X behind the boards; retain with two small cable ties.
// Set antenna_depth to e.g. 19.0 for a flat 37.4 x 17.5 mm Seeed FPC A-02.
// A top-open rear notch also allows routing the coax to an external antenna.
antenna_length = 50.0;
antenna_depth = 12.0;
antenna_height = 10.0;
antenna_clear = 0.8;
antenna_floor_h = 1.0;
antenna_tie_w = 3.0;
antenna_tie_h = 1.8;
antenna_cable_d = 2.4;        // clearance around thin coax; drop it in from above

// ---- Lid retention ----
snap_tol = 0.20;
lip_t = 0.8;
lip_h = 4.0;
lid_snap_w = 5.0;
lid_snap_bump = 0.45;
lid_snap_h = 1.2;
lid_snap_drop = 1.5;          // bump starts this far below seam
lid_finger_gap = 0.8;

// ---- Passive ventilation ----
vent_w = 2.0;
vent_pitch = 4.0;
vent_border = 3.0;
side_vent_h = 2.0;

// ---- Derived geometry ----
// All board positions below use case coordinates (no hidden second offset).
esp_x = wall + side_clear;
esp_y = wall + front_clear;
dac_x = esp_x + esp_w + board_gap;
dac_y = esp_y;
pcb_z = floor_t + ledge_h;
esp_usb_z = pcb_z - esp_usbc_h;
esp_usb_open_z = esp_usb_z - (esp_usb_open_h-esp_usbc_h)/2;
esp_usb_open_top = esp_usb_open_z + esp_usb_open_h;
boards_back = max(esp_y + esp_l, dac_y + dac_depth);
antenna_y = boards_back + rear_service_gap;
cavity_w = max(esp_w + board_gap + dac_front + 2*side_clear,
               antenna_length + 2*antenna_clear);
cavity_l = antenna_y + antenna_depth + antenna_clear - wall;
box_w = cavity_w + 2*wall;
box_l = cavity_l + 2*wall;
base_h = max(pcb_z + max(esp_pcb_t, dac_total_h) + headroom,
             floor_t + antenna_floor_h + antenna_tie_h + antenna_height + lip_h + 1);
box_h = base_h + floor_t;
antenna_x = (box_w - antenna_length)/2;
// Two separated snap fingers on each side; ventilation lies below them.
lid_snap_y = [box_l*0.32, box_l*0.73];
antenna_exit_x = esp_x + esp_w - 3.5; // flipped XIAO: rear-right U.FL
antenna_exit_z = base_h - lip_h - antenna_cable_d;
eps = 0.02;
$fn = 40;

assert(board_gap == 3.0, "Keep the original 3 mm board gap.");
assert(abs(dac_x - (esp_x + esp_w) - board_gap) < 0.001);
assert(side_clear > tol + clip_t + clip_bite + clip_relief,
       "XIAO spring fingers need room to flex outside the PCB.");
assert(board_gap > tol + clip_t + clip_bite + clip_relief,
       "Spring finger must not hit the neighbouring DAC.");
assert(ledge_h >= 3, "Leave room for solder and ventilation below the PCBs.");
assert(ledge_h - max(esp_comp_h, esp_usbc_h, esp_ufl_h) >= esp_under_air,
       "Raise both PCB supports to leave air below the inverted XIAO.");
assert(esp_usb_open_h >= esp_usbc_h + 2*tol && esp_usb_open_z > floor_t,
       "USB opening must clear the connector and preserve the case floor.");
assert(lip_h > lid_snap_drop + lid_snap_h);
assert(antenna_length + 2*antenna_clear <= cavity_w);
assert(antenna_cable_d > 0 && antenna_exit_z > pcb_z + esp_pcb_t);
assert(PART == "base" || PART == "lid" || PART == "both" ||
       PART == "assembled" || PART == "print", "Unknown PART selector.");
echo(case_mm = [box_w, box_l, box_h], board_gap_mm = board_gap,
     pcb_under_clearance_mm = ledge_h,
     xiao_component_air_mm = ledge_h-max(esp_comp_h,esp_usbc_h,esp_ufl_h),
     antenna_envelope_mm = [antenna_length, antenna_depth, antenna_height]);

// ============================================================
// Primitives
// ============================================================
module rounded_box(w, l, h, r) {
    linear_extrude(h)
        hull()
            for (x = [r, w-r], y = [r, l-r])
                translate([x, y]) circle(r=r);
}

// Extrude a profile given as [outward, height] along a local edge (X).
module edge_profile(points, width) {
    multmatrix([[0,0,1,0], [1,0,0,0], [0,1,0,0], [0,0,0,1]])
        linear_extrude(width) polygon(points);
}

// Local board edge is Y=0; PCB lies at negative Y, stem at positive Y.
// A separate foot supports the underside without shortening the spring arm.
module pcb_clip(width, pcb_t) {
    hook_z = pcb_z + pcb_t + clip_z_tol;
    translate([0, tol, floor_t-eps])
        cube([width, clip_t, hook_z-floor_t+clip_hook_h+eps]);
    translate([0, 0, hook_z])
        edge_profile([[-clip_bite,0], [tol+clip_t,0],
                      [tol+clip_t,clip_hook_h], [tol,clip_hook_h]], width);
    // Foot and spring only connect at the case floor.
    translate([0, -support_bite, floor_t-eps])
        cube([width, support_bite, ledge_h+eps]);
}

module pcb_stop(width, pcb_t) {
    // Rigid front toe for DAC; PCB slides under its small retaining lip.
    translate([0, -support_bite, floor_t-eps])
        cube([width, support_bite+tol+clip_t, ledge_h+eps]);
    translate([0, tol, pcb_z-eps])
        cube([width, clip_t, pcb_t+clip_z_tol+clip_hook_h+eps]);
    translate([0, -clip_bite, pcb_z+pcb_t+clip_z_tol])
        cube([width, tol+clip_t+clip_bite, clip_hook_h]);
}

module board_mounts() {
    // Four XIAO clips on the side-edge corners, not across the GPIO rows.
    for (dy = esp_clip_y) {
        translate([esp_x, esp_y+dy, 0]) rotate([0,0,90])
            pcb_clip(esp_clip_w, esp_pcb_t);
        translate([esp_x+esp_w, esp_y+dy+esp_clip_w, 0]) rotate([0,0,-90])
            pcb_clip(esp_clip_w, esp_pcb_t);
    }
    // Front stops flank the LOWER USB plug opening; no stop enters its width.
    for (dx = [1.2, esp_w-2.4])
        translate([esp_x+dx, esp_y-tol-clip_t, floor_t-eps])
            cube([1.2, clip_t, ledge_h+esp_pcb_t/2+eps]);
    // Rear stops leave the rear-right U.FL/coax route open BELOW the PCB.
    for (dx = [2.0, 8.0])
        translate([esp_x+dx, esp_y+esp_l+tol, floor_t-eps])
            cube([1.5, clip_t, ledge_h+esp_pcb_t/2+eps]);
    // DAC front toes and rear fingers keep retention out of the middle of
    // the inter-board gap; only small corner locators enter the wiring space.
    for (dx = dac_clip_x) {
        translate([dac_x+dx+dac_clip_w, dac_y, 0]) rotate([0,0,180])
            pcb_stop(dac_clip_w, dac_pcb_t);
        translate([dac_x+dx, dac_y+dac_depth, 0])
            pcb_clip(dac_clip_w, dac_pcb_t);
    }
    // Low corner fences prevent DAC sliding sideways under the front toes.
    // They end below PCB top, so they do not cover the pin rows.
    for (dx = [-tol-clip_t, dac_front+tol])
        translate([dac_x+dx, dac_y+dac_depth-1.2, floor_t-eps])
            cube([clip_t, 1.0, ledge_h+dac_pcb_t/2+eps]);
}

module connector_cutouts(z_top) {
    // Open upwards for installing already-wired boards without threading plugs.
    translate([esp_x+(esp_w-esp_usb_open_w)/2, -eps, esp_usb_open_z])
        cube([esp_usb_open_w, wall+2*eps, z_top-esp_usb_open_z+eps]);
    translate([dac_x+dac_jack_start-tol, -eps, pcb_z+dac_pcb_t-tol])
        cube([dac_jack_w+2*tol, wall+2*eps,
              z_top-pcb_z-dac_pcb_t+tol+eps]);
}

module vent_field(x, y, w, l, z, h) {
    count = floor((w-2*vent_border+vent_pitch-vent_w)/vent_pitch);
    used = count*vent_w + (count-1)*(vent_pitch-vent_w);
    // Short spans across the slots are easy to bridge when slicing.
    for (i = [0:count-1])
        translate([x+(w-used)/2+i*vent_pitch, y+vent_border, z])
            cube([vent_w, l-2*vent_border, h]);
}

module board_vents(z, h) {
    vent_field(esp_x, esp_y, esp_w, esp_l, z, h);
    vent_field(dac_x, dac_y, dac_front, dac_depth, z, h);
}

module antenna_cable_cutout(z_top) {
    // U-shaped notch through the rear wall. The lid lip is interrupted too.
    translate([antenna_exit_x, box_l-wall-eps, antenna_exit_z+antenna_cable_d/2])
        rotate([-90,0,0]) cylinder(d=antenna_cable_d, h=wall+2*eps);
    translate([antenna_exit_x-antenna_cable_d/2, box_l-wall-eps,
               antenna_exit_z+antenna_cable_d/2])
        cube([antenna_cable_d, wall+2*eps, z_top-antenna_exit_z]);
}

module antenna_mount() {
    // Two broad raised saddles with tunnels for loose, replaceable cable ties.
    // The radiator stays behind the boards, clear of the metal USB/shield/jack.
    for (fraction = [0.22, 0.78])
        translate([antenna_x+antenna_length*fraction-3,
                   antenna_y, floor_t-eps])
            difference() {
                cube([6, antenna_depth, antenna_floor_h+antenna_tie_h+eps]);
                translate([(6-antenna_tie_w)/2, -eps, antenna_floor_h])
                    cube([antenna_tie_w, antenna_depth+2*eps, antenna_tie_h-0.4]);
            }
}

// ============================================================
// Base and lid
// ============================================================
module base() {
    union() {
        difference() {
            rounded_box(box_w, box_l, base_h, corner_r);
            translate([wall, wall, floor_t]) cube([cavity_w, cavity_l, base_h]);
            connector_cutouts(base_h);
            board_vents(-eps, floor_t+2*eps);
            // Low side intakes still admit air when the bottom rests on a table.
            for (x = [-eps, box_w-wall-eps], y = [7:5:boards_back-3])
                translate([x,y,floor_t+0.8])
                    cube([wall+2*eps, 3.0, side_vent_h]);
            antenna_cable_cutout(base_h);
            // Matching recesses: lid fingers engage the walls, not free space.
            for (side = [0,1], y = lid_snap_y)
                translate([side == 0 ? wall-lid_snap_bump-snap_tol : box_w-wall-eps,
                           y-lid_snap_w/2-snap_tol,
                           base_h-lid_snap_drop-lid_snap_h-snap_tol])
                    cube([lid_snap_bump+snap_tol+eps, lid_snap_w+2*snap_tol,
                          lid_snap_h+2*snap_tol]);
        }
        board_mounts();
        antenna_mount();
    }
}

// The lid's outside face is at local Z=floor_t; the locating lip points down.
module lid() {
    difference() {
        union() {
            rounded_box(box_w, box_l, floor_t, corner_r);
            // Close the tall assembly slots above the connectors. These tongues
            // sit in the front wall, leaving clearance around the actual plugs.
            for (opening = [[esp_x+(esp_w-esp_usb_open_w)/2,esp_usb_open_w,
                             esp_usb_open_top],
                            [dac_x+dac_jack_start-tol,dac_jack_w+2*tol,
                             pcb_z+dac_total_h+0.5]])
                translate([opening[0]+snap_tol,snap_tol,opening[2]-base_h])
                    cube([opening[1]-2*snap_tol,wall-2*snap_tol,
                          base_h-opening[2]+eps]);
            // Close the rear assembly notch above the coax without pinching it.
            translate([antenna_exit_x-antenna_cable_d/2+snap_tol,
                       box_l-wall+snap_tol,
                       antenna_exit_z+antenna_cable_d+tol-base_h])
                cube([antenna_cable_d-2*snap_tol,wall-2*snap_tol,
                      base_h-antenna_exit_z-antenna_cable_d-tol+eps]);
            difference() {
                translate([wall+snap_tol,wall+snap_tol,-lip_h])
                    cube([cavity_w-2*snap_tol,cavity_l-2*snap_tol,lip_h+eps]);
                translate([wall+snap_tol+lip_t,wall+snap_tol+lip_t,-lip_h-eps])
                    cube([cavity_w-2*(snap_tol+lip_t),
                          cavity_l-2*(snap_tol+lip_t),lip_h+2*eps]);
                // Isolate four elastic lid fingers, attached only at the roof.
                for (side = [0,1], y = lid_snap_y, end = [-1,1])
                    translate([side == 0 ? wall-eps : box_w-wall-snap_tol-lip_t-eps,
                               y+end*(lid_snap_w/2+lid_finger_gap/2)-lid_finger_gap/2,
                               -lip_h-eps])
                        cube([snap_tol+lip_t+2*eps,lid_finger_gap,lip_h+eps]);
            }
            // Outward triangular detents, with an insertion ramp at the bottom.
            for (side = [0,1], y = lid_snap_y)
                translate([side == 0 ? wall+snap_tol : box_w-wall-snap_tol,
                           y+ (side == 0 ? -lid_snap_w/2 : lid_snap_w/2),
                           -lid_snap_drop-lid_snap_h])
                    rotate([0,0,side == 0 ? 90 : -90])
                        edge_profile([[-eps,0], [lid_snap_bump,lid_snap_h*0.7],
                                      [lid_snap_bump,lid_snap_h],[-eps,lid_snap_h]],
                                     lid_snap_w);
        }
        board_vents(-eps, floor_t+2*eps);
        // Do not run the locating lip through the USB/jack insertion openings.
        for (opening = [[esp_x+(esp_w-esp_usb_open_w)/2,esp_usb_open_w],
                        [dac_x+dac_jack_start-tol,dac_jack_w+2*tol]])
            translate([opening[0]-tol,wall-eps,-lip_h-eps])
                cube([opening[1]+2*tol,snap_tol+lip_t+2*eps,lip_h+eps]);
        translate([antenna_exit_x-antenna_cable_d/2-tol,
                   box_l-wall-snap_tol-lip_t-eps,-lip_h-eps])
            cube([antenna_cable_d+2*tol,snap_tol+lip_t+2*eps,lip_h+eps]);
    }
}

module lid_for_print() {
    translate([0,box_l,floor_t]) rotate([180,0,0]) lid();
}

// Hardware is defined component-side up in local coordinates, then rotated
// 180 degrees about Y. This flips X and Z while keeping USB facing forward.
module xiao_preview() {
    translate([esp_x+esp_w,esp_y,pcb_z+esp_pcb_t]) rotate([0,180,0]) {
        color("SeaGreen")
            rounded_box(esp_w,esp_l,esp_pcb_t,esp_corner_r);
        color("Silver") translate([(esp_w-esp_usbc_w)/2,-esp_usbc_protrude,esp_pcb_t])
            cube([esp_usbc_w,7.5,esp_usbc_h]);
        color("Silver") translate([2.5,6.5,esp_pcb_t])
            cube([12.8,10,esp_comp_h]);
        color("Gold") translate([3.5,esp_l-1.6,esp_pcb_t])
            cylinder(d=3.0,h=esp_ufl_h);
    }
}

module coax_preview() {
    // Reserved cable envelope: underneath rear-right, then up behind the PCB.
    cable_z = pcb_z-esp_ufl_h+antenna_cable_d/2;
    points = [[antenna_exit_x,esp_y+esp_l-1.6,cable_z],
              [antenna_exit_x,boards_back+rear_service_gap/2,cable_z],
              [antenna_exit_x,antenna_y,
               floor_t+antenna_floor_h+antenna_tie_h+antenna_height/2]];
    color("DimGray")
        for (i = [0:len(points)-2])
            hull() for (p = [points[i],points[i+1]])
                translate(p) sphere(d=antenna_cable_d);
}

module board_preview() {
    // Approximate envelopes, not detailed component CAD.
    xiao_preview();
    coax_preview();
    color("MediumPurple") translate([dac_x,dac_y,pcb_z])
        cube([dac_front,dac_depth,dac_pcb_t]);
    color("DimGray") translate([dac_x+dac_jack_start,
                                dac_y-dac_jack_protrude,pcb_z+dac_pcb_t])
        cube([dac_jack_w,dac_jack_protrude+5,dac_total_h-dac_pcb_t]);
    color("Orange",0.3) translate([antenna_x,antenna_y,
                                  floor_t+antenna_floor_h+antenna_tie_h])
        cube([antenna_length,antenna_depth,antenna_height]);
}

if (PART == "base" || PART == "both" || PART == "assembled" || PART == "print")
    color("SlateGray") base();
if (PART == "lid") color("SteelBlue") lid_for_print();
if (PART == "print") translate([box_w+8,0,0]) color("SteelBlue") lid_for_print();
if (PART == "both" || PART == "assembled")
    translate([0,0,base_h+(PART == "both" ? 15 : 0)]) color("SteelBlue",0.85) lid();
if ($preview && SHOW_BOARDS && (PART == "both" || PART == "assembled" || PART == "base"))
    %board_preview();

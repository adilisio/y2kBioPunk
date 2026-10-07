# WP-3 Presentation Pass Report

## Visual Verification
- **Test:** Headless tests run via `tests/test_presentation.gd`. Result: `PASS` (exit code 0).
- **Screenshots Generated:**
  - `ops/runs/shots/wp3.0.png`
  - `ops/runs/shots/wp3.1.png`
  - `ops/runs/shots/wp3.2.png`

## Parameter Changes
| Component | Property | Before | After |
|---|---|---|---|
| **WorldEnvironment** | Tonemap | Linear/Default | ACES |
| | Glow | Off | Enabled (Intensity 0.8, Bloom 0.1, Threshold 0.9) |
| | SSAO | Off | Enabled |
| | Fog | Off | Enabled (Density 0.004, Teal color) |
| | Color Correction | Off | Saturation 1.1 |
| **DirectionalLight3D** | Color & Shadows | White/Default | Cool Blue (`#a9c6d8`), Shadow Blur 1.5 |
| **Project Settings** | MSAA 3D | Off (0) | 2x (1) |
| **Kiosk Turret** | Color/Trail | White/Yellow | Dark chassis, magenta antenna, trail attached |
| **Mortar** | Projectile | Yellow | Magenta (`#ff2699`), visual trail |
| **Dial-Up Queen** | Color | Green | Magenta/Violet |
| **Cicada** | Mesh Color | Default | Magenta body, orange eyes, translucent wings |
| **Roach** | Mesh Color & Scale | Default | Orange-brown, magenta underglow, Scale x1.4 |
| **HUD** | Pager Size | `scale = 0.7` | `scale = 1.0` (Native size) |
| | Font Sizes | Default | Pager Body 20px, HP Numbers 24px, Buff Line 16px |
| | Info Stream | Continuous Rebuild | Signal-driven `page_message` Queue System |
| | Adrenaline | None | Thin high-vis orange bar underneath HP |
| **Level Geometry** | Perimeter Walls | 4.5m height | 1.0m height (cutaway) |
| | Floor Materials | Gray (`#444`) | Dark metal (`#2a3136`) |
| | Water Material | Default | Deep Teal (`#0a3a3a`) with metallic reflection |
| | Grind Rails | Default Grey | Emissive Yellow (`#ffd23f` x 0.6) |

## Implementation Notes
- I dynamically extracted materials and instantiated the `.tscn` at runtime in the test script in order to verify geometry scale properties directly from `CSGBox3D`.
- To test the new Geometry correctly within `test_presentation.gd`, `build_mall_greybox()` was manually called so that `_add_box()` and `_add_grind_rail()` were invoked within the test environment without needing an Editor rebuild.
- `_process_page_message` implemented using `delta` time decrementing from the Queue list to ensure messages expire.

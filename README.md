**Abstract**
A fully functional Flappy Bird clone built entirely in PIC16F877A Assembly, rendered on a Nokia 5110 (PCD8544) monochrome LCD, and simulated in SimulIDE. Written without an OS or C runtime every byte of RAM, every CPU cycle, and every pixel is managed by hand within the PIC's 368-byte RAM budget. 

**UPDATE 1**

# Flappy Bird +

A fully playable Flappy Bird clone built entirely in **PIC assembly language**, running on a **PIC16F877A** microcontroller and rendered on a **Nokia 5110 (PCD8544) 84×48 monochrome LCD**, with a single push-button as the only input. No OS, no C runtime, no framebuffer, every pixel is computed live, every frame, on an 8-bit core with 368 bytes of RAM.


## Features

- Custom **splash screen** with double-width title text and a blinking "PRESS START" prompt
- **Gravity + impulse physics** using integer Euler integration and two's-complement velocity
- **Single-button flap control** with proper edge-triggered debouncing
- **Two-pipe staggered scrolling system** with independently randomized gap positions (LFSR-based PRNG)
- **AABB collision detection** done entirely with 8-bit subtraction and STATUS flag checks
- **Live score overlay** rendered inline during the frame draw (+5 per pipe cleared)
- **Two-frame bird sprite animation** (normal / dead)
- **Persistent high score** stored in on-chip EEPROM, survives power cycles
- **Zero-framebuffer, single-pass rendering pipeline** — fits inside the PIC's 368-byte RAM budget

---

## Hardware Required


Microcontroller | Microchip PIC16F877A (40-pin DIP) | Runs all game logic |
Display | Nokia 5110 LCD (PCD8544 controller, 84×48 px) | Game graphics |
Push-button | Tactile momentary switch | Flap / jump input, wired to RB0 |
Resistors | 10 kΩ × 2 | Pull-up on MCLR, pull-down on button |
Crystal | HS-mode external crystal | Clock source (CONFIG FOSC=HS) |
Power supply | 5 V regulated | Powers PIC + LCD |

## Software Tools

- **MPLAB X IDE** — editing and project management
- **XC8 / MPASM Assembler** — assembles the `.asm` source
- **SimulIDE** — open-source circuit simulator with a PIC16F877A + PCD8544 model, used for all testing without physical hardware

## Circuit Wiring

The Nokia 5110 LCD talks over a **bit-banged SPI bus**:

<img width="702" height="485" alt="Screenshot 2026-07-30 at 11 00 15 PM" src="https://github.com/user-attachments/assets/1e950236-4683-49bf-a26f-dfe06fd5a8b8" />

## Getting Started

1. Install **MPLAB X IDE** and the **XC8/MPASM** toolchain from Microchip.
2. Create a new MPLAB X project targeting **PIC16F877A**.
3. Add `Final_Code_EC-304.asm` as the project's source file.
4. Build the project — this produces a `.hex` file.
5. Open **SimulIDE**, drop in a `PIC16F877A` and a `PCD8544` (Nokia 5110) component, wire them per the table above, and load the built `.hex` onto the PIC.
6. Run the simulation. On power-up you'll see the splash screen; press the button to start.

To flash onto real hardware instead of simulating, use a PICKit-compatible programmer with the same `.hex` file — the CONFIG bits (`FOSC=HS, WDTE=OFF, PWRTE=ON, LVP=OFF`) are already set at the top of the source.

## Working

**Memory layout.** All game state (bird position/velocity, score, pipe positions/gaps, high score, temp registers) lives in a small `gvars` PSECT using named registers rather than hardcoded addresses.

**Rendering.** `DRAW_FRAME` scans all 6 LCD pages × 84 columns. For every (page, column) cell it OR's together whatever layers overlap that pixel — ceiling/ground, pipe, bird sprite, score digits — into a single byte, then streams that byte out over bit-banged SPI. There is no in-memory framebuffer; each pixel is computed exactly once per frame.

**Physics.** Each frame, `bird_vel` increases by 1 (gravity) and is added to `bird_y`. A button press sets `bird_vel = 253` (i.e. −3 in two's complement), producing an upward flap. Ground/ceiling bounds end the round by setting `bird_dead`.

**Pipes.** Two pipes (`pipeA`, `pipeB`) scroll left continuously, staggered 45 px apart so one is always on screen. When a pipe scrolls fully off the left edge, it wraps to the right and gets a new randomized Y position from a lightweight LFSR-based PRNG (`RANDOM`).

**Collision.** `DO_COLLISION_CHECK` does axis-aligned bounding-box checks: horizontal overlap first, then vertical overlap against the pipe gap.

**Persistence.** High score is read from EEPROM at boot (with validation — invalid/uninitialized values are zeroed) and written back, with the mandatory unlock sequence and a write-timeout guard, whenever a run beats the stored score.

Full technical detail for each subsystem is in `FlappyBirdPlus_Report.pdf`, sections 3–8.

---

## Problems Faced and their Solutions

Building a real-time game entirely in PIC assembly, on 368 bytes of RAM, with no OS and no framebuffer, surfaced a long list of hardware and firmware problems. Here's what came up and how each was resolved.

### 1. RAM too small for a framebuffer
**Problem:** A naive Flappy Bird implementation would render into an off-screen buffer and blit it to the LCD. The Nokia 5110 is 84×48 px = 504 bits ≈ 63 bytes minimum for 1bpp, which sounds affordable — but once bird state, pipe state, score, temp registers, and stack usage were accounted for, a full buffer plus double-buffering headroom didn't comfortably fit inside the PIC16F877A's 368 bytes of general-purpose RAM alongside everything else.
**Solution:** I moved to a **single-pass, zero-framebuffer rendering model**. `DRAW_FRAME` computes each of the 504 output bytes on the fly by checking, for every (page, column) cell, whether the ground, a pipe, the bird, or a score digit occupies that pixel — then sends the byte straight to the LCD over SPI. Nothing is buffered; every pixel is computed exactly once per frame.

### 2. No font fit the display
**Problem:** The Nokia 5110 is only 48 px tall (6 pages × 8 px). A standard 5×7 pixel font was too tall for the gameplay area, and scaling an existing font down produced illegible glyphs.
**Solution:** I designed a **custom 3-column bitmap font** (3 bytes of pixel data + 1 spacing byte per character, 4 px wide total) stored in a `FONT_DATA` lookup table, compact enough for score digits and UI text. For the splash-screen title, instead of maintaining a second large-font table, I wrote each column byte twice (`DRAW_BIG_CHAR`) to get a legible double-width title "for free."

### 3. Button input was noisy / kept multi-firing
**Problem:** Two separate issues showed up on the same pin. First, PORTB pins are multiplexed with the ADC by default, so reading RB0 as a plain digital button initially returned analogue noise instead of a clean high/low level. Second, once digital reads worked, holding the button down caused the bird to flap every single frame instead of once per press.
**Solution:** For the ADC issue, `ADCON1` is explicitly set to `0x06` at startup to configure all PORTA/PORTB pins as digital I/O, disabling the ADC entirely. For the multi-fire issue, I added an edge detector (`btn_prev`) that only applies the upward-flap impulse on the released→pressed transition, then requires a release before it will fire again — implemented purely with register compares, no hardware timers needed.

### 4. Bird sprite tearing across LCD page boundaries
**Problem:** The LCD is addressed in 8-pixel-tall "pages," but the bird's Y position is a continuous pixel value that doesn't line up with page boundaries most of the time. A naive sprite blit would only ever draw the bird correctly when it happened to sit exactly on a page boundary, and would clip or misplace it everywhere else.
**Solution:** `CALC_BIRD_PIXELS` computes the bird's sub-page bit offset (`bird_y AND 0x07`) and shifts the sprite byte left or right by that amount, with separate handling (`BIRD_SAME_PAGE` / `BIRD_NEXT_PAGE`) for when the sprite straddles two pages — writing the correct partial byte into whichever page is currently being rendered.

### 5. Pseudo-random pipe heights without a hardware RNG
**Problem:** The PIC16F877A has no hardware random number generator, but pipe gap positions needed to feel unpredictable across runs, not just be a fixed repeating pattern.
**Solution:** I implemented a minimal **Linear Feedback Shift Register (LFSR)** (`RANDOM`), seeded at boot with `0x88`, that rotates and XORs an 8-bit state register on every call. It's not cryptographically random, but it's more than sufficient to make pipe placement feel varied during gameplay, and it costs almost no cycles.

### 6. EEPROM writes could hang the game
**Problem:** Writing to the PIC's on-chip EEPROM requires a strict unlock sequence (`0x55` then `0xAA` to `EECON2`) followed by polling a "write in progress" bit. If that polling loop has no exit condition and a write silently fails (e.g. simulator quirks, brown-out edge cases), the game would freeze indefinitely waiting for a write that never completes.
**Solution:** I added a **bounded timeout loop** (`EE_WAIT` / `EE_DONE`) around the EEPROM write-complete poll, using a decrementing counter instead of an unconditional wait — so a failed write times out and returns instead of hanging the game.

### 7. Garbage/uninitialized EEPROM on first boot
**Problem:** On a brand-new chip (or after erasing), EEPROM bytes can start at `0xFF` or other invalid values, which would show up as a nonsensical high score like "HIGH SCORE: 15" (digit ≥ 10 has no meaning in a tens/ones display).
**Solution:** At startup, after reading the stored high-score bytes, I added a **validation check** — if either digit is `≥ 10`, the stored value is treated as uninitialized and both bytes are zeroed before use.

### 8. Bank switching bugs (silently wrong registers)
**Problem:** The PIC16F877A splits its special-function registers across 4 memory banks (selected via `RP0`/`RP1` in `STATUS`). TRIS registers live in Bank 1; EEPROM control registers live in Banks 2/3. Forgetting to switch banks before touching a register — or forgetting to switch *back* afterward — causes writes to silently land on the wrong register with no error, which is one of the hardest classes of bug to spot in PIC assembly.
**Solution:** I used `BANKSEL` directives consistently before every bank-sensitive register access, and made it a habit to explicitly return to Bank 0 (`BANKSEL PORTA`) at the end of every EEPROM routine, so the rest of the code could always assume Bank 0 by default.

### 9. Frame rate was inconsistent / SPI transmission dominated timing
**Problem:** A software busy-wait delay alone wasn't a reliable way to pace the game, because the actual bottleneck turned out to be the **504-byte SPI transmission** to the LCD every frame (504 bytes × 8 bit-banged clock pulses each), which took far longer than the delay loop itself at a 4 MHz clock.
**Solution:** Rather than fighting this, I tuned `FRAME_DELAY`'s nested busy-wait (outer count 5, inner count 255) to a modest ~10–15 ms and accepted that the SPI transfer, not the delay loop, would be the real frame-rate limiter — landing at a playable ~15–30 fps that felt consistent because the SPI cost is constant every frame.

### 10. Indexed table lookups crossing the 256-instruction page boundary
**Problem:** Strings and font/sprite data are stored in program memory and accessed via the classic PIC16 trick of adding an index to `PCL` and jumping (`RETLW` table pattern). This works fine until the table's address, plus the index, crosses a 256-instruction page boundary — at which point `PCLATH` needs to be incremented too, or the jump silently lands in the wrong page and returns garbage data.
**Solution:** Every lookup routine (`GET_FONT`, `GET_BIRD_SPRITE`, the `STR_*` string tables) explicitly loads `PCLATH` with the table's high byte before the indexed jump, and checks the carry out of the low-byte addition to conditionally `INCF PCLATH, f` — handling the page-crossing case correctly instead of assuming the table always stays within one page.

### 11. Debugging low-level rendering was hard with real sprites
**Problem:** Debugging collision detection, pipe scrolling, and scoring logic was much harder when errors in the bird sprite or font rendering made it unclear whether a visual glitch was a physics bug or a rendering bug.
**Solution:** I deliberately built the game in two phases: first with the **bird and pipes as plain filled rectangles**, so I could verify gravity, collision, scrolling, and scoring logic were all correct against simple, easy-to-reason-about shapes — and only afterward swapped in the bitmap bird sprite and font glyphs, once the underlying game loop was already known-good.

---

## Possible Extensions

- Shrink the pipe gap as the score increases, for a rising difficulty curve
- Add sound feedback via a piezo buzzer on flap/collision events
- Support a second button or potentiometer for menu navigation
- Port the bit-banged SPI driver to the PIC's hardware MSSP peripheral for lower CPU overhead

## Credits

Developed by **Abeet Paul Singh Bali** and **Vivaan Goel** as the EC-304 Embedded Systems project at Delhi Technological University, under the supervision of **Mr. Vinay Kumar (Assistant Professor, Dept. of ECE)**.


## Update 2

For a demo video, refer to https://youtu.be/RdwyjQI84KU

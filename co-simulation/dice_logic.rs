//! Timing and face selection shared by the Wasm and Cortex-M controllers.

pub struct Dice {
    pub raw_pressed: bool,
    pub contact_edges: u32,
    pub rolls: u32,
    stable_pressed: bool,
    raw_since_ms: u32,
    last_roll_ms: u32,
    face: u8,
}

impl Dice {
    pub const fn new() -> Self {
        Self {
            raw_pressed: false,
            contact_edges: 0,
            rolls: 0,
            stable_pressed: false,
            raw_since_ms: 0,
            last_roll_ms: 0,
            face: 0,
        }
    }

    pub fn sample(&mut self, ms: u32, pressed: bool) -> u8 {
        if pressed != self.raw_pressed {
            self.raw_pressed = pressed;
            self.raw_since_ms = ms;
            self.contact_edges += 1;
        }
        if pressed != self.stable_pressed && ms.wrapping_sub(self.raw_since_ms) >= 10 {
            self.stable_pressed = pressed;
            if pressed {
                self.rolls += 1;
                self.last_roll_ms = ms;
                self.face = self.face % 6 + 1;
            }
        }
        if ms.wrapping_sub(self.last_roll_ms) < 250 {
            self.face
        } else {
            0
        }
    }
}

//! Test fixture oracle. Measurements never affect the controller's decisions.

const TICK_NS: i64 = 1_000_000;
const FIRST_ROLL_NS: i64 = 28_000_000;
const PRESS_PERIOD_NS: i64 = 100_000_000;
const FACE_COUNT: u32 = 6;
const BLANK_NS: i64 = 778_000_000;

// D1 is the low bit and D7 is the high bit. These masks come from the
// schematic's pip table, independently of the Modelica GPIO decoder.
const EXPECTED_PIPS: [u8; 7] = [0, 8, 65, 73, 99, 107, 119];

pub struct PlayMonitor {
    pub currents: [f64; 7],
    pub verified_faces: u8,
    pub sequence_errors: u32,
    pub pattern_errors: u32,
    pub blank_time: i64,
    previous_command: u8,
}

impl PlayMonitor {
    pub const fn new() -> Self {
        Self {
            currents: [0.0; 7],
            verified_faces: 0,
            sequence_errors: 0,
            pattern_errors: 0,
            blank_time: 0,
            previous_command: 0,
        }
    }

    pub fn sample(&mut self, time: i64, rolls: u32, command: u8) {
        if rolls != expected_rolls(time) || command != expected_face(time) {
            self.sequence_errors += 1;
        }
        if self.previous_command != 0 && command == 0 {
            self.blank_time = time;
        }
        self.previous_command = command;

        // Run42 observes the plant before applying the new guest command.
        let observed_face = expected_face(time - TICK_NS);
        let mask = EXPECTED_PIPS[usize::from(observed_face)];
        let valid_pattern = self.currents.iter().enumerate().all(|(pip, current)| {
            if mask & (1 << pip) != 0 {
                (0.002..=0.005).contains(current)
            } else {
                (0.0..0.00001).contains(current)
            }
        });
        if !valid_pattern {
            self.pattern_errors += 1;
        } else if observed_face != 0 {
            self.verified_faces |= 1 << (observed_face - 1);
        }
    }
}

fn expected_rolls(time: i64) -> u32 {
    if time < FIRST_ROLL_NS {
        return 0;
    }
    ((time - FIRST_ROLL_NS) / PRESS_PERIOD_NS + 1).min(i64::from(FACE_COUNT)) as u32
}

fn expected_face(time: i64) -> u8 {
    if time >= BLANK_NS {
        return 0;
    }
    expected_rolls(time) as u8
}

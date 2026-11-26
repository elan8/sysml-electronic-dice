//! Device-independent controller for the dice co-simulation guest.
#![no_std]

mod play_monitor;

use play_monitor::PlayMonitor;

const SAMPLE_PERIOD_NS: i64 = 1_000_000;
const DEBOUNCE_NS: i64 = 10_000_000;
const DISPLAY_TIMEOUT_NS: i64 = 250_000_000;

struct Controller {
    clock: i64,
    next_sample: i64,
    button_voltage: f64,
    rail_voltage: f64,
    raw_pressed: bool,
    stable_pressed: bool,
    raw_since: i64,
    contact_edges: u32,
    accepted_rolls: u32,
    last_roll_time: i64,
    face: u8,
    face_command: u8,
    monitor: PlayMonitor,
}

impl Controller {
    const fn new() -> Self {
        Self {
            clock: 0,
            next_sample: SAMPLE_PERIOD_NS,
            button_voltage: 0.0,
            rail_voltage: 0.0,
            raw_pressed: false,
            stable_pressed: false,
            raw_since: 0,
            contact_edges: 0,
            accepted_rolls: 0,
            last_roll_time: 0,
            face: 0,
            face_command: 0,
            monitor: PlayMonitor::new(),
        }
    }

    fn sample_button(&mut self) {
        // Retain the preceding logic level through the undefined GPIO band.
        let pressed = if self.button_voltage <= 0.3 * self.rail_voltage {
            true
        } else if self.button_voltage >= 0.7 * self.rail_voltage {
            false
        } else {
            self.raw_pressed
        };

        if pressed != self.raw_pressed {
            self.raw_pressed = pressed;
            self.raw_since = self.clock;
            self.contact_edges += 1;
        }

        if self.raw_pressed != self.stable_pressed && self.clock - self.raw_since >= DEBOUNCE_NS {
            self.stable_pressed = self.raw_pressed;
            if self.stable_pressed {
                self.accepted_rolls += 1;
                self.last_roll_time = self.clock;
                self.face = self.face % 6 + 1;
            }
        }

        self.face_command = if self.clock - self.last_roll_time < DISPLAY_TIMEOUT_NS {
            self.face
        } else {
            0
        };
    }
}

static mut STATE: Controller = Controller::new();

fn with_state<T>(operation: impl FnOnce(&mut Controller) -> T) -> T {
    // Run42 calls this guest serially. No operation re-enters the ABI.
    unsafe { operation(&mut *core::ptr::addr_of_mut!(STATE)) }
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    core::arch::wasm32::unreachable()
}

#[no_mangle]
pub extern "C" fn api() -> i32 {
    2
}

#[no_mangle]
pub extern "C" fn initialize() -> i32 {
    with_state(|state| *state = Controller::new());
    0
}

#[no_mangle]
pub extern "C" fn clock() -> i64 {
    with_state(|state| state.clock)
}

#[no_mangle]
pub extern "C" fn deadline() -> i64 {
    with_state(|state| state.next_sample)
}

#[no_mangle]
pub extern "C" fn provide(index: i32, value: f64) -> i32 {
    with_state(|state| {
        match index {
            0 => state.button_voltage = value,
            1 => state.rail_voltage = value,
            2..=8 => state.monitor.currents[(index - 2) as usize] = value,
            _ => return 1,
        }
        0
    })
}

#[no_mangle]
pub extern "C" fn advance(target: i64) -> i32 {
    with_state(|state| {
        if target < state.clock || target > state.next_sample {
            return 1;
        }
        state.clock = target;
        if target == state.next_sample {
            if state.rail_voltage <= 0.0 {
                return 1;
            }
            state.sample_button();
            state
                .monitor
                .sample(state.clock, state.accepted_rolls, state.face_command);
            state.next_sample += SAMPLE_PERIOD_NS;
        }
        0
    })
}

#[no_mangle]
pub extern "C" fn receive(_: i32) -> i32 {
    1
}

#[no_mangle]
pub extern "C" fn sample(index: i32) -> f64 {
    with_state(|state| match index {
        0 => f64::from(state.face_command),
        1 => f64::from(state.accepted_rolls),
        2 => f64::from(state.contact_edges),
        3 => state.monitor.blank_time as f64 / 1e9,
        4 => f64::from(state.monitor.sequence_errors),
        5 => f64::from(state.monitor.pattern_errors),
        6 => f64::from(state.monitor.verified_faces.count_ones()),
        _ => f64::NAN,
    })
}

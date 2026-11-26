//! Device-independent controller for the dice co-simulation guest.
#![no_std]

mod dice_logic;
mod play_monitor;

use play_monitor::PlayMonitor;

const SAMPLE_PERIOD_NS: i64 = 1_000_000;

struct Controller {
    clock: i64,
    next_sample: i64,
    button_voltage: f64,
    rail_voltage: f64,
    dice: dice_logic::Dice,
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
            dice: dice_logic::Dice::new(),
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
            self.dice.raw_pressed
        };
        self.face_command = self
            .dice
            .sample((self.clock / SAMPLE_PERIOD_NS) as u32, pressed);
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
                .sample(state.clock, state.dice.rolls, state.face_command);
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
        1 => f64::from(state.dice.rolls),
        2 => f64::from(state.dice.contact_edges),
        3 => state.monitor.blank_time as f64 / 1e9,
        4 => f64::from(state.monitor.sequence_errors),
        5 => f64::from(state.monitor.pattern_errors),
        6 => f64::from(state.monitor.verified_faces.count_ones()),
        _ => f64::NAN,
    })
}

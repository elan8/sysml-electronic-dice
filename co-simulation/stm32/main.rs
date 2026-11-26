//! Bare-metal STM32F407 firmware. SysTick samples the actual GPIO input.
#![no_std]
#![no_main]

#[path = "../dice_logic.rs"]
mod dice_logic;

use core::ptr::{addr_of_mut, read_volatile, write_volatile};
use dice_logic::Dice;

const RCC_AHB1ENR: usize = 0x4002_3830;
const GPIOA: usize = 0x4002_0000;
const GPIOD: usize = 0x4002_0c00;
const SYSTICK: usize = 0xe000_e010;
const LED_PINS: u32 = 0x7f;
const PIPS: [u32; 7] = [0, 8, 65, 73, 99, 107, 119];

static mut DICE: Dice = Dice::new();
static mut MS: u32 = 0;
static mut SHOWN: u8 = 0;

#[no_mangle]
static mut DICE_ROLLS: u32 = 0;
#[no_mangle]
static mut DICE_EDGES: u32 = 0;
#[no_mangle]
static mut DICE_BLANK_MS: u32 = 0;
#[no_mangle]
static mut DICE_LAST_ROLL_MS: u32 = 0;

fn read(address: usize) -> u32 {
    unsafe { read_volatile(address as *const u32) }
}

fn write(address: usize, value: u32) {
    unsafe { write_volatile(address as *mut u32, value) }
}

#[no_mangle]
extern "C" fn Reset() -> ! {
    unsafe {
        addr_of_mut!(DICE).write(Dice::new());
        addr_of_mut!(MS).write(0);
        addr_of_mut!(SHOWN).write(0);
        write_volatile(addr_of_mut!(DICE_ROLLS), 0);
        write_volatile(addr_of_mut!(DICE_EDGES), 0);
        write_volatile(addr_of_mut!(DICE_BLANK_MS), 0);
        write_volatile(addr_of_mut!(DICE_LAST_ROLL_MS), 0);
    }
    write(RCC_AHB1ENR, read(RCC_AHB1ENR) | 9);
    write(GPIOA, read(GPIOA) & !3);
    write(GPIOD, (read(GPIOD) & !0x3fff) | 0x1555);
    write(GPIOD + 0x18, LED_PINS << 16);
    write(SYSTICK + 4, 167_999); // 1 ms with the bench's 168 MHz core clock.
    write(SYSTICK + 8, 0);
    write(SYSTICK, 7); // Processor clock, interrupt enabled.
    loop {
        unsafe { core::arch::asm!("wfi", options(nomem, nostack)) }
    }
}

#[no_mangle]
extern "C" fn SysTick() {
    // The reset code initializes state before enabling this non-reentrant IRQ.
    unsafe {
        MS = MS.wrapping_add(1);
        let dice = &mut *addr_of_mut!(DICE);
        let previous_rolls = dice.rolls;
        let face = dice.sample(MS, read(GPIOA + 0x10) & 1 == 0);
        if dice.rolls != previous_rolls {
            write_volatile(addr_of_mut!(DICE_LAST_ROLL_MS), MS);
        }
        write_volatile(addr_of_mut!(DICE_ROLLS), dice.rolls);
        write_volatile(addr_of_mut!(DICE_EDGES), dice.contact_edges);
        if face != SHOWN {
            if face == 0 {
                write_volatile(addr_of_mut!(DICE_BLANK_MS), MS);
            }
            let mask = PIPS[usize::from(face)];
            write(GPIOD + 0x18, mask | ((LED_PINS & !mask) << 16));
            SHOWN = face;
        }
    }
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo<'_>) -> ! {
    loop {}
}

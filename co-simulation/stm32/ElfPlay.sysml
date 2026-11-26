package DiceElf {
    private import ISQ::ElectricCurrentValue;
    private import ScalarValues::Integer;
    private import SI::*;
    private import VerificationCases::*;

    part def Firmware {
        state running {
            attribute rolls : Integer;
            attribute contactEdges : Integer;
            attribute blankMs : Integer;
            attribute lastRollMs : Integer;
            attribute topLeft : Integer;
            attribute topLeftCurrent : ElectricCurrentValue;
            attribute topRight : Integer;
            attribute topRightCurrent : ElectricCurrentValue;
            attribute middleLeft : Integer;
            attribute middleLeftCurrent : ElectricCurrentValue;
            attribute center : Integer;
            attribute centerCurrent : ElectricCurrentValue;
            attribute middleRight : Integer;
            attribute middleRightCurrent : ElectricCurrentValue;
            attribute bottomLeft : Integer;
            attribute bottomLeftCurrent : ElectricCurrentValue;
            attribute bottomRight : Integer;
            attribute bottomRightCurrent : ElectricCurrentValue;
            entry;
            then ready;
            state ready;
        }
    }

    verification <'DICE-VER-007'> playSixRolls {
        @VerificationMethod { kind = VerificationMethodKind::test; }
        subject firmware : Firmware;
        objective {
            verify ElectronicDice::oneRollPerPress;
            verify ElectronicDice::displayTimeout;
            verify DiceCircuit::pipDrive;
        }
        action play { accept after 0.800 [s]; }
        assert constraint sixAccepted { firmware.running.rolls == 6 }
        assert constraint sixBouncingPresses { firmware.running.contactEdges == 24 }
        assert constraint blankedAfterSixth {
            firmware.running.blankMs - firmware.running.lastRollMs == 250
        }
        assert constraint topLeftBlank { firmware.running.topLeft == 0 and firmware.running.topLeftCurrent < 0.00001 [A] }
        assert constraint topRightBlank { firmware.running.topRight == 0 and firmware.running.topRightCurrent < 0.00001 [A] }
        assert constraint middleLeftBlank { firmware.running.middleLeft == 0 and firmware.running.middleLeftCurrent < 0.00001 [A] }
        assert constraint centerBlank { firmware.running.center == 0 and firmware.running.centerCurrent < 0.00001 [A] }
        assert constraint middleRightBlank { firmware.running.middleRight == 0 and firmware.running.middleRightCurrent < 0.00001 [A] }
        assert constraint bottomLeftBlank { firmware.running.bottomLeft == 0 and firmware.running.bottomLeftCurrent < 0.00001 [A] }
        assert constraint bottomRightBlank { firmware.running.bottomRight == 0 and firmware.running.bottomRightCurrent < 0.00001 [A] }
    }
}

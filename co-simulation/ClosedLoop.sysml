package DiceClosedLoop {
    private import ISQ::*;
    private import ScalarValues::*;
    private import SI::*;
    private import VerificationCases::*;

    part def SampledController {
        doc /* The Run42 driver maps the Wasm guest's outputs and Modelica
             * observations to the attributes of this state. */
        state controller {
            attribute faceCommand : Integer;
            attribute acceptedRolls : Integer;
            attribute contactEdges : Integer;
            attribute blankTime : TimeValue;
            attribute sequenceErrors : Integer;
            attribute patternErrors : Integer;
            attribute verifiedFaces : Integer;
            attribute buttonVoltage : ElectricPotentialValue;
            attribute railVoltage : ElectricPotentialValue;
            attribute topLeftCurrent : ElectricCurrentValue;
            attribute topRightCurrent : ElectricCurrentValue;
            attribute middleLeftCurrent : ElectricCurrentValue;
            attribute centerCurrent : ElectricCurrentValue;
            attribute middleRightCurrent : ElectricCurrentValue;
            attribute bottomLeftCurrent : ElectricCurrentValue;
            attribute bottomRightCurrent : ElectricCurrentValue;
            entry;
            then running;
            state running;
        }
    }

    verification <'DICE-VER-006'> playSixRolls {
        @VerificationMethod { kind = VerificationMethodKind::test; }

        doc /* Six presses 100 ms apart go through the physical pull-up and
             * GPIO input. Each starts with a 6 ms closure and a 6 ms opening
             * before the 40 ms stable closure. At each tick the test
             * compares the roll count, face command and measured LED currents
             * with the fixture schedule and schematic pip map. */
        subject firmware : SampledController;
        objective {
            verify ElectronicDice::oneRollPerPress;
            verify DiceCircuit::pipDrive;
            verify DiceCircuit::buttonLevels;
            verify ElectronicDice::displayTimeout;
        }
        action observe { accept after 0.800 [s]; }

        assert constraint receivedAllRawEdges { firmware.controller.contactEdges == 24 }
        assert constraint rolledOncePerPress { firmware.controller.acceptedRolls == 6 }
        assert constraint rollAndDisplayTiming { firmware.controller.sequenceErrors == 0 }
        assert constraint allFacesMeasured { firmware.controller.verifiedFaces == 6 }
        assert constraint pipCurrentsMatch { firmware.controller.patternErrors == 0 }
        assert constraint blankedAfterLastRoll {
            firmware.controller.blankTime >= 0.7775 [s] and firmware.controller.blankTime <= 0.7785 [s]
        }
        assert constraint displayBlank { firmware.controller.faceCommand == 0 }
        assert constraint releasedInputHigh {
            firmware.controller.buttonVoltage > 0.7 * firmware.controller.railVoltage
        }
        assert constraint topLeftOff { firmware.controller.topLeftCurrent < 0.00001 [A] }
        assert constraint topRightOff { firmware.controller.topRightCurrent < 0.00001 [A] }
        assert constraint middleLeftOff { firmware.controller.middleLeftCurrent < 0.00001 [A] }
        assert constraint centerOff { firmware.controller.centerCurrent < 0.00001 [A] }
        assert constraint middleRightOff { firmware.controller.middleRightCurrent < 0.00001 [A] }
        assert constraint bottomLeftOff { firmware.controller.bottomLeftCurrent < 0.00001 [A] }
        assert constraint bottomRightOff { firmware.controller.bottomRightCurrent < 0.00001 [A] }
    }
}

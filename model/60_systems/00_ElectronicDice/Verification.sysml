package DiceVerification {
    private import DiceLibrary::*;
    private import SI::*;
    private import VerificationCases::*;

    verification <'DICE-VER-001'> bouncingPress {
        @VerificationMethod { kind = VerificationMethodKind::test; }

        doc /* The controller selected by DiceIntegration receives one physical
             * press with scripted contact bounce. The assertion reads the roll
             * count directly so two identical displayed faces cannot hide a
             * duplicate roll. The case exercises the controller in isolation. */
        subject controller : RollController::RollControllerArchitecture;
        objective { verify ElectronicDice::oneRollPerPress; }

        action stimulus {
            send new ButtonClosed() to controller;
            then accept after 0.006 [s];
            then send new ButtonOpened() to controller;
            then accept after 0.006 [s];
            then send new ButtonClosed() to controller;
            then accept after 0.040 [s];
        }
        assert constraint singleRoll { controller.firmware.acceptedRolls == 1 }
        assert constraint firstFace { controller.firmware.face == 1 }
    }

    verification <'DICE-VER-002'> releaseAndRollAgain {
        @VerificationMethod { kind = VerificationMethodKind::test; }

        doc /* A short open pulse during the first hold must not re-arm the
             * button. A sustained release must re-arm it for the second press. */
        subject controller : RollController::RollControllerArchitecture;
        objective { verify ElectronicDice::oneRollPerPress; }

        action stimulus {
            send new ButtonClosed() to controller;
            then accept after 0.040 [s];
            then send new ButtonOpened() to controller;
            then accept after 0.006 [s];
            then send new ButtonClosed() to controller;
            then accept after 0.040 [s];
            then send new ButtonOpened() to controller;
            then accept after 0.040 [s];
            then send new ButtonClosed() to controller;
            then accept after 0.040 [s];
        }
        assert constraint twoRolls { controller.firmware.acceptedRolls == 2 }
        assert constraint secondFace { controller.firmware.face == 2 }
    }
}

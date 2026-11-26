package DiceClosedLoopDocuments {
    private import Elan8::Documents::*;

    view verificationReport {
        @Document {
            title = "Electronic Dice Closed-Loop Verification";
            number = "DICE-VR-002";
            revision = "B";
            status = "Demo";
            template = "verification-report";
        }
        view setup {
            @Section { title = "Button, firmware and LED circuit"; }
            doc /* The Modelica fixture repeats a bouncing press six times.
                 * Run42 gives the Wasm controller the measured button and
                 * supply voltages every millisecond. The controller applies
                 * a 10 ms debounce, drives a deterministic sequence from face
                 * one to six, and restarts the 250 ms display timer at each
                 * roll. The test checks the roll count and face sequence at
                 * every sample, verifies the seven branch currents against
                 * the schematic for each face, and checks the display after
                 * the timeout. */
        }
        view result {
            @Section { title = "Verification result"; }
            @Table {
                columns = "Case = name, Verifies = verifies, Verdict = verdict, Time = verdict-time";
                kind = "verification case";
                verdicts = "closed-loop-verdicts.json";
            }
            expose DiceClosedLoop::playSixRolls;
        }
    }
}

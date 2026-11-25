package DiceDocuments {
    private import Elan8::Documents::*;

    view verificationReport {
        @Document {
            title = "Electronic Dice Verification Report";
            number = "DICE-VR-001";
            revision = "B";
            status = "Demo";
            template = "verification-report";
        }
        view comparison {
            @Section { title = "Debounce comparison"; }
            doc /* The same scripted cases run first at 3 ms, then at the
                 * selected 10 ms setting. The stimulus and assertions stay fixed. */
            @Table {
                columns = "Case = name, Verdict = verdict, Detail = verdict-detail";
                kind = "verification case";
                verdicts = "fast-controller-verdicts.json";
                caption = "3 ms comparison";
            }
            expose DiceVerification::bouncingPress;
            expose DiceVerification::releaseAndRollAgain;
        }
        view requirements {
            @Section { title = "Requirement and verification cases"; }
            @Table {
                columns = "ID = id, Text = text, Verified by = verified-by";
                kind = "requirement";
            }
            expose ElectronicDice::oneRollPerPress;
        }
        view results {
            @Section { title = "Selected 10 ms results"; }
            @Table {
                columns = "Case = name, Verdict = verdict, Time = verdict-time, Final state = verdict-state";
                kind = "verification case";
                verdicts = "controller-verdicts.json";
            }
            expose DiceVerification::bouncingPress;
            expose DiceVerification::releaseAndRollAgain;
        }
        view electricalRequirements {
            @Section { title = "Electrical requirements"; }
            @Table {
                columns = "ID = id, Text = text, Verified by = verified-by";
                kind = "requirement";
            }
            expose DiceCircuit::railAndCurrent;
            expose DiceCircuit::pipDrive;
            expose DiceCircuit::buttonLevels;
        }
        view electricalResults {
            @Section { title = "Battery-powered circuit results"; }
            doc /* A nominal 4.5 V source represents three series AAA alkaline
                 * cells. The Modelica circuit includes the supply, decoupling,
                 * button and seven LED branches. The electrical test fixture
                 * commands the LED outputs independently of the button. */
            @Table {
                columns = "Case = name, Verifies = verifies, Verdict = verdict, Time = verdict-time";
                kind = "verification case";
                verdicts = "electrical-verdicts.json";
            }
            expose DiceCircuit::blankReleased;
            expose DiceCircuit::sixPressed;
            expose DiceCircuit::oneReleased;
        }
        view architecture : StandardViewDefinitions::InterconnectionView {
            @Section { title = "Product architecture"; }
            doc /* The button supplies raw contact edges to the roll controller.
                 * The controller qualifies those edges and sends the selected
                 * face to the seven-LED display. The battery supplies both.
                 * The cases exercise the controller and observe its roll count
                 * and face command. They stop at the controller interface. */
            @Diagram { depth = 0; }
            expose ElectronicDice::DiceArchitecture::rollButton;
            expose ElectronicDice::DiceArchitecture::controller;
            expose ElectronicDice::DiceArchitecture::pipDisplay;
            expose ElectronicDice::DiceArchitecture::battery;
        }
    }
}

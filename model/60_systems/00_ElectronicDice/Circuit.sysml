package DiceCircuit {
    private import Elan8::PhysicalModeling::ModelicaModel;
    private import ISQ::*;
    private import SI::*;
    private import VerificationCases::*;

    port def Pin;

    part def AlkalinePack {
        @ModelicaModel { className = "ElectronicDiceBoard.AlkalinePack"; resourceUri = "ElectronicDiceBoard.mo"; }
        attribute voltage : ElectricPotentialValue;
        attribute internalResistance : ResistanceValue;
        attribute current : ElectricCurrentValue;
        port positive : Pin;
        port negative : Pin;
    }

    part def Resistor {
        @ModelicaModel { className = "ElectronicDiceBoard.Resistor"; resourceUri = "ElectronicDiceBoard.mo"; }
        attribute resistance : ResistanceValue;
        port positive : Pin;
        port negative : Pin;
    }

    part def DecouplingCapacitor {
        @ModelicaModel { className = "ElectronicDiceBoard.DecouplingCapacitor"; resourceUri = "ElectronicDiceBoard.mo"; }
        attribute capacitance : CapacitanceValue;
        attribute initialVoltage : ElectricPotentialValue;
        port positive : Pin;
        port negative : Pin;
    }

    part def PushButtonContact {
        @ModelicaModel { className = "ElectronicDiceBoard.PushButtonContact"; resourceUri = "ElectronicDiceBoard.mo"; }
        port positive : Pin;
        port negative : Pin;
    }

    part def LedBranch {
        @ModelicaModel { className = "ElectronicDiceBoard.LedBranch"; resourceUri = "ElectronicDiceBoard.mo"; }
        attribute resistance : ResistanceValue = 680 [ohm];
        attribute forwardVoltage : ElectricPotentialValue = 1.9 [V];
        attribute current : ElectricCurrentValue;
        port positive : Pin;
        port negative : Pin;
    }

    part def AtTiny1616Io {
        doc /* Electrical equivalent of the supply, input and seven GPIO
             * outputs. The test fixture commands blank, six, then one. */
        @ModelicaModel { className = "ElectronicDiceBoard.AtTiny1616Io"; resourceUri = "ElectronicDiceBoard.mo"; }
        attribute railVoltage : ElectricPotentialValue;
        attribute buttonVoltage : ElectricPotentialValue;
        port vdd : Pin;
        port gnd : Pin;
        port button : Pin;
        port topLeft : Pin;
        port topRight : Pin;
        port middleLeft : Pin;
        port center : Pin;
        port middleRight : Pin;
        port bottomLeft : Pin;
        port bottomRight : Pin;
    }

    part def Ground {
        @ModelicaModel { className = "ElectronicDiceBoard.Ground"; resourceUri = "ElectronicDiceBoard.mo"; }
        port pin : Pin;
    }

    part def Board {
        doc /* Electrical realization of the selected die. Seven branches
             * represent R1–R7 and D1–D7. The power switch is held on in these
             * operating-point tests and modeled as its contact resistance. */
        part battery : AlkalinePack {
            attribute :>> voltage = 4.5 [V];
            attribute :>> internalResistance = 0.9 [ohm];
        }
        part powerSwitch : Resistor { attribute :>> resistance = 0.1 [ohm]; }
        part mcu : AtTiny1616Io;
        part ground : Ground;
        part decoupling : DecouplingCapacitor {
            attribute :>> capacitance = 0.1 [micro * F];
            attribute :>> initialVoltage = 4.5 [V];
        }
        part bulk : DecouplingCapacitor {
            attribute :>> capacitance = 10 [micro * F];
            attribute :>> initialVoltage = 4.5 [V];
        }
        part rollSwitch : PushButtonContact;
        part pullup : Resistor { attribute :>> resistance = 10 [kilo * ohm]; }
        part topLeft : LedBranch;
        part topRight : LedBranch;
        part middleLeft : LedBranch;
        part center : LedBranch;
        part middleRight : LedBranch;
        part bottomLeft : LedBranch;
        part bottomRight : LedBranch;

        connect battery.positive to powerSwitch.positive;
        connect powerSwitch.negative to mcu.vdd;
        connect mcu.vdd to decoupling.positive;
        connect mcu.vdd to bulk.positive;
        connect mcu.vdd to pullup.positive;
        connect pullup.negative to mcu.button;
        connect mcu.button to rollSwitch.positive;

        connect ground.pin to battery.negative;
        connect ground.pin to mcu.gnd;
        connect ground.pin to bulk.negative;
        connect ground.pin to decoupling.negative;
        connect ground.pin to rollSwitch.negative;

        connect mcu.topLeft to topLeft.positive;
        connect topLeft.negative to ground.pin;
        connect mcu.topRight to topRight.positive;
        connect topRight.negative to ground.pin;
        connect mcu.middleLeft to middleLeft.positive;
        connect middleLeft.negative to ground.pin;
        connect mcu.center to center.positive;
        connect center.negative to ground.pin;
        connect mcu.middleRight to middleRight.positive;
        connect middleRight.negative to ground.pin;
        connect mcu.bottomLeft to bottomLeft.positive;
        connect bottomLeft.negative to ground.pin;
        connect mcu.bottomRight to bottomRight.positive;
        connect bottomRight.negative to ground.pin;

        attribute railVoltage : ElectricPotentialValue;
        attribute buttonVoltage : ElectricPotentialValue;
        attribute batteryCurrent : ElectricCurrentValue;
        bind railVoltage = mcu.railVoltage;
        bind buttonVoltage = mcu.buttonVoltage;
        bind batteryCurrent = battery.current;
        attribute topLeftCurrent : ElectricCurrentValue;
        bind topLeftCurrent = topLeft.current;
        attribute topRightCurrent : ElectricCurrentValue;
        bind topRightCurrent = topRight.current;
        attribute middleLeftCurrent : ElectricCurrentValue;
        bind middleLeftCurrent = middleLeft.current;
        attribute centerCurrent : ElectricCurrentValue;
        bind centerCurrent = center.current;
        attribute middleRightCurrent : ElectricCurrentValue;
        bind middleRightCurrent = middleRight.current;
        attribute bottomLeftCurrent : ElectricCurrentValue;
        bind bottomLeftCurrent = bottomLeft.current;
        attribute bottomRightCurrent : ElectricCurrentValue;
        bind bottomRightCurrent = bottomRight.current;
    }

    requirement <'DICE-ELEC-001'> railAndCurrent {
        doc /* With a nominal 4.5 V pack and the display showing six, the MCU
             * rail shall be 2.7–5.5 V and pack current shall be below 30 mA. */
    }
    requirement <'DICE-ELEC-002'> pipDrive {
        doc /* In the nominal electrical fixture, each commanded pip shall
             * draw 2–5 mA. Each uncommanded pip shall draw less than 0.01 mA. */
    }
    requirement <'DICE-ELEC-003'> buttonLevels {
        doc /* With the nominal pack, the released input shall be above 0.7 VDD
             * and the pressed input below 0.3 VDD. */
    }

    verification <'DICE-VER-003'> blankReleased {
        @VerificationMethod { kind = VerificationMethodKind::test; }
        subject board : Board;
        objective { verify pipDrive; verify buttonLevels; }
        action observe { accept after 0.0005 [s]; }
        assert constraint buttonHigh { board.buttonVoltage > 0.7 * board.railVoltage }
        assert constraint topLeftOff { board.topLeftCurrent < 0.00001 [A] }
        assert constraint topRightOff { board.topRightCurrent < 0.00001 [A] }
        assert constraint middleLeftOff { board.middleLeftCurrent < 0.00001 [A] }
        assert constraint centerOff { board.centerCurrent < 0.00001 [A] }
        assert constraint middleRightOff { board.middleRightCurrent < 0.00001 [A] }
        assert constraint bottomLeftOff { board.bottomLeftCurrent < 0.00001 [A] }
        assert constraint bottomRightOff { board.bottomRightCurrent < 0.00001 [A] }
    }

    verification <'DICE-VER-004'> sixPressed {
        @VerificationMethod { kind = VerificationMethodKind::test; }
        subject board : Board;
        objective { verify railAndCurrent; verify pipDrive; verify buttonLevels; }
        action observe { accept after 0.005 [s]; }
        assert constraint railInRange { board.railVoltage >= 2.7 [V] and board.railVoltage <= 5.5 [V] }
        assert constraint currentUnderBudget { board.batteryCurrent > 0 [A] and board.batteryCurrent < 0.03 [A] }
        assert constraint buttonLow { board.buttonVoltage < 0.3 * board.railVoltage }
        assert constraint topLeftOn { board.topLeftCurrent >= 0.002 [A] and board.topLeftCurrent <= 0.005 [A] }
        assert constraint topRightOn { board.topRightCurrent >= 0.002 [A] and board.topRightCurrent <= 0.005 [A] }
        assert constraint middleLeftOn { board.middleLeftCurrent >= 0.002 [A] and board.middleLeftCurrent <= 0.005 [A] }
        assert constraint centerOff { board.centerCurrent < 0.00001 [A] }
        assert constraint middleRightOn { board.middleRightCurrent >= 0.002 [A] and board.middleRightCurrent <= 0.005 [A] }
        assert constraint bottomLeftOn { board.bottomLeftCurrent >= 0.002 [A] and board.bottomLeftCurrent <= 0.005 [A] }
        assert constraint bottomRightOn { board.bottomRightCurrent >= 0.002 [A] and board.bottomRightCurrent <= 0.005 [A] }
    }

    verification <'DICE-VER-005'> oneReleased {
        @VerificationMethod { kind = VerificationMethodKind::test; }
        subject board : Board;
        objective { verify pipDrive; verify buttonLevels; }
        action observe { accept after 0.01 [s]; }
        assert constraint buttonHigh { board.buttonVoltage > 0.7 * board.railVoltage }
        assert constraint topLeftOff { board.topLeftCurrent < 0.00001 [A] }
        assert constraint topRightOff { board.topRightCurrent < 0.00001 [A] }
        assert constraint middleLeftOff { board.middleLeftCurrent < 0.00001 [A] }
        assert constraint centerOn { board.centerCurrent >= 0.002 [A] and board.centerCurrent <= 0.005 [A] }
        assert constraint middleRightOff { board.middleRightCurrent < 0.00001 [A] }
        assert constraint bottomLeftOff { board.bottomLeftCurrent < 0.00001 [A] }
        assert constraint bottomRightOff { board.bottomRightCurrent < 0.00001 [A] }
    }
}

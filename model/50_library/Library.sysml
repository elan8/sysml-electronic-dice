package DiceLibrary {
    private import ScalarValues::*;

    item def ButtonClosed;
    item def ButtonOpened;

    port def ActuationPort {
        out attribute pressed : Boolean;
    }
    port def ContactPort {
        out attribute closed : Boolean;
    }
    port def FacePort {
        out attribute face : Integer;
    }
    port def PipPort {
        out attribute litPips : Integer;
    }
    port def SupplyPort {
        out attribute voltage : ISQ::ElectricPotentialValue;
    }

    part def PushButton {
        port actuator : ~ActuationPort;
        port contact : ContactPort;
    }
    part def PipDisplay {
        port command : ~FacePort;
        port pips : PipPort;
        port supply : ~SupplyPort;
        attribute ledCount : Integer = 7;
    }
    part def Battery {
        port supply : SupplyPort;
    }
    part def ThreeAaaAlkalinePack :> Battery {
        doc /* Three replaceable 1.5 V AAA alkaline cells wired in series. */
        attribute nominalVoltage : ISQ::ElectricPotentialValue = 4.5 [SI::V];
    }
}

package RollController {
    private import DiceLibrary::*;
    private import Elan8::SystemsEngineering::*;
    private import ISQ::TimeValue;
    private import ScalarValues::*;
    private import SI::*;

    part def RollControllerSpecification :> SystemSpecification {
        port contact : ~ContactPort;
        port command : FacePort;
        port supply : ~SupplyPort;
    }

    part def Microcontroller;

    part def RollControllerArchitecture
        :> RollControllerSpecification, SystemArchitecture {
        part microcontroller : Microcontroller;

        state firmware {
            doc /* The logical switch harness sends one event per raw edge. A
                 * press or release qualifies after its level stays stable for
                 * the debounce interval. The sequence 1 through 6 is a
                 * deterministic stand-in for the product's roll generator. */
            attribute debounce : TimeValue = 0.010 [s];
            attribute acceptedRolls : Integer;
            attribute face : Integer;

            entry;
            then initializing;
            state initializing {
                entry action initialize {
                    assign acceptedRolls := 0;
                    then assign face := 0;
                }
            }
            transition initialized first initializing then ready;

            state ready;
            state qualifyingPress {
                do action waitForStablePress { accept after debounce; }
            }
            state held;
            state qualifyingRelease {
                do action waitForStableRelease { accept after debounce; }
            }

            transition closeContact first ready accept ButtonClosed then qualifyingPress;
            transition cancelPress first qualifyingPress accept ButtonOpened then ready;
            transition confirmPress first qualifyingPress
                do action registerRoll {
                    assign acceptedRolls := acceptedRolls + 1;
                    then if face == 6 {
                        assign face := 1;
                    } else {
                        assign face := face + 1;
                    }
                }
                then held;
            transition openContact first held accept ButtonOpened then qualifyingRelease;
            transition cancelRelease first qualifyingRelease accept ButtonClosed then held;
            transition confirmRelease first qualifyingRelease then ready;
        }

        bind command.face = firmware.face;
        allocate firmware to microcontroller;
    }
}

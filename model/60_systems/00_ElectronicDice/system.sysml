package ElectronicDice {
    private import DiceLibrary::*;
    private import Elan8::SystemsEngineering::*;
    private import ScalarValues::Integer;

    requirement def SingleRollRequirement {
        subject die : DiceSpecification;
        require constraint { die.rollsPerPress == 1 }
    }
    requirement <'DICE-SYS-001'> oneRollPerPress : SingleRollRequirement {
        doc /* Each deliberate press shall register exactly one roll. The demo
             * envelope includes up to 6 ms at either transient contact level,
             * followed by at least 40 ms at the stable pressed or released level. */
    }
    dependency rollRequirementSource
        from oneRollPerPress to DiceStakeholderRequirements::throwAtWill;

    part def DiceSpecification :> SystemSpecification {
        port button : ~ActuationPort;
        port display : PipPort;
        attribute rollsPerPress : Integer;
        satisfy oneRollPerPress;
    }

    part def DiceArchitecture :> DiceSpecification, SystemArchitecture {
        part rollButton : PushButton;
        part controller : RollController::RollControllerSpecification;
        part pipDisplay : PipDisplay;
        part battery : Battery;

        bind button = rollButton.actuator;
        bind display = pipDisplay.pips;
        connect rollButton.contact to controller.contact;
        connect controller.command to pipDisplay.command;
        connect battery.supply to controller.supply;
        connect battery.supply to pipDisplay.supply;
    }

    part def DiceIntegration :> DiceArchitecture, SystemIntegration {
        part redefines controller : RollController::RollControllerArchitecture;
        part redefines battery : ThreeAaaAlkalinePack;
    }
    part demoDie : DiceIntegration;
    dependency circuitRealizesSelectedDesign from DiceCircuit::Board to DiceIntegration;

    package Views {
        view specification : SpecificationView {
            expose ElectronicDice::DiceSpecification;
            expose ElectronicDice::oneRollPerPress;
        }
        view architecture : ArchitectureView {
            expose ElectronicDice::DiceArchitecture;
        }
        view integration : IntegrationView {
            expose ElectronicDice::demoDie;
        }
    }
}

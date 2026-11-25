package DiceContext {
    part def Player {
        port finger : DiceLibrary::ActuationPort;
        port sight : ~DiceLibrary::PipPort;
    }

    ref part player : Player;
    ref part die : ElectronicDice::DiceSpecification;
    connect player.finger to die.button;
    connect die.display to player.sight;

    view context : Elan8::SystemsEngineering::ContextView {
        expose DiceContext::**;
    }
}

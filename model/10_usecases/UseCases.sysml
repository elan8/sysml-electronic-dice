package DiceUseCases {
    use case rollDie {
        subject die : ElectronicDice::DiceSpecification;
        actor player : DiceContext::Player;
        doc /* The player presses and releases the roll button. The die registers
             * a single roll and shows its face as pips. Switch bounce is normal.
             * Holding the button does not cause another roll. */
    }
}

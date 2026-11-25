package DiceStakeholderRequirements {
    requirement <'DICE-NEED-001'> throwAtWill {
        subject die : ElectronicDice::DiceSpecification;
        doc /* The player needs each deliberate press to count as one throw,
             * with a face that can be read across the game table. */
    }
}

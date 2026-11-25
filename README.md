# Electronic dice

A pocket-sized, battery-powered die with a pushbutton, a microcontroller and a seven-LED pip display. The first increment asks whether one deliberate press produces exactly one roll when the switch bounces.

## Model

The project follows [Elan8 MBSE Methodology](https://github.com/elan8/mbse-methodology). [Root.sysml](model/Root.sysml) aliases the selected product as `systemOfInterest`.

| Area | Contents |
| --- | --- |
| [Context](model/00_context/Context.sysml) and [use case](model/10_usecases/UseCases.sysml) | The player presses the button and reads the pips. |
| [Stakeholder needs](model/20_requirements/StakeholderRequirements.sysml) | One throw per deliberate press and a readable result. |
| [Electronic dice](model/60_systems/00_ElectronicDice/system.sysml) | Black-box specification, gray-box architecture and white-box selection of the controller design. |
| [Roll controller](model/60_systems/RollController/system.sysml) | Controller contract and firmware behavior allocated to the microcontroller. |
| [Verification](model/60_systems/00_ElectronicDice/Verification.sysml) | Timed raw-contact inputs and assertions on roll count and face. |
| [Report](model/80_documents/Documents.sysml) | Doc42 architecture, requirement traceability and Run42 verdicts. |

## Run the demo

Use Spec42 0.60.2, the SysML v2 2026-04 standard-library sources, the Elan8 domain-library sources, a Run42 build that supports authored state-machine verification, and Doc42 0.8.1. The verified local tool and dependency details are in [project.md](project.md). Commercial builds use the applicable Elan8 credentials.

From this project directory, with the tools on PATH:

```powershell
./scripts/demo.ps1 -StdlibPath <expanded-stdlib> -DomainLibraryPath <domain-library-model>
```

Pass `-Spec42`, `-Run42` and `-Doc42` to select specific executables. Each execution stores its model snapshots and evidence in a new `generated/` subdirectory. The script checks the selected model, changes only the debounce setting in the comparison snapshot, runs both snapshots, and builds `DICE-VR-001.pdf` using the resulting JSON records.

| Scenario | 3 ms comparison | 10 ms selected |
| --- | --- | --- |
| One bouncing press | Fail. The count and face assertions fail. | Pass. One roll registers. |
| Release bounce and a second deliberate press | Fail. The count and face assertions fail. | Pass. Two rolls register. |

The stimulus uses raw contact edges with 6 ms transient pulses and 40 ms stable intervals. The selected design qualifies both closure and opening before it accepts a roll or re-arms. The face advances through a deterministic 1–6 sequence so the cases can check the observed face as well as the count. This increment executes the logical controller. Pip mapping, display timeout, a production random number generator, compiled firmware and electrical simulation are follow-on work.

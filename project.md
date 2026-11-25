# Project baseline

- System of interest is `ElectronicDice::demoDie`. The player operates the button and reads the display from outside the product boundary.
- The model follows Elan8 methodology 0.5.0. The die has specification, architecture and integration definitions. The developed roll controller has a specification and an architecture. The selected die integration redefines its controller usage with that architecture.
- The language baseline is SysML v2.0 with the 2026-04 standard-library distribution. The validated Spec42 release is 0.60.2.
- The local run used the domain-library source at revision `f546777607f153293adc7f913eceaa680315cc19` under `run42/.cache/domain-library/model`. This supplies the Elan8 method roles. Doc42 0.8.1 supplies the document vocabulary and rendering.
- The tested Run42 executable reports `0.0.0 (Rumoca 0.10.4 embedded) (unlicensed development build)`. Its SHA-256 is `ffc8415ca0334f780282d3a93adc6aee866a69003ba2b4c79e56b0449cb34645`. Run42 records its build status and input hashes in each verdict file.

## Local reproduction

From the workspace containing the Elan8 checkouts:

```powershell
./sysml-electronic-dice/scripts/demo.ps1 `
    -Spec42 ./.cleanup/spec42-0.60.2-ci/spec42.exe `
    -Run42 ./run42/target/debug/run42.exe `
    -Doc42 ./doc42/target/release-0.8.1/windows/doc42.exe `
    -StdlibPath ./run42/.cache/sysml-stdlib-2026-04/expanded `
    -DomainLibraryPath ./run42/.cache/domain-library/model
```

The selected model passes Spec42 with zero warnings or errors. A Spec42 model export with referenced library elements also passes the methodology's `check_structure.py --complete-selection` check. Both Run42 cases fail their assertions at 3 ms and pass at 10 ms. Doc42 reads both JSON files and generates the report.

The stimulus starts with the switch open. The 6 ms transients and 40 ms stable periods are illustrative. The tests bypass GPIO physics and exercise the selected controller behavior with logical edges. The report establishes the outcome for the two authored scenarios.

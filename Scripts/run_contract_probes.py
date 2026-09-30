#!/usr/bin/env python3
"""Compile and run production-source contracts on macOS without SDKs or payments.

SwiftPM builds verify the complete module separately. Dependency roots default to
its checkouts; BROAD_CORE_ROOT and BROAD_MONETIZATION_ROOT can select local copies.
Only an explicit Combine import is added to temporary UIFlows source copies.
"""

import os
from pathlib import Path
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parent.parent
CORE = Path(os.environ.get("BROAD_CORE_ROOT", ROOT / ".build/checkouts/broad-core-ios"))
MONETIZATION = Path(os.environ.get(
    "BROAD_MONETIZATION_ROOT", ROOT / ".build/checkouts/broad-monetization-ios"
))


def run(arguments):
    subprocess.run(list(map(str, arguments)), check=True)


def require_sources(files):
    for path in files:
        if not path.is_file():
            raise FileNotFoundError(f"Missing production source: {path}")
    return files


def main():
    for name, dependency in (("BROAD_CORE_ROOT", CORE), ("BROAD_MONETIZATION_ROOT", MONETIZATION)):
        if not (dependency / "Sources").is_dir():
            raise FileNotFoundError(
                f"Dependency checkout missing: {dependency}. Build the package first or set {name}."
            )

    with tempfile.TemporaryDirectory(prefix="broad-ui-contracts-") as temporary:
        scratch = Path(temporary)
        flags = ["xcrun", "swiftc", "-swift-version", "5", "-strict-concurrency=complete",
                 "-warnings-as-errors", "-module-cache-path", scratch / "ModuleCache"]
        core_source = CORE / "Sources/BroadCore"
        core_files = sorted((core_source / "Domain").rglob("*.swift"))
        core_files += [core_source / name for name in (
            "Infrastructure/Networking/NetworkFailureClassifier.swift",
            "Application/Storage/KeyValueStoreProtocol.swift",
            "Data/Cache/VersionedJSONCacheRepository.swift",
            "Infrastructure/Logging/NoOpBroadLogger.swift",
        )]
        print("Building production BroadCore contracts", flush=True)
        run([*flags, "-emit-library", "-emit-module", "-module-name", "BroadCore",
             *require_sources(core_files), "-emit-module-path", scratch / "BroadCore.swiftmodule",
             "-o", scratch / "libBroadCore.dylib"])

        base = MONETIZATION / "Sources/BroadMonetization"
        monetization_files = sorted((base / "Domain").rglob("*.swift"))
        for directory in ("Infrastructure/RemoteConfig", "Application/Recovery"):
            monetization_files += sorted((base / directory).rglob("*.swift"))
        monetization_files += [base / name for name in (
            "Application/Purchase/MonetizationOperationGate.swift",
            "Application/Purchase/PendingApplePurchaseStoreProtocol.swift",
            "Application/PurchaseManagers/TokenPurchaseModels.swift",
            "Application/PurchaseManagers/TokenPurchaseManager.swift",
            "Application/Checkout/CheckoutSelectedProductUseCase.swift",
            "Infrastructure/Analytics/NoOpMonetizationAnalytics.swift",
            "Infrastructure/Analytics/NonBlockingMonetizationAnalytics.swift",
        )]
        linking = ["-I", scratch, "-L", scratch, "-lBroadCore",
                   "-Xlinker", "-rpath", "-Xlinker", scratch]
        print("Building production BroadMonetization contracts", flush=True)
        run([*flags, "-emit-library", "-emit-module", "-module-name", "BroadMonetization",
             *linking, *require_sources(monetization_files),
             "-emit-module-path", scratch / "BroadMonetization.swiftmodule",
             "-o", scratch / "libBroadMonetization.dylib"])

        ui_source = ROOT / "Sources/BroadUIFlows"
        ui_files = sorted((ui_source / "Domain/Paywall").rglob("*.swift"))
        for directory in ("Presentation/Paywall", "Presentation/TokenPaywall"):
            for path in sorted((ui_source / directory).glob("*.swift")):
                if "import SwiftUI" not in path.read_text():
                    ui_files.append(path)
        sources = []
        for index, path in enumerate(require_sources(ui_files)):
            copy = scratch / f"{index}-{path.name}"
            copy.write_text("import Combine\n" + path.read_text())
            sources.append(copy)

        probes = ROOT / "Scripts/ContractProbes"
        for name in ("TokenCatalogProbe", "ProductNamesProbe"):
            print(f"Running {name}", flush=True)
            executable = scratch / name
            run([*flags, "-parse-as-library", *linking, "-lBroadMonetization", *sources,
                 probes / "ContractProbeSupport.swift", probes / f"{name}.swift", "-o", executable])
            run([executable])
        print("PASS: all executable UIFlows contracts", flush=True)
        print("Settings host/gate: use Gallery > Settings (real host); requires SwiftUI/UIKit.", flush=True)


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        print(f"FAIL: compiler or executable exited with code {error.returncode}", file=sys.stderr)
        sys.exit(1)
    except OSError as error:
        print(f"FAIL: contract probes: {error}", file=sys.stderr)
        sys.exit(1)

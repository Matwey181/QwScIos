"""Keep the standalone Swift exporter on the native wire model and curves."""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
source=(root/'ios/App/MotionModel.swift').read_text()
core=source.split('@MainActor enum MotionEvaluator')[0].replace('import UIKit\n','')
(root/'ios/Resources/motion-core.txt').write_text(core)

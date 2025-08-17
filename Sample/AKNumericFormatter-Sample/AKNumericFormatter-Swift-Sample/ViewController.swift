//
//  ViewController.swift
//  AKNumericFormatter-Swift-Sample
//
//  Created by imurashov on 15.08.2025.
//

import UIKit
import AKNumericFormatter_Swift

class ViewController: UIViewController {
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var formatFulfilledLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateFormatterDependentUI()
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            textField.numericFormatter = nil
        } else {
            let mode: AKNumericFormatter.Mode = (sender.selectedSegmentIndex == 1) ? .mixed : .strict
            textField.numericFormatter = AKNumericFormatter.formatter(mask: "+1(***)***-****", placeholder: "*", mode: mode)
        }
        updateFormatterDependentUI()
    }

    @IBAction func textFieldEditingChanged(_ sender: Any) {
        updateFormatFulfilledLabel()
    }

    private func updateFormatterDependentUI() {
        textField.placeholder = textField.numericFormatter?.mask
        updateFormatFulfilledLabel()
    }

    private func updateFormatFulfilledLabel() {
        if let formatter = textField.numericFormatter {
            let isFormatFulfilled = formatter.isFormatFulfilled(textField.text ?? "")
            formatFulfilledLabel.text = "Format fulfilled: " + (isFormatFulfilled ? "YES" : "NO")
            formatFulfilledLabel.isHidden = false
        } else {
            formatFulfilledLabel.isHidden = true
        }
    }
}

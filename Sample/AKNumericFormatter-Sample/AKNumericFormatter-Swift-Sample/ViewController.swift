//
//  ViewController.swift
//  AKNumericFormatter-Swift-Sample
//
//  Created by imurashov on 15.08.2025.
//

import UIKit
import AKNumericFormatter_Swift

class ViewController: UIViewController {
    
    private let segmentedControl = UISegmentedControl(
        items: ["Без форматирования", "Смешанный", "Строгий"]
    )
    private let textField = UITextField()
    private let formatFulfilledLabel = UILabel()

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white

        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        formatFulfilledLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(segmentedControl)
        view.addSubview(textField)
        view.addSubview(formatFulfilledLabel)

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            textField.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textField.heightAnchor.constraint(equalToConstant: 40),

            formatFulfilledLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 12),
            formatFulfilledLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            formatFulfilledLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        textField.borderStyle = .roundedRect
        textField.placeholder = ""

        formatFulfilledLabel.textColor = .darkGray
        formatFulfilledLabel.textAlignment = .left
        formatFulfilledLabel.isHidden = true

        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = 0

        textField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)

        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateFormatterDependentUI()
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            textField.numericFormatter = nil
        } else {
            let mode: AKNumericFormatter.Mode = (sender.selectedSegmentIndex == 1) ? .mixed : .strict
            textField.numericFormatter = AKNumericFormatter.formatter(mask: "+1(***)***-****", placeholder: "*", mode: mode)
        }
        updateFormatterDependentUI()
    }

    @objc private func textFieldEditingChanged(_ sender: UITextField) {
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

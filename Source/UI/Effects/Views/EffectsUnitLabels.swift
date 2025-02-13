//
//  EffectsUnitLabels.swift
//  Aural
//
//  Copyright © 2025 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//  
import Cocoa

// Marker classes / protocols to differentiate between different types of labels when
// recursively traversing through a view tree.

protocol FunctionLabel {}

protocol FunctionCaptionLabel: FunctionLabel {}

protocol FunctionValueLabel: FunctionLabel {}

class CenterTextFunctionCaptionLabel: CenterTextLabel, FunctionCaptionLabel {
}

class TopTextFunctionCaptionLabel: TopTextLabel, FunctionCaptionLabel {
}

class TopTextFunctionValueLabel: TopTextLabel, FunctionValueLabel {
}

class BottomTextFunctionCaptionLabel: BottomTextLabel, FunctionCaptionLabel {
}

class BottomTextFunctionValueLabel: BottomTextLabel, FunctionValueLabel {
}

class CenterTextFunctionValueLabel: CenterTextLabel, FunctionValueLabel {
}

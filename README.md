# Furniture Disassembler - SketchUp Plugin Documentation

![SketchUp Plugin](https://img.shields.io/badge/SketchUp-Plugin-green.svg)
![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Technical Specifications](#technical-specifications)
- [Export Formats](#export-formats)
- [License](#license)
- [Contributing](#contributing)

## Overview

The Furniture Disassembler is a SketchUp plugin designed to automate the process of preparing 3D furniture models for CNC manufacturing. It identifies flat panels, optimizes their arrangement on standard sheet sizes, and generates production-ready files.

## Features

### Core Functionality
- **Panel Detection**:
  - Automatically identifies flat panel components
  - Configurable thickness threshold (default: <50mm)
  - Handles both Groups and Component Instances

- **Smart Nesting**:
  - Arranges panels on standard sheet sizes (2440mm×1220mm default)
  - First-fit decreasing algorithm for space optimization
  - Tracks remaining material on each sheet

### Export Capabilities
- **CSV Export**:
  - Spreadsheet with all panel dimensions
  - Includes sheet assignment for each panel
- **DXF Export**:
  - 2D representations of all panels
  - Compatible with most CNC software

### Reporting
- Detailed summary of detected panels
- Visual feedback through SketchUp's UI

## Installation

1. Download the `furniture_disassembler.rb` file
2. Place it in SketchUp's Plugins folder:
   - Windows: `C:\Users\[USERNAME]\AppData\Roaming\SketchUp\SketchUp [VERSION]\SketchUp\Plugins`
   - Mac: `~/Library/Application Support/SketchUp [VERSION]/SketchUp/Plugins`
3. Restart SketchUp

## Usage

1. **Run the Plugin**:
   - Navigate to: `Plugins → Extract Panels for CNC`

2. **Workflow**:
   - The plugin will:
     1. Scan your model for panels
     2. Show a summary report
     3. Prompt to save CSV and DXF files

3. **Customization**:
   - Adjust panel thickness threshold in code (line 47)
   - Modify standard sheet sizes in code (lines 69-70)

## Technical Specifications

### Requirements
- SketchUp 2017 or later
- Ruby (included with SketchUp)

### Data Structure
Panels are represented as hashes with:
```ruby
{
  entity: Sketchup::ComponentInstance,  # Reference to the model object
  width: Length,                        # Panel width in mm
  height: Length,                       # Panel height in mm
  thickness: Length,                    # Panel thickness in mm
  sheet: Integer                        # Sheet assignment number
}

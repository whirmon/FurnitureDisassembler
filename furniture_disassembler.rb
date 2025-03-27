# Furniture Disassembler - A SketchUp plugin for CNC panel extraction
# Copyright (c) 2025 Pablo J. Zuniga
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module FurnitureDisassembler
    require 'sketchup.rb'  # SketchUp API
    require 'csv'          # Ruby CSV library for export
  
    # Main function to extract panels from the current model
    # Scans through all entities, identifies flat panels, nests them, and generates exports
    def self.extract_panels
      # Get active SketchUp model and its entities
      model = Sketchup.active_model
      entities = model.active_entities
      panels = []
      
      # Iterate through all entities in the model
      entities.each do |entity|
        # Only process groups and component instances
        next unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
        
        # Get bounding box dimensions of the entity
        bbox = entity.bounds
        
        # Sort dimensions to identify thickness (smallest dimension)
        dims = [bbox.width, bbox.height, bbox.depth].sort
        thickness = dims[0]  # Smallest dimension is thickness
        width = dims[1]      # Middle dimension is width
        height = dims[2]     # Largest dimension is height
        
        # Identify as panel if thickness is below threshold (adjustable)
        if thickness < 50.mm # 50mm threshold for panel thickness
          panels << { 
            entity: entity, 
            width: width, 
            height: height, 
            thickness: thickness 
          }
        end
      end
      
      # Process the detected panels
      panels = nest_panels(panels)  # Nest panels on standard sheets
      export_to_csv(panels)         # Export to CSV file
      generate_dxf(panels)          # Generate DXF file
      report_panels(panels)         # Show summary report
      
      panels  # Return the panels array (optional)
    end
    
    # Nests panels on standard sheet sizes to optimize material usage
    # @param panels [Array] Array of panel hashes with width/height dimensions
    # @return [Array] Array of panels with sheet assignments added
    def self.nest_panels(panels)
      return panels if panels.empty?  # Return if no panels
      
      # Standard sheet dimensions (2440x1220mm is common for plywood/MDF)
      sheet_width = 2440.mm
      sheet_height = 1220.mm
      used_space = []  # Tracks available space on each sheet
      
      # Sort panels by largest dimension first (better for nesting)
      panels.sort_by! { |p| -[p[:width], p[:height]].max }
      nested_panels = []
      
      # Nesting algorithm (first-fit decreasing size)
      panels.each do |panel|
        placed = false
        
        # Try to place panel on existing sheets with available space
        used_space.each do |space|
          if (panel[:width] <= space[:remaining_width] && 
              panel[:height] <= space[:remaining_height])
            # Place panel and reduce available space
            space[:remaining_width] -= panel[:width]
            nested_panels << panel.merge(sheet: space[:sheet])
            placed = true
            break
          end
        end
        
        # If panel didn't fit, create new sheet
        unless placed
          new_sheet = { 
            width: sheet_width, 
            height: sheet_height, 
            remaining_width: sheet_width - panel[:width],
            remaining_height: sheet_height,
            sheet: used_space.size + 1 
          }
          used_space << new_sheet
          nested_panels << panel.merge(sheet: new_sheet[:sheet])
        end
      end
      
      nested_panels
    end
    
    # Generates a summary report of detected panels
    # @param panels [Array] Array of panel hashes
    def self.report_panels(panels)
      return UI.messagebox("No panels detected.") if panels.empty?
      
      report = "Detected Panels:\n"
      panels.each_with_index do |panel, index|
        report += "Panel #{index + 1} (Sheet #{panel[:sheet]}): " \
                  "Width: #{panel[:width].to_mm}mm, " \
                  "Height: #{panel[:height].to_mm}mm, " \
                  "Thickness: #{panel[:thickness].to_mm}mm\n"
      end
      
      UI.messagebox(report)
    end
    
    # Exports panel data to CSV file
    # @param panels [Array] Array of panel hashes
    def self.export_to_csv(panels)
      return if panels.empty?  # Exit if no panels
      
      # Prompt user for save location
      filepath = UI.savepanel("Save Panel Data", "", "panels.csv")
      return unless filepath  # Exit if user cancels
      
      # Write CSV data
      CSV.open(filepath, "w") do |csv|
        csv << ["Sheet", "Width (mm)", "Height (mm)", "Thickness (mm)"]
        panels.each do |panel|
          csv << [
            panel[:sheet], 
            panel[:width].to_mm, 
            panel[:height].to_mm, 
            panel[:thickness].to_mm
          ]
        end
      end
      
      UI.messagebox("CSV file saved successfully!")
    end
    
    # Generates a DXF file with 2D representations of panels
    # @param panels [Array] Array of panel hashes
    def self.generate_dxf(panels)
      return if panels.empty?  # Exit if no panels
      
      # Prompt user for save location
      filepath = UI.savepanel("Save DXF File", "", "panels.dxf")
      return unless filepath  # Exit if user cancels
      
      # Write DXF file (basic format)
      File.open(filepath, "w") do |file|
        # DXF header sections
        file.puts "0\nSECTION\n2\nHEADER\n0\nENDSEC"
        file.puts "0\nSECTION\n2\nTABLES\n0\nENDSEC"
        file.puts "0\nSECTION\n2\nBLOCKS\n0\nENDSEC"
        
        # Entities section (where our geometry goes)
        file.puts "0\nSECTION\n2\nENTITIES"
        
        # Create a rectangle (LWPOLYLINE) for each panel
        panels.each do |panel|
          width = panel[:width].to_mm
          height = panel[:height].to_mm
          
          file.puts "0\nLWPOLYLINE"
          file.puts "8\n0"       # Layer 0
          file.puts "90\n4"      # 4 vertices
          # Rectangle vertices (counter-clockwise)
          file.puts "10\n0\n20\n0"             # Bottom-left
          file.puts "10\n#{width}\n20\n0"       # Bottom-right
          file.puts "10\n#{width}\n20\n#{height}" # Top-right
          file.puts "10\n0\n20\n#{height}"      # Top-left
        end
        
        # Close DXF sections
        file.puts "0\nENDSEC"
        file.puts "0\nEOF"
      end
      
      UI.messagebox("DXF file saved successfully!")
    end
    
    # Register the plugin menu item (if not already loaded)
    unless file_loaded?(__FILE__)
      UI.menu("Plugins").add_item("Extract Panels for CNC") { self.extract_panels }
      file_loaded(__FILE__)
    end
  end